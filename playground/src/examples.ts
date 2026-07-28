export interface Example {
  id: string;
  label: string;
  rule: string;
  pass: string;
  fail: string;
}

export function exampleUrl(
  file: string,
  base = import.meta.env.BASE_URL,
): string {
  const normalizedBase = base.endsWith("/") ? base : `${base}/`;
  return `${normalizedBase}examples/${file}`;
}

export async function loadExamples(): Promise<Example[]> {
  const response = await fetch(exampleUrl("manifest.json"));
  if (!response.ok) throw new Error("failed to load example manifest");
  return response.json() as Promise<Example[]>;
}

export async function loadExampleText(file: string): Promise<string> {
  const response = await fetch(exampleUrl(file));
  if (!response.ok) throw new Error(`failed to load ${file}`);
  return response.text();
}
