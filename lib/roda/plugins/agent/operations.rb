# frozen_string_literal: true

class Roda::RodaPlugins::Agent
  module Operations
    def create!(name)
      klass = agent_class!(name)
      scope = scope!(name)
      if agent = scope.find(klass)
        {ok: true, id: agent.id}
      else
        agent = scope.create(klass)
        {ok: true, id: agent.id}
      end
    end

    def update!(query, name)
      klass = agent_class!(name)
      scope = scope!(name)
      stream = stream!(name).new(sse).tap(&:hello)
      agent = scope.find!(klass)
      res = agent.talk(query, stream:)
      stream&.done(res:)
    rescue ActiveRecord::RecordNotFound
      stream&.error(message: "agent unavailable")
    rescue => e
      stream&.error(message: "internal server error")
    end

    def destroy!(name)
      klass = agent_class!(name)
      scope = scope!(name)
      scope.destroy(klass)
      {ok: true}
    end

    private

    def agent!(name)
      LLM::Object.from(Agent.registry[name])
    end

    def agent_class!(name)
      agent!(name).class
    end

    def scope!(name)
      agent!(name).scope
    end

    def stream!(name)
      agent!(name).stream || Roda::RodaPlugins::Agent::Stream
    end
  end
end