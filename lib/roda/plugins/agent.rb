# frozen_string_literal: true

class Roda::RodaPlugins
  module Agent
    require_relative "agent/operations"

    extend self
    extend Operations
    DEFAULTS = {path: "agents", scope: :session}.freeze
    SCOPES   = {session: SessionScope, global: GlobalScope}

    ##
    # @param [Roda] app
    # @param [Hash] _options
    # @return [void]
    def load_dependencies(app, _options)
      app.plugin :json
      app.plugin :sse
      app.plugin :all_verbs
      app.plugin :sessions, secret: ENV["SESSION_SECRET"] || "change me" * 24
      app.plugin :route_csrf, require_request_specific_tokens: false, check_header: true
    end

    ##
    # @param [Roda] app
    # @param [Hash] options
    # @return [void]
    def configure(app, options)
      options = DEFAULTS.merge(options)
      global_store = {}
      options[:agents].each do |agent|
        scope = SCOPES[agent[:scope]]
        key = agent[:class].name
        registry[key] = agent.slice(:class, :stream).merge!(scope:)
      end
      app.opts[:agent] = option.slice(:path).merge!(app: Routes)
    end

    ##
    # @return [String => Class(LLM::Agent)]
    def registry
      @registry ||= {}
    end

    module InstanceMethods
      def mount_agents!(r)
        options = self.class.opts[:agent]
        r.on(options[:path]) { r.run options[:app] }
      end
    end
  end
  register_plugin(:agent, Agent)
end