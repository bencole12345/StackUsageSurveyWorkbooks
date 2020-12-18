# Tools used by this Makefile (override if they're somewhere else!)
ESCAPE_ANALYSIS_TOOL ?= /home/ben/dev/EscapeAnalysisTool/build/EscapeAnalysisTool
GCLANG ?= gclang
LLVM_DIS ?= llvm-dis
GET_BC ?= get-bc

# Paths to the directories of program sources
GREP_SOURCE ?= /home/ben/clones/grep-3.6
OCAML_SOURCE ?= /home/ben/clones/ocaml

# Binaries to be decompiled
GREP_BINARY ?= /usr/bin/grep

do-analysis: analysis_output/grep_dynamic.csv analysis_output/grep_static.csv analysis_output/ocamlrun.csv
	@echo "Done, find the CSV files in the analysis_output directory."

clean:
	rm -rf built_llvm_binaries
	rm -rf analysis_output

# The location that the .bc and .ll files will be located
built_llvm_binaries:
	mkdir built_llvm_binaries

built_llvm_binaries/grep_dynamic.bc: built_llvm_binaries
	@echo "Compiling Grep from source"
	cd $(GREP_SOURCE); \
		CC=$(GCLANG) $(GREP_SOURCE)/configure; \
		make
	@echo "Extracting LLVM bitcode"
	$(GET_BC) $(GREP_SOURCE)/src/grep
	cp $(GREP_SOURCE)/src/grep.bc built_llvm_binaries/grep_dynamic.bc

# TODO: This one doesn't seem to work - maybe the LDFLAGS command is different for Clang?
built_llvm_binaries/grep_static.bc: built_llvm_binaries
	@echo "Compiling Grep from source with static linking"
	cd $(GREP_SOURCE); \
		CC=$(GCLANG) $(GREP_SOURCE)/configure CFLAGS=-static LDFLAGS='-static -llibc'; \
		make
	@echo "Extracting LLVM bitcode"
	$(GET_BC) $(GREP_SOURCE)/src/grep
	cp $(GREP_SOURCE)/src/grep.bc built_llvm_binaries/grep_static.bc

built_llvm_binaries/ocamlrun.bc: built_llvm_binaries
	@echo "Compiling OCaml runtime from source"
	cd $(OCAML_SOURCE); \
		CC=$(GCLANG) $(OCAML_SOURCE)/configure; \
		make
	@echo "Extracting LLVM bitcode"
	$(GET_BC) $(OCAML_SOURCE)/runtime/ocamlrun
	cp $(OCAML_SOURCE)/runtime/ocamlrun.bc built_llvm_binaries

.PRECIOUS: built_llvm_binaries/%.ll
built_llvm_binaries/%.ll: built_llvm_binaries/%.bc
	@echo Disassembling $*.bc to $*.ll
	$(LLVM_DIS) built_llvm_binaries/$*.bc

# The location that the CSV files will be located
analysis_output:
	mkdir analysis_output

analysis_output/%.csv: analysis_output built_llvm_binaries/%.ll
	@echo Running EscapeAnalysisTool on file $*.ll
	$(ESCAPE_ANALYSIS_TOOL) built_llvm_binaries/$*.ll -o analysis_output/$*.csv
	@echo Analysis complete, find the results in analysis_output/$*.csv.
