# frozen_string_literal: true

require "bundler/setup"
require_relative "config/boot"

namespace :db do
  desc "Create the database if it does not exist"
  task :create do
    require "active_record/tasks/database_tasks"
    ActiveRecord::Tasks::DatabaseTasks.create(ActiveRecord::Base.connection_db_config)
  end

  desc "Run pending migrations (creating the database first if needed)"
  task migrate: :create do
    before = schema_versions
    migration_context.migrate
    after = schema_versions
    applied = after - before
    if applied.empty?
      puts "No pending migrations (schema is up to date)."
    else
      puts "Applied #{applied.size} migration(s):"
      applied.each { |v| puts "  #{v}" }
    end
  end

  desc "Rollback the most recent migration"
  task :rollback do
    migration_context.rollback
  end

  desc "Show migration status"
  task :status do
    migration_context.migrations_status.each do |status, version, name|
      puts "#{status.ljust(12)} #{version}  #{name}"
    end
  end

  def migration_context
    pool = ActiveRecord::Base.connection_pool
    ActiveRecord::MigrationContext.new(
      File.join(__dir__, "db", "migrate"),
      ActiveRecord::SchemaMigration.new(pool),
      ActiveRecord::InternalMetadata.new(pool)
    )
  end

  def schema_versions
    ActiveRecord::SchemaMigration
      .new(ActiveRecord::Base.connection_pool)
      .versions
      .to_set
  end
end

namespace :docs do
  desc "Generate API docs for llm.rb"
  task :"llm.rb" do
    chdir  = File.join(__dir__, "..", "llm.rb")
    outdir = File.join(__dir__, "public", "api-docs", "llm.rb")
    template = File.join(__dir__, "..", "blog", "yardtmpl")
    rm_rf(outdir)
    yardoc(chdir:, outdir:, template:)
  end
end

def yardoc(chdir:, outdir:, template:)
  Dir.chdir(chdir) do
    sh [
      "bundle", "exec", "yardoc",
      "-o", outdir, "-p", template, "lib"
    ].join(" ")
  end
end
