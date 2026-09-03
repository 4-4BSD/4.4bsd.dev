# frozen_string_literal: true

module Roda::RodaPlugins::Agent
  module Operations
    def create!(name)
      klass = agent_class!(name)
      ##
      # The 'scope' local is resolved to self.
      # It refers to an instance of Roda.
      scope = scope!(name).new(scope)
      agent = scope.find(klass) || scope.create(klass)
      {ok: true, id: agent.id}
    end

    def update!(name, params, sse)
      klass = agent_class!(name)
      ##
      # The 'scope' local is resolved to self.
      # It refers to an instance of Roda.
      scope = scope!(name).new(scope)
      stream = stream!(name).new(sse).tap(&:hello)
      agent = scope.find!(klass)
      res = agent.talk(params["q"], stream:)
      stream&.goodbye(res:)
    rescue ActiveRecord::RecordNotFound
      stream&.error(message: "agent unavailable")
    rescue
      stream&.error(message: "internal server error")
    end

    def destroy!(name)
      klass = agent_class!(name)
      ##
      # The 'scope' local is resolved to self.
      # It refers to an instance of Roda.
      scope = scope!(name).new(scope)
      scope.destroy(klass)
      {ok: true}
    end

    private

    def agent!(name)
      LLM::Object.from(LLM::Roda.registry[name])
    end

    def agent_class!(name)
      agent!(name).class
    end

    def scope!(name)
      agent!(name).scope
    end

    def stream!(name)
      agent!(name).stream || LLM::Roda::Stream
    end
  end
end
