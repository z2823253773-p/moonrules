import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { engine } from "../src/engine";
import { type Example, exampleUrl } from "../src/examples";

const examplesDir = join(process.cwd(), "public", "examples");
const manifestPath = join(examplesDir, "manifest.json");

function readExample(file: string): string {
  return readFileSync(join(examplesDir, file), {
    encoding: "utf8",
  });
}

function readManifest(): Example[] {
  return JSON.parse(readFileSync(manifestPath, { encoding: "utf8" })) as Example[];
}

describe("examples", () => {
  it("builds base-aware example URLs", () => {
    expect(exampleUrl("coupon.rule.json", "/moonrules/")).toBe(
      "/moonrules/examples/coupon.rule.json",
    );
    expect(exampleUrl("coupon.rule.json", "/moonrules")).toBe(
      "/moonrules/examples/coupon.rule.json",
    );
  });

  it("manifest references files that exist", () => {
    for (const example of readManifest()) {
      expect(existsSync(join(examplesDir, example.rule))).toBe(true);
      expect(existsSync(join(examplesDir, example.pass))).toBe(true);
      expect(existsSync(join(examplesDir, example.fail))).toBe(true);
    }
  });

  it("manifest pass and fail examples evaluate as labeled", () => {
    for (const example of readManifest()) {
      const rule = readExample(example.rule);
      const pass = engine.evaluate(rule, readExample(example.pass), "full");
      const fail = engine.evaluate(rule, readExample(example.fail), "full");

      expect(pass.ok).toBe(true);
      expect(pass.report?.decision.status).toBe("pass");
      expect(fail.ok).toBe(true);
      expect(fail.report?.decision.status).toBe("fail");
    }
  });
});
