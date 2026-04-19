#!/usr/bin/env python3
"""Surgical, schema-safe patcher for GestaoFerias_VacationApproval flow JSON.

This script updates only workflow logic/actions while preserving connector topology.
"""

from __future__ import annotations

import argparse
import json
import shutil
import tempfile
import zipfile
from pathlib import Path
from typing import Any, Dict


PENDING_EXPRESSION = {
    "and": [
        {
            "equals": [
                "@coalesce(triggerOutputs()?['body/Status/Value'], triggerOutputs()?['body/Status'])",
                "PENDING",
            ]
        }
    ]
}

EMPLOYEE_FOUND_EXPRESSION = {
    "and": [{"greater": ["@length(outputs('GetEmployeeDetails')?['body/value'])", 0]}]
}

BALANCE_FOUND_EXPRESSION = {
    "and": [{"greater": ["@length(outputs('GetCurrentBalance')?['body/value'])", 0]}]
}


def _parse_card(card_text: str) -> Dict[str, Any]:
    return json.loads(card_text)


def _dump_card(card: Dict[str, Any]) -> str:
    return json.dumps(card, ensure_ascii=False, indent=2)


def patch_definition_obj(flow_obj: Dict[str, Any]) -> Dict[str, Any]:
    definition = flow_obj["properties"]["definition"]
    actions = definition["actions"]

    def ensure_failed_terminate(container: Dict[str, Any], name: str) -> None:
        terminate = container.get(name, {"type": "Terminate", "inputs": {"runStatus": "Failed"}})
        if terminate.get("type") != "Terminate":
            terminate = {"type": "Terminate", "inputs": {"runStatus": "Failed"}}
        terminate_inputs = terminate.setdefault("inputs", {})
        terminate_inputs["runStatus"] = "Failed"
        terminate_inputs.pop("runError", None)
        container[name] = terminate

    condition_pending = actions["Condition_Status_PENDING"]
    condition_pending["expression"] = PENDING_EXPRESSION
    pending_yes_actions = condition_pending.setdefault("actions", {})

    employee_if = pending_yes_actions.get("Condition_Employee_Found")
    if employee_if and employee_if.get("type") == "If":
        employee_actions = employee_if.setdefault("actions", {})
        employee_actions.pop("Set_varApproverEmail_FromDirectory", None)
        post_card = employee_actions.get("PostApprovalCard")
        condition_approved = employee_actions.get("Condition_Approved")
    else:
        post_card = pending_yes_actions.pop("PostApprovalCard", None)
        condition_approved = pending_yes_actions.pop("Condition_Approved", None)
        employee_if = {
            "type": "If",
            "expression": EMPLOYEE_FOUND_EXPRESSION,
            "actions": {
                "PostApprovalCard": post_card,
                "Condition_Approved": condition_approved,
            },
            "else": {"actions": {}},
        }
        pending_yes_actions["Condition_Employee_Found"] = employee_if
        employee_actions = employee_if["actions"]

    if post_card is None or condition_approved is None:
        raise RuntimeError("Could not locate PostApprovalCard/Condition_Approved actions to patch.")

    # Enforce employee guard structure.
    employee_if["expression"] = EMPLOYEE_FOUND_EXPRESSION
    employee_else_actions = employee_if.setdefault("else", {}).setdefault("actions", {})
    ensure_failed_terminate(employee_else_actions, "Terminate_Employee_Not_Found")

    # Enrich adaptive card with TemConflito indicator.
    card_path = "body/body/messageBody"
    card_text = post_card["inputs"]["parameters"][card_path]
    card_json = _parse_card(card_text)
    for block in card_json.get("body", []):
        if block.get("type") != "FactSet":
            continue
        facts = block.get("facts", [])
        has_conflict = any(f.get("title") == "Conflito com equipe:" for f in facts)
        if not has_conflict:
            facts.insert(
                4,
                {
                    "title": "Conflito com equipe:",
                    "value": "@{if(triggerOutputs()?['body/TemConflito'], 'SIM', 'Nao')}",
                },
            )
    post_card["inputs"]["parameters"][card_path] = _dump_card(card_json)

    # Keep schema conservative: no SetVariable chaining/self-reference.
    post_card["inputs"]["parameters"]["body/body/recipient/to"] = (
        "@{coalesce(first(outputs('GetEmployeeDetails')?['body/value'])?['AprovadorEmail'], variables('varApproverEmail'))}"
    )
    post_card.pop("runAfter", None)
    employee_actions["PostApprovalCard"] = post_card
    employee_actions["Condition_Approved"] = condition_approved

    # Approved branch integrity/order fixes.
    approved_actions = condition_approved.setdefault("actions", {})
    balance_if = approved_actions.get("Condition_Balance_Record_Found")
    balance_actions: Dict[str, Any]
    if balance_if and balance_if.get("type") == "If":
        balance_actions = balance_if.setdefault("actions", {})
    else:
        balance_if = {"type": "If", "actions": {}, "else": {"actions": {}}}
        approved_actions["Condition_Balance_Record_Found"] = balance_if
        balance_actions = balance_if["actions"]

    get_current_balance = approved_actions.get("GetCurrentBalance")
    if get_current_balance is None:
        get_current_balance = balance_actions.get("GetCurrentBalance")
    if get_current_balance is None:
        get_current_balance = approved_actions.get("GetCurrentBalance")
    if get_current_balance is None:
        get_current_balance = approved_actions.pop("GetCurrentBalance", None)
    else:
        approved_actions.pop("GetCurrentBalance", None)

    update_status_approved = balance_actions.get("Update_Status_APPROVED") or approved_actions.pop(
        "Update_Status_APPROVED", None
    )
    update_balance = balance_actions.get("Update_Balance_Deduct") or approved_actions.pop(
        "Update_Balance_Deduct", None
    )
    notify_teams_approved = balance_actions.get("Notify_Employee_Teams_Approved") or approved_actions.pop(
        "Notify_Employee_Teams_Approved", None
    )
    notify_email_approved = balance_actions.get("Notify_Employee_Email_Approved") or approved_actions.pop(
        "Notify_Employee_Email_Approved", None
    )

    if None in (
        get_current_balance,
        update_status_approved,
        update_balance,
        notify_teams_approved,
        notify_email_approved,
    ):
        raise RuntimeError("Could not locate all approved-branch actions to patch.")

    get_current_balance["runAfter"] = {}

    update_balance["runAfter"] = {}
    update_balance_params = update_balance["inputs"]["parameters"]
    update_balance_params["item/DiasAgendados"] = (
        "@{add(first(outputs('GetCurrentBalance')?['body/value'])?['DiasAgendados'], triggerOutputs()?['body/DiasUteis'])}"
    )
    update_balance_params["item/DataAtualizacao"] = "@{utcNow()}"

    update_status_approved["runAfter"] = {"Update_Balance_Deduct": ["Succeeded"]}
    update_status_approved["inputs"]["parameters"]["item/DataAprovacao"] = "@{utcNow()}"

    notify_teams_approved["runAfter"] = {"Update_Status_APPROVED": ["Succeeded"]}
    notify_email_approved["runAfter"] = {
        "Notify_Employee_Teams_Approved": ["Succeeded", "Failed", "Skipped"]
    }

    balance_if["type"] = "If"
    balance_if["runAfter"] = {"GetCurrentBalance": ["Succeeded"]}
    balance_if["expression"] = BALANCE_FOUND_EXPRESSION
    balance_if["actions"] = {
        "Update_Balance_Deduct": update_balance,
        "Update_Status_APPROVED": update_status_approved,
        "Notify_Employee_Teams_Approved": notify_teams_approved,
        "Notify_Employee_Email_Approved": notify_email_approved,
    }
    balance_else_actions = balance_if.setdefault("else", {}).setdefault("actions", {})
    ensure_failed_terminate(balance_else_actions, "Terminate_Balance_Not_Found")

    approved_actions["GetCurrentBalance"] = get_current_balance
    approved_actions["Condition_Balance_Record_Found"] = balance_if

    # Rejected branch: stamp DataAprovacao.
    rejected_actions = condition_approved.setdefault("else", {}).setdefault("actions", {})
    update_status_rejected = rejected_actions.get("Update_Status_REJECTED")
    if update_status_rejected:
        update_status_rejected["inputs"]["parameters"]["item/DataAprovacao"] = "@{utcNow()}"

    # Ops visibility hardening.
    flow_obj["properties"]["flowFailureAlertSubscribed"] = True
    return flow_obj


