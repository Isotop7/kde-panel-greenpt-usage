ifeq ($(HOME),)
$(error HOME is not set)
endif

PLASMOID_ID = dev.greenpt.credits
PLASMOID_DIR = $(HOME)/.local/share/plasma/plasmoids/$(PLASMOID_ID)

.PHONY: install uninstall

install:
	sh package/translate/build.sh
	rm -rf "$(PLASMOID_DIR)"
	mkdir -p "$(PLASMOID_DIR)"
	cp -r package/. "$(PLASMOID_DIR)/"

uninstall:
	rm -rf "$(PLASMOID_DIR)"
