import { Icons } from "/assets/js/icons.js"

function Console() {
  const self = Object.create(null)

  const form = document.getElementById("console-form")
  const input = document.querySelector(".console-input")
  const answer = document.getElementById("console-answer")
  const status = document.getElementById("console-status")
  const reset = document.querySelector(".console-reset")
  const expand = document.querySelector(".console-expand")
  const consoleEl = document.getElementById("home-console")
  const output = document.getElementById("console-output")
  const answerTemplate = document.getElementById("console-answer-template")

  const renderDefaultAnswer = () => {
    const clone = answerTemplate.content.cloneNode(true)
    answer.innerHTML = ""
    answer.replaceChildren(clone)
    output.classList.add("is-centered")
  }
  renderDefaultAnswer()

  const iconFor = (name) => {
    if (name === "man") return Icons.ManPage
    if (name === "apropos") return Icons.Apropos
    return Icons.PkgSearch
  }

  const TOOL_LABELS = {
    man: "Reading man page...",
    apropos: "Searching man pages...",
    "pkg-search": "Searching packages..."
  }

  const TOOL_DONE_LABELS = {
    man: "Read man page",
    apropos: "Searched man pages",
    "pkg-search": "Searched packages"
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
      status.appendChild(makeItem("is-thinking", "<span>Thinking...</span>"))
    } else if (during && hasActive) {
      const heading = document.createElement("p")
      heading.className = "console-status-title"
      heading.textContent = "Working on it"
      status.appendChild(heading)
      for (const name of activeTools.values()) {
        const label = TOOL_LABELS[name] || "Working..."
        status.appendChild(makeItem("", iconFor(name) + "<span>" + label + "</span>"))
      }
    }

    if (hasHistory) {
      const heading = document.createElement("p")
      heading.className = "console-status-title"
      heading.textContent = "Completed"
      status.appendChild(heading)
      for (const [name, count] of completedTools) {
        const itemLabel = (TOOL_DONE_LABELS[name] || "Worked") + " x" + count
        status.appendChild(makeItem("is-done", iconFor(name) + "<span>" + itemLabel + "</span>"))
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
    output.classList.remove("is-centered")
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
    answer.classList.remove("is-error")
    renderDefaultAnswer()
    clearStatus()
    input.focus()
  }

  return self
}

export { Console }
