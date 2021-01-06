# Tools used by this Makefile (override if they're somewhere else!)
ESCAPE_ANALYSIS_TOOL ?= /home/ben/dev/EscapeAnalysisTool/build/EscapeAnalysisTool
CLANG ?= clang
CMAKE ?= cmake
GCLANG ?= gclang
GCLANGPLUSPLUS ?= gclang++
LLVM_DIS ?= llvm-dis
GET_BC ?= get-bc

# Paths to the directories of program sources
GREP_SOURCE ?= /home/ben/clones/grep-3.6
OCAML_SOURCE ?= /home/ben/clones/ocaml
LLVM_SOURCE ?= /home/ben/clones/llvm-project

# Shortcuts for supported programs
grep: analysis_output/grep.csv
grep_static: analysis_output/grep_static.csv
ocamlrun: analysis_output/ocamlrun.csv
ocamlrun_static: analysis_output/ocamlrun_static.csv
clang: analysis_output/clang.csv

# Run the analysis on all programs
all: grep ocamlrun clang
	@echo "Done, find the CSV files in the analysis_output directory."

# Run the analysis on all programs, using static linking where possible
all-static: grep-static ocamlrun-static clang
	@echo "Done, find the CSV files in the analysis_output directory."

# Remove all generated files and directories
clean:
	rm -rf built_llvm_binaries
	rm -rf analysis_output

# Where the .ll and .bc files will be stored
built_llvm_ir:
	mkdir built_llvm_ir

# Where the .s files will be stored
built_assembly:
	mkdir built_assembly

# Grep, built from source using dynamic linking
built_llvm_ir/grep.bc: built_llvm_ir
	@echo "Compiling Grep from source with dynamic linking"
	cd $(GREP_SOURCE); \
		CC=$(GCLANG) $(GREP_SOURCE)/configure; \
		make
	@echo "Extracting LLVM bitcode"
	$(GET_BC) $(GREP_SOURCE)/src/grep
	cp $(GREP_SOURCE)/src/grep.bc built_llvm_ir/grep.bc

# Grep, built from source using static linking
built_llvm_ir/grep_static.bc: built_llvm_ir
	@echo "Compiling Grep from source with static linking"
	cd $(GREP_SOURCE); \
		CC=$(GCLANG) $(GREP_SOURCE)/configure CFLAGS=-static LDFLAGS='-static -llibc'; \
		make
	@echo "Extracting LLVM bitcode"
	$(GET_BC) $(GREP_SOURCE)/src/grep
	cp $(GREP_SOURCE)/src/grep.bc built_llvm_ir/grep_static.bc

# OCaml runtime, built from source using dynamic linking
built_llvm_ir/ocamlrun.bc: built_llvm_ir
	@echo "Compiling OCaml runtime from source with dynamic linking"
	cd $(OCAML_SOURCE); \
		CC=$(GCLANG) $(OCAML_SOURCE)/configure; \
		make
	@echo "Extracting LLVM bitcode"
	$(GET_BC) $(OCAML_SOURCE)/runtime/ocamlrun
	cp $(OCAML_SOURCE)/runtime/ocamlrun.bc built_llvm_ir/ocamlrun.bc

# OCaml runtime, built from source using static linking
built_llvm_ir/ocamlrun_static.bc: built_llvm_ir
	@echo "Compiling OCaml runtime from source with static linking"
	cd $(OCAML_SOURCE); \
		CC=$(GCLANG) $(OCAML_SOURCE)/configure CFLAGS=-static LDFLAGS='-static -llibc'; \
		make
	@echo "Extracting LLVM bitcode"
	$(GET_BC) $(OCAML_SOURCE)/runtime/ocamlrun
	cp $(OCAML_SOURCE)/runtime/ocamlrun.bc built_llvm_ir/ocamlrun_static.bc

$(LLVM_SOURCE)/build:
	mkdir $(LLVM_SOURCE)/build

# Clang (and LLVM), built from source using dynamic linking
built_llvm_ir/clang.bc: built_llvm_ir $(LLVM_SOURCE)/build
	@echo "Compiling Clang from source with dynamic linking"
	cd $(LLVM_SOURCE)/build; \
		CXX=$(GCLANGPLUSPLUS) $(CMAKE) -DLLVM_ENABLE_PROJECTS=clang -G "Ninja" ../llvm; \
		$(CMAKE) --build .
	@echo "Extracting LLVM bitcode"
	$(GET_BC) $(LLVM_SOURCE)/build/bin/clang-12
	cp $(LLVM_SOURCE)/build/bin/clang-12.bc built_llvm_ir/clang.bc

# Use llvm-dis to disassemble .bc files into .ll files
.PRECIOUS: built_llvm_ir/%.ll  # Don't automatically delete
built_llvm_ir/%.ll: built_llvm_ir/%.bc
	@echo Disassembling $*.bc to $*.ll
	$(LLVM_DIS) built_llvm_ir/$*.bc

# Convert LLVM's .bc bitcode files into assembly code
built_assembly/%.s: built_assembly built_llvm_ir/%.bc
	@echo Copiling $*.bc into $*.s
	$(CLANG) -S built_llvm_ir/$*.bc -O2 -o built_assembly/$*.s

# The location that the CSV files will be located
analysis_output:
	mkdir analysis_output

# Run EscapeAnalysisTool to produce CSV files
analysis_output/%.csv: analysis_output built_llvm_ir/%.bc
	@echo Running EscapeAnalysisTool on file $*.bc
	$(ESCAPE_ANALYSIS_TOOL) built_llvm_ir/$*.bc -o analysis_output/$*.csv
	@echo Analysis complete, find the results in analysis_output/$*.csv.
