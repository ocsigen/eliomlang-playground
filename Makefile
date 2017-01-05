
##----------------------------------------------------------------------
## DISCLAIMER
##
## This file contains the rules to make an Eliom project. The project is
## configured through the variables in the file Makefile.options.
##----------------------------------------------------------------------

include Makefile.options

##----------------------------------------------------------------------
##			      Internals

## Required binaries
OCAMLC            := ocamlfind c
OCAMLOPT          := ocamlfind opt
JS_OF_OCAML       := js_of_ocaml
OCAMLDEP          := ocamlfind dep

DEPSDIR := _deps

JSOO_OPTIONS := +eliomlang.runtime.client/eliom.js $(JSOO_OPTIONS)

ifeq ($(DEBUG),yes)
  DEBUG_JS ?= --pretty --noinline --debuginfo --source-map
endif

SERVERMODE=-passopt -mode -passopt server
CLIENTMODE=-passopt -mode -passopt client

##----------------------------------------------------------------------
## General

.PHONY: all byte opt
all: byte
byte opt:: main.js
byte:: ${PROJECT_NAME}.server.byte
opt:: ${PROJECT_NAME}.server.opt

##----------------------------------------------------------------------

SERVER_INC := ${addprefix -server-package ,${SERVER_PACKAGES}}
CLIENT_INC := ${addprefix -client-package ,${CLIENT_PACKAGES}}
GEN_INC := ${addprefix -package ,${PACKAGES}}

# Packages for link
SERVER_LINK := ${addprefix -package ,${PACKAGES} ${SERVER_PACKAGES}}
CLIENT_LINK := ${addprefix -package ,${PACKAGES} ${CLIENT_PACKAGES}}

# Packages for ocamldep
PPX_INC := ${addprefix -package ,${SERVER_PACKAGES} ${CLIENT_PACKAGES} ${PACKAGES}}

INC=$(GEN_INC) $(SERVER_INC) $(CLIENT_INC)

##----------------------------------------------------------------------
## Aux

ocamldep=$(shell $(OCAMLDEP) $(1) -sort $(PPX_INC) $(filter %.ml,$(2))) $(shell $(OCAMLDEP) -sort $(PPX_INC) $(filter %.eliom,$(2)))

objs=$(patsubst %.ml,%.$(1),$(patsubst %.eliom,%.$(2).$(1),$(3)))
depsort=$(call objs,$(1),$(2),$(call ocamldep,-mode $(2),$(3)))

##----------------------------------------------------------------------
## Generic compilation

%.server.cmi: %.server.mli
	${OCAMLC} -mode server -c ${INC} -g $<
%.client.cmi: %.client.mli
	${OCAMLC} -mode client -c ${INC} -g $<
%.cmi: %.eliomi
	${OCAMLC} -mode eliom -c ${INC} -g $<

%.server.cmo: %.server.ml
	${OCAMLC} -mode server -c ${INC} -g $<
%.server.cmx: %.server.ml
	${OCAMLOPT} -mode server -c ${INC} -g $<
%.client.cmo: %.client.ml
	${OCAMLC} -mode client -c ${INC} -g $<

%.client.cmo %.server.cmo: %.eliom
	${OCAMLC} -mode eliom -c ${INC} -g $<
%.client.cmo %.server.cmx: %.eliom
	${OCAMLOPT} -mode eliom -c ${INC} -g $<

# %.cmxs: %.cmxa
# 	$(OCAMLOPT) -shared -linkall -o $@ -g $<

# %.byte: %.cma
# 	$(OCAMLC) $(LINKFLAGS) -linkall $(INC) -o $@ -g $<

##----------------------------------------------------------------------
## Server side compilation

$(PROJECT_NAME).server.byte: $(call objs,cmo,server,$(SERVER_FILES))
	${OCAMLC} -mode server $(SERVER_LINK) -linkpkg -linkall -o $@ -g $(call depsort,cmo,server,$(SERVER_FILES))

$(PROJECT_NAME).server.opt: $(call objs,cmx,server,$(SERVER_FILES))
	${OCAMLOPT} -mode server $(SERVER_LINK) -linkpkg -linkall -o $@ -g $(call depsort,cmx,server,$(SERVER_FILES))


##----------------------------------------------------------------------
## Client side compilation

main.js: $(PROJECT_NAME).client.byte
	${JS_OF_OCAML} $(JSOO_OPTIONS) -o $@ $(DEBUG_JS) $<

$(PROJECT_NAME).client.byte: $(call objs,cmo,client,$(CLIENT_FILES))
	${OCAMLC} -mode client $(CLIENT_LINK) -linkpkg -linkall -o $@ -g $(call depsort,cmo,client,$(CLIENT_FILES))

##----------------------------------------------------------------------
## Dependencies

include .depend

.depend: $(patsubst %,$(DEPSDIR)/%.depend,$(SERVER_FILES)) $(patsubst %,$(DEPSDIR)/%.depend,$(CLIENT_FILES))
	cat $^ > $@

$(DEPSDIR)/%.depend: % | $(DEPSDIR)
	$(OCAMLDEP) $(PPX_INC) $< > $@
$(DEPSDIR)/%.eliom.depend: %.eliom | $(DEPSDIR)
	$(OCAMLDEP) -mode eliom $(PPX_INC) $< > $@
$(DEPSDIR)/%.client.ml.depend: %.client.ml | $(DEPSDIR)
	$(OCAMLDEP) -mode client $(PPX_INC) $< > $@
$(DEPSDIR)/%.server.ml.depend: %.server.ml | $(DEPSDIR)
	$(OCAMLDEP) -mode server $(PPX_INC) $< > $@

$(DEPSDIR):
	mkdir $@

##----------------------------------------------------------------------
## Clean up

clean:
	-rm -f *.cm[ioax] *.cmxa *.cmxs *.o *.a *.annot
	-rm -f *.type_mli
	-rm -f main.js

distclean: clean
	-rm -rf $(DEPSDIR) .depend
