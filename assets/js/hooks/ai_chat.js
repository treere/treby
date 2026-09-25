// Persists the assistant panel open state across page changes and refresh.
// The visible/hidden state is server-rendered (component `:open` assign) so
// LiveView re-renders (e.g. message streaming) cannot reset the panel closed;
// this hook only applies the persisted state on mount and reports toggles.
const STORAGE_KEY = "treby-ai-chat-open";

const AiChatToggle = {
  mounted() {
    this.panel = this.el.querySelector("[data-ai-chat-panel]");

    if (localStorage.getItem(STORAGE_KEY) === "1") {
      this.setOpen(true, true);
    }

    this.el.addEventListener("click", (event) => {
      if (event.target.closest("[data-ai-chat-toggle]")) {
        event.preventDefault();
        this.setOpen(!this.isOpen(), true);
      }
    });
  },

  isOpen() {
    return this.panel && !this.panel.classList.contains("hidden");
  },

  setOpen(open, sync) {
    if (!this.panel) return;
    this.panel.classList.toggle("hidden", !open);
    localStorage.setItem(STORAGE_KEY, open ? "1" : "0");
    if (sync) {
      this.pushEventTo(this.el, "set_open", { open });
    }
  },
};

// Moves/resizes the floating assistant panel and persists its geometry.
// Position and size are inline styles, re-applied in updated() because
// LiveView strips client-set attributes on patch. Kept off-screen by
// clamping to the viewport on every interaction and window resize.
const GEOMETRY_KEY = "treby-ai-chat-geometry";
const MIN_WIDTH = 320;
const MIN_HEIGHT = 256;
const EDGE = 8;

const AiChatGeometry = {
  mounted() {
    this.panel = this.el;
    this.restore();
    this.bindDrag();
    this.bindResize();
    this.onResize = () => this.reclamp();
    window.addEventListener("resize", this.onResize);
  },

  updated() {
    // LiveView patches the panel and clears client-set inline styles, so
    // re-apply the known geometry after every server update.
    if (this.geometry) this.apply(this.geometry, false);
  },

  destroyed() {
    window.removeEventListener("resize", this.onResize);
  },

  restore() {
    let stored = null;
    try {
      stored = JSON.parse(localStorage.getItem(GEOMETRY_KEY));
    } catch (_) {
      stored = null;
    }
    if (stored && typeof stored.w === "number" && typeof stored.h === "number") {
      this.apply(stored, false);
    }
  },

  reclamp() {
    if (this.geometry) this.apply(this.geometry, true);
  },

  clamp(g) {
    const vw = window.innerWidth;
    const vh = window.innerHeight;
    const w = Math.min(Math.max(g.w, MIN_WIDTH), Math.max(MIN_WIDTH, vw - EDGE * 2));
    const h = Math.min(Math.max(g.h, MIN_HEIGHT), Math.max(MIN_HEIGHT, vh - EDGE * 2));
    const x = Math.min(Math.max(g.x, EDGE), Math.max(EDGE, vw - w - EDGE));
    const y = Math.min(Math.max(g.y, EDGE), Math.max(EDGE, vh - h - EDGE));
    return { x, y, w, h };
  },

  apply(g, save) {
    const c = this.clamp(g);
    Object.assign(this.panel.style, {
      left: `${c.x}px`,
      top: `${c.y}px`,
      width: `${c.w}px`,
      height: `${c.h}px`,
      right: "auto",
      bottom: "auto",
    });
    this.geometry = c;
    if (save) localStorage.setItem(GEOMETRY_KEY, JSON.stringify(c));
  },

  bindDrag() {
    const handle = this.panel.querySelector("[data-ai-chat-drag]");
    if (!handle) return;

    handle.addEventListener("pointerdown", (event) => {
      if (event.target.closest("button, a, input, select, textarea")) return;
      event.preventDefault();
      const start = this.panel.getBoundingClientRect();
      const startX = event.clientX;
      const startY = event.clientY;
      handle.setPointerCapture(event.pointerId);

      const move = (e) =>
        this.apply(
          { x: start.left + e.clientX - startX, y: start.top + e.clientY - startY, w: start.width, h: start.height },
          false
        );
      const up = () => {
        handle.removeEventListener("pointermove", move);
        handle.removeEventListener("pointerup", up);
        if (this.geometry) localStorage.setItem(GEOMETRY_KEY, JSON.stringify(this.geometry));
      };

      handle.addEventListener("pointermove", move);
      handle.addEventListener("pointerup", up);
    });
  },

  bindResize() {
    const grip = this.panel.querySelector("[data-ai-chat-resize]");
    if (!grip) return;

    grip.addEventListener("pointerdown", (event) => {
      event.preventDefault();
      const start = this.panel.getBoundingClientRect();
      const startX = event.clientX;
      const startY = event.clientY;
      grip.setPointerCapture(event.pointerId);

      const move = (e) =>
        this.apply(
          { x: start.left, y: start.top, w: start.width + e.clientX - startX, h: start.height + e.clientY - startY },
          false
        );
      const up = () => {
        grip.removeEventListener("pointermove", move);
        grip.removeEventListener("pointerup", up);
        if (this.geometry) localStorage.setItem(GEOMETRY_KEY, JSON.stringify(this.geometry));
      };

      grip.addEventListener("pointermove", move);
      grip.addEventListener("pointerup", up);
    });
  },
};

const AiAutoScroll = {
  mounted() {
    this.scrollToBottom(true);
    this.observer = new MutationObserver(() => this.scrollToBottom(false));
    this.observer.observe(this.el, { childList: true, subtree: true });
  },

  destroyed() {
    this.observer?.disconnect();
  },

  scrollToBottom(force) {
    const nearBottom =
      this.el.scrollHeight - this.el.scrollTop - this.el.clientHeight < 80;
    if (force || nearBottom) {
      this.el.scrollTop = this.el.scrollHeight;
    }
  },
};

export { AiAutoScroll, AiChatGeometry };
export default AiChatToggle;
