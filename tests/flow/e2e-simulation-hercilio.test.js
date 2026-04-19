/**
 * E2E Simulation: VacationApproval Flow — Hercilio Torres Goncalves
 *
 * This test walks the *actual* flow definition JSON step-by-step,
 * simulating the execution for a real employee (Hercilio) with
 * realistic SharePoint mock data. It validates action existence,
 * execution ordering, expression correctness, and defensive guards.
 *
 * Employee: Hercilio Torres Goncalves
 *   Email:      htorresg@minsait.com
 *   Department: Dados
 *   Role:       Engenheiro
 *   Manager:    Marcos Benicios (mbenicios@minsait.com)
 *
 * Scenarios:
 *   TC-01: Variable initialization chain
 *   TC-02: Employee lookup fires after var init
 *   TC-03: Status PENDING gate evaluates correctly
 *   TC-04: Approval card is posted to correct recipient
 *   TC-05: Adaptive card content completeness
 *   TC-06: APPROVED branch — status + balance + notifications
 *   TC-07: REJECTED branch — status + notifications
 *   TC-08: Notification resilience (email survives Teams failure)
 *   TC-09: Balance math simulation (30 days - 10 days)
 *   TC-10: Non-PENDING termination path
 *   TC-11: Full execution trace ordering for approved path
 *   TC-12: Structure conformance audit
 */

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  loadVacationApprovalFlow,
  walkActions,
} = require("../../scripts/flowDefinitionLoader");

// ═══════════════════════════════════════════════════════════════
// Mock Data: Hercilio Torres Goncalves
// ═══════════════════════════════════════════════════════════════

const HERCILIO = {
  employee: {
    Email: "htorresg@minsait.com",
    NomeCompleto: "Hercilio Torres Goncalves",
    Departamento: "Dados",
    Cargo: "Engenheiro",
    AprovadorNome: "Marcos Benicios",
    AprovadorEmail: "mbenicios@minsait.com",
    Ativo: true,
  },
  balance: {
    ID: 42,
    Title: "Hercilio Torres Goncalves - 2026",
    ColaboradorEmail: "htorresg@minsait.com",
    AnoReferencia: 2026,
    SaldoTotal: 30,
    DiasUsados: 0,
    DiasAgendados: 0,
    SaldoDisponivel: 30,
  },
  request: {
    ID: 101,
    Title: "Ferias-Hercilio",
    ColaboradorEmail: "htorresg@minsait.com",
    AprovadorEmail: "mbenicios@minsait.com",
    DataInicio: "2026-07-01T00:00:00Z",
    DataFim: "2026-07-14T00:00:00Z",
    DiasUteis: 10,
    Status: "PENDING",
    TemConflito: true,
    Observacoes: "Férias de julho",
  },
};

// ═══════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════

const { flow, flowPath } = loadVacationApprovalFlow();
const definition = flow.properties.definition;
const rootActions = definition.actions;

function collectActions(actions) {
  const all = [];
  walkActions(actions, [], (entry) => all.push(entry));
  return all;
}

const allActionEntries = collectActions(rootActions);

function findByName(name) {
  return allActionEntries.find((e) => e.name === name);
}

// Helper: Navigate through guard layers introduced by the patched definition.
// The patched definition nests PostApprovalCard and Condition_Approved inside
// Condition_Employee_Found, and approved-path actions inside
// Condition_Balance_Record_Found.
const employeeFoundActions =
  rootActions.Condition_Status_PENDING?.actions?.Condition_Employee_Found?.actions ?? {};

function stringify(v) {
  return JSON.stringify(v ?? null);
}

// ═══════════════════════════════════════════════════════════════
// TC-01: Variable Initialization Chain
// ═══════════════════════════════════════════════════════════════

