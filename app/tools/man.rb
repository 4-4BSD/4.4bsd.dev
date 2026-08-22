# frozen_string_literal: true

module Raven::Tools
  class Man < LLM::Tool
    require "llm/tools/utils"

    name "man"
    description "read a man page"
    parameter :name, String, "the name of the man page"
    parameter :section, Number, "optional section"
    parameter :timeout, Integer, "how long to wait"
    required %i[name]
    defaults section: nil, timeout: 5

    def call(name:, section: nil, timeout: 5)
      validate!(name:, section:)
      command = spawn(name:, section:)
      wait(command:, timeout:)
      {ok: command.success?, stdout: command.stdout, stderr: command.stderr}
    rescue LLM::Interrupt
      command.kill! if command&.running?
      raise
    end

    private

    def validate!(name:, section:)
      # no-op for now
    end

    def spawn(name:, section:)
      Command
        .new("man")
        .argv(section ? section : "")
        .argv(name)
        .spawn
    end

    LLM.require "test-cmd.rb", "~> 1.1"
    Command = Test::Cmd
  end
end
