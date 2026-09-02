# frozen_string_literal: true

require "bundler/setup"
require_relative "config/boot"

namespace :db do
  desc "Create the database if it does not exist"
  task :create do
    require "active_record/tasks/database_tasks"
    ActiveRecord::Tasks::DatabaseTasks.create(ActiveRecord::Base.connection_db_config)
  ensure
    ##
    # DatabaseTasks.create leaves the pool connected to the
    # maintenance database ("postgres") when the target
    # database already exists. Restore the connection to the
    # configured database.
    ActiveRecord::Base.establish_connection(db_config)
  end

  desc "Run pending migrations (creating the database first if needed)"
  task migrate: :create do
    applied = migration_context.migrate
    if applied == true
      puts "No pending migrations (schema was already up to date)."
    else
      puts "Migrations complete."
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

  ##
  # @return [ActiveRecord::MigrationContext]
  def migration_context
    pool = ActiveRecord::Base.connection_pool
    ActiveRecord::MigrationContext.new(
      File.join(__dir__, "db", "migrate"),
      ActiveRecord::SchemaMigration.new(pool),
      ActiveRecord::InternalMetadata.new(pool)
    )
  end

  ##
  # Loads the database config for the current environment.
  def db_config
    raw    = ERB.new(File.read(File.join(__dir__, "config", "database.yml"))).result
    config = YAML.safe_load(raw, aliases: true)
    config.fetch(Raven.env)
  end
end

require_relative "rake/lib/migrations"
namespace :g do
  desc "Generate a migration (e.g. rake g:migration[create_users])"
  task :migration, [:name] do |_task, args|
    Raven::Migrations.generate(args[:name])
  rescue ArgumentError => error
    abort error.message
  end
end

