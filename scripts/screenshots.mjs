import { createRequire } from "node:module"
import { spawn, spawnSync } from "node:child_process"
import { mkdir } from "node:fs/promises"
import { resolve, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const __dirname = dirname(fileURLToPath(import.meta.url))

// Resolve @playwright/test from the documentation site's node_modules,
// which is where it is declared as a dev dependency.
const require = createRequire(resolve(__dirname, "..", "site", "package.json"))
const { chromium } = require("@playwright/test")

const SCREENSHOTS_DIR = resolve(__dirname, "..", "site", "public", "screenshots")
const BASE_URL = "http://localhost:4000"
const VIEWPORT = { width: 1280, height: 900 }

// Resolve real entity ids from the seeded dev database so screenshots work
// with binary_id primary keys (the demo pages can't be reached at /1).
const ID_SCRIPT = `
Logger.configure(level: :critical)
alias Treby.{Repo, Tenants, Jobs, Candidates}
tenant = Repo.all(Tenants.Tenant) |> List.first()
jobs = Jobs.list_jobs(tenant.id)
candidates = Candidates.list_candidates(tenant.id)
IO.puts("__TRBY_JOBS__")
Enum.each(jobs, fn j -> IO.puts("#{j.title}|#{j.id}") end)
IO.puts("__TRBY_CANDIDATES__")
Enum.each(candidates, fn c -> IO.puts("#{c.name}|#{c.id}") end)
`

function resolveSeedIds() {
  const res = spawnSync("mix", ["run", "-e", ID_SCRIPT], {
    cwd: resolve(__dirname, ".."),
    encoding: "utf8",
    env: { ...process.env },
  })
  const stdout = res.stdout || ""
  const jobs = {}
  const candidates = {}
  let section = null
  for (const line of stdout.split("\n")) {
    if (line.startsWith("__TRBY_JOBS__")) {
      section = "jobs"
      continue
    }
    if (line.startsWith("__TRBY_CANDIDATES__")) {
      section = "candidates"
      continue
    }
    if (!section || line.trim() === "") continue
    const [label, id] = line.split("|")
    if (section === "jobs") jobs[label] = id
    if (section === "candidates") candidates[label] = id
  }
  const firstJob = Object.values(jobs)[0]
  const secondJob = Object.values(jobs)[1]
  const firstCandidate = Object.values(candidates)[0]
  if (!firstJob || !secondJob || !firstCandidate) {
    throw new Error("Could not resolve seed entity ids — run `mix ecto.reset` first")
  }
  return { firstJob, secondJob, firstCandidate }
}

const seedIds = resolveSeedIds()

// Ensure demo multi-workspace user exists for workspace switching screenshots
const MULTI_SETUP = `
alias Treby.{Repo, Tenants, Accounts, Memberships}
alias Treby.Accounts.User
# Ensure Beta tenant exists
beta = case Tenants.get_tenant_by_slug("beta") do
  nil -> {:ok, t} = Tenants.create_tenant(%{name: "Beta Corp", slug: "beta"}); t
  t -> t
end
# Ensure multi user exists and belongs to both acme and beta
email = "multi@demo.com"
user = case Accounts.get_user_by_email(email) do
  nil ->
    acme = Tenants.get_tenant_by_slug("acme")
    {:ok, u} = acme |> Ecto.build_assoc(:users) |> User.changeset(%{email: email, password: "password123", name: "Multi Demo", role: "admin"}) |> Repo.insert()
    {:ok, _} = Memberships.create_membership(%{user_id: u.id, tenant_id: acme.id, role: "admin"})
    {:ok, _} = Memberships.create_membership(%{user_id: u.id, tenant_id: beta.id, role: "member"})
    u
  u ->
    # Ensure memberships exist
    acme = Tenants.get_tenant_by_slug("acme")
    unless Memberships.member?(u.id, acme.id), do: Memberships.create_membership(%{user_id: u.id, tenant_id: acme.id, role: "admin"})
    unless Memberships.member?(u.id, beta.id), do: Memberships.create_membership(%{user_id: u.id, tenant_id: beta.id, role: "member"})
    u
end
IO.puts("multi setup done")
`
try {
  spawnSync("mix", ["run", "-e", MULTI_SETUP], { cwd: resolve(__dirname, ".."), encoding: "utf8" })
} catch {}


const screenshotDefs = [
  // Public pages (no auth needed)
  { name: "01-homepage", url: () => `${BASE_URL}/` },

  { name: "03-login-page", url: () => `${BASE_URL}/login` },
  { name: "19-register-page", url: () => `${BASE_URL}/register` },
  { name: "16-public-careers", url: () => `${BASE_URL}/acme/careers` },
  {
    name: "17-public-job-detail",
    url: () => `${BASE_URL}/acme/careers/${seedIds.firstJob}`,
  },
  {
    name: "18-apply-form",
    url: () => `${BASE_URL}/acme/careers/${seedIds.firstJob}/apply`,
  },

  // Authenticated pages (after login)
  { name: "04-dashboard", url: () => `${BASE_URL}/app/`, auth: true },
  { name: "05-jobs-list", url: () => `${BASE_URL}/app/jobs`, auth: true },
  { name: "22-job-detail", url: () => `${BASE_URL}/app/jobs/${seedIds.firstJob}`, auth: true },
  { name: "07-pipeline-kanban", url: () => `${BASE_URL}/app/pipeline/${seedIds.firstJob}`, auth: true },
  { name: "08-candidates-list", url: () => `${BASE_URL}/app/candidates`, auth: true },
  { name: "09-candidate-detail", url: () => `${BASE_URL}/app/candidates/${seedIds.firstCandidate}`, auth: true },
  { name: "24-merge-center", url: () => `${BASE_URL}/app/candidates/merge`, auth: true },
  { name: "10-analytics", url: () => `${BASE_URL}/app/analytics`, auth: true },
  { name: "12-job-analytics", url: () => `${BASE_URL}/app/jobs/${seedIds.firstJob}/analytics`, auth: true },
  { name: "11-settings", url: () => `${BASE_URL}/app/settings`, auth: true },
  { name: "12-settings-pipeline", url: () => `${BASE_URL}/app/settings/pipeline`, auth: true },
  { name: "13-settings-team", url: () => `${BASE_URL}/app/settings/team`, auth: true },
  { name: "14-settings-fields", url: () => `${BASE_URL}/app/settings/fields`, auth: true },
  { name: "15-settings-branding", url: () => `${BASE_URL}/app/settings/branding`, auth: true },
  { name: "23-message-queue", url: () => `${BASE_URL}/app/messages-queue`, auth: true },
  { name: "26-portal-login", url: () => `${BASE_URL}/acme/portal/login` },
  { name: "27-workspace-picker", url: () => `${BASE_URL}/choose-tenant`, auth: true },
  { name: "28-header-switcher", url: () => `${BASE_URL}/acme/app`, auth: true },
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
    const context = await browser.newContext({
      viewport: VIEWPORT,
      colorScheme: "light",
    })
    const page = await context.newPage()

    // Capture public pages first
    console.log("Capturing public pages...")
    for (const def of screenshotDefs.filter((d) => !d.auth)) {
      console.log(`  ${def.name}...`)
      try {
        await page.goto(def.url(), { waitUntil: "domcontentloaded", timeout: 15000 })
        await page.waitForTimeout(500)
        await page.screenshot({ path: resolve(SCREENSHOTS_DIR, `${def.name}.png`) })
      } catch (err) {
        console.warn(`  ⚠ Failed to capture ${def.name}: ${err.message}`)
      }
    }

    // Login
    console.log("Logging in...")
    await page.goto(`${BASE_URL}/login`, { waitUntil: "domcontentloaded" })
    await page.fill('input[name="user[email]"]', "admin@acme.com")
    await page.fill('input[name="user[password]"]', "password123")
    await page.click('button[type="submit"]')
    await page.waitForTimeout(2000)
    console.log(`  Current URL after login: ${page.url()}`)
    console.log("Logged in successfully")

    // Capture authenticated pages
    console.log("Capturing authenticated pages...")
    for (const def of screenshotDefs.filter((d) => d.auth && !d.name.startsWith("27-") && !d.name.startsWith("28-"))) {
      console.log(`  ${def.name}...`)
      try {
        await page.goto(def.url(), { waitUntil: "domcontentloaded", timeout: 15000 })
        await page.waitForTimeout(500)
        await page.screenshot({ path: resolve(SCREENSHOTS_DIR, `${def.name}.png`) })
      } catch (err) {
        console.warn(`  ⚠ Failed to capture ${def.name}: ${err.message}`)
      }
    }

    // Capture workspace switching: login as multi-workspace user
    console.log("Capturing workspace switching (multi-workspace user)...")
    try {
      await page.goto(`${BASE_URL}/login`, { waitUntil: "domcontentloaded" })
      await page.fill('input[name="user[email]"]', "multi@demo.com")
      await page.fill('input[name="user[password]"]', "password123")
      await page.click('button[type="submit"]')
      await page.waitForTimeout(2000)
      console.log(`  Current URL after multi login: ${page.url()}`)
      console.log("  Logged in as multi@demo.com, on choose-tenant")
      await page.goto(`${BASE_URL}/choose-tenant`, { waitUntil: "domcontentloaded", timeout: 15000 })
      await page.waitForTimeout(500)
      await page.screenshot({ path: resolve(SCREENSHOTS_DIR, `27-workspace-picker.png`) })
      console.log("  27-workspace-picker... done")
      // Now pick first workspace and capture header switcher
      await page.goto(`${BASE_URL}/acme/app`, { waitUntil: "domcontentloaded", timeout: 15000 })
      await page.waitForTimeout(500)
      // Try to open switcher if visible
      try {
        await page.click('#workspace-switcher button', { timeout: 2000 })
        await page.waitForTimeout(300)
      } catch {}
      await page.screenshot({ path: resolve(SCREENSHOTS_DIR, `28-header-switcher.png`) })
      console.log("  28-header-switcher... done")
    } catch (err) {
      console.warn(`  ⚠ Failed to capture workspace switching: ${err.message}`)
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
