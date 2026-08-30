import { defineConfig } from "vitepress"

export default defineConfig({
  base: "/treby/",
  title: "Treby",
  description: "Open-source Applicant Tracking System built with Phoenix LiveView",

  head: [
    ["link", { rel: "icon", type: "image/svg+xml", href: "/treby/favicon.svg" }],
  ],

  ignoreDeadLinks: [
    /^http:\/\/localhost/,
  ],

  themeConfig: {
    logo: "/treby/logo.svg",

    nav: [
      { text: "Home", link: "/" },
      { text: "Features", link: "/features/" },
      { text: "Getting Started", link: "/getting-started" },
      { text: "Architecture", link: "/architecture" },
      { text: "Roadmap", link: "/roadmap" },
      {
        text: "GitHub",
        link: "https://github.com/treere/treby",
      },
    ],

    sidebar: [
      {
        text: "Introduction",
        items: [
          { text: "What is Treby?", link: "/" },
          { text: "Getting Started", link: "/getting-started" },
          { text: "Architecture", link: "/architecture" },
          { text: "Roadmap", link: "/roadmap" },
        ],
      },
      {
        text: "Features",
        items: [
          { text: "Overview", link: "/features/" },
          { text: "Dashboard", link: "/features/dashboard" },
          { text: "Kanban Pipeline", link: "/features/pipeline" },
          { text: "Public Career Pages", link: "/features/career-pages" },
          { text: "Candidate Management", link: "/features/candidate-management" },
          { text: "Candidate Portal", link: "/features/candidate-portal" },
          { text: "Interview Scheduling", link: "/features/interview-scheduling" },
          { text: "Scorecards", link: "/features/scorecards" },
          { text: "Analytics", link: "/features/analytics" },
          { text: "Job Analytics", link: "/features/job-analytics" },
          { text: "Email Notifications", link: "/features/email-notifications" },
          { text: "Message Scheduler", link: "/features/message-scheduler" },
          { text: "CSV Import", link: "/features/csv-import" },
          { text: "Bulk Operations", link: "/features/bulk-operations" },
          { text: "Candidate Comparison", link: "/features/comparison" },
          { text: "Source Tracking", link: "/features/source-tracking" },
          { text: "Custom Fields", link: "/features/custom-fields" },
          { text: "Dark Mode", link: "/features/dark-mode" },
          { text: "Workspace Switching", link: "/features/workspace-switching" },
        ],
      },
    ],

    search: {
      provider: "local",
    },

    socialLinks: [
      { icon: "github", link: "https://github.com/treere/treby" },
    ],

    footer: {
      message: "Built with Phoenix LiveView",
      copyright: "MIT License",
    },
  },
})
