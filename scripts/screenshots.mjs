import { createRequire } from "node:module"
import { spawn, spawnSync } from "node:child_process"
import { mkdir, readdir, readFile } from "node:fs/promises"
import { resolve, dirname } from "node:path"
import { fileURLToPath } from "node:url"
import { createHash } from "node:crypto"
import { existsSync } from "node:fs"

const __dirname = dirname(fileURLToPath(import.meta.url))

// Resolve @playwright/test from the documentation site's node_modules,
 // which is where it is declared as a dev dependency.
const require = createRequire(resolve(__dirname, "..", "site", "package.json"))
const { chromium } = require("@playwright/test")
let AxeBuilder = null
try {
  AxeBuilder = require("@axe-core/playwright").default
} catch {}
if (!AxeBuilder) {
  try { AxeBuilder = require("@axe-core/playwright") } catch {}
}

const SCREENSHOTS_DIR = resolve(__dirname, "..", "site", "public", "screenshots")
const BASE_URL = "http://localhost:4000"
const VIEWPORT = { width: 1280, height: 900 }

// ---------- Early CLI: --help without DB ----------
const earlyArgs = process.argv.slice(2)
if (earlyArgs.includes("--help") || earlyArgs.includes("-h")) {
  console.log(`
Usage: node scripts/screenshots.mjs [options]

Options:
  --only <names>   Retake only specific screenshots, comma-separated.
                   Example: --only 28-header-switcher,32-settings-language
                   Also supports --only=28-header-switcher,32-...
  --failed         Retake only failed screenshots (missing or duplicate of login page).
                   Detects auth screenshots identical to 03-login-page.png via hash.
  --axe            Also run axe-core a11y checks on each page (local only)
  --help, -h       Show this help
  (no args)        Retake all screenshots
`)
  process.exit(0)
}

// Resolve real entity ids from the seeded dev database so screenshots work
// with binary_id primary keys (the demo pages can't be reached at /1).
const ID_SCRIPT = `
Logger.configure(level: :critical)
import Ecto.Query, only: [from: 2]
alias Treby.{Repo, Tenants, Jobs, Candidates, Pipeline}
tenant = Repo.all(Tenants.Tenant) |> List.first()
if tenant do
  IO.puts("__TRBY_TENANT__")
  IO.puts("#{tenant.slug}|#{tenant.id}")
  jobs = Jobs.list_jobs(tenant.id)
  candidates = Candidates.list_candidates(tenant.id)
  IO.puts("__TRBY_JOBS__")
  Enum.each(jobs, fn j -> IO.puts("#{j.title}|#{j.id}") end)
  IO.puts("__TRBY_CANDIDATES__")
  Enum.each(candidates, fn c -> IO.puts("#{c.name}|#{c.id}") end)
  pipeline_id = Pipeline.default_pipeline_id(tenant.id)
  IO.puts("__TRBY_PIPELINE__")
  IO.puts(pipeline_id)
  apps = Repo.all(from a in Treby.Pipeline.Application, where: a.tenant_id == ^tenant.id, limit: 2)
  IO.puts("__TRBY_APPS__")
  Enum.each(apps, fn a -> IO.puts("#{a.id}") end)
else
  IO.puts("__TRBY_TENANT__")
end
`

