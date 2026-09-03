# frozen_string_literal: true

class Raven::Agents::Beastie
  class Stream < LLM::Roda::Stream
    def hello
      @io.write(": connected\n\n")
    end

    def goodbye(res:)
      emit("done", answer: res.content)
    end
  end
end
