# Makefile --- A simple Makefile for working on specs.

# This is a generic Makefile for generating HTML documents from Bikeshed
# and Markdown source files.

# Bikeshed (.bs) is a popular format for writing specifications in. This
# Makefile assumes you have a local install of bikeshed. Installation
# instructions can be found here:
#
#     https://tabatkins.github.io/bikeshed/#installing

# Markdown (.md) is commonly used for README files, explainers, and
# other documentation adjacent to specifications.
#
# This Makefile assumes you have a local install of the Python markdown2
# module. You can install it like any other Python module, with pip:
#
#     pip install markdown2
#
# It also assumes you have doctoc installed. This is a tool that
# automatically generates Table of Contents for Markdown files. It can
# be installed like any other NPM module:
#
#    npm install -g doctoc

docs    = $(patsubst %.md,%.html,$(wildcard *.md))
specs   = $(patsubst %.bs,%.html,$(wildcard *.bs))

.PHONY: all docs specs clean
.SUFFIXES: .bs .md .html

all: docs specs
docs: $(docs)
specs: $(specs)

clean:
	rm -f $(docs) $(specs) *~

.bs.html:
	bikeshed spec $< $@

.md.html:
	echo "<!doctype html>\n<meta charset=utf-8>\n" > $@
	doctoc $<
	markdown2 $< >> $@
