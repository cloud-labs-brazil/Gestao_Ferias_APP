const test = require("node:test");
const assert = require("node:assert/strict");

const {
  loadVacationApprovalFlow,
  walkActions,
} = require("../../scripts/flowDefinitionLoader");

function stringify(value) {
  return JSON.stringify(value ?? null);
}

function collectActions(definitionActions) {
  const all = [];
  walkActions(definitionActions, [], (entry) => {
    all.push(entry);
  });
  return all;
}

function actionLocalText(action) {
  const localProjection = {
    type: action?.type,
    runAfter: action?.runAfter,
    expression: action?.expression,
    inputs: action?.inputs,
  };
  return stringify(localProjection);
}

function findFirstByName(actions, name) {
  return actions.find((entry) => entry.name === name);
}

function hasRequiredRunAfterStatus(runAfter, dependencyName, statuses) {
  if (!runAfter || typeof runAfter !== "object") {
    return false;
  }
  const actual = runAfter[dependencyName];
  if (!Array.isArray(actual)) {
    return false;
  }
  return statuses.every((status) => actual.includes(status));
}

function buildRunAfterGraph(actionEntries) {
  const graph = new Map();
  const allNames = new Set(actionEntries.map((entry) => entry.name));

  for (const name of allNames) {
    graph.set(name, new Set());
  }

  for (const entry of actionEntries) {
    const runAfter = entry.action.runAfter;
    if (!runAfter || typeof runAfter !== "object") {
      continue;
    }
    for (const dependencyName of Object.keys(runAfter)) {
      if (!allNames.has(dependencyName)) {
        continue;
      }
      graph.get(dependencyName).add(entry.name);
    }
  }

  return graph;
}

function hasPath(graph, source, target) {
  if (!graph.has(source) || !graph.has(target)) {
    return false;
  }
  const queue = [source];
  const visited = new Set([source]);

  while (queue.length > 0) {
    const current = queue.shift();
    if (current === target) {
      return true;
    }
    for (const next of graph.get(current)) {
      if (visited.has(next)) {
        continue;
      }
      visited.add(next);
      queue.push(next);
    }
  }

  return false;
}

const { flow, flowPath } = loadVacationApprovalFlow();
const definition = flow?.properties?.definition;
const rootActions = definition?.actions ?? {};
const allActionEntries = collectActions(rootActions);

test("loads VacationApproval flow definition", () => {
  assert.ok(definition, `Missing properties.definition in flow JSON at ${flowPath}`);
  assert.ok(
    Object.keys(rootActions).length > 0,
    `Missing root actions in flow definition at ${flowPath}`
  );
});

test("employee guard exists before first(GetEmployeeDetails body/value) usage", () => {
  const dangerousPattern = "first(outputs('GetEmployeeDetails')?['body/value'])";
  const dangerousUsages = [];
  const guardActions = [];

  for (const entry of allActionEntries) {
    const actionText = actionLocalText(entry.action);
    if (actionText.includes(dangerousPattern)) {
      dangerousUsages.push(entry);
    }

    if (entry.action.type === "If") {
      const expressionText = stringify(entry.action.expression);
      const referencesEmployeeRows =
        expressionText.includes("GetEmployeeDetails") &&
        expressionText.includes("body/value");
      const checksForPresence =
        expressionText.includes("empty(") ||
        expressionText.includes("length(") ||
        expressionText.includes("greater(");

      if (referencesEmployeeRows && checksForPresence) {
        guardActions.push(entry);
      }
    }
  }

  assert.ok(
    guardActions.length > 0,
    [
      "Missing employee existence guard.",
      "Expected an If action checking GetEmployeeDetails body/value with empty/length/greater before card rendering.",
      `Flow: ${flowPath}`,
    ].join(" ")
  );

  for (const usage of dangerousUsages) {
    const guarded = guardActions.some((guard) => {
      if (guard.path.length >= usage.path.length) {
        return false;
      }
      for (let i = 0; i < guard.path.length; i += 1) {
        if (guard.path[i] !== usage.path[i]) {
          return false;
        }
      }
      return true;
    });

    assert.ok(
      guarded,
      [
        `Unsafe GetEmployeeDetails first() usage found at action path: ${usage.path.join(" > ")}`,
        "Usage is not nested under an employee existence guard.",
        `Flow: ${flowPath}`,
      ].join(" ")
    );
  }
});

test("pending condition is robust (Status/Value, not raw Status string only)", () => {
  const pendingCondition = findFirstByName(allActionEntries, "Condition_Status_PENDING");
  assert.ok(pendingCondition, `Missing Condition_Status_PENDING action in ${flowPath}`);

  const expressionText = stringify(pendingCondition.action.expression);
  const referencesStatusValue =
    expressionText.includes("body/Status/Value") ||
    expressionText.includes("['body/Status']?['Value']");

  assert.ok(
    referencesStatusValue,
    [
      "Condition_Status_PENDING must evaluate the SharePoint choice value via Status/Value.",
      `Current expression: ${expressionText}`,
      `Flow: ${flowPath}`,
    ].join(" ")
  );
});

