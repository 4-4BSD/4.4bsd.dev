# frozen_string_literal: true

module Raven::Scopes
  ##
  # The {Raven::Scopes::Session Session} scope stores one
  # agent per visitor session, and records the visitor's
  # client IP on each generated agent.
  class Session < LLM::Roda::Scope::Session
    ##
    # Create an agent and bind it to this visitor's
    # session, tagging it with the client IP.
    #
    # @param [Class(LLM::Agent)] klass
    # @return [LLM::Agent]
    def create(klass)
      klass.create!(owner: request.ip).tap { session[key!(klass)] = _1.id }
    end
  end
end