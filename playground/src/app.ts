import "./styles.css";
import type { AdapterResponse, TraceMode } from "./contracts";
import { JsonEditor } from "./editor";
import { engine } from "./engine";
import { type Example, loadExamples, loadExampleText } from "./examples";
import {
  countTraceNodes,
  decisionLabel,
  renderDiagnostic,
  renderTrace,
  responseJson,
} from "./renderers";

const root = document.querySelector<HTMLDivElement>("#app");
if (!root) throw new Error("missing #app");
root.innerHTML = `
  <main class="shell">
    <header>
      <p class="eyebrow">MoonBit · Explainable rules</p>
      <h1>MoonRules Playground</h1>
      <p>规则和数据只在本地浏览器处理，不会上传服务器。</p>
    </header>
    <div class="toolbar">
      <select id="example" aria-label="选择示例"></select>
      <select id="variant" aria-label="选择数据结果">
        <option value="fail">不通过数据</option>
        <option value="pass">通过数据</option>
      </select>
      <select id="trace-mode" aria-label="选择 Trace 模式">
        <option value="full">Full</option>
        <option value="summary">Summary</option>
        <option value="off">Off</option>
      </select>
      <button id="check" type="button">Check</button>
      <button id="evaluate" type="button">Evaluate</button>
      <button id="format" type="button">Format JSON</button>
    </div>
    <section class="workspace">
      <article class="editor-card">
        <h2>Rule JSON</h2>
        <div id="rule-editor" aria-label="Rule JSON editor"></div>
      </article>
      <article class="editor-card">
        <h2>Data JSON</h2>
        <div id="data-editor" aria-label="Data JSON editor"></div>
      </article>
    </section>
    <section class="result-card" id="result" aria-live="polite">
      <div class="result-header">
        <h2>Result</h2>
        <div class="result-actions">
          <button id="copy-result" type="button" disabled>Copy JSON</button>
          <button id="download-result" type="button" disabled>Download JSON</button>
        </div>
      </div>
      <div class="status-card" id="status-card" data-status="idle">
        Run Check or Evaluate to inspect the result.
      </div>
      <div class="tabs" role="tablist" aria-label="Result sections">
        <button id="tab-trace" type="button" role="tab" aria-selected="true" aria-controls="panel-trace">Trace</button>
        <button id="tab-diagnostics" type="button" role="tab" aria-selected="false" aria-controls="panel-diagnostics">Diagnostics</button>
        <button id="tab-json" type="button" role="tab" aria-selected="false" aria-controls="panel-json">JSON</button>
        <button id="tab-stats" type="button" role="tab" aria-selected="false" aria-controls="panel-stats">Stats</button>
      </div>
      <div id="panel-trace" class="result-panel" role="tabpanel" aria-labelledby="tab-trace"></div>
      <div id="panel-diagnostics" class="result-panel" role="tabpanel" aria-labelledby="tab-diagnostics" hidden></div>
      <pre id="panel-json" class="result-panel json-panel" role="tabpanel" aria-labelledby="tab-json" hidden></pre>
      <pre id="panel-stats" class="result-panel stats-panel" role="tabpanel" aria-labelledby="tab-stats" hidden></pre>
    </section>
  </main>
`;

const exampleSelect = getElement<HTMLSelectElement>("example");
const variantSelect = getElement<HTMLSelectElement>("variant");
const traceModeSelect = getElement<HTMLSelectElement>("trace-mode");
const checkButton = getElement<HTMLButtonElement>("check");
const evaluateButton = getElement<HTMLButtonElement>("evaluate");
const formatButton = getElement<HTMLButtonElement>("format");
const copyButton = getElement<HTMLButtonElement>("copy-result");
const downloadButton = getElement<HTMLButtonElement>("download-result");
const statusCard = getElement<HTMLElement>("status-card");
const tracePanel = getElement<HTMLElement>("panel-trace");
const diagnosticsPanel = getElement<HTMLElement>("panel-diagnostics");
const jsonPanel = getElement<HTMLPreElement>("panel-json");
const statsPanel = getElement<HTMLPreElement>("panel-stats");
const ruleEditorHost = getElement<HTMLElement>("rule-editor");
const dataEditorHost = getElement<HTMLElement>("data-editor");

let examples: Example[] = [];
let exampleLoadToken = 0;
let lastResponse: AdapterResponse | null = null;
const ruleEditor = new JsonEditor(
  ruleEditorHost,
  "{\n}",
  runEvaluate,
  "Rule JSON editor",
);
const dataEditor = new JsonEditor(
  dataEditorHost,
  "{\n}",
  runEvaluate,
  "Data JSON editor",
);

function getElement<T extends HTMLElement>(id: string): T {
  const element = document.getElementById(id);
  if (!element) throw new Error(`missing #${id}`);
  return element as T;
}

function selectedTraceMode(): TraceMode {
  return traceModeSelect.value as TraceMode;
}

function selectedExample(): Example {
  const example = examples.find((item) => item.id === exampleSelect.value);
  if (!example) throw new Error("missing selected example");
  return example;
}

