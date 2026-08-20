# frozen_string_literal: true

module Raven::Routes
  class API < Application
    route do |r|
      r.on("agents") { r.run Agents }
      r.on("agent")  { r.run Agent }
    end
  end
end