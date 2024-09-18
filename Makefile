BIKESHED ?= bikeshed
BIKESHED_ARGS ?= --print=plain

.PHONY: lint watch watch-app all

# TODO: Generalize targets to reduce duplication.

all: index.html application.html

index.html: index.bs messages_appendix.html
	$(BIKESHED) $(BIKESHED_ARGS) spec $<

application.html: application.bs application_messages.html
	$(BIKESHED) $(BIKESHED_ARGS) spec $<

messages_appendix.html: messages_appendix.cddl scripts/pygmentize_dir.py scripts/cddl_lexer.py scripts/openscreen_cddl_dfns.py
	./scripts/pygmentize_dir.py

application_messages.html: application_messages.cddl scripts/pygmentize_dir.py scripts/cddl_lexer.py scripts/openscreen_cddl_dfns.py
	./scripts/pygmentize_dir.py

lint: index.bs
	$(BIKESHED) $(BIKESHED_ARGS) --dry-run --force spec --line-numbers $<

watch: index.bs
	@echo 'Browse to file://${PWD}/index.html'
	$(BIKESHED) $(BIKESHED_ARGS) watch $<

watch-app: application.bs
	@echo 'Browse to file://${PWD}/application.html'
	$(BIKESHED) $(BIKESHED_ARGS) watch $<


