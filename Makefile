BIKESHED ?= bikeshed
BIKESHED_ARGS ?= --print=plain

# Define all spec source files
BS_SOURCES = index.bs application.bs network.bs

.PHONY: lint watch all

all: index.html application.html network.html

index.html: index.bs messages_appendix.html
	$(BIKESHED) $(BIKESHED_ARGS) spec $<

application.html: application.bs application_messages.html
	$(BIKESHED) $(BIKESHED_ARGS) spec $<

network.html: network.bs network_messages.html
	$(BIKESHED) $(BIKESHED_ARGS) spec $<

CDDL_SOURCES = messages_appendix.cddl application_messages.cddl network_messages.cddl
CDDL_OUTPUTS = messages_appendix.html application_messages.html network_messages.html
PYGMENTIZE_DIR = ./scripts/pygmentize_dir.py
MESSAGE_SCRIPTS = $(PYGMENTIZE_DIR) scripts/cddl_lexer.py scripts/openscreen_cddl_dfns.py

$(CDDL_OUTPUTS) : $(CDDL_SOURCES) $(MESSAGE_SCRIPTS)
	$(PYGMENTIZE_DIR)

lint: $(BS_SOURCES)
	@for file in $(BS_SOURCES); do \
		echo "Linting $$file..."; \
		$(BIKESHED) $(BIKESHED_ARGS) --dry-run --die-when=late --line-numbers spec $$file; \
	done

watch: $(BS_SOURCES)
	@for file in $(BS_SOURCES); do \
		echo "Browse to file://${PWD}/$$file"; \
		( $(BIKESHED) $(BIKESHED_ARGS) watch $$file & ) \
	done
