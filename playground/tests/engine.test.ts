import { describe, expect, it } from "vitest";
import { parseAdapterResponse } from "../src/engine";

describe("parseAdapterResponse", () => {
  it("accepts an evaluation envelope", () => {
    const result = parseAdapterResponse(
      '{"ok":true,"kind":"evaluation","report":{"decision":{"status":"fail"},"trace":{"rule_path":"condition","operator":"==","status":"fail","resolved_inputs":[],"result":false,"message":"x","children":[]},"stats":{"steps_executed":3,"nodes_evaluated":3,"max_depth_reached":2,"trace_nodes_emitted":3}},"diagnostics":[]}',
    );
    expect(result.kind).toBe("evaluation");
    expect(result.report?.decision.status).toBe("fail");
  });

  it("rejects malformed adapter output", () => {
    expect(() => parseAdapterResponse("not-json")).toThrow(
      "MoonRules adapter returned invalid JSON",
    );
  });
});
