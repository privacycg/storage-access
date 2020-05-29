# This Makefile assumes you have a local install of bikeshed. Like any
# other Python tool, you install it with pip:
#
#     python3 -m pip install bikeshed && bikeshed update

# It also assumes you have doctoc installed. This is a tool that
# automatically generates Table of Contents for Markdown files. It can
# be installed like any other NPM module:
#
#    npm install -g doctoc

.PHONY: all clean update-explainer-toc
.SUFFIXES: .bs .html

all: update-explainer-toc index.html

clean:
	rm -f *.html *~

index.html: storage-access.bs Makefile
	bikeshed --die-on=warning spec $< $@

update-explainer-toc: README.md Makefile
	doctoc $< --title "## Table of Contents" > /dev/null
