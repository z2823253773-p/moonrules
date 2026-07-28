export type DecisionStatus = "pass" | "fail" | "indeterminate";
export type TraceStatus = "value" | "pass" | "fail" | "error" | "skipped";
export type TraceMode = "full" | "summary" | "off";

export interface Diagnostic {
  code: string;
  severity: "error" | "warning";
  rule_path: string;
  message: string;
  suggestion: string;
}

export interface TraceNode {
  rule_path: string;
  operator: string;
  status: TraceStatus;
  resolved_inputs: Array<{ source: string; value: unknown }>;
  result: unknown;
  message: string;
  children: TraceNode[];
}

export interface EvaluationReport {
  decision: { status: DecisionStatus; error?: unknown };
  trace: TraceNode;
  stats: {
    steps_executed: number;
    nodes_evaluated: number;
    max_depth_reached: number;
    trace_nodes_emitted: number;
  };
}

export interface AdapterResponse {
  ok: boolean;
  kind: "check" | "evaluation" | "input_error" | "internal_error";
  report: EvaluationReport | null;
  diagnostics: Diagnostic[];
}
