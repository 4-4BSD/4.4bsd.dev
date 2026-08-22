function Console() {
  const self = Object.create(null)

  const form = document.getElementById("console-form")
  const input = document.querySelector(".console-input")
  const answer = document.getElementById("console-answer")
  const status = document.getElementById("console-status")
  const reset = document.querySelector(".console-reset")
  const expand = document.querySelector(".console-expand")
  const consoleEl = document.getElementById("home-console")

  const GITHUB_ICON = '<svg class="console-status-icon" viewBox="0 0 16 16" width="14" height="14" fill="currentColor" aria-hidden="true"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27s1.36.09 2 .27c1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0 0 16 8c0-4.42-3.58-8-8-8z"/></svg>'

  const TOOL_LABELS = {
    man: "Reading man page…",
    apropos: "Searching man pages…"
  }

  const TOOL_DONE_LABELS = {
    man: "Read man page",
    apropos: "Searched man pages"
  }

  const activeTools = new Map()
  const completedTools = new Map()
  let turnDone = false
  let hasStreamed = false

  const makeItem = (className, html) => {
    const item = document.createElement("div")
    item.className = "console-status-item" + (className ? " " + className : "")
    item.innerHTML = html
    return item
  }

  const renderStatus = () => {
    status.innerHTML = ""
    const during = !turnDone
    const hasActive = activeTools.size > 0
    const hasHistory = completedTools.size > 0
    const showThinking = during && !hasActive && !hasStreamed
    const showPanel = showThinking || (during && hasActive) || hasHistory

    if (!showPanel) {
      status.classList.remove("is-active")
      return
    }

    if (showThinking) {
      status.appendChild(makeItem("is-thinking", "<span>Thinking…</span>"))
    } else if (during && hasActive) {
      const heading = document.createElement("p")
      heading.className = "console-status-title"
      heading.textContent = "Working on it"
      status.appendChild(heading)
      for (const name of activeTools.values()) {
        const label = TOOL_LABELS[name] || "Working…"
        status.appendChild(makeItem("", GITHUB_ICON + "<span>" + label + "</span>"))
      }
    }

    if (hasHistory) {
      const heading = document.createElement("p")
      heading.className = "console-status-title"
      heading.textContent = "Completed"
      status.appendChild(heading)
      for (const [name, count] of completedTools) {
        const itemLabel = (TOOL_DONE_LABELS[name] || "Worked") + " ×" + count
        status.appendChild(makeItem("is-done", GITHUB_ICON + "<span>" + itemLabel + "</span>"))
      }
    }

    status.classList.add("is-active")
  }

  const clearStatus = () => {
    activeTools.clear()
    completedTools.clear()
    turnDone = false
    hasStreamed = false
    status.innerHTML = ""
    status.classList.remove("is-active")
  }

  const renderAnswer = (markdown) => {
    answer.textContent = markdown
    answer.innerHTML = marked.parse(markdown)
    answer.querySelectorAll("a").forEach((el) => el.target = "_blank")
    answer.querySelectorAll("a").forEach((el) => el.rel = "noopener")
    answer.querySelectorAll("pre code").forEach((el) => hljs.highlightElement(el))
  }

  const showError = (message) => {
    clearStatus()
    answer.classList.add("is-error")
    answer.textContent = message
  }

  self.form = form
  self.input = input
  self.answer = answer
  self.status = status
  self.reset = reset
  self.expand = expand
  self.consoleEl = consoleEl

  self.beginTurn = () => {
    answer.innerHTML = ""
    answer.classList.remove("is-error")
    clearStatus()
    renderStatus()
  }

  self.toolCall = (id, name) => {
    activeTools.set(id, name)
    renderStatus()
  }

  self.toolReturn = (id, name) => {
    if (activeTools.has(id)) {
      activeTools.delete(id)
      completedTools.set(name, (completedTools.get(name) || 0) + 1)
    }
    renderStatus()
  }

  self.streamStarted = () => {
    hasStreamed = true
    renderStatus()
  }

  self.finishTurn = () => {
    turnDone = true
    renderStatus()
  }

  self.renderAnswer = renderAnswer
  self.showError = showError

  self.resetUI = () => {
    answer.innerHTML = ""
    answer.classList.remove("is-error")
    clearStatus()
  }

  return self
}

export { Console }
