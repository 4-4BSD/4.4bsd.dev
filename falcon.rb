#!/usr/bin/env -S bundle exec falcon host
# frozen_string_literal: true

##
# Falcon service definition for 4.4bsd.dev.
#
# Run with `bundle exec falcon host` (or `service bsd44 reload`), which
# starts an async-service Controller that:
#
#   * binds a single shared listener in the parent process,
#   * forks N worker processes that all accept on that shared listener, and
#   * on SIGHUP performs a blue-green restart: it forks fresh workers, waits
#     for them to become ready, then gracefully drains the old ones.
#
# Each worker loads the app fresh from config.ru, so a SIGHUP picks up newly
# deployed code without dropping any in-flight requests.
#
# NOTE: Do not enable `preload` here. Preloading loads the application into
# the parent process, which would make new workers inherit *stale* in-memory
# code on reload. We deliberately keep the parent thin and let each worker
# boot the app from disk.

require "falcon/environment/rack"

hostname = "4.4bsd.dev"
bind = ENV.fetch("BSD44_BIND", "127.0.0.1")
port = ENV.fetch("BSD44_PORT", "9292")
count = Integer(ENV.fetch("BSD44_WORKERS", "1"))

service(hostname) do
  include Falcon::Environment::Rack
  count(count)
  preload(false)
  endpoint do
    Async::HTTP::Endpoint.parse("http://#{bind}:#{port}").with(
      protocol: Async::HTTP::Protocol::HTTP1
    )
  end
end
