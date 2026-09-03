# frozen_string_literal: true

class Roda::RodaPlugins
  module Agent
    require_relative "agent/router"
    require_relative "agent/scope"
    require_relative "agent/scope/session"
    require_relative "agent/stream"
    require_relative "agent/operations"

    extend self
    extend Operations
    DEFAULTS = {path: "agents", scope: :session}.freeze
    SCOPES   = {session: Scope::Session}.freeze

    ##
    # @param [Roda] _app
    # @param [Hash] _options
    # @return [void]
    def load_dependencies(_app, _options)
      nil
    end

    ##
    # @param [Roda] app
    # @param [Hash] options
    # @return [void]
    def configure(app, options)
      options = DEFAULTS.merge(options)
      options[:agents].each do |agent|
        scope = SCOPES[agent[:scope]].new(app)
        key = agent[:class].name
        registry[key] = agent.slice(:class, :stream).merge!(scope:)
      end
      app.opts[:agent] = options.slice(:path).merge!(app: Router)
    end

    ##
    # @return [String => Class(LLM::Agent)]
    def registry
      @registry ||= {}
    end

    module RequestMethods
      ##
      # Mounts the agent fleet under the configured path,
      # e.g. `r.agent!` in the app's route block.
      #
      # @return [void]
      def agent!
        options = scope.class.opts[:agent]
        on(options[:path]) { run options[:app] }
      end
    end
  end
  register_plugin(:agent, Agent)
end

module LLM
  Roda = Roda::RodaPlugins::Agent
end