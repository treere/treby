// Reflects assistant-proposed form values into the actual <input> elements.
//
// The server reassigns @form, but LiveView's input recovery keeps the
// client-side input values as source of truth for phx-change forms, so a
// server push alone never reaches the visible field. This hook listens for
// the "ai_form_applied" event and writes the values directly, then dispatches
// input/change so phx-change validation runs.
const AiFormApply = {
  mounted() {
    this.handleEvent("ai_form_applied", ({ values }) => {
      if (!values) return;

      for (const [field, value] of Object.entries(values)) {
        const input = this.el.querySelector(
          `[name$="[${field}]"], [name="${field}"]`
        );
        if (!input) continue;

        if (input.type === "checkbox" || input.type === "radio") {
          input.checked = !!value;
        } else {
          input.value = value;
        }

        input.dispatchEvent(new Event("input", { bubbles: true }));
        input.dispatchEvent(new Event("change", { bubbles: true }));
      }
    });
  },
};

export default AiFormApply;
