# MendelIHT

*A modern approach to analyze data from a Genome Wide Association Studies (GWAS)*

| **Documentation** | **Build Status** | **Code Coverage**  |
|-------------------|------------------|--------------------|
| [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://OpenMendel.github.io/MendelIHT.jl/latest) [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://OpenMendel.github.io/MendelIHT.jl/stable) | [![Build Status](https://travis-ci.org/OpenMendel/MendelIHT.jl.svg?branch=master)](https://travis-ci.org/OpenMendel/MendelIHT.jl) [![Build status](https://ci.appveyor.com/api/projects/status/s7dxx48g1ol9hqi0?svg=true)](https://ci.appveyor.com/project/biona001/mendeliht-jl) | [![Coverage Status](https://coveralls.io/repos/github/OpenMendel/MendelIHT.jl/badge.svg?branch=master)](https://coveralls.io/github/OpenMendel/MendelIHT.jl?branch=master)  [![codecov](https://codecov.io/gh/OpenMendel/MendelIHT.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/OpenMendel/MendelIHT.jl)

## Installation

Start Julia, press `]` to enter package manager mode, and type the following (after `pkg>`):
```
(v1.0) pkg> add https://github.com/OpenMendel/SnpArrays.jl
(v1.0) pkg> add https://github.com/OpenMendel/MendelSearch.jl
(v1.0) pkg> add https://github.com/OpenMendel/MendelBase.jl
(v1.0) pkg> add https://github.com/OpenMendel/MendelIHT.jl
```
The order of installation is important!

## Documentation

+ [**Latest**](https://OpenMendel.github.io/MendelIHT.jl/latest/)
+ [**Stable**](https://OpenMendel.github.io/MendelIHT.jl/stable/)

## Video Introduction

[![Video Introduction to MendelIHT.jl](https://github.com/OpenMendel/MendelIHT.jl/blob/master/figures/video_intro.png)](https://www.youtube.com/watch?v=UPIKafShwFw)

## Citation and Reproducibility:

A preprint of our paper is available on [bioRxiv](https://www.biorxiv.org/content/10.1101/697755v1). If you use `MendelIHT.jl`, please cite:

```
Benjamin B. Chu, Kevin L. Keys, Janet S. Sinsheimer, and Kenneth Lange. Multivariate GWAS: Generalized Linear Models, Prior Weights, and Double Sparsity. bioRxiv doi:10.1101/697755
```

In the `figures` subfolder, one can find all the code to reproduce the figures and tables in our preprint. The `Project.toml` and `Manifest.toml` files can be used together to instantiate the exact same computing environment as was used in our paper. For more information about `.toml` files, please visit Julia's [Pkg documentation](https://docs.julialang.org/en/v1.0/stdlib/Pkg/#Glossary-1). 
