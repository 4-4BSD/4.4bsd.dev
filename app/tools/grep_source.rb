# frozen_string_literal: true

module Raven::Tools
  class GrepSource < LLM::Tool
    name "grep-source"
    description "Search the FreeBSD codebase for a pattern"
    parameter :pattern, String, "a search pattern"
    required %i[pattern]

    def call(pattern:)
      Fdr.grep(paths: %w[/usr/src], pattern:).to_a
    end
  end
end