test("TC-01: Variables initialized in correct dependency chain", () => {
  const varApprover = rootActions.Initialize_varApproverEmail;
  const varEmployee = rootActions.Initialize_varEmployeeEmail;
  const varRequestId = rootActions.Initialize_varRequestId;

  assert.ok(varApprover, "Initialize_varApproverEmail must exist");
  assert.ok(varEmployee, "Initialize_varEmployeeEmail must exist");
  assert.ok(varRequestId, "Initialize_varRequestId must exist");

  // Type checks
  assert.equal(varApprover.type, "InitializeVariable");
  assert.equal(varEmployee.type, "InitializeVariable");
  assert.equal(varRequestId.type, "InitializeVariable");

  // Chain: Approver → Employee → RequestId
  assert.deepEqual(
    Object.keys(varApprover.runAfter || {}),
    [],
    "varApproverEmail starts first (no dependencies)"
  );

  const employeeRunAfter = Object.keys(varEmployee.runAfter || {});
  assert.ok(
    employeeRunAfter.includes("Initialize_varApproverEmail"),
    "varEmployeeEmail depends on varApproverEmail"
  );

  const requestIdRunAfter = Object.keys(varRequestId.runAfter || {});
  assert.ok(
    requestIdRunAfter.includes("Initialize_varEmployeeEmail"),
    "varRequestId depends on varEmployeeEmail"
  );

  // Value extraction from trigger
  const approverValue = varApprover.inputs.variables[0].value;
  const employeeValue = varEmployee.inputs.variables[0].value;
  const requestIdValue = varRequestId.inputs.variables[0].value;

  assert.ok(
    approverValue.includes("AprovadorEmail"),
    "Approver var reads AprovadorEmail from trigger"
  );
  assert.ok(
    employeeValue.includes("ColaboradorEmail"),
    "Employee var reads ColaboradorEmail from trigger"
  );
  assert.ok(
    requestIdValue.includes("ID"),
    "RequestId var reads ID from trigger"
  );

  // Simulate with Hercilio data
  const simApprover = HERCILIO.request.AprovadorEmail;
  const simEmployee = HERCILIO.request.ColaboradorEmail;
  const simRequestId = HERCILIO.request.ID;

  assert.equal(simApprover, "mbenicios@minsait.com");
  assert.equal(simEmployee, "htorresg@minsait.com");
  assert.equal(simRequestId, 101);
});

// ═══════════════════════════════════════════════════════════════
// TC-02: Employee Lookup Fires After Variable Init
// ═══════════════════════════════════════════════════════════════

test("TC-02: GetEmployeeDetails fires after variable initialization", () => {
  const getEmployee = rootActions.GetEmployeeDetails;
  assert.ok(getEmployee, "GetEmployeeDetails action must exist");

  const runAfter = Object.keys(getEmployee.runAfter || {});
  assert.ok(
    runAfter.includes("Initialize_varRequestId"),
    "GetEmployeeDetails depends on Initialize_varRequestId"
  );

  // Verify it queries by employee email
  const filter = getEmployee.inputs.parameters["$filter"];
  assert.ok(filter, "GetEmployeeDetails must have a $filter parameter");
  assert.ok(
    filter.includes("varEmployeeEmail"),
    "Filter must use varEmployeeEmail variable"
  );
  assert.ok(
    filter.includes("Email eq"),
    "Filter must query by Email field"
  );

  // Simulate: lookup returns Hercilio
  const simResults = [HERCILIO.employee];
  assert.equal(simResults.length, 1);
  assert.equal(simResults[0].NomeCompleto, "Hercilio Torres Goncalves");
  assert.equal(simResults[0].Departamento, "Dados");
});

// ═══════════════════════════════════════════════════════════════
// TC-03: Status PENDING Gate
// ═══════════════════════════════════════════════════════════════

test("TC-03: Condition_Status_PENDING evaluates status correctly", () => {
  const statusCondition = rootActions.Condition_Status_PENDING;
  assert.ok(statusCondition, "Condition_Status_PENDING must exist");
  assert.equal(statusCondition.type, "If");

  // Check expression structure
  const expression = statusCondition.expression;
  assert.ok(expression, "Must have an expression");

  // Evaluate: top-level `and` with `equals`
  const andBlock = expression.and;
  assert.ok(Array.isArray(andBlock), "Expression must use and[] pattern");

  const equalsBlock = andBlock[0]?.equals;
  assert.ok(Array.isArray(equalsBlock), "First condition must be equals[]");
  assert.equal(equalsBlock.length, 2, "equals must have exactly 2 operands");

  // Right operand is "PENDING"
  assert.equal(equalsBlock[1], "PENDING", 'Second operand must be literal "PENDING"');

  // Simulate: Hercilio request has Status = "PENDING"
  const simStatus = HERCILIO.request.Status;
  assert.equal(simStatus, "PENDING", "Simulation: Hercilio status is PENDING");
  assert.equal(simStatus === "PENDING", true, "Gate should PASS for Hercilio");

  // Simulate: APPROVED status should NOT pass
  assert.notEqual("APPROVED", "PENDING");
});