function resolveSeedIds() {
  const res = spawnSync("mix", ["run", "-e", ID_SCRIPT], {
    cwd: resolve(__dirname, ".."),
    encoding: "utf8",
    env: { ...process.env },
  })
  const stdout = res.stdout || ""
  if (res.error) throw res.error
  const jobs = {}
  const candidates = {}
  let section = null
  let tenantSlug = "acme"
  let pipelineId = null
  const appIds = []
  for (const line of stdout.split("\n")) {
    if (line.startsWith("__TRBY_TENANT__")) { section = "tenant"; continue }
    if (line.startsWith("__TRBY_JOBS__")) { section = "jobs"; continue }
    if (line.startsWith("__TRBY_CANDIDATES__")) { section = "candidates"; continue }
    if (line.startsWith("__TRBY_PIPELINE__")) { section = "pipeline"; continue }
    if (line.startsWith("__TRBY_APPS__")) { section = "apps"; continue }
    if (!section || line.trim() === "") continue
    if (section === "tenant") {
      const [slug] = line.split("|")
      if (slug) tenantSlug = slug.trim()
      section = null // only one line
      continue
    }
    if (section === "jobs") {
      const [label, id] = line.split("|")
      if (label && id) jobs[label] = id.trim()
    } else if (section === "candidates") {
      const [label, id] = line.split("|")
      if (label && id) candidates[label] = id.trim()
    } else if (section === "pipeline") {
      pipelineId = line.trim()
      section = null
    } else if (section === "apps") {
      if (line.trim()) appIds.push(line.trim())
    }
  }
  const firstJob = Object.values(jobs)[0]
  const secondJob = Object.values(jobs)[1]
  const firstCandidate = Object.values(candidates)[0]
  const secondCandidate = Object.values(candidates)[1]
  const firstApp = appIds[0]
  if (!firstJob || !secondJob || !firstCandidate) {
    throw new Error("Could not resolve seed entity ids — run `mix ecto.reset` first. Output: " + stdout)
  }
  return { tenantSlug, firstJob, secondJob, firstCandidate, secondCandidate, pipelineId, firstApp }
}

const seedIds = resolveSeedIds()
console.log(`Resolved tenant=${seedIds.tenantSlug} firstJob=${seedIds.firstJob.slice(0,8)} pipeline=${seedIds.pipelineId?.slice(0,8)}`)

// Ensure demo memberships exist for admin/member and multi-workspace user
const SETUP_SCRIPT = `
alias Treby.{Repo, Tenants, Accounts, Memberships}
alias Treby.Accounts.User
# Ensure admin and member have memberships (seeds backfill for legacy DBs)
acme = Tenants.get_tenant_by_slug("${seedIds.tenantSlug}") || Tenants.get_tenant_by_slug("acme")
for {email, role} <- [{"admin@acme.com", "admin"}, {"member@acme.com", "member"}] do
  case Accounts.get_user_by_email(email) do
    nil -> :ok
    user ->
      unless Memberships.member?(user.id, acme.id) do
        {:ok, _} = Memberships.create_membership(%{user_id: user.id, tenant_id: acme.id, role: role})
        IO.puts("created membership for " <> email)
      end
  end
end
# Ensure Beta tenant exists
beta = case Tenants.get_tenant_by_slug("beta") do
  nil -> {:ok, t} = Tenants.create_tenant(%{name: "Beta Corp", slug: "beta"}); t
  t -> t
end
# Ensure multi user exists and belongs to both acme and beta
email = "multi@demo.com"
user = case Accounts.get_user_by_email(email) do
  nil ->
    {:ok, u} = acme |> Ecto.build_assoc(:users) |> User.changeset(%{email: email, password: "password123", name: "Multi Demo", role: "admin"}) |> Repo.insert()
    {:ok, _} = Memberships.create_membership(%{user_id: u.id, tenant_id: acme.id, role: "admin"})
    {:ok, _} = Memberships.create_membership(%{user_id: u.id, tenant_id: beta.id, role: "member"})
    u
  u ->
    unless Memberships.member?(u.id, acme.id), do: Memberships.create_membership(%{user_id: u.id, tenant_id: acme.id, role: "admin"})
    unless Memberships.member?(u.id, beta.id), do: Memberships.create_membership(%{user_id: u.id, tenant_id: beta.id, role: "member"})
    u
end
IO.puts("setup done")
`
try {
  const r = spawnSync("mix", ["run", "-e", SETUP_SCRIPT], { cwd: resolve(__dirname, ".."), encoding: "utf8" })
  if (r.stdout) console.log(r.stdout.trim())
  if (r.stderr) console.warn(r.stderr.trim())
} catch (e) {
  console.warn("Setup script failed", e)
}


const tenant = seedIds.tenantSlug

