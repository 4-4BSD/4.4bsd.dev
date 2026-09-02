# frozen_string_literal: true

module Raven::Agents
  class Beastie < ActiveRecord::Base
    acts_as_paranoid
    acts_as_agent(format: :jsonb) do |agent|
      agent.set name: "beastie",
                description: "a chatbot for the 4.4bsd.dev website",
                instructions: proc { File.read(File.join(__dir__, "beastie", "prompt.md")) },
                tools: :tools,
                concurrency: :async
    end

    ##
    # @return [Array<LLM::Tool>]
    def tools
      [
        Raven::Tools::ReadSource,
        Raven::Tools::GrepSource,
        Raven::Tools::Man,
        Raven::Tools::Apropos,
        Raven::Tools::PkgSearch
      ]
    end

    private

    def set_provider
      LLM.deepseek
    end
  end
end