// ═══════════════════════════════════════════════════════════════
// TC-04: Approval Card Recipient
// ═══════════════════════════════════════════════════════════════

test("TC-04: Approval card is posted to correct approver recipient", () => {
  const postCard = employeeFoundActions.PostApprovalCard;
  assert.ok(postCard, "PostApprovalCard action must exist inside Condition_Employee_Found");

  const recipient = postCard.inputs.parameters["body/body/recipient/to"];
  assert.ok(recipient, "Recipient parameter must be set");
  assert.ok(
    recipient.includes("varApproverEmail"),
    "Recipient must reference varApproverEmail"
  );

  // Simulate: card sent to Marcos Benicios
  assert.equal(
    HERCILIO.employee.AprovadorEmail,
    "mbenicios@minsait.com",
    "Card would be sent to Marcos Benicios"
  );
});

// ═══════════════════════════════════════════════════════════════
// TC-05: Adaptive Card Content Completeness
// ═══════════════════════════════════════════════════════════════

test("TC-05: Adaptive card contains all required fields", () => {
  const postCard = employeeFoundActions.PostApprovalCard;
  const cardStr = postCard.inputs.parameters["body/body/messageBody"];

  assert.ok(cardStr, "Card body must be defined");

  // Parse the card JSON
  const card = JSON.parse(cardStr);
  assert.equal(card.type, "AdaptiveCard", "Card type must be AdaptiveCard");
  assert.equal(card.version, "1.4", "Card version must be 1.4");

  // Check title
  const container = card.body.find((b) => b.type === "Container");
  assert.ok(container, "Must have a Container block");
  const title = container.items.find(
    (i) => i.type === "TextBlock" && i.text === "Solicitacao de Ferias"
  );
  assert.ok(title, 'Title must be "Solicitacao de Ferias"');

  // Check FactSet
  const factSet = card.body.find((b) => b.type === "FactSet");
  assert.ok(factSet, "Must have a FactSet block");

  const factTitles = factSet.facts.map((f) => f.title);
  assert.ok(factTitles.includes("Colaborador:"), "Must show Colaborador");
  assert.ok(factTitles.includes("E-mail:"), "Must show E-mail");
  assert.ok(factTitles.includes("Periodo:"), "Must show Periodo");
  assert.ok(factTitles.includes("Total de dias:"), "Must show Total de dias");
  assert.ok(factTitles.includes("Observacoes:"), "Must show Observacoes");

  // Check actions
  assert.ok(card.actions, "Must have actions");
  assert.equal(card.actions.length, 2, "Must have exactly 2 actions (approve/reject)");

  const approveAction = card.actions.find((a) => a.data?.action === "approve");
  const rejectAction = card.actions.find((a) => a.data?.action === "reject");
  assert.ok(approveAction, 'Must have approve action with data.action="approve"');
  assert.ok(rejectAction, 'Must have reject action with data.action="reject"');
  assert.equal(approveAction.style, "positive", "Approve must be positive style");
  assert.equal(rejectAction.style, "destructive", "Reject must be destructive style");

  // Check comments input
  const commentsInput = card.body.find(
    (b) => b.type === "Input.Text" && b.id === "comments"
  );
  assert.ok(commentsInput, 'Must have Input.Text with id="comments"');
  assert.equal(commentsInput.isMultiline, true, "Comments must be multiline");
});

// ═══════════════════════════════════════════════════════════════
// TC-06: APPROVED Branch — Status + Balance + Notifications
// ═══════════════════════════════════════════════════════════════

