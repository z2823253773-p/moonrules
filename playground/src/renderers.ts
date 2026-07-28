import type {
  AdapterResponse,
  DecisionStatus,
  Diagnostic,
  TraceNode,
} from "./contracts";

function element<K extends keyof HTMLElementTagNameMap>(
  tagName: K,
  text?: string,
): HTMLElementTagNameMap[K] {
  const node = document.createElement(tagName);
  if (text !== undefined) node.textContent = text;
  return node;
}

export function countTraceNodes(node: TraceNode): number {
  return (
    1 +
    node.children.reduce(
      (total, child) => total + countTraceNodes(child),
      0,
    )
  );
}

export function decisionLabel(status: DecisionStatus): string {
  return status.toUpperCase();
}

export function renderDiagnostic(diagnostic: Diagnostic): HTMLElement {
  const article = element("article");
  article.className = "diagnostic";

  article.append(
    element("strong", `${diagnostic.code} · ${diagnostic.rule_path}`),
    element("p", diagnostic.message),
  );

  const suggestion = element("p", diagnostic.suggestion);
  suggestion.className = "suggestion";
  article.append(suggestion);

  return article;
}

export function renderTrace(node: TraceNode, open = false): HTMLElement {
  const details = element("details");
  details.className = `trace-node status-${node.status}`;
  details.open = open || node.status === "fail" || node.status === "error";

  details.append(
    element(
      "summary",
      `${node.status.toUpperCase()} · ${node.operator} · ${node.rule_path}`,
    ),
  );

  if (node.message) {
    details.append(element("p", node.message));
  }

  for (const child of node.children) {
    details.append(renderTrace(child));
  }

  return details;
}

export function responseJson(response: AdapterResponse): string {
  return JSON.stringify(response, null, 2);
}
