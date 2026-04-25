clean:
	find . -name '*.bak' -o -name '*.tdy' -exec 'rm' '{}' ';'
	rm -rf t/cover_db;
	rm -rf t/Service/cover_db;

test:
	prove t
	prove t/Service
	npm test

cover:
	rm -rf t/cover_db;
	cd t && PERL5OPT=-MDevel::Cover prove .; 
	cd t && PERL5OPT=-MDevel::Cover prove ./Service;

report:
	npm test -- --coverage
	cd t && cover -summary

# Configure perltidy command (install perltidy from CPAN if needed)
PERLTIDY ?= perltidy
# Extensions to treat as Perl
PERL_EXTS := pl pm t cgi plx
# Directories to search (adjust)
SRC_DIRS := .
# Files or dirs to exclude (rsync-style patterns; grep -v used below)
EXCLUDES := vendor node_modules .git

# Build a regex for extensions
EXT_REGEX := \.($(subst ,|,$(PERL_EXTS)))$$

.PHONY: indent
indent:
	@echo "Finding Perl files..."
	@find $(SRC_DIRS) -name '*.pl' -o -name '*.pm' -o -name '*.t' -type f \
		> .perltidy_file_list || true
	@if [ ! -s .perltidy_file_list ]; then \
	  echo "No Perl files found."; \
	  rm -f .perltidy_file_list; \
	else \
	  echo "Running perltidy on files..."; \
	  set -e; \
	  cat .perltidy_file_list | while IFS= read -r f; do \
	    echo "  perltidy $$f"; \
	    $(PERLTIDY) -q $$f || { echo "perltidy failed on $$f"; exit 1; }; \
	  done; \
	  rm -f .perltidy_file_list; \
	fi
