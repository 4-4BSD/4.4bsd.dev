# frozen_string_literal: true

module Raven
  require "bundler/setup"
  require "active_record"
  require "roda"
  require "roda/plugins/sse"
  require "llm"
  require "llm/active_record"
  require "json"
  require "erb"
  require "yaml"
  require "base64"
  require "test/cmd"
  require "fdr"
  require "paranoia"

  Routes = Module.new
  Agents = Module.new

  ##
  # @return [String]
  def self.env
    ENV["RACK_ENV"] || "development"
  end

  ##
  # @return [String]
  def self.root
    File.realpath File.join(__dir__, "..")
  end

  ##
  # @return [String]
  def self.appdir
    File.join root, "app"
  end

  ##
  # @return [String]
  def self.version
    @version ||= File.read(File.join(root, ".version")).strip
  end

  ##
  # Establish database connection
  raw    = ERB.new(File.read(File.join(__dir__, "database.yml"))).result
  config = YAML.safe_load(raw, aliases: true)
  conn   = config.fetch(Raven.env)
  ActiveRecord::Base.establish_connection(conn)

  ##
  # Boot the rest of the application: load the agent plugin first
  # (it registers `:agent` and defines the LLM::Roda stream alias),
  # then load every app file sorted by path. That ordering puts
  # app/agents/... before app/routes/... so `Beastie` exists before
  # application.rb calls `plugin :agent, agents: [Beastie, ...]`.
  require "roda-llm"
  Dir[File.join(appdir, "scopes", "**", "*.rb")].sort.each { require(_1) }
  Dir[File.join(appdir, "**", "*.rb")].sort.each { require(_1) }
end


