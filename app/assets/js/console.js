import { marked } from "marked"
import hljs from "highlight.js/lib/common"
import { Icons } from "./icons.js"

// Turn bare man-page references like ls(1), jail(2) into
// anchor tags. Runs on the raw markdown before parsing.
marked.use({
  extensions: [{
    name: "manRef",
    level: "inline",
    start(src) { return src.match(/[a-zA-Z][\w.-]*\(\d\)/)?.index },
    tokenizer(src) {
      const m = /^([a-zA-Z][\w.-]*)\((\d)\)/.exec(src)
      if (!m) return false
      return {
        type: "manRef",
        raw: m[0],
        name: m[1],
        section: m[2]
      }
    },
    renderer({ name, section }) {
      const href = `/man/${name}?section=${section}`
      return `<a href="${href}">${name}(${section})</a>`
    }
  }]
})

function Console() {
  const self = Object.create(null)

  const form = document.getElementById("console-form")
  const input = document.querySelector(".console-input")
  const answer = document.getElementById("console-answer")
  const status = document.getElementById("console-status")
  const reset = document.querySelector(".console-reset")
  const expand = document.querySelector(".console-expand")
  const consoleEl = document.getElementById("home-console")
  const answerTemplate = document.getElementById("console-answer-template")

  const renderDefaultAnswer = () => {
    const clone = answerTemplate.content.cloneNode(true)
    answer.innerHTML = ""
    answer.replaceChildren(clone)
  }
  renderDefaultAnswer()

  const iconFor = (name) => {
    if (name === "man") return Icons.ManPage
    if (name === "apropos") return Icons.Apropos
    if (name === "grep-source") return Icons.GrepSource
    if (name === "read-source") return Icons.ReadSource
    return Icons.PkgSearch
  }

  const TOOL_LABELS = {
    man: "Reading man page...",
    apropos: "Searching man pages...",
    "pkg-search": "Searching packages...",
    "grep-source": "Searching FreeBSD source...",
    "read-source": "Reading FreeBSD source..."
  }

  const TOOL_DONE_LABELS = {
    man: "Read man page",
    apropos: "Searched man pages",
    "pkg-search": "Searched packages",
    "grep-source": "Searched FreeBSD source",
    "read-source": "Read FreeBSD source"
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

  let pendingMd = null
  let pointerOverLink = false

  const doRender = (highlight = true) => {
    if (pendingMd == null) return
    const md = pendingMd
    pendingMd = null
    answer.innerHTML = marked.parse(md)
    answer.querySelectorAll("a").forEach((el) => {
      el.target = "_blank"
      el.rel = "noopener"
    })
    if (highlight)
      answer.querySelectorAll("pre code").forEach((el) => hljs.highlightElement(el))
  }

  const scheduleRender = (markdown) => {
    pendingMd = markdown
    if (!pointerOverLink) doRender(false)
  }

  const flushRender = (markdown) => {
    if (markdown != null) pendingMd = markdown
    if (!pointerOverLink) doRender(true)
  }

  // While streaming, doRender replaces answer.innerHTML, which
  // destroys the <a> the user clicked before navigation completes.
  // Intercept clicks on links and navigate via window.open, which
  // fires synchronously and survives the DOM replacement.
  answer.addEventListener("click", (e) => {
    const link = e.target.closest?.("a")
    if (!link?.href) return
    e.preventDefault()
    window.open(link.href, "_blank", "noopener")
  })

  // Park renders while the pointer is over a link so it stays
  // put and is clickable. Resume immediately when the pointer leaves.
  answer.addEventListener("pointerover", (e) => {
    if (e.target.closest?.("a")) pointerOverLink = true
  })
  answer.addEventListener("pointerout", (e) => {
    if (e.target.closest?.("a") && !e.relatedTarget?.closest?.("a")) {
      pointerOverLink = false
      if (pendingMd) doRender(false)
    }
  })

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
    pendingMd = null
    pointerOverLink = false
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

  self.renderAnswer = scheduleRender
  self.flushRender = flushRender
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