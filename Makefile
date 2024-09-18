BIKESHED ?= bikeshed
BIKESHED_ARGS ?= --print=plain

.PHONY: lint watch watch-net 

all: index.html network.html

index.html: index.bs messages_appendix.html
	$(BIKESHED) $(BIKESHED_ARGS) spec $<

messages_appendix.html: messages_appendix.cddl scripts/pygmentize_dir.py scripts/cddl_lexer.py scripts/openscreen_cddl_dfns.py
	./scripts/pygmentize_dir.py

network.html: network.bs network_messages.html
	$(BIKESHED) $(BIKESHED_ARGS) spec $<

network_messages.html: network_messages.cddl scripts/pygmentize_dir.py scripts/cddl_lexer.py scripts/openscreen_cddl_dfns.py
	./scripts/pygmentize_dir.py

lint: index.bs
	$(BIKESHED) $(BIKESHED_ARGS) --dry-run --force spec --line-numbers $<

watch: index.bs
	@echo 'Browse to file://${PWD}/index.html'
	$(BIKESHED) $(BIKESHED_ARGS) watch $<

watch-net: network.bs
	@echo 'Browse to file://${PWD}/network.html'
	$(BIKESHED) $(BIKESHED_ARGS) watch $<