test("balance deduction update includes SaldoDisponivel, DiasAgendados, and DataAtualizacao", () => {
  const balanceUpdate = findFirstByName(allActionEntries, "Update_Balance_Deduct");
  assert.ok(balanceUpdate, `Missing Update_Balance_Deduct action in ${flowPath}`);

  const params = balanceUpdate.action?.inputs?.parameters ?? {};
  assert.ok(
    Object.prototype.hasOwnProperty.call(params, "item/SaldoDisponivel"),
    `Update_Balance_Deduct missing item/SaldoDisponivel in ${flowPath}`
  );
  assert.ok(
    Object.prototype.hasOwnProperty.call(params, "item/DiasAgendados"),
    `Update_Balance_Deduct missing item/DiasAgendados in ${flowPath}`
  );
  assert.ok(
    Object.prototype.hasOwnProperty.call(params, "item/DataAtualizacao"),
    `Update_Balance_Deduct missing item/DataAtualizacao in ${flowPath}`
  );
});

test("approved and rejected status updates write DataAprovacao", () => {
  const approvedUpdate = findFirstByName(allActionEntries, "Update_Status_APPROVED");
  const rejectedUpdate = findFirstByName(allActionEntries, "Update_Status_REJECTED");

  assert.ok(approvedUpdate, `Missing Update_Status_APPROVED in ${flowPath}`);
  assert.ok(rejectedUpdate, `Missing Update_Status_REJECTED in ${flowPath}`);

  const approvedParams = approvedUpdate.action?.inputs?.parameters ?? {};
  const rejectedParams = rejectedUpdate.action?.inputs?.parameters ?? {};

  assert.ok(
    Object.prototype.hasOwnProperty.call(approvedParams, "item/DataAprovacao"),
    `Update_Status_APPROVED missing item/DataAprovacao in ${flowPath}`
  );
  assert.ok(
    Object.prototype.hasOwnProperty.call(rejectedParams, "item/DataAprovacao"),
    `Update_Status_REJECTED missing item/DataAprovacao in ${flowPath}`
  );
});

test("approved path ordering enforces balance success before status APPROVED write", () => {
  const approvedCondition = findFirstByName(allActionEntries, "Condition_Approved");
  assert.ok(approvedCondition, `Missing Condition_Approved action in ${flowPath}`);

  const approvedConditionActions = approvedCondition.action?.actions ?? {};
  const approvedBranchEntries = collectActions(approvedConditionActions);
  const statusApproved = findFirstByName(approvedBranchEntries, "Update_Status_APPROVED");
  const balanceDeduct = findFirstByName(approvedBranchEntries, "Update_Balance_Deduct");

  assert.ok(statusApproved, `Missing Update_Status_APPROVED in approved branch (${flowPath})`);
  assert.ok(balanceDeduct, `Missing Update_Balance_Deduct in approved branch (${flowPath})`);

  const graph = buildRunAfterGraph(approvedBranchEntries);
  const balanceBeforeStatus = hasPath(graph, "Update_Balance_Deduct", "Update_Status_APPROVED");
  const statusBeforeBalance = hasPath(graph, "Update_Status_APPROVED", "Update_Balance_Deduct");

  assert.ok(
    balanceBeforeStatus,
    [
      "Approved path must ensure Update_Balance_Deduct runs before Update_Status_APPROVED.",
      `Flow: ${flowPath}`,
      `Update_Status_APPROVED.runAfter: ${stringify(statusApproved.action.runAfter)}`,
    ].join(" ")
  );

  assert.ok(
    !statusBeforeBalance,
    [
      "Detected invalid dependency path where Update_Status_APPROVED can execute before Update_Balance_Deduct.",
      `Flow: ${flowPath}`,
      `Update_Balance_Deduct.runAfter: ${stringify(balanceDeduct.action.runAfter)}`,
    ].join(" ")
  );

  assert.ok(
    hasRequiredRunAfterStatus(
      statusApproved.action.runAfter,
      "Update_Balance_Deduct",
      ["Succeeded"]
    ),
    [
      "Update_Status_APPROVED must directly depend on Update_Balance_Deduct Succeeded.",
      `Flow: ${flowPath}`,
      `Update_Status_APPROVED.runAfter: ${stringify(statusApproved.action.runAfter)}`,
    ].join(" ")
  );
});

test("failure alert subscription is enabled wherever represented", () => {
  const topLevel = flow?.properties?.flowFailureAlertSubscribed;
  const metadataLevel =
    flow?.properties?.definition?.metadata?.failureAlertSubscription;

  if (typeof topLevel !== "undefined") {
    assert.equal(
      topLevel,
      true,
      `properties.flowFailureAlertSubscribed must be true (found ${topLevel}) in ${flowPath}`
    );
  }

  if (typeof metadataLevel !== "undefined") {
    assert.equal(
      metadataLevel,
      true,
      `properties.definition.metadata.failureAlertSubscription must be true (found ${metadataLevel}) in ${flowPath}`
    );
  }
});
