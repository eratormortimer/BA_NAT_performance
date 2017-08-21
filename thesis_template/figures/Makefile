.SILENT :
.PHONY  : all

FIGURES  := $(basename $(wildcard *.tikz))

PDFLATEX ?= $(shell which pdflatex)
BIBTEX ?= $(shell which bibtex)
DIFF ?= $(shell which diff)
GREP ?= $(shell which grep)
AWK ?= $(shell which awk)
CP ?= $(shell which cp)

PDFLATEX_FLAGS	:= -interaction=nonstopmode -shell-escape
GREP_FLAGS += -E -B 0 -A 2

# terminal colors
ifneq ($(COLORTERM),false)
  NOCOLOR := "\033[0m"
  RED := "\033[1;31m"
  BLUE := "\033[1;34m"
  GREEN := "\033[1;32m"
  YELLOW := "\033[1;33m"
  CYAN := "\033[1;36m"
  WHITE := "\033[1;37m"
  MAGENTA := "\033[1;35m"
  BOLD := "\033[1m"
else
  NOCOLOR := ""
  RED := ""
  BLUE := ""
  GREEN := ""
  YELLOW := ""
  CYAN := ""
  WHITE := ""
  MAGENTA := ""
  BOLD := ""
endif

# helper functions for filename conversion
getname = $(firstword $(subst ., ,$(1)))
getaux = $(call getname,$(1)).aux

# messaging functions
msgtarget = printf $(GREEN)"%s"$(MAGENTA)" %s"$(NOCOLOR)"\n" "$(1)" "$(2)"
msgcompile = printf $(BOLD)"%-25s"$(NOCOLOR)" %s\n" "[$(1)]" "$(2)"
msgfail = printf "%-25s "$(RED)"%s"$(NOCOLOR)"\n" "" "FAILED! Continuing ..."
msginfo = printf "%-25s "$(CYAN)"%s"$(NOCOLOR)"\n" "" "$(1)"

define copy-files
	$(call CP,-r ../pream pream)
	$(call CP,-r ../packages packages)
endef

define run-typeset
  $(call msgcompile,$(PDFLATEX),$(1)); \
  $(PDFLATEX) $(PDFLATEX_FLAGS) $(1) 1>/dev/null 2>&1 || \
    $(call msgfail)
endef

define extract-log
  $(call msgtarget,Extracting log file for target,$(1)); \
  $(GREP) $(GREP_FLAGS) \
	-e "Warning|Error|Underfull|Overfull|\!|Reference|Label|Citation" \
	$(call getname,$(1)).log || :
endef

all: $(addsuffix .pdf,$(FIGURES))

%.pdf: %.tikz
	cp -r ../pream pream
	cp -r ../packages packages
	$(call run-typeset,$<)
	$(call extract-log,$<)

clean:
	rm -rfv pream
	rm -rfv packages
	rm -fv $(addsuffix .aux,$(FIGURES))
	rm -fv $(addsuffix .log,$(FIGURES))
	rm -fv $(addsuffix .toc,$(FIGURES))
	rm -fv $(addsuffix .lof,$(FIGURES))
	rm -fv $(addsuffix .lot,$(FIGURES))
	rm -fv $(addsuffix .eps,$(FIGURES))
	rm -fv $(addsuffix .bbl,$(FIGURES))
	rm -fv $(addsuffix .out,$(FIGURES))
	rm -fv $(addsuffix .fls,$(FIGURES))
	rm -fv $(addsuffix .blg,$(FIGURES))
	rm -fv $(addsuffix .auxlock,$(FIGURES))
	rm -fv $(addsuffix .nav,$(FIGURES))
	rm -fv $(addsuffix .snm,$(FIGURES))

cleanall:
	make clean
	rm -fv $(addsuffix .pdf,$(FIGURES))
