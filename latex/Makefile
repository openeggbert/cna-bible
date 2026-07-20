LATEXMK = latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error

.PHONY: all volume1 volume2 clean

all: volume1 volume2

volume1:
	cd volume1 && $(LATEXMK) main.tex

volume2:
	cd volume2 && $(LATEXMK) main.tex

clean:
	cd volume1 && latexmk -C main.tex
	cd volume2 && latexmk -C main.tex
