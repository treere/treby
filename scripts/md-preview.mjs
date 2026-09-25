#!/usr/bin/env node
// Render a markdown file (with mermaid blocks) to a standalone HTML preview
// and open it in the browser. Usage:
//   node scripts/md-preview.mjs reports/ai-chat-liveview-integrazione.md
// Optional flags: --no-open  --out <path>
import { readFileSync, writeFileSync } from "node:fs"
import { execFileSync } from "node:child_process"
import { basename, resolve } from "node:path"
import { tmpdir } from "node:os"

const args = process.argv.slice(2)
const file = args.find((a) => !a.startsWith("--") && args[args.indexOf(a) - 1] !== "--out")
if (!file) {
  console.error("usage: node scripts/md-preview.mjs <file.md> [--no-open] [--out <path>]")
  process.exit(1)
}

const md = readFileSync(file, "utf8")
const title = basename(file)
const b64 = Buffer.from(md, "utf8").toString("base64")
const outIdx = args.indexOf("--out")
const out = outIdx >= 0 ? resolve(args[outIdx + 1]) : resolve(tmpdir(), title.replace(/\.md$/i, "") + ".preview.html")

const html = `<!doctype html>
<html lang="it">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>${title}</title>
<style>
  :root { color-scheme: light dark; }
  body { margin: 0; font: 16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
         color: #18181b; background: #fff; }
  @media (prefers-color-scheme: dark) { body { color: #e4e4e7; background: #18181b; } }
  main { max-width: 900px; margin: 0 auto; padding: 40px 24px 80px; }
  h1, h2, h3 { line-height: 1.25; margin-top: 1.6em; }
  h1 { border-bottom: 1px solid currentColor; padding-bottom: .3em; }
  h2 { border-bottom: 1px solid rgba(128,128,128,.25); padding-bottom: .25em; }
  a { color: #ea580c; }
  code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: .9em;
         background: rgba(128,128,128,.15); padding: .15em .4em; border-radius: 4px; }
  pre { background: rgba(128,128,128,.10); padding: 16px; border-radius: 10px; overflow-x: auto; }
  pre code { background: none; padding: 0; }
  blockquote { margin: 1em 0; padding: .2em 1em; border-left: 4px solid #ea580c; color: #71717a; }
  table { border-collapse: collapse; width: 100%; margin: 1.2em 0; font-size: .95em; }
  th, td { border: 1px solid rgba(128,128,128,.35); padding: 8px 12px; text-align: left; vertical-align: top; }
  th { background: rgba(128,128,128,.12); }
  .mermaid { margin: 1.6em 0; text-align: center; overflow-x: auto; }
  hr { border: none; border-top: 1px solid rgba(128,128,128,.35); margin: 2.5em 0; }
</style>
</head>
<body>
<main id="content">Caricamento…</main>
<script type="module">
import { marked } from "https://cdn.jsdelivr.net/npm/marked@12/lib/marked.esm.js"
import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs"

const b64 = "${b64}"
const bytes = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0))
const md = new TextDecoder().decode(bytes)

marked.setOptions({ gfm: true, breaks: false })
document.getElementById("content").innerHTML = marked.parse(md)

// marked emits mermaid fences as <pre><code class="language-mermaid">.
// Swap them for mermaid nodes, then render.
document.querySelectorAll("pre > code.language-mermaid").forEach((code) => {
  const div = document.createElement("div")
  div.className = "mermaid"
  div.textContent = code.textContent
  code.parentElement.replaceWith(div)
})

const dark = matchMedia("(prefers-color-scheme: dark)").matches
mermaid.initialize({ startOnLoad: false, theme: dark ? "dark" : "default", securityLevel: "loose" })
try { await mermaid.run({ querySelector: ".mermaid" }) } catch (e) { console.error(e) }
</script>
</body>
</html>`

writeFileSync(out, html)
console.log(out)

if (!args.includes("--no-open")) {
  try {
    execFileSync("xdg-open", [out], { stdio: "ignore" })
  } catch {
    console.error("Could not open a browser automatically; open the file above manually.")
  }
}
