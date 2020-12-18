# Stack Usage Survey

Here is where I will store all my Jupyter notebooks used to analyse the data I collect as part of my survey of stack memory usage by popular applications.

## List of notebooks

- [Analysis of EscapeAnalysisTool data](https://github.com/bencole12345/StackUsageSurveyWorkbooks/blob/main/Static%20Stack%20Usage%20Survey.ipynb)

## How to reproduce data

See the included Makefile. The default target, `make do-analysis`, compiles all source programs to LLVM IR and runs EscapeAnalysisTool on them all. The CSV files will be written to `analysis_output`, and you can see the generated `.bc` and `.ll` files in `build_llvm_binaries`. Note that the notebook looks in `notebook_data`, so if you want to run the notebook with new data, you (by design) have to copy it across manually.

The Makefile uses various links to binaries and source directories that you can override if your files are located in a different place. In particular, you'll almost certainly want to override the path to `ESCAPE_ANALYSIS_TOOL`.