function renderResponse(response: AdapterResponse): void {
  lastResponse = response;
  copyButton.disabled = false;
  downloadButton.disabled = false;
  copyButton.textContent = "Copy JSON";

  diagnosticsPanel.replaceChildren(
    ...(response.diagnostics.length > 0
      ? response.diagnostics.map(renderDiagnostic)
      : [emptyMessage("No diagnostics.")]),
  );
  jsonPanel.textContent = responseJson(response);
  tracePanel.replaceChildren();
  statsPanel.textContent = "";

  if (response.report) {
    const status = response.report.decision.status;
    statusCard.dataset.status = status;
    statusCard.replaceChildren(
      document.createTextNode(
        `${decisionIcon(status)} ${decisionLabel(status)}`,
      ),
    );
    tracePanel.append(renderTrace(response.report.trace, true));
    statsPanel.textContent = [
      `Steps: ${response.report.stats.steps_executed}`,
      `Evaluated nodes: ${response.report.stats.nodes_evaluated}`,
      `Maximum depth: ${response.report.stats.max_depth_reached}`,
      `Full trace nodes: ${response.report.stats.trace_nodes_emitted}`,
      `Returned trace nodes: ${countTraceNodes(response.report.trace)}`,
    ].join("\n");
    return;
  }

  statusCard.dataset.status = response.ok ? "checked" : "error";
  statusCard.replaceChildren(
    document.createTextNode(
      response.ok ? "✓ CHECKED" : `⚠ ${response.kind.toUpperCase()}`,
    ),
  );
  tracePanel.replaceChildren(emptyMessage("No trace for this result."));
  statsPanel.textContent = "No evaluation stats for this result.";
}

function renderError(error: unknown): void {
  const message = error instanceof Error ? error.message : String(error);
  renderResponse({
    ok: false,
    kind: "internal_error",
    report: null,
    diagnostics: [
      {
        code: "INTERNAL_ERROR",
        severity: "error",
        rule_path: "playground",
        message,
        suggestion: "Check the browser console or retry after editing input.",
      },
    ],
  });
}

function emptyMessage(message: string): HTMLElement {
  const paragraph = document.createElement("p");
  paragraph.className = "empty-state";
  paragraph.textContent = message;
  return paragraph;
}

function decisionIcon(status: "pass" | "fail" | "indeterminate"): string {
  if (status === "pass") return "✓";
  if (status === "fail") return "×";
  return "⚠";
}

async function loadSelectedExample(): Promise<boolean> {
  const token = ++exampleLoadToken;
  const example = selectedExample();
  const dataFile = variantSelect.value === "pass" ? example.pass : example.fail;
  const [rule, data] = await Promise.all([
    loadExampleText(example.rule),
    loadExampleText(dataFile),
  ]);
  if (token !== exampleLoadToken) return false;
  ruleEditor.setValue(rule);
  dataEditor.setValue(data);
  return true;
}

function runCheck(): void {
  try {
    renderResponse(engine.check(ruleEditor.getValue(), selectedTraceMode()));
  } catch (error) {
    renderError(error);
  }
}

function runEvaluate(): void {
  try {
    const checked = engine.check(ruleEditor.getValue(), selectedTraceMode());
    if (!checked.ok || checked.diagnostics.length > 0) {
      renderResponse(checked);
      return;
    }
    renderResponse(
      engine.evaluate(
        ruleEditor.getValue(),
        dataEditor.getValue(),
        selectedTraceMode(),
      ),
    );
  } catch (error) {
    renderError(error);
  }
}

checkButton.addEventListener("click", runCheck);
evaluateButton.addEventListener("click", runEvaluate);
formatButton.addEventListener("click", () => {
  try {
    ruleEditor.format();
    dataEditor.format();
  } catch (error) {
    renderError(error);
  }
});
copyButton.addEventListener("click", () => {
  if (!lastResponse) return;
  navigator.clipboard
    .writeText(responseJson(lastResponse))
    .then(() => {
      copyButton.textContent = "Copied";
      window.setTimeout(() => {
        copyButton.textContent = "Copy JSON";
      }, 1200);
    })
    .catch(renderError);
});
downloadButton.addEventListener("click", () => {
  if (!lastResponse) return;
  const blob = new Blob([responseJson(lastResponse)], {
    type: "application/json",
  });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = "moonrules-report.json";
  anchor.click();
  URL.revokeObjectURL(url);
});
exampleSelect.addEventListener("change", () => {
  loadSelectedExample()
    .then((loaded) => {
      if (loaded) runEvaluate();
    })
    .catch(renderError);
});
variantSelect.addEventListener("change", () => {
  loadSelectedExample()
    .then((loaded) => {
      if (loaded) runEvaluate();
    })
    .catch(renderError);
});

for (const tab of document.querySelectorAll<HTMLButtonElement>('[role="tab"]')) {
  tab.addEventListener("click", () => {
    for (const candidate of document.querySelectorAll<HTMLButtonElement>(
      '[role="tab"]',
    )) {
      const selected = candidate === tab;
      candidate.setAttribute("aria-selected", String(selected));
      const panelId = candidate.getAttribute("aria-controls");
      if (!panelId) continue;
      const panel = document.getElementById(panelId);
      if (panel) panel.hidden = !selected;
    }
  });
}

loadExamples()
  .then(async (loaded) => {
    examples = loaded;
    exampleSelect.replaceChildren(
      ...examples.map((example) => {
        const option = document.createElement("option");
        option.value = example.id;
        option.textContent = example.label;
        return option;
      }),
    );
    await loadSelectedExample();
    runEvaluate();
  })
  .catch(renderError);
