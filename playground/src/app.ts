import "./styles.css";

const root = document.querySelector<HTMLDivElement>("#app");
if (!root) throw new Error("missing #app");
root.innerHTML = `
  <main class="shell">
    <header>
      <p class="eyebrow">MoonBit · Explainable rules</p>
      <h1>MoonRules Playground</h1>
      <p>规则和数据只在本地浏览器处理，不会上传服务器。</p>
    </header>
    <section class="notice">Engine connected. Editors arrive in the next task.</section>
  </main>
`;
