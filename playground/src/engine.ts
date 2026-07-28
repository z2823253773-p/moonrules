import type { AdapterResponse, TraceMode } from "./contracts";

export function parseAdapterResponse(source: string): AdapterResponse {
  try {
    return JSON.parse(source) as AdapterResponse;
  } catch {
    throw new Error("MoonRules adapter returned invalid JSON");
  }
}

export interface MoonRulesEngine {
  check(rule: string, traceMode: TraceMode): AdapterResponse;
  evaluate(rule: string, data: string, traceMode: TraceMode): AdapterResponse;
}

// @ts-expect-error generated MoonBit module has no declaration file
import * as moonrules from "./generated/moonrules.js";

export const engine: MoonRulesEngine = {
  check(rule, traceMode) {
    return parseAdapterResponse(
      moonrules.check_json(rule, JSON.stringify({ trace_mode: traceMode })),
    );
  },
  evaluate(rule, data, traceMode) {
    return parseAdapterResponse(
      moonrules.evaluate_json(
        rule,
        data,
        JSON.stringify({ trace_mode: traceMode }),
      ),
    );
  },
};
