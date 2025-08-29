.SUFFIXES:

PREFIX := /usr/local

.PHONY: all
all:

.PHONY: install
install:
	mkdir -p "$(DESTDIR)$(PREFIX)/lib/pkgconfig"
	mkdir -p "$(DESTDIR)$(PREFIX)/share/freestnd-cxx-hdrs"
	for arch in aarch64 i686 loongarch64 m68k riscv64 x86_64; do \
		cp -r $$arch "$(DESTDIR)$(PREFIX)/share/freestnd-cxx-hdrs/"; \
		sed "s/@architecture@/$$arch/g;s|@prefix@|$(PREFIX)|g" freestnd-cxx-hdrs.pc.in > "$(DESTDIR)$(PREFIX)/lib/pkgconfig/freestnd-cxx-hdrs-$$arch.pc"; \
	done
