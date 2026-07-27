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
import topbar from "../vendor/topbar"
import Sortable from "../vendor/sortable.min.js"

// Make Sortable available globally for LiveView hooks
window.Sortable = Sortable

// SortableJS Hook for LiveView
const SortableHook = {
  mounted() {
    this.stageId = this.el.dataset.stageId
    this.sortable = Sortable.create(this.el, {
      group: "pipeline",
      animation: 150,
      ghostClass: "opacity-50",
      dragClass: "shadow-lg",
      onEnd: (evt) => {
        const applicationId = evt.item.dataset.applicationId
        const newStageId = evt.to.dataset.stageId
        this.pushEvent("move_candidate", {
          application_id: applicationId,
          stage_id: newStageId
        })
      }
    })
  },
  destroyed() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }
}

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

