# frozen_string_literal: true

class Roda::RodaPlugins::Agent
  class Router < Roda
    plugin :json
    plugin :sse
    plugin :all_verbs
    plugin :sessions, secret: ENV["SESSION_SECRET"] || "change me" * 24
    plugin :route_csrf, require_request_specific_tokens: false, check_header: true

    route do |r|
      r.on String do |name|
        r.post(true) { [check_csrf!, Agent.create!(name)].last }
        r.sse { |sse| Agent.update!(name, r.params, sse) }
        r.delete(true) { [check_csrf!, Agent.destroy!(name)].last }
      end
    end
  end
end