def patch_definition_file(path: Path) -> None:
    obj = json.loads(path.read_text(encoding="utf-8"))
    patched = patch_definition_obj(obj)
    path.write_text(
        json.dumps(patched, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )


def patch_export_zip(input_zip: Path, output_zip: Path) -> None:
    with tempfile.TemporaryDirectory(prefix="flow_patch_") as td:
        temp_dir = Path(td)
        with zipfile.ZipFile(input_zip, "r") as zf:
            zf.extractall(temp_dir)

        definition_files = list(temp_dir.glob("Microsoft.Flow/flows/*/definition.json"))
        if len(definition_files) != 1:
            raise RuntimeError(
                f"Expected exactly one definition.json in export, found {len(definition_files)}."
            )

        patch_definition_file(definition_files[0])
        with zipfile.ZipFile(output_zip, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            for file_path in temp_dir.rglob("*"):
                if file_path.is_file():
                    zf.write(file_path, arcname=str(file_path.relative_to(temp_dir)))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--definition", type=Path, help="Path to VacationApproval_Definition.json")
    parser.add_argument("--input-zip", type=Path, help="Path to exported package zip")
    parser.add_argument("--output-zip", type=Path, help="Path to output patched zip")
    args = parser.parse_args()

    if args.definition:
        patch_definition_file(args.definition)
        print(f"Patched definition: {args.definition}")

    if args.input_zip:
        if not args.output_zip:
            raise SystemExit("--output-zip is required when --input-zip is provided.")
        patch_export_zip(args.input_zip, args.output_zip)
        print(f"Patched zip: {args.output_zip}")

    if not args.definition and not args.input_zip:
        raise SystemExit("Provide --definition and/or --input-zip.")


if __name__ == "__main__":
    main()
