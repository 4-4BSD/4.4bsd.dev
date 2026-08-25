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
  # Establish database connection
  raw    = ERB.new(File.read(File.join(__dir__, "database.yml"))).result
  config = YAML.safe_load(raw, aliases: true)
  conn   = config.fetch(Raven.env)
  ActiveRecord::Base.establish_connection(conn)

  ##
  # Boot the rest of the application
  require File.join(appdir, "routes", "application")
  Dir[File.join(appdir, "**", "*.rb")].sort.each { require(_1) }
end


