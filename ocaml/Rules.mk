# First, and therefore default, target.
all: targets

# We will need to change this when we make the OCaml-C interface.
OCAMLBUILD := ocamlbuild
OCAMLCFLAGS := -cflags -I,/home/mihir/uppaal/include
OCAMLLFLAGS := -lflags -cclib,-L/home/mihir/uppaal/lib
OCAMLLFLAGS += -lflags -cclib,-ludbm
OCAMLLFLAGS += -lflags -cclib,-lstdc++

# The next three are to compact some of the dependencies in the top
# level.
grammar_types := grammar-noweb/grammar_types.mli \
grammar-noweb/grammar_types.ml

clock_utilities := utilities/clock_utilities.ml \
utilities/clock_utilities.mli

fernandez := fernandez-ocaml-noweb/fernandez.ml \
fernandez-ocaml-noweb/fernandez.mli

dir := c
include $(dir)/Rules.mk
dir := fernandez-ocaml-noweb
include $(dir)/Rules.mk
dir := grammar-noweb
include $(dir)/Rules.mk
dir := next_step
include $(dir)/Rules.mk
dir := utilities
include $(dir)/Rules.mk

# Top level dependencies.

.PHONY: targets
targets: next_step.native

libzone_stubs.a: \
c/zone_stubs.mli \
c/zone.mllib \
c/zone_stubs.c
	$(OCAMLBUILD) libzone_stubs.a

calc.native: \
zone-valuation-graph/calc.ml \
$(grammar_types) \
grammar-noweb/lexer.mll \
grammar-noweb/parser.mly \
grammar-noweb/parse_timed_automaton.ml \
fernandez-ocaml-noweb/fernandez.ml \
fernandez-ocaml-noweb/fernandez.mli \
Rules.mk \
_tags \
myocamlbuild.ml

next_step.native: \
next_step/next_step.ml \
$(clock_utilities) \
$(grammar_types) \
grammar-noweb/lexer.mll \
grammar-noweb/parser.mly \
utilities/parse_timed_automaton.ml \
$(fernandez) \
c/zone_stubs.mli \
c/zone_stubs.c \
Rules.mk \
_tags\
myocamlbuild.ml

%.native:
	$(OCAMLBUILD) $(OCAMLCFLAGS) $(OCAMLLFLAGS) \
	next_step/next_step.native

calc.top: zone-valuation-graph/calc.mltop
	ocamlbuild zone-valuation-graph/calc.top
