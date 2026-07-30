import { chromium } from "@playwright/test"
import { spawn } from "node:child_process"
import { mkdir } from "node:fs/promises"
import { resolve, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const __dirname = dirname(fileURLToPath(import.meta.url))
const SCREENSHOTS_DIR = resolve(__dirname, "..", "site", "public", "screenshots")
const BASE_URL = "http://localhost:4000"
const VIEWPORT = { width: 1280, height: 900 }

const screenshotDefs = [
  // Public pages (no auth needed)
  { name: "01-homepage", url: () => `${BASE_URL}/` },

  { name: "03-login-page", url: () => `${BASE_URL}/login` },
  { name: "19-register-page", url: () => `${BASE_URL}/register` },
  { name: "16-public-careers", url: () => `${BASE_URL}/acme/careers` },
  { name: "17-public-job-detail", url: () => `${BASE_URL}/acme/careers/1` },
  { name: "18-apply-form", url: () => `${BASE_URL}/acme/careers/1/apply` },

  // Authenticated pages (after login)
  { name: "04-dashboard", url: () => `${BASE_URL}/app/`, auth: true },
  { name: "05-jobs-list", url: () => `${BASE_URL}/app/jobs`, auth: true },
  { name: "22-job-detail", url: () => `${BASE_URL}/app/jobs/1`, auth: true },
  { name: "07-pipeline-kanban", url: () => `${BASE_URL}/app/pipeline/1`, auth: true },
  { name: "08-candidates-list", url: () => `${BASE_URL}/app/candidates`, auth: true },
  { name: "09-candidate-detail", url: () => `${BASE_URL}/app/candidates/1`, auth: true },
  { name: "10-analytics", url: () => `${BASE_URL}/app/analytics`, auth: true },
  { name: "11-settings", url: () => `${BASE_URL}/app/settings`, auth: true },
  { name: "12-settings-pipeline", url: () => `${BASE_URL}/app/settings/pipeline`, auth: true },
  { name: "13-settings-team", url: () => `${BASE_URL}/app/settings/team`, auth: true },
  { name: "14-settings-fields", url: () => `${BASE_URL}/app/settings/fields`, auth: true },
  { name: "15-settings-branding", url: () => `${BASE_URL}/app/settings/branding`, auth: true },
]

async function waitForServer(url, timeoutMs = 120000) {
  const start = Date.now()
  while (Date.now() - start < timeoutMs) {
    try {
      const res = await fetch(url)
      if (res.ok) return
    } catch {}
    await new Promise((r) => setTimeout(r, 1000))
  }
  throw new Error(`Server did not start within ${timeoutMs}ms`)
}

async function startPhoenix() {
  const proc = spawn("mix", ["phx.server"], {
    cwd: resolve(__dirname, ".."),
    stdio: ["ignore", "ignore", "ignore"],
    env: { ...process.env },
    detached: true,
  })
  return proc
}

async function run() {
  await mkdir(SCREENSHOTS_DIR, { recursive: true })

  console.log("Starting Phoenix server...")
  const server = startPhoenix()
  let killed = false
  const killServer = () => {
    if (killed) return
    killed = true
    try { process.kill(-server.pid, "SIGTERM") } catch {}
    try { server.kill("SIGTERM") } catch {}
  }

  process.on("SIGINT", killServer)
  process.on("SIGTERM", killServer)

  try {
    console.log("Waiting for server...")
    await waitForServer(`${BASE_URL}/login`)

    const browser = await chromium.launch()
    const context = await browser.newContext({ viewport: VIEWPORT })
    const page = await context.newPage()

    // Capture public pages first
    console.log("Capturing public pages...")
    for (const def of screenshotDefs.filter((d) => !d.auth)) {
      console.log(`  ${def.name}...`)
      try {
        await page.goto(def.url(), { waitUntil: "networkidle", timeout: 15000 })
        await page.waitForTimeout(500)
        await page.screenshot({ path: resolve(SCREENSHOTS_DIR, `${def.name}.png`) })
      } catch (err) {
        console.warn(`  ⚠ Failed to capture ${def.name}: ${err.message}`)
      }
    }

    // Login
    console.log("Logging in...")
    await page.goto(`${BASE_URL}/login`, { waitUntil: "networkidle" })
    await page.fill('input[name="user[email]"]', "admin@acme.com")
    await page.fill('input[name="user[password]"]', "password123")
    await page.click('button[type="submit"]')
    await page.waitForURL("**/app/**", { timeout: 10000 })
    console.log("Logged in successfully")

    // Capture authenticated pages
    console.log("Capturing authenticated pages...")
    for (const def of screenshotDefs.filter((d) => d.auth)) {
      console.log(`  ${def.name}...`)
      try {
        await page.goto(def.url(), { waitUntil: "networkidle", timeout: 15000 })
        await page.waitForTimeout(500)
        await page.screenshot({ path: resolve(SCREENSHOTS_DIR, `${def.name}.png`) })
      } catch (err) {
        console.warn(`  ⚠ Failed to capture ${def.name}: ${err.message}`)
      }
    }

    await browser.close()
    console.log("\n✓ All screenshots captured!")
  } finally {
    killServer()
  }
}

run().catch((err) => {
  console.error("Screenshot script failed:", err)
  process.exit(1)
})
