import { describe, expect, it } from "vitest";
import type { TraceNode } from "../src/contracts";
import { countTraceNodes, decisionLabel } from "../src/renderers";

describe("render helpers", () => {
  it("counts trace nodes recursively and labels decisions", () => {
    const root: TraceNode = {
      rule_path: "condition",
      operator: "and",
      status: "fail",
      resolved_inputs: [],
      result: false,
      message: "root failed",
      children: [
        {
          rule_path: "condition.and[0]",
          operator: "==",
          status: "pass",
          resolved_inputs: [],
          result: true,
          message: "child passed",
          children: [],
        },
      ],
    };

    expect(countTraceNodes(root)).toBe(2);
    expect(decisionLabel("indeterminate")).toBe("INDETERMINATE");
  });
});
