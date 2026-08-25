# frozen_string_literal: true

class Raven::Routes::API
  class Agent < self
    route do |r|
      r.get(true) do
        r.sse do |sse|
          q = r.params["q"].to_s
          stream = Raven::Agents::Puffy::Stream.new(sse).tap(&:hello)
          agent = Raven::Agents::Puffy.find(agent_id)
          res = agent.talk(q, stream:)
          stream.done(res:)
        rescue ActiveRecord::RecordNotFound
          stream.error(message: "agent unavailable")
        rescue => e
          warn "sse error: #{e.class}: #{e.message}"
          stream.error(message: "internal server error (#{e.class})")
        end
      end

      r.delete(true) do
        check_csrf!
        Raven::Agents::Puffy.find_by(id: agent_id)&.destroy
        session.delete("agent_id")
        {ok: true}
      end
    end

    ##
    # @return [String, nil]
    def agent_id
      session["agent_id"]
    end
  end
end
