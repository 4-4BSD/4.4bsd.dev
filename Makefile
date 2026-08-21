PREFIX ?= /usr/local
APPNAME ?= rubydev
APPDIR ?= $(PREFIX)/share/$(APPNAME)
RCDIR ?= $(PREFIX)/etc/rc.d
BUNDLE ?= bundle
INSTALL ?= install
MKDIR ?= mkdir -p
RM ?= rm -f
SED ?= sed
RSYNC ?= rsync
# Sync in place: only changed files are swapped, stale files are removed
# with --delete, and runtime state (the sqlite database) is never touched.
# This is safe to run against a live, running app without an outage window.
RSYNC_OPTS ?= -a --delete --exclude '*.sqlite3' --exclude '*.sqlite3-*'

# How the running service is restarted after a deploy. The rc.d script
# overrides `restart` to do a graceful Falcon blue-green reload (SIGHUP),
# so this is the soft, zero-downtime path.
RC_SERVICE ?= service
RC_NAME ?= $(APPNAME)
# How the database password is read from rc.conf (rubydev_db_password) so
# `deploy` can pass it to the migrate step's environment.
SYSRC ?= sysrc
# The rc.conf key that holds the PostgreSQL password for the app role.
DB_PASSWORD_KEYS ?= rubydev_db_password

APP_FILES = Rakefile config.ru falcon.rb Gemfile Gemfile.lock LICENSE README.md
APP_DIRS = .bundle bin app config db libexec public

RACK_ENV ?= production

.PHONY: install deinstall bundle check-bundle deploy

install: check-bundle
	$(MKDIR) "$(DESTDIR)$(APPDIR)"
	for file in $(APP_FILES); do \
		$(RSYNC) -a "$$file" "$(DESTDIR)$(APPDIR)/$$file"; \
	done
	for dir in $(APP_DIRS); do \
		$(RSYNC) $(RSYNC_OPTS) "$$dir/" "$(DESTDIR)$(APPDIR)/$$dir/"; \
	done
	$(MKDIR) "$(DESTDIR)$(RCDIR)"
	$(SED) -e "s|%%APPDIR%%|$(APPDIR)|g" -e "s|%%PREFIX%%|$(PREFIX)|g" \
		etc/rc.d/rubydev.in > "$(DESTDIR)$(RCDIR)/rubydev"
	chmod 0555 "$(DESTDIR)$(RCDIR)/rubydev"

bundle:
	$(BUNDLE) config set path .bundle/gems
	$(BUNDLE) install

# Deploy: sync the app in place, apply any pending migrations, then do a
# graceful (zero-downtime) restart via the rc.d script. Migrations run
# before the reload so workers boot against the latest schema.
deploy: install
	# Inherit the database password from rc.conf (rubydev_db_password) via
	# sysrc into the migrate step's environment so production can authenticate.
	@password=$$( $(SYSRC) -e -n "$(DB_PASSWORD_KEYS)" 2>/dev/null ); \
	if [ -z "$$password" ]; then \
		echo "warning: $(DB_PASSWORD_KEYS) is not set in rc.conf; production migrate may fail"; \
	fi; \
	cd "$(DESTDIR)$(APPDIR)" && \
	RACK_ENV=$(RACK_ENV) RUBYDEV_DB_PASSWORD="$$password" "$(BUNDLE)" exec rake db:migrate
	$(RC_SERVICE) "$(RC_NAME)" restart

check-bundle:
	@test -f .bundle/config || (echo "Run 'make bundle' as an unprivileged user before 'make install'." >&2; exit 1)
	@test -d .bundle/gems || (echo "Run 'make bundle' as an unprivileged user before 'make install'." >&2; exit 1)

deinstall:
	$(RM) "$(DESTDIR)$(RCDIR)/rubydev"
	rm -rf "$(DESTDIR)$(APPDIR)"
