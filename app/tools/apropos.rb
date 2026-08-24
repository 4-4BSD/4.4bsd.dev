# frozen_string_literal: true

module Raven::Tools
  class Apropos < LLM::Tool
    require "llm/tools/utils"
    include Utils

    name "apropos"
    description "search the manual pages for keyword(s)"
    parameter :keywords, Array[String], "the keyword(s) to search for"
    parameter :timeout, Integer, "how long to wait"
    required %i[keywords]
    defaults timeout: 5

    def call(keywords:, timeout: 5)
      validate!(keywords:)
      command = spawn(keywords:)
      wait(command:, timeout:)
      {ok: command.success?, stdout: command.stdout, stderr: command.stderr}
    rescue LLM::Interrupt
      command.kill! if command&.running?
      raise
    end

    private

    def validate!(keywords:)
      # no-op for now
    end

    def spawn(keywords:)
      Command
        .new("apropos")
        .env("MANPATH" => "/usr/share/man")
        .argv(*keywords)
        .spawn
    end

    LLM.require "test-cmd.rb", "~> 2.1"
    Command = Test::Command
  end
end
