PREFIX ?= /usr/local
APPNAME ?= bsd44
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
# How the database password is read from rc.conf (bsd44_db_password) so
# `deploy` can pass it to the migrate step's environment.
SYSRC ?= sysrc
# The rc.conf key that holds the PostgreSQL password for the app role.
DB_PASSWORD_KEYS ?= bsd44_db_password

APP_FILES = Rakefile config.ru falcon.rb Gemfile Gemfile.lock LICENSE README.md .version
APP_DIRS = .bundle bin app config db libexec public

RACK_ENV ?= production

.PHONY: install deinstall bundle check-bundle deploy assets

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
		etc/rc.d/bsd44.in > "$(DESTDIR)$(RCDIR)/bsd44"
	chmod 0555 "$(DESTDIR)$(RCDIR)/bsd44"

bundle:
	$(BUNDLE) config set path .bundle/gems
	$(BUNDLE) install

# Build frontend assets locally (never on the server). Produces
# public/assets/js/main.js and public/css/main.css, which are committed
# and shipped by `install`.
assets:
	npm install
	npm run build

# Deploy: sync the app in place, apply any pending migrations, then do a
# graceful (zero-downtime) restart via the rc.d script. Migrations run
# before the reload so workers boot against the latest schema.
deploy: install
	# Inherit the database password from rc.conf (bsd44_db_password) via
	# sysrc into the migrate step's environment so production can authenticate.
	@password=$$( $(SYSRC) -e -n "$(DB_PASSWORD_KEYS)" 2>/dev/null ); \
	if [ -z "$$password" ]; then \
		echo "warning: $(DB_PASSWORD_KEYS) is not set in rc.conf; production migrate may fail"; \
	fi; \
	cd "$(DESTDIR)$(APPDIR)" && \
	RACK_ENV=$(RACK_ENV) BSD44_DB_PASSWORD="$$password" "$(BUNDLE)" exec rake db:migrate
	$(RC_SERVICE) "$(RC_NAME)" restart

check-bundle:
	@test -f .bundle/config || (echo "Run 'make bundle' as an unprivileged user before 'make install'." >&2; exit 1)
	@test -d .bundle/gems || (echo "Run 'make bundle' as an unprivileged user before 'make install'." >&2; exit 1)

# Write the current HEAD commit into .version. Runs automatically before
# every commit (see .git/hooks/pre-commit) so .version always tracks HEAD.
version:
	@git rev-parse HEAD > .version
	@echo "wrote .version: $$(cat .version)"

deinstall:
	$(RM) "$(DESTDIR)$(RCDIR)/bsd44"
	rm -rf "$(DESTDIR)$(APPDIR)"