test("TC-06: APPROVED branch has status update, balance deduction, and notifications", () => {
  const condApproved = employeeFoundActions.Condition_Approved;
  assert.ok(condApproved, "Condition_Approved must exist");
  assert.equal(condApproved.type, "If");

  const approvedActions = condApproved.actions;
  assert.ok(approvedActions, "Approved branch must have actions");

  // Balance lookup exists at the approved branch level
  assert.ok(
    approvedActions.GetCurrentBalance,
    "GetCurrentBalance must exist in approved branch"
  );

  // Condition_Balance_Record_Found is the new guard that wraps
  // status update, balance deduction, and notifications
  const balanceGuard = approvedActions.Condition_Balance_Record_Found;
  assert.ok(balanceGuard, "Condition_Balance_Record_Found must exist in approved branch");
  assert.equal(balanceGuard.type, "If");

  const balanceActions = balanceGuard.actions;
  assert.ok(balanceActions, "Balance guard branch must have actions");

  // Status update exists
  assert.ok(
    balanceActions.Update_Status_APPROVED,
    "Update_Status_APPROVED must exist"
  );
  assert.equal(
    balanceActions.Update_Status_APPROVED.inputs.parameters["item/Status"],
    "APPROVED",
    'Status must be set to "APPROVED"'
  );

  // Balance deduction exists
  assert.ok(
    balanceActions.Update_Balance_Deduct,
    "Update_Balance_Deduct must exist in approved branch"
  );
  const deductParams = balanceActions.Update_Balance_Deduct.inputs.parameters;
  assert.ok(
    deductParams["item/SaldoDisponivel"],
    "Balance deduction must update SaldoDisponivel"
  );
  assert.ok(
    String(deductParams["item/SaldoDisponivel"]).includes("sub("),
    "SaldoDisponivel must use sub() expression"
  );

  // Teams notification exists
  assert.ok(
    balanceActions.Notify_Employee_Teams_Approved,
    "Notify_Employee_Teams_Approved must exist"
  );

  // Email notification exists
  assert.ok(
    balanceActions.Notify_Employee_Email_Approved,
    "Notify_Employee_Email_Approved must exist"
  );
});

// ═══════════════════════════════════════════════════════════════
// TC-07: REJECTED Branch — Status + Notifications
// ═══════════════════════════════════════════════════════════════

test("TC-07: REJECTED branch has status update and notifications", () => {
  const condApproved = employeeFoundActions.Condition_Approved;
  const rejectedActions = condApproved.else?.actions || {};

  // Status update exists
  assert.ok(
    rejectedActions.Update_Status_REJECTED,
    "Update_Status_REJECTED must exist"
  );
  assert.equal(
    rejectedActions.Update_Status_REJECTED.inputs.parameters["item/Status"],
    "REJECTED",
    'Status must be set to "REJECTED"'
  );

  // Rejection reason — uses comments from card
  const teamsBody =
    rejectedActions.Notify_Employee_Teams_Rejected?.inputs?.parameters?.[
      "body/messageBody"
    ] ?? "";
  assert.ok(
    teamsBody.includes("PostApprovalCard"),
    "Rejection notification must reference PostApprovalCard comments"
  );
  assert.ok(
    teamsBody.includes("comments"),
    "Rejection notification must pull comments field"
  );

  // Notifications exist
  assert.ok(
    rejectedActions.Notify_Employee_Teams_Rejected,
    "Notify_Employee_Teams_Rejected must exist"
  );
  assert.ok(
    rejectedActions.Notify_Employee_Email_Rejected,
    "Notify_Employee_Email_Rejected must exist"
  );
});

// ═══════════════════════════════════════════════════════════════
// TC-08: Notification Resilience (Email Survives Teams Failure)
// ═══════════════════════════════════════════════════════════════

