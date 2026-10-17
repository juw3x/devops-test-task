.RECIPEPREFIX = >
.PHONY: lint test verify

SCRIPTS := $(shell find setup scripts tests -name '*.sh')

lint:
> shellcheck $(SCRIPTS)

test:
> bash tests/test_check_page.sh

verify:
> bash scripts/verify.sh
