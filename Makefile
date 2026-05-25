SHELL := /bin/bash
BOARD := board.bash
EXAMPLE := example.sh

.PHONY: help lint test example install clean

help:
	@echo "available targets:"
	@echo "  make lint     check bash syntax"
	@echo "  make test     run sanity checks"
	@echo "  make example  run the example script"
	@echo "  make install  copy board.bash to /usr/local/lib/"
	@echo "  make clean    remove temp files"

lint:
	@echo "checking $(BOARD) syntax..."
	bash -n $(BOARD)
	@echo "checking $(EXAMPLE) syntax..."
	bash -n $(EXAMPLE)
	@echo "both files look good"

test: lint
	@echo "running sanity checks..."
	@bash -c '. ./$(BOARD) && \
		paint --red "  paint works" && \
		paint --green --bold "  bold paint works" && \
		paint -n --cyan "  no-newline paint " && echo "ok" && \
		info "info() works" && \
		ok "ok() works" && \
		(is_linux && echo "  platform detection works" || \
		 echo "  (not linux, that is fine)") && \
		echo "  all tests passed"'

example: lint
	@echo "running example script..."
	@./$(EXAMPLE)

install: $(BOARD)
	@echo "installing $(BOARD) to /usr/local/lib..."
	@sudo install -m 644 $(BOARD) /usr/local/lib/$(BOARD)
	@echo "done. source it with: source /usr/local/lib/$(BOARD)"

uninstall:
	@echo "removing /usr/local/lib/$(BOARD)..."
	@sudo rm -f /usr/local/lib/$(BOARD)
	@echo "done"

clean:
	@rm -f /tmp/board_spinner_out.*
	@echo "cleaned up temp files"

