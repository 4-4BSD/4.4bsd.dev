# frozen_string_literal: true

module Raven::Routes
  class API < Roda
    plugin :sessions, secret: ENV["SESSION_SECRET"] || "change me" * 24
    plugin :route_csrf, require_request_specific_tokens: false, check_header: true
    plugin :json
    plugin :sse
    plugin :all_verbs

    route do |r|
      r.on("agents") { r.run Agents }
      r.on("agent")  { r.run Agent }
    end
  end
end