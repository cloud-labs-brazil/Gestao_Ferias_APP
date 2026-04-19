const fs = require("node:fs");
const path = require("node:path");

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function readJsonFile(filePath) {
  const raw = fs.readFileSync(filePath, "utf8");
  return JSON.parse(raw);
}

function getDisplayName(flowJson) {
  return flowJson?.properties?.displayName ?? "";
}

function getCandidateDefinitionFiles(repoRoot) {
  const candidates = [];
  const flowsRoot = path.join(
    repoRoot,
    "power_automate",
    "extracted",
    "Microsoft.Flow",
    "flows"
  );

  if (!fs.existsSync(flowsRoot)) {
    return candidates;
  }

  for (const entry of fs.readdirSync(flowsRoot, { withFileTypes: true })) {
    if (!entry.isDirectory()) {
      continue;
    }
    const definitionPath = path.join(flowsRoot, entry.name, "definition.json");
    if (fs.existsSync(definitionPath)) {
      candidates.push(definitionPath);
    }
  }

  return candidates;
}

function loadVacationApprovalFlow(repoRoot = process.cwd()) {
  const explicitPath = process.env.FLOW_DEFINITION_PATH;
  if (explicitPath) {
    const resolved = path.isAbsolute(explicitPath)
      ? explicitPath
      : path.resolve(repoRoot, explicitPath);
    if (!fs.existsSync(resolved)) {
      throw new Error(
        `FLOW_DEFINITION_PATH does not exist: ${resolved}`
      );
    }
    return { flow: readJsonFile(resolved), flowPath: resolved };
  }

  const candidates = getCandidateDefinitionFiles(repoRoot);
  if (candidates.length === 0) {
    throw new Error(
      "No flow definition files found under power_automate/extracted/Microsoft.Flow/flows/*/definition.json"
    );
  }

  const parsed = candidates.map((flowPath) => {
    const flow = readJsonFile(flowPath);
    return { flow, flowPath, displayName: getDisplayName(flow) };
  });

  const exactMatch = parsed.find(
    (entry) => entry.displayName === "GestaoFerias_VacationApproval"
  );
  if (exactMatch) {
    return exactMatch;
  }

  const partialMatch = parsed.find((entry) =>
    /vacationapproval/i.test(entry.displayName)
  );
  if (partialMatch) {
    return partialMatch;
  }

  if (parsed.length === 1) {
    return parsed[0];
  }

  const details = parsed
    .map((entry) => `${entry.displayName || "<no-display-name>"} @ ${entry.flowPath}`)
    .join("\n");
  throw new Error(
    `Unable to uniquely identify VacationApproval flow definition. Set FLOW_DEFINITION_PATH.\nCandidates:\n${details}`
  );
}

function walkActions(actions, ancestors = [], visit) {
  if (!isObject(actions)) {
    return;
  }

  for (const [name, action] of Object.entries(actions)) {
    if (!isObject(action)) {
      continue;
    }
    const currentPath = [...ancestors, name];
    visit({ name, action, path: currentPath });

    if (isObject(action.actions)) {
      walkActions(action.actions, currentPath, visit);
    }
    if (isObject(action.else?.actions)) {
      walkActions(action.else.actions, currentPath, visit);
    }
  }
}

module.exports = {
  loadVacationApprovalFlow,
  walkActions,
};
