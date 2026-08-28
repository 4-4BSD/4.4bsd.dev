# frozen_string_literal: true

class Raven::Routes::API
  class Agents < self
    route do |r|
      r.post(true) do
        check_csrf!
        create_agent!(session["agent_id"])
      end
    end

    private

    ##
    # Create an agent, yo.
    # @return [Hash]
    def create_agent!(id)
      if agent = Raven::Agents::Puffy.find_by(id:)
        {ok: true, id: agent.id}
      else
        agent = Raven::Agents::Puffy.create!
        session["agent_id"] = agent.id
        {ok: true, id: agent.id}
      end
    end
  end
end