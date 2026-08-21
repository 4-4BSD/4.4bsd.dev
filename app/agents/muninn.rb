# frozen_string_literal: true

module Raven::Agents
  class Muninn < ActiveRecord::Base
    acts_as_agent(format: :jsonb) do |agent|
      agent.set name: "r.uby.dev",
                description: "a chatbot for the r.uby.dev website",
                instructions: proc { File.read(File.join(__dir__, "muninn", "prompt.md")) },
                tools: :tools,
                concurrency: :async
    end

    ##
    # @return [LLM::MCP]
    def github
      @github ||= LLM::MCP.http(
        url: "https://api.githubcopilot.com/mcp/",
        headers: {"Authorization" => "Bearer #{ENV['GITHUB_RUBYDEV_PAT']}"},
        transport: :net_http_persistent
      )
    end

    ##
    # @return [Array<LLM::Tool>]
    def tools
      github.tools.select { allowlist.include?(_1.name.to_s) }
    end

    private

    def set_provider
      LLM.deepseek
    end

    def allowlist
      %w[
         get_commit
         get_file_contents
         list_branches
         list_commits
         search_code
         search_commits
         search_repositories
         search_issues
         pull_request_read
         list_pull_requests
         list_issues
         issue_read
      ].freeze
    end
  end
end
