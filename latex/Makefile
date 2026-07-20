LATEXMK = latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error

.PHONY: all book clean

all: book

book:
	cd book && $(LATEXMK) main.tex

clean:
	cd book && latexmk -C main.tex
