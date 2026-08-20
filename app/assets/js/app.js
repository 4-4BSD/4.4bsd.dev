import { Agent } from "/assets/js/agent.js"
import { Console } from "/assets/js/console.js"

function App() {
  const self = Object.create(null)
  const console = Console()
  const agent = Agent()

  self.boot = () => {
    console.form.addEventListener("submit", async (event) => {
      event.preventDefault()
      const q = console.input.value.trim()
      if (!q) return

      console.input.value = ""
      console.beginTurn()

      let buffer = ""

      try {
        await agent.create()

        let stream
        stream = Agent.Stream({
          onToolCall(data) {
            console.toolCall(data.id, data.name)
          },

          onToolReturn(data) {
            console.toolReturn(data.id, data.name)
          },

          onContent(data) {
            console.streamStarted()
            buffer += data.text
            console.renderAnswer(buffer)
          },

          onDone(data) {
            stream.close()
            console.finishTurn()
            if (buffer.trim() === "" && data.answer) {
              console.renderAnswer(data.answer)
            }
          },

          onFailed(data) {
            stream.close()
            console.showError(data.error || "Something went wrong. Please try again.")
          }
        }).open(q)
      } catch (err) {
        console.showError("Something went wrong. Please try again.")
      }
    })

    console.reset.addEventListener("click", async () => {
      try {
        await agent.destroy()
      } catch {
        /* ignore */
      }
      console.resetUI()
      await agent.create()
    })

    console.expand.addEventListener("click", () => {
      const expanded = console.consoleEl.classList.toggle("is-expanded")
      console.expand.setAttribute("aria-expanded", expanded ? "true" : "false")
      console.expand.title = expanded ? "Collapse chat" : "Expand chat"
    })

    if (window.matchMedia("(hover: hover)").matches) {
      console.input.focus()
    }
  }

  return self
}

App().boot()
