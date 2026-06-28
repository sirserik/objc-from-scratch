.PHONY: pdf tasks check all clean help

PDF := Objective-C-s-nulya.pdf
TASKS_PDF := Zadachi-s-sobesedovaniy-po-Objective-C.pdf

help:
	@echo "Цели:"
	@echo "  make pdf    — собрать PDF учебника ($(PDF))"
	@echo "  make tasks  — собрать мини-PDF задач собеса ($(TASKS_PDF))"
	@echo "  make check  — скомпилировать все примеры из code/"
	@echo "  make all    — check + pdf + tasks"
	@echo "  make clean  — удалить собранные PDF"

pdf:
	./build/build-pdf.sh

tasks:
	./build/build-tasks-pdf.sh

check:
	./build/check-code.sh

all: check pdf tasks

clean:
	rm -f $(PDF) $(TASKS_PDF)