// ---------- CLI: --only, --failed, --help ----------
const cliArgs = process.argv.slice(2)
function printHelp() {
  console.log(`
Usage: node scripts/screenshots.mjs [options]

Options:
  --only <names>   Retake only specific screenshots, comma-separated.
                   Example: --only 28-header-switcher,32-settings-language
                   Also supports --only=28-header-switcher,32-...
  --failed         Retake only failed screenshots (missing or duplicate of login page).
                   Detects auth screenshots identical to 03-login-page.png via hash.
  --axe            Also run axe-core a11y checks on each page (local only)
  --help, -h       Show this help
  (no args)        Retake all screenshots
`)
}
if (cliArgs.includes("--help") || cliArgs.includes("-h")) {
  printHelp()
  process.exit(0)
}

let onlyNames = null
let failedOnly = false
for (let i = 0; i < cliArgs.length; i++) {
  const a = cliArgs[i]
  if (a === "--failed") failedOnly = true
  else if (a === "--only") {
    onlyNames = (cliArgs[i + 1] || "").split(",").map((s) => s.trim()).filter(Boolean)
    i++
  } else if (a.startsWith("--only=")) {
    onlyNames = a.slice("--only=".length).split(",").map((s) => s.trim()).filter(Boolean)
  }
}

async function getFailedNames(allDefs) {
  // Hash login page if it exists
  const loginPath = resolve(SCREENSHOTS_DIR, "03-login-page.png")
  let loginHash = null
  if (existsSync(loginPath)) {
    try {
      const buf = await readFile(loginPath)
      loginHash = createHash("sha256").update(buf).digest("hex")
    } catch {}
  }
  const failed = new Set()
  // Check missing files
  let existing = new Set()
  try {
    const files = await readdir(SCREENSHOTS_DIR)
    for (const f of files) if (f.endsWith(".png")) existing.add(f.replace(/\.png$/, ""))
  } catch {}
  for (const def of allDefs) {
    if (!existing.has(def.name)) {
      failed.add(def.name)
      continue
    }
    if (def.auth && loginHash) {
      try {
        const buf = await readFile(resolve(SCREENSHOTS_DIR, `${def.name}.png`))
        const h = createHash("sha256").update(buf).digest("hex")
        if (h === loginHash) failed.add(def.name)
      } catch {}
    }
  }
  return failed
}

