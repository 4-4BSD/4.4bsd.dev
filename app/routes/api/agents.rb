# frozen_string_literal: true

class Raven::Routes::API
  class Agents < self
    route do |r|
      r.post(true) do
        check_csrf!
        if agent = Raven::Agents::Puffy.find_by(id: agent_id)
          {ok: true, id: agent.id}
        else
          agent = Raven::Agents::Puffy.create!
          session["agent_id"] = agent.id
          {ok: true, id: agent.id}
        end
      end
    end

    private

    ##
    # @return [String]
    def agent_id
      session["agent_id"]
    end
  end
end