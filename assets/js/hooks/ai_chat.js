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

export { AiAutoScroll };
export default AiChatToggle;
