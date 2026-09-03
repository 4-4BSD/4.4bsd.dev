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
      stream = (klass::Stream rescue Raven::Stream).new(sse).tap(&:hello)
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
      Routes.registry[name] or raise "no agent registered under #{name.inspect}"
    end

    def agent_class!(name)
      entry_for(name)[:class]
    end

    def scope!(name)
      entry_for(name)[:scope]
    end
  end
end