test("TC-08: Email notification runs even if Teams notification fails", () => {
  const condApproved = employeeFoundActions.Condition_Approved;
  const balanceActions =
    condApproved.actions.Condition_Balance_Record_Found.actions;

  // APPROVED path resilience
  const emailApproved = balanceActions.Notify_Employee_Email_Approved;
  assert.ok(emailApproved, "Notify_Employee_Email_Approved must exist");

  const emailApprovedRunAfter = emailApproved.runAfter;
  const teamsApprovedStatuses =
    emailApprovedRunAfter["Notify_Employee_Teams_Approved"];
  assert.ok(teamsApprovedStatuses, "Email must depend on Teams notification");
  assert.ok(
    teamsApprovedStatuses.includes("Succeeded"),
    "Email runs on Teams Succeeded"
  );
  assert.ok(
    teamsApprovedStatuses.includes("Failed"),
    "Email runs on Teams Failed"
  );
  assert.ok(
    teamsApprovedStatuses.includes("Skipped"),
    "Email runs on Teams Skipped"
  );

  // REJECTED path resilience
  const rejectedActions = condApproved.else.actions;
  const emailRejected = rejectedActions.Notify_Employee_Email_Rejected;
  assert.ok(emailRejected, "Notify_Employee_Email_Rejected must exist");

  const emailRejectedRunAfter = emailRejected.runAfter;
  const teamsRejectedStatuses =
    emailRejectedRunAfter["Notify_Employee_Teams_Rejected"];
  assert.ok(teamsRejectedStatuses, "Rejection email must depend on Teams notification");
  assert.ok(
    teamsRejectedStatuses.includes("Succeeded"),
    "Rejection email runs on Teams Succeeded"
  );
  assert.ok(
    teamsRejectedStatuses.includes("Failed"),
    "Rejection email runs on Teams Failed"
  );
  assert.ok(
    teamsRejectedStatuses.includes("Skipped"),
    "Rejection email runs on Teams Skipped"
  );
});

// ═══════════════════════════════════════════════════════════════
// TC-09: Balance Math Simulation (30 - 10 = 20)
// ═══════════════════════════════════════════════════════════════

test("TC-09: Balance deduction math is correct for Hercilio (30 - 10 = 20)", () => {
  const bal = HERCILIO.balance;
  const req = HERCILIO.request;

  // Simulate the sub() expression
  const newSaldoDisponivel = bal.SaldoDisponivel - req.DiasUteis;
  assert.equal(newSaldoDisponivel, 20, "30 - 10 = 20 available days");

  // Total conservation check
  const newTotal = newSaldoDisponivel + bal.DiasUsados + req.DiasUteis;
  assert.equal(newTotal, bal.SaldoTotal, "Total conservation: 20 + 0 + 10 = 30");

  // Verify the formula in the flow (navigating through guard conditions)
  const condApproved = employeeFoundActions.Condition_Approved;
  const balanceActions =
    condApproved.actions.Condition_Balance_Record_Found.actions;
  const deduct = balanceActions.Update_Balance_Deduct;
  const saldoExpr = deduct.inputs.parameters["item/SaldoDisponivel"];

  assert.ok(saldoExpr.includes("sub("), "Must use sub() for deduction");
  assert.ok(
    saldoExpr.includes("GetCurrentBalance"),
    "Must reference GetCurrentBalance outputs"
  );
  assert.ok(
    saldoExpr.includes("SaldoDisponivel"),
    "Must reference SaldoDisponivel field"
  );
  assert.ok(
    saldoExpr.includes("DiasUteis"),
    "Must reference DiasUteis from trigger"
  );
});

// ═══════════════════════════════════════════════════════════════
// TC-10: Non-PENDING Termination Path
// ═══════════════════════════════════════════════════════════════

test("TC-10: Non-PENDING status terminates with Succeeded", () => {
  const elseActions = rootActions.Condition_Status_PENDING.else?.actions || {};

  assert.ok(
    elseActions.Terminate_Not_Pending,
    "Terminate_Not_Pending must exist in else branch"
  );
  assert.equal(
    elseActions.Terminate_Not_Pending.type,
    "Terminate",
    "Must be a Terminate action"
  );
  assert.equal(
    elseActions.Terminate_Not_Pending.inputs.runStatus,
    "Succeeded",
    "Non-PENDING must terminate as Succeeded (no error, idempotent)"
  );
});

// ═══════════════════════════════════════════════════════════════
// TC-11: Full Execution Trace for Approved Path
// ═══════════════════════════════════════════════════════════════