const screenshotDefs = [
  // Public pages (no auth needed)
  { name: "01-homepage", url: () => `${BASE_URL}/` },
  { name: "03-login-page", url: () => `${BASE_URL}/login` },
  { name: "19-register-page", url: () => `${BASE_URL}/register` },
  { name: "16-public-careers", url: () => `${BASE_URL}/${tenant}/careers` },
  {
    name: "17-public-job-detail",
    url: () => `${BASE_URL}/${tenant}/careers/${seedIds.firstJob}`,
  },
  {
    name: "18-apply-form",
    url: () => `${BASE_URL}/${tenant}/careers/${seedIds.firstJob}/apply`,
  },
  { name: "26-portal-login", url: () => `${BASE_URL}/${tenant}/portal/login` },

  // Authenticated pages (after login) — tenant-scoped
  { name: "04-dashboard", url: () => `${BASE_URL}/${tenant}/app`, auth: true },
  { name: "05-jobs-list", url: () => `${BASE_URL}/${tenant}/app/jobs`, auth: true },
  { name: "22-job-detail", url: () => `${BASE_URL}/${tenant}/app/jobs/${seedIds.firstJob}`, auth: true },
  { name: "07-pipeline-kanban", url: () => `${BASE_URL}/${tenant}/app/pipeline/${seedIds.firstJob}`, auth: true },
  { name: "08-candidates-list", url: () => `${BASE_URL}/${tenant}/app/candidates`, auth: true },
  { name: "09-candidate-detail", url: () => `${BASE_URL}/${tenant}/app/candidates/${seedIds.firstCandidate}`, auth: true },
  { name: "24-merge-center", url: () => `${BASE_URL}/${tenant}/app/candidates/merge`, auth: true },
  { name: "10-analytics", url: () => `${BASE_URL}/${tenant}/app/analytics`, auth: true },
  { name: "12-job-analytics", url: () => `${BASE_URL}/${tenant}/app/jobs/${seedIds.firstJob}/analytics`, auth: true },
  { name: "11-settings", url: () => `${BASE_URL}/${tenant}/app/settings`, auth: true },
  { name: "12-settings-pipeline", url: () => `${BASE_URL}/${tenant}/app/settings/pipeline`, auth: true },
  { name: "13-settings-team", url: () => `${BASE_URL}/${tenant}/app/settings/team`, auth: true },
  { name: "14-settings-fields", url: () => `${BASE_URL}/${tenant}/app/settings/fields`, auth: true },
  { name: "15-settings-branding", url: () => `${BASE_URL}/${tenant}/app/settings/branding`, auth: true },
  { name: "23-message-queue", url: () => `${BASE_URL}/${tenant}/app/messages-queue`, auth: true },

  // New useful screenshots
  { name: "29-csv-import", url: () => `${BASE_URL}/${tenant}/app/import`, auth: true },
  {
    name: "30-comparison",
    url: () => {
      const ids = [seedIds.firstCandidate, seedIds.secondCandidate].filter(Boolean).join(",")
      return `${BASE_URL}/${tenant}/app/candidates/compare?ids=${ids}`
    },
    auth: true,
  },
  { name: "31-settings-sources", url: () => `${BASE_URL}/${tenant}/app/settings/sources`, auth: true },
  { name: "32-settings-language", url: () => `${BASE_URL}/${tenant}/app/settings/language`, auth: true },
  { name: "33-settings-scorecards", url: () => `${BASE_URL}/${tenant}/app/settings/scorecards`, auth: true },
  { name: "34-interviews-dashboard", url: () => `${BASE_URL}/${tenant}/app/interviews`, auth: true },
  { name: "35-settings-calendar", url: () => `${BASE_URL}/${tenant}/app/settings/calendar`, auth: true },
  { name: "36-settings-availability", url: () => `${BASE_URL}/${tenant}/app/settings/availability`, auth: true },
  { name: "37-settings-emails", url: () => `${BASE_URL}/${tenant}/app/settings/emails`, auth: true },
  { name: "38-settings-audit-log", url: () => `${BASE_URL}/${tenant}/app/settings/audit-log`, auth: true },
  { name: "39-settings-notifications", url: () => `${BASE_URL}/${tenant}/app/settings/notifications`, auth: true },
  ...(seedIds.pipelineId
    ? [{ name: "40-pipeline-stages", url: () => `${BASE_URL}/${tenant}/app/settings/pipeline/${seedIds.pipelineId}`, auth: true }]
    : []),
  ...(seedIds.firstApp
    ? [{ name: "41-schedule-page", url: () => `${BASE_URL}/${tenant}/app/schedule/${seedIds.firstApp}`, auth: true }]
    : []),
  { name: "42-portal-verify", url: () => `${BASE_URL}/${tenant}/portal/verify` },

  // Workspace switching (multi user)
  { name: "27-workspace-picker", url: () => `${BASE_URL}/choose-tenant`, auth: "multi" },
  { name: "28-header-switcher", url: () => `${BASE_URL}/${tenant}/app`, auth: "multi", openSwitcher: true },
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

async function login(page, email, password) {
  await page.goto(`${BASE_URL}/login`, { waitUntil: "domcontentloaded", timeout: 15000 })
  await page.fill('input[name="user[email]"]', email)
  await page.fill('input[name="user[password]"]', password)
  await page.click('button[type="submit"]')
  // Wait for redirect — compatible with older Playwright
  await page.waitForTimeout(2500)
  // Also wait for network idle to ensure LiveView mounted
  try { await page.waitForLoadState("networkidle", { timeout: 5000 }) } catch {}
  const url = page.url()
  if (url.includes("/login")) {
    const body = await page.content()
    if (body.includes("Invalid email or password")) {
      throw new Error(`Login failed for ${email}: invalid credentials`)
    }
    throw new Error(`Login failed for ${email}: still on /login (${url})`)
  }
  console.log(`  ✓ Logged in as ${email} -> ${url}`)
}

async function assertNotLogin(page, name) {
  const url = page.url()
  if (url.includes("/login")) {
    throw new Error(`${name} redirected to login (url=${url})`)
  }
  const content = await page.content()
  // Login page contains this heading and the email field name
  if (content.includes("Sign in to your account") && content.includes('name="user[email]"')) {
    throw new Error(`${name} shows login page content (url=${url})`)
  }
}

let axeEnabled = process.argv.includes("--axe")
let axeViolations = []

async function capturePage(page, def) {
  const url = def.url()
  console.log(`  ${def.name} -> ${url}`)
  await page.goto(url, { waitUntil: "domcontentloaded", timeout: 15000 })
  await page.waitForTimeout(700)
  // Some LiveViews need websocket mount — short wait, don't block long
  try { await page.waitForLoadState("networkidle", { timeout: 1500 }) } catch {}
  // Verify not on login for auth pages
  if (def.auth) {
    try {
      await assertNotLogin(page, def.name)
    } catch (err) {
      // Re-throw with context so caller can retry login
      err.isLoginRedirect = true
      throw err
    }
  }
  // Open workspace switcher if requested
  if (def.openSwitcher) {
    try {
      await page.click('#workspace-switcher button', { timeout: 2000 })
      await page.waitForTimeout(400)
    } catch {}
  }
  const out = resolve(SCREENSHOTS_DIR, `${def.name}.png`)
  await page.screenshot({ path: out, fullPage: false })
  // Post-capture guard: if we thought we were auth but file is login-sized, warn
  console.log(`    ✓ ${def.name}.png`)

  // Axe a11y check (opt-in via --axe, local only)
  if (axeEnabled && AxeBuilder) {
    try {
      const results = await new AxeBuilder({ page }).analyze()
      const critical = results.violations.filter((v) => ["critical", "serious"].includes(v.impact))
      if (critical.length > 0) {
        console.warn(`    ⚠ axe: ${critical.length} serious/critical violations on ${def.name}`)
        for (const v of critical) console.warn(`      - ${v.id}: ${v.description} (${v.nodes.length} nodes)`)
        axeViolations.push({ page: def.name, violations: critical })
      } else if (results.violations.length > 0) {
        console.log(`    axe: ${results.violations.length} minor/moderate violations (ok)`)
      }
    } catch (err) {
      console.warn(`    axe failed on ${def.name}: ${err.message}`)
    }
  }
}

async function run() {
  await mkdir(SCREENSHOTS_DIR, { recursive: true })

  // Resolve effective set based on CLI
  let effectiveDefs = screenshotDefs
  if (onlyNames) {
    const set = new Set(onlyNames)
    effectiveDefs = screenshotDefs.filter((d) => set.has(d.name))
    console.log(`--only filter: ${effectiveDefs.length} screenshot(s): ${effectiveDefs.map((d) => d.name).join(", ")}`)
    if (effectiveDefs.length === 0) {
      console.warn("No matching screenshot names — check --only list")
      return
    }
  } else if (failedOnly) {
    const failed = await getFailedNames(screenshotDefs)
    effectiveDefs = screenshotDefs.filter((d) => failed.has(d.name))
    if (effectiveDefs.length === 0) {
      console.log("✓ No failed screenshots detected — all auth images differ from login and all files present.")
      return
    }
    console.log(`--failed: retaking ${effectiveDefs.length} screenshot(s): ${effectiveDefs.map((d) => d.name).join(", ")}`)
  }

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

    // Capture public pages first (no auth)
    const publicDefs = effectiveDefs.filter((d) => !d.auth)
    if (publicDefs.length > 0) {
      console.log("Capturing public pages...")
      for (const def of publicDefs) {
        try {
          await capturePage(page, def)
        } catch (err) {
          console.warn(`  ⚠ Failed to capture ${def.name}: ${err.message}`)
          throw err
        }
      }
    } else {
      console.log("Skipping public pages (not in filter)")
    }

    // Login as admin if needed
    const needAdmin = effectiveDefs.some((d) => d.auth === true)
    const needMulti = effectiveDefs.some((d) => d.auth === "multi")
    if (needAdmin) {
      console.log("Logging in as admin@acme.com...")
      await login(page, "admin@acme.com", "password123")
    }

    // Capture authenticated pages (standard user)
    console.log(needAdmin ? "Capturing authenticated pages (admin)..." : "Skipping admin pages (not in filter)")
    const authDefs = effectiveDefs.filter((d) => d.auth === true)
    for (const def of authDefs) {
      let attempts = 0
      while (attempts < 2) {
        try {
          await capturePage(page, def)
          break
        } catch (err) {
          if (err.isLoginRedirect && attempts === 0) {
            console.warn(`  ↻ ${def.name} was login, re-logging in... (${err.message})`)
            try {
              await login(page, "admin@acme.com", "password123")
            } catch (loginErr) {
              console.warn(`  ⚠ Re-login failed for ${def.name}: ${loginErr.message}`)
              break
            }
            attempts++
            continue
          }
          console.warn(`  ⚠ Failed to capture ${def.name}: ${err.message}`)
          break
        }
      }
      // small pause to avoid overwhelming LiveView
      await page.waitForTimeout(300)
    }

    // Capture workspace switching: login as multi-workspace user
    if (needMulti) {
      console.log("Capturing workspace switching (multi-workspace user)...")
      await login(page, "multi@demo.com", "password123")
    } else {
      console.log("Skipping workspace-switching pages (not in filter)")
    }
    const multiDefs = effectiveDefs.filter((d) => d.auth === "multi")
    for (const def of multiDefs) {
      try {
        await capturePage(page, def)
      } catch (err) {
        console.warn(`  ⚠ Failed to capture ${def.name}: ${err.message}`)
        throw err
      }
    }

    // Dark mode variant: only when doing full capture or dashboard is requested
    const shouldDark = !onlyNames && !failedOnly || effectiveDefs.some((d) => d.name === "04-dashboard")
    if (shouldDark) {
      try {
        console.log("Capturing dark mode...")
        // Ensure we are logged in as admin for dark mode (if we switched to multi, re-login)
        if (needMulti && !needAdmin) {
          await login(page, "admin@acme.com", "password123")
        } else if (needAdmin && effectiveDefs.some((d) => d.auth === "multi")) {
          // we are on multi session, switch back to admin
          await login(page, "admin@acme.com", "password123")
        }
        await page.goto(`${BASE_URL}/${tenant}/app`, { waitUntil: "domcontentloaded", timeout: 15000 })
        await page.waitForTimeout(800)
        await assertNotLogin(page, "dark-mode check")
        await page.evaluate(() => localStorage.setItem("phx:theme", "dark"))
        await page.goto(`${BASE_URL}/${tenant}/app`, { waitUntil: "domcontentloaded", timeout: 15000 })
        await page.waitForTimeout(800)
        try { await page.waitForLoadState("networkidle", { timeout: 3000 }) } catch {}
        await page.screenshot({ path: resolve(SCREENSHOTS_DIR, `25-dark-mode.png`) })
        console.log("    ✓ 25-dark-mode.png")
      } catch (err) {
        console.warn(`  ⚠ Failed to capture dark mode: ${err.message}`)
      }
    } else {
      console.log("Skipping dark mode (not in filter)")
    }

    await browser.close()
    if (axeEnabled) {
      if (axeViolations.length > 0) {
        console.warn(`\n⚠ axe a11y: ${axeViolations.length} pages with serious/critical violations`)
        for (const { page, violations } of axeViolations) console.warn(`  - ${page}: ${violations.map((v) => v.id).join(", ")}`)
      } else {
        console.log("\n✓ axe a11y: no serious/critical violations")
      }
    }
    console.log("\n✓ All screenshots captured and verified (no login-page duplicates)!")
  } finally {
    killServer()
  }
}

run().catch((err) => {
  console.error("Screenshot script failed:", err)
  process.exit(1)
})
