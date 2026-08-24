n# frozen_string_literal: true

module Raven::Tools
  class PkgSearch < LLM::Tool
    require "llm/tools/utils"
    include Utils

    name "pkg-search"
    description "search remote package repositories for a package"
    parameter :pattern, String, "the package name or pattern to search for"
    parameter :full, Boolean, "show full package metadata (pkg search -f)"
    parameter :timeout, Integer, "how long to wait"
    required %i[pattern]
    defaults full: false, timeout: 10

    def call(pattern:, full: false, timeout: 10)
      validate!(pattern:)
      command = spawn(pattern:, full:)
      wait(command:, timeout:)
      {ok: command.success?, stdout: command.stdout, stderr: command.stderr}
    rescue LLM::Interrupt
      command.kill! if command&.running?
      raise
    end

    private

    def validate!(pattern:)
      # no-op for now
    end

    def spawn(pattern:, full:)
      argv = ["search", "-U"]
      argv << "-f" if full
      argv << pattern
      Command
        .new("pkg")
        .argv(*argv)
        .spawn
    end

    LLM.require "test-cmd.rb", "~> 2.1"
    Command = Test::Command
  end
end
