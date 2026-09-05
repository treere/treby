import Sortable from "sortablejs"

export default {
  mounted() {
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