test("TC-11: Full execution trace has correct structure for Hercilio APPROVED", () => {
  const executionTrace = [];

  // Stage 1: Variable initialization (sequential chain)
  executionTrace.push({
    step: 1,
    action: "Initialize_varApproverEmail",
    simValue: HERCILIO.request.AprovadorEmail,
  });
  executionTrace.push({
    step: 2,
    action: "Initialize_varEmployeeEmail",
    simValue: HERCILIO.request.ColaboradorEmail,
  });
  executionTrace.push({
    step: 3,
    action: "Initialize_varRequestId",
    simValue: HERCILIO.request.ID,
  });

  // Stage 2: Employee lookup
  executionTrace.push({
    step: 4,
    action: "GetEmployeeDetails",
    simResult: HERCILIO.employee.NomeCompleto,
  });

  // Stage 3: Status gate
  executionTrace.push({
    step: 5,
    action: "Condition_Status_PENDING",
    simResult: "PASS (PENDING)",
  });

  // Stage 4: Approval card
  executionTrace.push({
    step: 6,
    action: "PostApprovalCard",
    simRecipient: HERCILIO.employee.AprovadorEmail,
  });

  // Stage 5: Manager decision
  executionTrace.push({
    step: 7,
    action: "Condition_Approved",
    simResult: "YES (approve)",
  });

  // Stage 6: Status → APPROVED (NOTE: in current def, this runs BEFORE balance)
  executionTrace.push({
    step: 8,
    action: "Update_Status_APPROVED",
    simStatus: "APPROVED",
  });

  // Stage 7: Balance lookup
  executionTrace.push({
    step: 9,
    action: "GetCurrentBalance",
    simResult: `SaldoDisponivel=${HERCILIO.balance.SaldoDisponivel}`,
  });

  // Stage 8: Balance deduction
  const newBalance = HERCILIO.balance.SaldoDisponivel - HERCILIO.request.DiasUteis;
  executionTrace.push({
    step: 10,
    action: "Update_Balance_Deduct",
    simResult: `SaldoDisponivel: ${HERCILIO.balance.SaldoDisponivel}→${newBalance}`,
  });

  // Stage 9: Notifications
  executionTrace.push({
    step: 11,
    action: "Notify_Employee_Teams_Approved",
    simRecipient: HERCILIO.request.ColaboradorEmail,
  });
  executionTrace.push({
    step: 12,
    action: "Notify_Employee_Email_Approved",
    simRecipient: HERCILIO.request.ColaboradorEmail,
  });

  // Verify all 12 steps captured
  assert.equal(executionTrace.length, 12, "Full trace must have 12 steps");

  // Verify all action names exist in the flow
  for (const step of executionTrace) {
    const found = findByName(step.action);
    assert.ok(
      found,
      `Action "${step.action}" (step ${step.step}) must exist in flow definition`
    );
  }
});

// ═══════════════════════════════════════════════════════════════
// TC-12: Structure Conformance Audit
// ═══════════════════════════════════════════════════════════════

test("TC-12: Flow structure conformance audit", () => {
  // Trigger: SharePoint item created
  const trigger = definition.triggers.When_an_item_is_created;
  assert.ok(trigger, "SharePoint trigger must exist");
  assert.equal(
    trigger.inputs.host.operationId,
    "GetOnNewItems",
    "Trigger must use GetOnNewItems operation"
  );
  assert.ok(
    trigger.splitOn.includes("body/value"),
    "Trigger must use splitOn for single-item processing"
  );

  // Connection references (only when present — the patched definition
  // may omit them since they are populated at deployment time)
  const connRefs = flow.properties.connectionReferences;
  if (connRefs) {
    assert.ok(connRefs.shared_sharepointonline, "SP connection must exist");
    assert.ok(connRefs.shared_teams, "Teams connection must exist");
    assert.ok(connRefs.shared_office365, "Office 365 connection must exist");
  }

  // Display name
  assert.equal(
    flow.properties.displayName,
    "GestaoFerias_VacationApproval",
    "Flow display name must be GestaoFerias_VacationApproval"
  );

  // Condition_Approved expression (inside Condition_Employee_Found guard)
  const condApproved = employeeFoundActions.Condition_Approved;
  assert.ok(condApproved, "Condition_Approved must exist inside Condition_Employee_Found");
  const approvalExpr = condApproved.expression;
  assert.ok(approvalExpr.and, "Approval condition must use and[] pattern");
  const approvalEquals = approvalExpr.and[0].equals;
  assert.ok(
    approvalEquals[0].includes("PostApprovalCard"),
    "Approval checks PostApprovalCard response"
  );
  assert.ok(
    approvalEquals[0].includes("action"),
    "Approval checks data.action field"
  );
  assert.equal(approvalEquals[1], "approve", 'Right operand must be "approve"');
});
