import { Api } from "/assets/js/api.js"

const EVENT_HANDLERS = {
  tool_call:   "onToolCall",
  tool_return: "onToolReturn",
  content:     "onContent",
  done:        "onDone",
  failed:      "onFailed"
}

function Agent() {
  const self = Object.create(null)
  const api = Api()

  self.create = async () => {
    const res = await api.request("POST", "/api/agents")
    return res.json()
  }

  self.destroy = async () => {
    const res = await api.request("DELETE", "/api/agent")
    return res.json()
  }

  return self
}

Agent.Stream = function Stream(handlers = {}) {
  const self = Object.create(null)

  self.open = (q) => {
    self.es = new EventSource("/api/agent?q=" + encodeURIComponent(q))
    for (const [event, handler] of Object.entries(EVENT_HANDLERS)) {
      if (handlers[handler]) {
        self.es.addEventListener(event, (e) => handlers[handler](JSON.parse(e.data)))
      }
    }
    self.es.onerror = () => self.close()
    return self
  }

  self.close = () => {
    self.es?.close()
    self.es = null
  }

  return self
}

export { Agent }
