// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/treby"
import topbar from "topbar"
import SortableHook from "./hooks/sortable"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, Sortable: SortableHook},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

function highlightActiveNav() {
  const path = window.location.pathname
  document.querySelectorAll("[data-nav]").forEach(el => {
    const navPath = el.getAttribute("data-nav")
    const isActive = path === navPath || (navPath !== "/app" && path.startsWith(navPath + "/"))
    if (el.classList.contains("nav-link")) {
      el.classList.toggle("border-blue-600", isActive)
      el.classList.toggle("text-blue-600", isActive)
      el.classList.toggle("border-transparent", !isActive)
    } else if (el.classList.contains("mobile-nav-link")) {
      el.classList.toggle("bg-blue-50", isActive)
      el.classList.toggle("text-blue-600", isActive)
    }
  })
}

highlightActiveNav()
window.addEventListener("phx:page-loading-stop", highlightActiveNav)

// Close mobile nav drawer when a link inside it is clicked
document.getElementById("mobile-nav-drawer")?.addEventListener("click", (e) => {
  if (e.target.closest("a")) {
    const drawer = document.getElementById("mobile-nav-drawer")
    const overlay = document.getElementById("mobile-nav-overlay")
    drawer?.classList.add("-translate-x-full")
    overlay?.classList.add("hidden")
  }
})

// Close mobile nav drawer when overlay is clicked
document.getElementById("mobile-nav-overlay")?.addEventListener("click", () => {
  const drawer = document.getElementById("mobile-nav-drawer")
  const overlay = document.getElementById("mobile-nav-overlay")
  drawer?.classList.add("-translate-x-full")
  overlay?.classList.add("hidden")
})

// Dead-view loading feedback: show spinner + loading label on full POST forms
document.addEventListener(
  "submit",
  (e) => {
    const form = e.target
    if (!(form instanceof HTMLFormElement)) return
    if (form.hasAttribute("phx-submit") || form.hasAttribute("data-phx-submit")) return
    // Only for non-LiveView forms (dead views); allow POST/PUT/PATCH/DELETE which all POST under the hood
    const method = (form.getAttribute("method") || form.method || "").toLowerCase()
    if (method === "get" || method === "") return

    const buttons = form.querySelectorAll('button[type="submit"]')
    if (buttons.length === 0) return

    buttons.forEach((btn) => {
      if (btn.disabled) return
      const loadingText =
        btn.getAttribute("phx-disable-with") || btn.getAttribute("data-loading-label")
      if (loadingText) {
        if (!btn.hasAttribute("data-phx-disable-with-restore")) {
          btn.setAttribute("data-phx-disable-with-restore", btn.innerHTML)
        }
        btn.innerHTML = ""
        const wrapper = document.createElement("span")
        wrapper.className = "inline-flex items-center gap-2"
        const spinner = document.createElement("span")
        spinner.className =
          "inline-block size-4 motion-safe:animate-spin rounded-full border-2 border-current border-t-transparent"
        spinner.setAttribute("aria-hidden", "true")
        wrapper.appendChild(spinner)
        wrapper.appendChild(document.createTextNode(" " + loadingText))
        btn.appendChild(wrapper)
      } else {
        // Generic spinner fallback: prepend spinner if no custom label
        const spinner = document.createElement("span")
        spinner.className =
          "inline-block size-4 motion-safe:animate-spin rounded-full border-2 border-current border-t-transparent mr-2"
        spinner.setAttribute("aria-hidden", "true")
        btn.prepend(spinner)
      }
      btn.disabled = true
      btn.setAttribute("aria-busy", "true")
      btn.classList.add("opacity-60", "pointer-events-none")
    })
  },
  true,
)

// Password visibility toggle (works on dead views and LiveViews via delegation)
document.addEventListener("click", (e) => {
  const btn = e.target.closest("[data-password-toggle]")
  if (!btn) return
  const wrapper = btn.closest("[data-password-wrapper]")
  const input = wrapper?.querySelector("[data-password-input]") || wrapper?.querySelector("input")
  if (!input) return
  const showing = input.type === "text"
  input.type = showing ? "password" : "text"
  const showLabel = btn.getAttribute("data-show-label") || "Show password"
  const hideLabel = btn.getAttribute("data-hide-label") || "Hide password"
  const label = showing ? showLabel : hideLabel
  btn.setAttribute("aria-pressed", String(!showing))
  btn.setAttribute("aria-label", label)
  wrapper?.querySelectorAll(".password-show-icon").forEach((el) => el.classList.toggle("hidden", !showing))
  wrapper?.querySelectorAll(".password-hide-icon").forEach((el) => el.classList.toggle("hidden", showing))
  const sr = btn.querySelector(".sr-only")
  if (sr) sr.textContent = label
})

// Auto-dismiss flash toasts after 5s (pointer-events-none container stays, row hides)
function initFlashAutoDismiss() {
  document.querySelectorAll("[data-flash-auto-dismiss]").forEach((el) => {
    if (el.dataset.autoDismissInit) return
    el.dataset.autoDismissInit = "1"
    const delay = parseInt(el.dataset.flashAutoDismiss || "5000", 10)
    setTimeout(() => {
      if (el.id === "notification-toast") {
        // Trigger LiveView toast_dismiss (clears assign, does not mark read) via close button
        const closeBtn = el.querySelector('[phx-click*="toast_dismiss"]')
        if (closeBtn) closeBtn.click()
        else el.click()
        return
      }
      el.style.transition = "opacity 200ms, transform 200ms"
      el.style.opacity = "0"
      el.style.transform = "translateY(-4px)"
      setTimeout(() => {
        el.style.display = "none"
        // clear server flash so it does not reappear on next render
        const kind = el.id.replace("flash-", "")
        if (window.liveSocket) {
          el.dispatchEvent(new CustomEvent("phx:clear-flash", {bubbles: true, detail: {key: kind}}))
        }
      }, 220)
    }, delay)
  })
}
new MutationObserver(initFlashAutoDismiss).observe(document.body, {childList: true, subtree: true})
document.addEventListener("DOMContentLoaded", initFlashAutoDismiss)
window.addEventListener("phx:page-loading-stop", initFlashAutoDismiss)

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

