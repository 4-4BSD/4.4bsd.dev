# frozen_string_literal: true

class Raven::Agents::Beastie
  class Stream < LLM::Stream
    def initialize(io)
      @io = io
    end

    def on_content(content)
      emit("content", text: content)
    end

    def on_tool_call(tool)
      emit("tool_call", id: tool.id, name: tool.name, arguments: tool.arguments&.to_h)
    end

    def on_tool_return(tool, result)
      emit("tool_return", id: tool.id, name: tool.name, ok: !result.error?)
    end

    def hello
      @io.write(": connected\n\n")
    end

    def done(res:)
      emit("done", answer: res.content)
    end

    def error(message:)
      emit("failed", error: message)
    end

    private

    def emit(type, payload)
      @io.write("event: #{type}\ndata: #{JSON.generate(payload)}\n\n")
    end
  end
end
