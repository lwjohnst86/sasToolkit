# Makefile to use knitr for package vignettes
# put all PDF targets here, separated by spaces

# ---------------------------------------------
# Settings, targets, and source files

SRC = \
	$(sort $(wildcard src/*.sas))

# ---------------------------------------------
# If make is run without a specified target (ie. `make`), a list of
# commands will be presented.

all: commands

## ---------------------------------------------

## commands : Show all commands in Makefile
commands :
	@grep -E '^##' Makefile | sed -e 's/##//g'

# Make pdf
#%.pdf: %.sas

## readme : Generate the README pdf file.
readme : README.pdf
	sed -i 's/-+-/-|-/g' README.md
	cat .pdfheader.md README.md | pandoc --highlight-style tango -o README.pdf

.PHONY: commands readme
