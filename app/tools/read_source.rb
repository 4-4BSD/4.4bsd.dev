# frozen_string_literal: true

module Raven::Tools
  class ReadSource < LLM::Tool
    name "read-source"
    description "Read a FreeBSD source file"
    parameter :path, String, "Absolute path to a file (eg /usr/src/README.md)"
    parameter :start, Integer, "Line number to start reading at"
    parameter :stop, Integer, "Line number to stop reading at"
    required %i[path]
    defaults start: nil, stop: nil

    def call(path:, start: nil, stop: nil)
      path = File.expand_path(path)
      start = Integer(start) if start
      stop = Integer(stop) if stop
      validate!(path:, start:, stop:)
      lines = []
      File.foreach(path).with_index(1) do |line, index|
        if start.nil? or (index >= start and index <= stop)
          lines << line
        end
      end
      lines
    end

    private

    def validate!(path:, start:, stop:)
      unless path.start_with?("/usr/src/")
        raise LLM::Error, "your path must start with /usr/src/"
      end
      if (start and stop.nil?) or (stop and start.nil?)
        raise LLM::Error, "you must provide both start and stop, or neither"
      end
      if start and stop and start > stop
        raise LLM::Error, "start must be less than or equal to stop"
      end
      if start and start < 1
        raise LLM::Error, "start must be a positive integer"
      end
    end
  end
end
