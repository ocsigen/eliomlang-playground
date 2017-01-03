
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

ifeq ($(DEBUG),yes)
  GENERATE_DEBUG ?= -g
  DEBUG_JS ?= -jsopt -pretty -jsopt -noinline -jsopt -debuginfo
endif

SERVERMODE=-passopt -mode -passopt server
CLIENTMODE=-passopt -mode -passopt client

##----------------------------------------------------------------------
## General

.PHONY: all byte opt
all: byte
byte opt:: ${PROJECT_NAME}.js
byte:: ${PROJECT_NAME}.server.byte
opt:: ${PROJECT_NAME}.server.opt

##----------------------------------------------------------------------
## Aux

ocamldep=$(shell $(OCAMLDEP) $(1) -sort $(2) $(filter %.eliom %.ml,$(3))))

objs=$(patsubst %.ml,%.$(1),$(patsubst %.eliom,%.$(2).$(1),$(3)))
depsort=$(call objs,$(1),$(2),$(call ocamldep,-mode $(2),$(3),$(4)))

##----------------------------------------------------------------------

SERVER_INC := ${addprefix -server-package ,${SERVER_PACKAGES}}
CLIENT_INC := ${addprefix -client-package ,${CLIENT_PACKAGES}}
GEN_INC := ${addprefix -package ,${PACKAGES}}

# Packages for ocamldep
PPX_INC := ${addprefix -package ,${SERVER_PACKAGES} ${CLIENT_PACKAGES} ${PACKAGES}}

INC=$(GEN_INC) $(SERVER_INC) $(CLIENT_INC)

##----------------------------------------------------------------------
## Generic compilation

%.cmi: %.mli
	${OCAMLC} -c ${INC} $(GENERATE_DEBUG) $<
%.cmi: %.eliomi
	${OCAMLC} -c ${INC} $(GENERATE_DEBUG) $<

%.cmo: %.ml
	${OCAMLC} -c ${INC} $(GENERATE_DEBUG) $<
%.cmx: %.ml
	${OCAMLOPT} -c ${INC} $(GENERATE_DEBUG) $<

%.client.cmo %.server.cmo: %.eliom
	${OCAMLC} -c ${INC} $(GENERATE_DEBUG) $<
%.client.cmo %.server.cmx: %.eliom
	${OCAMLOPT} -c ${INC} $(GENERATE_DEBUG) $<

%.cmxs: %.cmxa
	$(OCAMLOPT) -shared -linkall -o $@ $(GENERATE_DEBUG) $<

%.byte: %.cma
	$(CAMLC) $(LINKFLAGS) -o $@ $(GENERATE_DEBUG) $<

##----------------------------------------------------------------------
## Server side compilation

$(PROJECT_NAME).server.cma: $(call objs,cmo,server,$(SERVER_FILES))
	${OCAMLC} -a -o $@ $(GENERATE_DEBUG) \
          $(call depsort,cmo,server,$(INC),$(SERVER_FILES))

$(PROJECT_NAME).server.cmxa: $(call objs,cmx,server,$(SERVER_FILES))
	${OCAMLOPT} -a -o $@ $(GENERATE_DEBUG) \
          $(call depsort,cmx,server,$(INC),$(SERVER_FILES))


##----------------------------------------------------------------------
## Client side compilation

$(PROJECT_NAME).js: $(PROJECT_NAME).client.byte
	${JS_OF_OCAML} -o $@ $(DEBUG_JS) $<

$(PROJECT_NAME).client.cma: $(call objs,cmo,client,$(CLIENT_FILES))
	${OCAMLC} -a -o $@ $(GENERATE_DEBUG) \
          $(call depsort,cmo,client,$(INC),$(CLIENT_FILES))

##----------------------------------------------------------------------
## Dependencies

include .depend

.depend: $(patsubst %,$(DEPSDIR)/%.depend,$(SERVER_FILES)) $(patsubst %,$(DEPSDIR)/%.depend,$(CLIENT_FILES))
	cat $^ > $@

$(DEPSDIR)/%.depend: % | $(DEPSDIR)
	$(OCAMLDEP) $(PPX_INC) $< > $@

$(DEPSDIR):
	mkdir $@

##----------------------------------------------------------------------
## Clean up

clean:
	-rm -f *.cm[ioax] *.cmxa *.cmxs *.o *.a *.annot
	-rm -f *.type_mli
	-rm -f ${PROJECT_NAME}.js
	-rm -rf ${OCAML_CLIENT_DIR} ${OCAML_SERVER_DIR}

distclean: clean
	-rm -rf $(TEST_PREFIX) $(DEPSDIR) .depend
