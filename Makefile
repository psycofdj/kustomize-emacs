SOURCES = $(wildcard *.el | grep -v autoloader)
VERSION = $(shell cat kustomize-pkg.el | head -n1 | awk '{print $$3}' | sed 's/"//g')

all: install

dist: emacs-kustomize-$(VERSION).tar

emacs-kustomize-$(VERSION).tar: $(SOURCES)
	@mkdir kustomize-$(VERSION)
	@cp --parents -dR $(SOURCES) kustomize-$(VERSION)/
	@tar cvf emacs-kustomize-$(VERSION).tar kustomize-$(VERSION)
	@rm -rf kustomize-$(VERSION)

install: emacs-kustomize-$(VERSION).tar
	@rm -rf ~/.emacs.d/elpa/kustomize-*/
	emacs --batch --eval "(defconst pkg-to-install \"$(PWD)/emacs-kustomize-$(VERSION).tar\")" -l vendor/emacs-pkg-install.el
