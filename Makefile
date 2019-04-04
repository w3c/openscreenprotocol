BIKESHED ?= bikeshed
BIKESHED_ARGS ?= --print=plain

.PHONY: lint watch

index.html: index.bs messages_appendix.cddl
	./scripts/pygmentize_dir.py
	$(BIKESHED) $(BIKESHED_ARGS) spec $<

lint: index.bs
	$(BIKESHED) $(BIKESHED_ARGS) --dry-run --force spec --line-numbers $<

watch: index.bs
	@echo 'Browse to file://${PWD}/index.html'
	$(BIKESHED) $(BIKESHED_ARGS) watch $<


