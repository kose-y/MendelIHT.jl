
# Examples

Here we give numerous example analysis of GWAS data with `MendelIHT.jl`. For exact function input/output descriptions, see the manuel's API.


```julia
# machine information for reproducibility
versioninfo()
```

    Julia Version 1.6.0
    Commit f9720dc2eb (2021-03-24 12:55 UTC)
    Platform Info:
      OS: macOS (x86_64-apple-darwin19.6.0)
      CPU: Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz
      WORD_SIZE: 64
      LIBM: libopenlibm
      LLVM: libLLVM-11.0.1 (ORCJIT, skylake)
    Environment:
      JULIA_NUM_THREADS = 8



```julia
# load necessary packages for running all examples below
using MendelIHT
using SnpArrays
using DataFrames
using Distributions
using Random
using LinearAlgebra
using GLM
using DelimitedFiles
using Statistics
using BenchmarkTools

BLAS.set_num_threads(1) # prevent over subscription with multithreading & BLAS
Random.seed!(1111)      # set seed for reproducibility
```




    MersenneTwister(1111)



## Using MendelIHT.jl

Users are exposed to 2 levels of interface:
+ Wrapper functions [iht()](https://openmendel.github.io/MendelIHT.jl/latest/man/api/#MendelIHT.iht) and [cross_validate()](https://openmendel.github.io/MendelIHT.jl/latest/man/api/#MendelIHT.cross_validate). These functions are simple scripts that import data, runs IHT, and writes result to output automatically. Since they are very simplistic, they might fail for whatever reason (please file an issue on GitHub). If so, please use:
+ Core functions [fit_iht()](https://openmendel.github.io/MendelIHT.jl/latest/man/api/#MendelIHT.fit_iht) and [cv_iht()](https://openmendel.github.io/MendelIHT.jl/latest/man/api/#MendelIHT.cv_iht). Input arguments for these functions must be first imported into Julia by the user manually.

Below we use numerous examples to illustrate how to use these functions separately. 

## Parallel computing


To exploit `MendelIHT.jl`'s parallel processing, [start Julia with multiple threads](https://docs.julialang.org/en/v1/manual/multi-threading/#Starting-Julia-with-multiple-threads). Two levels of shared-memory parallelism is supported.
+ (genotype-matrix)-(vector or matrix) multiplication
+ cross validation

**Note**: If one is running IHT on `Matrix{Float64}`, BLAS should NOT run with multiple threads (execute `BLAS.set_num_threads(1)` before running IHT). This prevents [oversubscription](https://ieeexplore.ieee.org/document/5470434). 


```julia
Threads.nthreads() # show number of threads
```




    8



## Example 1: GWAS with PLINK/BGEN/VCF files

In this example, our data are stored in binary PLINK files:

+ `normal.bed`
+ `normal.bim`
+ `normal.fam`

which contains simulated (Gaussian) phenotypes for $n=1000$ samples and $p=10,000$ SNPs. There are $8$ causal variants and 2 causal non-genetic covariates (intercept and sex). 

These data are present under `MendelIHT/data` directory.


```julia
# change directory to where example data is located
cd(normpath(MendelIHT.datadir()))

# show working directory
@show pwd() 

# show files in current directory
readdir()
```

    pwd() = "/Users/biona001/.julia/dev/MendelIHT/data"





    23-element Vector{String}:
     ".DS_Store"
     "README.md"
     "covariates.txt"
     "cviht.summary.txt"
     "iht.beta.txt"
     "iht.cov.txt"
     "iht.summary.txt"
     "multivariate.bed"
     "multivariate.bim"
     "multivariate.fam"
     "multivariate.phen"
     "multivariate.trait.cov"
     "normal.bed"
     "normal.bim"
     "normal.fam"
     "normal_true_beta.txt"
     "phenotypes.txt"
     "sim.bed"
     "sim.bim"
     "sim.covariates.txt"
     "sim.fam"
     "sim.phenotypes.txt"
     "simulate.jl"



Here `covariates.txt` contains non-genetic covariates (intercept + sex), `normal.bed/bim/fam` are the PLINK files storing genetic covariates, `phenotypes.txt` are phenotypes for each sample, `normal_true_beta.txt` is the true statistical model used to generate the phenotypes, and `simulate.jl` is the script used to generate all the files. 

### Step 1: Run cross validation to determine best model size

See the [cross_validate](https://openmendel.github.io/MendelIHT.jl/latest/man/api/#MendelIHT.cross_validate) function API. Here, 
+ We run 5 fold cross validation (default `q`) across k = 1, 2, ..., 20.
+ Phenotypes are stored in the 6th column of `.fam` file
+ Other covariates are stored separately (which includes a column of 1 as intercept). Here we cross validate $k = 1,2,...20$. 

Note the first run might take awhile because Julia needs to compile the code. See FAQ. 


```julia
mses = cross_validate("normal", Normal, covariates="covariates.txt", phenotypes=6, path=1:20,);

# Alternative syntax
# mses = cross_validate("normal", Normal, covariates="covariates.txt", phenotypes=6, path=[1, 5, 10, 15, 20]) # test k = 1, 5, 10, 15, 20
# mses = cross_validate("normal", Normal, covariates="covariates.txt", phenotypes="phenotypes.txt", path=1:20) # when phenotypes are stored separately
```

    ****                   MendelIHT Version 1.4.1                  ****
    ****     Benjamin Chu, Kevin Keys, Chris German, Hua Zhou       ****
    ****   Jin Zhou, Eric Sobel, Janet Sinsheimer, Kenneth Lange    ****
    ****                                                            ****
    ****                 Please cite our paper!                     ****
    ****         https://doi.org/10.1093/gigascience/giaa044        ****
    


    [32mCross validating...100%|████████████████████████████████| Time: 0:00:03[39m


    
    
    Crossvalidation Results:
    	k	MSE
    	1	743.1703938637883
    	2	550.1707865831861
    	3	426.4937801368892
    	4	336.20365731861745
    	5	296.0672451743466
    	6	233.02850102286234
    	7	197.94215895091278
    	8	199.6451087657394
    	9	201.54148479914127
    	10	207.96968107938025
    	11	212.9172082563968
    	12	215.32570044375092
    	13	220.99781565117684
    	14	220.78097392409862
    	15	224.33931887771
    	16	220.7001228820031
    	17	226.6527593460433
    	18	227.36164871842863
    	19	237.23200258515894
    	20	238.24759588500916
    
    Best k = 7
    


Do not be alarmed if you get slightly different numbers, because cross validation breaks data into training/testing randomly. Set a seed by `Random.seed!(1234)` if you want reproducibility.

!!! note

    For VCF (`.vcf` or `.vcf.gz` and BGEN inputs, one simply add the file extensions to the wrapper functions. For instance, `cross_validate("normal.vcf.gz", Normal`) for VCF and `mses = cross_validate("normal.bgen", Normal)`. Note for BGEN, sample file name should be `normal.sample`. 

### Step 2: Run IHT on best k

See the [iht](https://openmendel.github.io/MendelIHT.jl/latest/man/api/#MendelIHT.iht) function API.

According to cross validation, `k = 7` achieves the minimum MSE. Thus we run IHT on the full dataset.


```julia
result = iht("normal", 7, Normal, covariates="covariates.txt", phenotypes=6)
```

    ****                   MendelIHT Version 1.4.1                  ****
    ****     Benjamin Chu, Kevin Keys, Chris German, Hua Zhou       ****
    ****   Jin Zhou, Eric Sobel, Janet Sinsheimer, Kenneth Lange    ****
    ****                                                            ****
    ****                 Please cite our paper!                     ****
    ****         https://doi.org/10.1093/gigascience/giaa044        ****
    
    Running sparse linear regression
    Number of threads = 8
    Link functin = IdentityLink()
    Sparsity parameter (k) = 7
    Prior weight scaling = off
    Doubly sparse projection = off
    Debias = off
    Max IHT iterations = 200
    Converging when tol < 0.0001 and iteration ≥ 5:
    
    Iteration 1: loglikelihood = -1403.6085154464329, backtracks = 0, tol = 0.8141937613701785
    Iteration 2: loglikelihood = -1397.922430744325, backtracks = 0, tol = 0.017959863148623176
    Iteration 3: loglikelihood = -1397.8812223841496, backtracks = 0, tol = 0.001989846075839033
    Iteration 4: loglikelihood = -1397.8807476657355, backtracks = 0, tol = 0.00016446741159857614
    Iteration 5: loglikelihood = -1397.8807416751808, backtracks = 0, tol = 2.0482155566893502e-5





    
    IHT estimated 7 nonzero SNP predictors and 2 non-genetic predictors.
    
    Compute time (sec):     0.028419017791748047
    Final loglikelihood:    -1397.8807416751808
    SNP PVE:                0.8343751445053728
    Iterations:             5
    
    Selected genetic predictors:
    [1m7×2 DataFrame[0m
    [1m Row [0m│[1m Position [0m[1m Estimated_β [0m
    [1m     [0m│[90m Int64    [0m[90m Float64     [0m
    ─────┼───────────────────────
       1 │     3137     0.424376
       2 │     4246     0.52343
       3 │     4717     0.922857
       4 │     6290    -0.677832
       5 │     7755    -0.542983
       6 │     8375    -0.792813
       7 │     9415    -2.17998
    
    Selected nongenetic predictors:
    [1m2×2 DataFrame[0m
    [1m Row [0m│[1m Position [0m[1m Estimated_β [0m
    [1m     [0m│[90m Int64    [0m[90m Float64     [0m
    ─────┼───────────────────────
       1 │        1     1.65223
       2 │        2     0.749865



The convergence criteria can be tuned by keywords `tol` and `min_iter`. 

### Step 3: Examine results

IHT picked 7 SNPs. The `Position` argument corresponds to the order in which the SNP appeared in the PLINK file, and the `Estimated_β` argument is the estimated effect size for the selected SNPs. To extract more information (for instance to extract `rs` IDs), we can do


```julia
snpdata = SnpData("normal")                   # import PLINK information
snps_idx = findall(!iszero, result.beta)      # indices of SNPs selected by IHT
selected_snps = snpdata.snp_info[snps_idx, :] # see which SNPs are selected
@show selected_snps;
```

    selected_snps = 7×6 DataFrame
     Row │ chromosome  snpid    genetic_distance  position  allele1  allele2
         │ String      String   Float64           Int64     String   String
    ─────┼───────────────────────────────────────────────────────────────────
       1 │ 1           snp3137               0.0         1  1        2
       2 │ 1           snp4246               0.0         1  1        2
       3 │ 1           snp4717               0.0         1  1        2
       4 │ 1           snp6290               0.0         1  1        2
       5 │ 1           snp7755               0.0         1  1        2
       6 │ 1           snp8375               0.0         1  1        2
       7 │ 1           snp9415               0.0         1  1        2


The table above displays the SNP information for the selected SNPs. Because there's only 7 causal SNPs, we found all of them. The 2 non-genetic covariates represented intercept and sex, with true effect size 1.5 and 1.0. Since data is simulated, the fields `chromosome`, `snpid`, `genetic_distance`, `position`, `allele1`, and `allele2` are fake. 

## Example 2: How to simulate data

Here we demonstrate how to use `MendelIHT.jl` and [SnpArrays.jl](https://github.com/OpenMendel/SnpArrays.jl) to simulate data, allowing you to design your own genetic studies. Note:
+ For more complex simulation, please use the module [TraitSimulations.jl](https://github.com/OpenMendel/TraitSimulation.jl).  
+ All linear algebra routines involving PLINK files are handled by [SnpArrays.jl](https://github.com/OpenMendel/SnpArrays.jl). 

First we simulate an example PLINK trio (`.bim`, `.bed`, `.fam`) and non-genetic covariates, then we illustrate how to import them. For simplicity, let us simulated indepent SNPs with binary phenotypes. Explicitly, our model is:

$$y_i \sim \rm Bernoulli(\mathbf{x}_i^T\boldsymbol\beta)$$
$$x_{ij} \sim \rm Binomial(2, \rho_j)$$
$$\rho_j \sim \rm Uniform(0, 0.5)$$
$$\beta_i \sim \rm N(0, 1)$$
$$\beta_{\rm intercept} = 1$$
$$\beta_{\rm sex} = 1.5$$


```julia
n = 1000            # number of samples
p = 10000           # number of SNPs
k = 10              # 10 causal SNPs
d = Bernoulli       # Binary (continuous) phenotypes
l = LogitLink()     # canonical link function

# set random seed
Random.seed!(0)

# simulate `sim.bed` file with no missing data
x = simulate_random_snparray("sim.bed", n, p)
xla = SnpLinAlg{Float64}(x, model=ADDITIVE_MODEL, center=true, scale=true, impute=true) 

# 2 nongenetic covariate: first column is the intercept, second column is sex: 0 = male 1 = female
z = ones(n, 2) 
z[:, 2] .= rand(0:1, n)
standardize!(@view(z[:, 2:end])) 

# randomly set genetic predictors where causal βᵢ ~ N(0, 1)
true_b = zeros(p) 
true_b[1:k] = randn(k)
shuffle!(true_b)

# find correct position of genetic predictors
correct_position = findall(!iszero, true_b)

# define effect size of non-genetic predictors: intercept & sex
true_c = [1.0; 1.5] 

# simulate phenotype using genetic and nongenetic predictors
prob = GLM.linkinv.(l, xla * true_b .+ z * true_c) # note genotype-vector multiplication is done with `xla`
y = [rand(d(i)) for i in prob]
y = Float64.(y); # turn y into floating point numbers

# create `sim.bim` and `sim.bam` files using phenotype
make_bim_fam_files(x, y, "sim")

#save covariates and phenotypes (without header)
writedlm("sim.covariates.txt", z, ',')
writedlm("sim.phenotypes.txt", y)
```

!!! note

    Please **standardize** (or at least center) your non-genetic covariates. If you use our `iht()` or `cross_validation()` functions, standardization is automatic. For genotype matrix, `SnpLinAlg` efficiently achieves this standardization. For non-genetic covariates, please use the built-in function `standardize!`. 

## Example 3: Logistic/Poisson/Negative-binomial GWAS

In Example 2, we simulated binary phenotypes, genotypes, non-genetic covariates, and we know true $k = 10$. Let's try running a logistic regression (i.e. phenotype follows the Bernoulli distribution) on this data. 


```julia
result = iht("sim", 10, Bernoulli, covariates="sim.covariates.txt")
```

    ****                   MendelIHT Version 1.4.1                  ****
    ****     Benjamin Chu, Kevin Keys, Chris German, Hua Zhou       ****
    ****   Jin Zhou, Eric Sobel, Janet Sinsheimer, Kenneth Lange    ****
    ****                                                            ****
    ****                 Please cite our paper!                     ****
    ****         https://doi.org/10.1093/gigascience/giaa044        ****
    
    Running sparse logistic regression
    Number of threads = 8
    Link functin = LogitLink()
    Sparsity parameter (k) = 10
    Prior weight scaling = off
    Doubly sparse projection = off
    Debias = off
    Max IHT iterations = 200
    Converging when tol < 0.0001 and iteration ≥ 5:
    
    Iteration 1: loglikelihood = -410.3429870797691, backtracks = 0, tol = 0.634130944297718
    Iteration 2: loglikelihood = -355.96269238167594, backtracks = 0, tol = 0.23373909459507045
    Iteration 3: loglikelihood = -335.19699443343046, backtracks = 0, tol = 0.1883878956755205
    Iteration 4: loglikelihood = -326.72483097632033, backtracks = 1, tol = 0.11662243126023769
    Iteration 5: loglikelihood = -323.42465587337426, backtracks = 1, tol = 0.1420748329251797
    Iteration 6: loglikelihood = -321.93583078185304, backtracks = 1, tol = 0.026234221625522528
    Iteration 7: loglikelihood = -321.14096662573917, backtracks = 2, tol = 0.01403839948881654
    Iteration 8: loglikelihood = -320.42084987563976, backtracks = 2, tol = 0.13238847469548456
    Iteration 9: loglikelihood = -319.96246645074956, backtracks = 1, tol = 0.011420657379532422
    Iteration 10: loglikelihood = -319.70632025148103, backtracks = 2, tol = 0.00906035620905566
    Iteration 11: loglikelihood = -319.5850116168617, backtracks = 3, tol = 0.00526542665002791
    Iteration 12: loglikelihood = -319.48907690537277, backtracks = 3, tol = 0.004636845354902531
    Iteration 13: loglikelihood = -319.4139596352546, backtracks = 3, tol = 0.00408655714336715
    Iteration 14: loglikelihood = -319.35538714433477, backtracks = 3, tol = 0.003602878389767637
    Iteration 15: loglikelihood = -319.3098337852715, backtracks = 3, tol = 0.0031763270937268033
    Iteration 16: loglikelihood = -319.2744765345821, backtracks = 3, tol = 0.0027994055509261194
    Iteration 17: loglikelihood = -319.2470792984031, backtracks = 3, tol = 0.002466034977718209
    Iteration 18: loglikelihood = -319.22588090965274, backtracks = 3, tol = 0.002171162642890488
    Iteration 19: loglikelihood = -319.2094997186901, backtracks = 3, tol = 0.001910458491633558
    Iteration 20: loglikelihood = -319.196855221667, backtracks = 3, tol = 0.0016801251066566392
    Iteration 21: loglikelihood = -319.1871046680043, backtracks = 3, tol = 0.0014767880705742493
    Iteration 22: loglikelihood = -319.1795922518739, backtracks = 3, tol = 0.0012974307079079153
    Iteration 23: loglikelihood = -319.17380866099757, backtracks = 3, tol = 0.0011393509372972647
    Iteration 24: loglikelihood = -319.16935904315795, backtracks = 3, tol = 0.0010001288849418076
    Iteration 25: loglikelihood = -319.1659377513872, backtracks = 3, tol = 0.0008775999638190499
    Iteration 26: loglikelihood = -319.16330850846356, backtracks = 3, tol = 0.0007698310622097819
    Iteration 27: loglikelihood = -319.16128887828387, backtracks = 3, tol = 0.0006750988244862079
    Iteration 28: loglikelihood = -319.1597381430372, backtracks = 3, tol = 0.0005918695947373657
    Iteration 29: loglikelihood = -319.1585478622643, backtracks = 3, tol = 0.0005187808423979859
    Iteration 30: loglikelihood = -319.1576345361046, backtracks = 3, tol = 0.0004546239877395596
    Iteration 31: loglikelihood = -319.15693391434667, backtracks = 3, tol = 0.0003983285784910115
    Iteration 32: loglikelihood = -319.1563965892339, backtracks = 3, tol = 0.000348947774612114
    Iteration 33: loglikelihood = -319.15598458731, backtracks = 3, tol = 0.00030564509321785363
    Iteration 34: loglikelihood = -319.15566873708605, backtracks = 3, tol = 0.0002676823575045028
    Iteration 35: loglikelihood = -319.15542663816296, backtracks = 3, tol = 0.00023440878567259604
    Iteration 36: loglikelihood = -319.15524109586636, backtracks = 3, tol = 0.00020525114972271962
    Iteration 37: loglikelihood = -319.1550989157, backtracks = 3, tol = 0.00017970493004996346
    Iteration 38: loglikelihood = -319.15498997558825, backtracks = 3, tol = 0.00015732638998333223
    Iteration 39: loglikelihood = -319.1549065123602, backtracks = 3, tol = 0.00013772549451164306
    Iteration 40: loglikelihood = -319.1548425732977, backtracks = 3, tol = 0.00012055959910162006
    Iteration 41: loglikelihood = -319.15479359478843, backtracks = 3, tol = 0.00010552783734578194
    Iteration 42: loglikelihood = -319.154756078745, backtracks = 3, tol = 9.236613986923397e-5





    
    IHT estimated 10 nonzero SNP predictors and 2 non-genetic predictors.
    
    Compute time (sec):     0.41863417625427246
    Final loglikelihood:    -319.154756078745
    SNP PVE:                0.5719420735919515
    Iterations:             42
    
    Selected genetic predictors:
    [1m10×2 DataFrame[0m
    [1m Row [0m│[1m Position [0m[1m Estimated_β [0m
    [1m     [0m│[90m Int64    [0m[90m Float64     [0m
    ─────┼───────────────────────
       1 │      520     0.400331
       2 │      715    -0.663321
       3 │      778    -0.497369
       4 │     1357     1.25802
       5 │     3266    -0.543574
       6 │     5492    -0.879088
       7 │     5800     0.595109
       8 │     6049    -0.488677
       9 │     6301    -2.22547
      10 │     7059     0.797472
    
    Selected nongenetic predictors:
    [1m2×2 DataFrame[0m
    [1m Row [0m│[1m Position [0m[1m Estimated_β [0m
    [1m     [0m│[90m Int64    [0m[90m Float64     [0m
    ─────┼───────────────────────
       1 │        1      1.06077
       2 │        2      1.41398



Since data is simulated, we can compare IHT's estimated effect size with the truth. 


```julia
[true_b[correct_position] result.beta[correct_position]]
```




    10×2 Matrix{Float64}:
     -0.787272  -0.663321
     -0.456783  -0.497369
      1.12735    1.25802
     -0.276592  -0.543574
      0.185925   0.0
     -0.891023  -0.879088
      0.498309   0.595109
     -2.15515   -2.22547
      0.166931   0.0
      0.82265    0.797472



**Conclusions:**
+ The 1st column are the true beta values, and the 2nd column is the estimated values. 
+ IHT found 8/10 genetic predictors, and estimates are reasonably close to truth. 
+ IHT missed SNPs with small effect size. With increased sample size, these small effects can be detected.
+ The estimated non-genetic effect size is also very close to the truth (1.0 and 1.5). 


```julia
# remove simulated data once they are no longer needed
rm("sim.bed", force=true)
rm("sim.bim", force=true)
rm("sim.fam", force=true)
rm("sim.covariates.txt", force=true)
rm("sim.phenotypes.txt", force=true)
rm("iht.beta.txt", force=true)
rm("iht.summary.txt", force=true)
rm("cviht.summary.txt", force=true)
```

## Example 4: Running IHT on general matrices

To run IHT on numeric matrices, one must call [fit_iht](https://openmendel.github.io/MendelIHT.jl/latest/man/api/#MendelIHT.fit_iht) and [cv_iht](https://openmendel.github.io/MendelIHT.jl/latest/man/api/#MendelIHT.cv_iht) directly. These functions are designed to work on `AbstractArray{T, 2}` type where `T` is a `Float64` or `Float32`. 

Note the vector of 1s (intercept) shouldn't be included in the design matrix itself, as it will be automatically included.

First we simulate some count response using the model:

$$y_i \sim \rm Poisson(\mathbf{x}_i^T \boldsymbol\beta)$$
$$x_{ij} \sim \rm Normal(0, 1)$$
$$\beta_i \sim \rm N(0, 0.3)$$


```julia
n = 1000             # number of samples
p = 10000            # number of SNPs
k = 10               # 9 causal predictors + intercept
d = Poisson          # Response distribution (count data)
l = LogLink()        # canonical link

# set random seed for reproducibility
Random.seed!(2020)

# simulate design matrix
x = randn(n, p)

# simulate response, true model b, and the correct non-0 positions of b
true_b = zeros(p)
true_b[1:k] .= rand(Normal(0, 0.5), k)
shuffle!(true_b)
intercept = 1.0
correct_position = findall(!iszero, true_b)
prob = GLM.linkinv.(l, intercept .+ x * true_b)
clamp!(prob, -20, 20) # prevents overflow
y = [rand(d(i)) for i in prob]
y = Float64.(y); # convert phenotypes to double precision
```

Now we have the response $y$, design matrix $x$. Let's run IHT and compare with truth.


```julia
# first run cross validation 
mses = cv_iht(y, x, path=1:20, d=Poisson(), l=LogLink());
```

    ****                   MendelIHT Version 1.4.1                  ****
    ****     Benjamin Chu, Kevin Keys, Chris German, Hua Zhou       ****
    ****   Jin Zhou, Eric Sobel, Janet Sinsheimer, Kenneth Lange    ****
    ****                                                            ****
    ****                 Please cite our paper!                     ****
    ****         https://doi.org/10.1093/gigascience/giaa044        ****
    


    [32mCross validating...100%|████████████████████████████████| Time: 0:00:04[39m


    
    
    Crossvalidation Results:
    	k	MSE
    	1	706.7023831995504
    	2	563.0550969636545
    	3	475.3126336967697
    	4	448.33305489844025
    	5	473.3927061149886
    	6	475.9412876637349
    	7	511.93220168171354
    	8	536.4191695297267
    	9	543.6710949911146
    	10	546.9984660275643
    	11	566.3240592279342
    	12	582.0306543995698
    	13	572.2797797481932
    	14	555.79078283183
    	15	604.8674191407598
    	16	596.6516289181405
    	17	620.9209742466778
    	18	617.8251652635175
    	19	668.4065630346416
    	20	620.4559701381145
    
    Best k = 4
    


Now run IHT on the full dataset using the best k (achieved at k = 4)


```julia
result = fit_iht(y, x, k=argmin(mses), d=Poisson(), l=LogLink())
```

    ****                   MendelIHT Version 1.4.1                  ****
    ****     Benjamin Chu, Kevin Keys, Chris German, Hua Zhou       ****
    ****   Jin Zhou, Eric Sobel, Janet Sinsheimer, Kenneth Lange    ****
    ****                                                            ****
    ****                 Please cite our paper!                     ****
    ****         https://doi.org/10.1093/gigascience/giaa044        ****
    
    Running sparse Poisson regression
    Number of threads = 8
    Link functin = LogLink()
    Sparsity parameter (k) = 4
    Prior weight scaling = off
    Doubly sparse projection = off
    Debias = off
    Max IHT iterations = 200
    Converging when tol < 0.0001 and iteration ≥ 5:
    
    Iteration 1: loglikelihood = -2931.927168207526, backtracks = 0, tol = 0.3028304004126476
    Iteration 2: loglikelihood = -2463.976586409181, backtracks = 0, tol = 0.05258775986537314
    Iteration 3: loglikelihood = -2390.0609910861317, backtracks = 0, tol = 0.05578942533348056
    Iteration 4: loglikelihood = -2360.2573652460405, backtracks = 0, tol = 0.030501089537329825
    Iteration 5: loglikelihood = -2347.564682228364, backtracks = 0, tol = 0.021241566894705643
    Iteration 6: loglikelihood = -2341.213319235788, backtracks = 0, tol = 0.014911500576741359
    Iteration 7: loglikelihood = -2338.1595979203516, backtracks = 0, tol = 0.009977646130123972
    Iteration 8: loglikelihood = -2336.62260487827, backtracks = 0, tol = 0.007575531231741733
    Iteration 9: loglikelihood = -2335.880219053057, backtracks = 0, tol = 0.004805807684709317
    Iteration 10: loglikelihood = -2335.5141435762675, backtracks = 0, tol = 0.0037615233194204824
    Iteration 11: loglikelihood = -2335.3385905823416, backtracks = 0, tol = 0.002308369328965646
    Iteration 12: loglikelihood = -2335.253553769631, backtracks = 0, tol = 0.0018289326626755682
    Iteration 13: loglikelihood = -2335.213007797983, backtracks = 0, tol = 0.0011024772411982043
    Iteration 14: loglikelihood = -2335.193580900639, backtracks = 0, tol = 0.0008779579192619493
    Iteration 15: loglikelihood = -2335.1843486179923, backtracks = 0, tol = 0.0005244723959117778
    Iteration 16: loglikelihood = -2335.1799508662666, backtracks = 0, tol = 0.00041859562583677315
    Iteration 17: loglikelihood = -2335.177864471046, backtracks = 0, tol = 0.0002489580169555706
    Iteration 18: loglikelihood = -2335.1768735313717, backtracks = 0, tol = 0.0001989010930461795
    Iteration 19: loglikelihood = -2335.1764038008278, backtracks = 0, tol = 0.00011804464492615356
    Iteration 20: loglikelihood = -2335.176181018449, backtracks = 0, tol = 9.43540926080076e-5





    
    IHT estimated 4 nonzero SNP predictors and 1 non-genetic predictors.
    
    Compute time (sec):     0.11140608787536621
    Final loglikelihood:    -2335.176181018449
    SNP PVE:                0.09120222939725625
    Iterations:             20
    
    Selected genetic predictors:
    [1m4×2 DataFrame[0m
    [1m Row [0m│[1m Position [0m[1m Estimated_β [0m
    [1m     [0m│[90m Int64    [0m[90m Float64     [0m
    ─────┼───────────────────────
       1 │       83    -0.809399
       2 │      989     0.378437
       3 │     4294    -0.274581
       4 │     4459     0.16944
    
    Selected nongenetic predictors:
    [1m1×2 DataFrame[0m
    [1m Row [0m│[1m Position [0m[1m Estimated_β [0m
    [1m     [0m│[90m Int64    [0m[90m Float64     [0m
    ─────┼───────────────────────
       1 │        1      1.26924




```julia
# compare IHT result with truth
[true_b[correct_position] result.beta[correct_position]]
```




    10×2 Matrix{Float64}:
     -1.303      -0.809399
      0.585809    0.378437
     -0.0700563   0.0
     -0.0901341   0.0
     -0.0620201   0.0
     -0.441452   -0.274581
      0.271429    0.16944
     -0.164888    0.0
     -0.0790484   0.0
      0.0829054   0.0



Since many of the true $\beta$ are small, we were only able to find 4 true signals (+ intercept). 

**Conclusion:** In this example, we ran IHT on count response with a general `Matrix{Float64}` design matrix. Since we used simulated data, we could compare IHT's estimates with the truth. 

## Example 5: Group IHT 

In this example, we show how to include group information to perform doubly sparse projections. Here the final model would contain at most $J = 5$ groups where each group contains limited number of (prespecified) SNPs. For simplicity, we assume the sparsity parameter $k$ is known. 

### Data simulation
To illustrate the effect of group IHT, we generated correlated genotype matrix according to the procedure outlined in [our paper](https://www.biorxiv.org/content/biorxiv/early/2019/11/19/697755.full.pdf). In this example, each SNP belongs to 1 of 500 disjoint groups containing 20 SNPs each; $j = 5$ distinct groups are each assigned $1,2,...,5$ causal SNPs with effect sizes randomly chosen from $\{−0.2,0.2\}$. In all there 15 causal SNPs.  For grouped-IHT, we assume perfect group information. That is, the selected groups containing 1∼5 causative SNPs are assigned maximum within-group sparsity $\lambda_g = 1,2,...,5$. The remaining groups are assigned $\lambda_g = 1$ (i.e. only 1 active predictor are allowed).


```julia
# define problem size
d = NegativeBinomial
l = LogLink()
n = 1000
p = 10000
block_size = 20                  #simulation parameter
num_blocks = Int(p / block_size) #simulation parameter

# set seed
Random.seed!(1234)

# assign group membership
membership = collect(1:num_blocks)
g = zeros(Int64, p)
for i in 1:length(membership)
    for j in 1:block_size
        cur_row = block_size * (i - 1) + j
        g[block_size*(i - 1) + j] = membership[i]
    end
end

#simulate correlated snparray
x = simulate_correlated_snparray("tmp.bed", n, p)
intercept = 0.5
x_float = convert(Matrix{Float64}, x, model=ADDITIVE_MODEL, center=true, scale=true)

#simulate true model, where 5 groups each with 1~5 snps contribute
true_b = zeros(p)
true_groups = randperm(num_blocks)[1:5]
sort!(true_groups)
within_group = [randperm(block_size)[1:1], randperm(block_size)[1:2], 
                randperm(block_size)[1:3], randperm(block_size)[1:4], 
                randperm(block_size)[1:5]]
correct_position = zeros(Int64, 15)
for i in 1:5
    cur_group = block_size * (true_groups[i] - 1)
    cur_group_snps = cur_group .+ within_group[i]
    start, last = Int(i*(i-1)/2 + 1), Int(i*(i+1)/2)
    correct_position[start:last] .= cur_group_snps
end
for i in 1:15
    true_b[correct_position[i]] = rand(-1:2:1) * 0.2
end
sort!(correct_position)

# simulate phenotype
r = 10 #nuisance parameter
μ = GLM.linkinv.(l, intercept .+ x_float * true_b)
clamp!(μ, -20, 20)
prob = 1 ./ (1 .+ μ ./ r)
y = [rand(d(r, i)) for i in prob] #number of failures before r success occurs
y = Float64.(y);
```


```julia
#run IHT without groups
ungrouped = fit_iht(y, x_float, k=15, d=NegativeBinomial(), l=LogLink(), verbose=false)

#run doubly sparse (group) IHT by specifying maximum number of SNPs for each group (in order)
max_group_snps = ones(Int, num_blocks)
max_group_snps[true_groups] .= collect(1:5)
variable_group = fit_iht(y, x_float, d=NegativeBinomial(), l=LogLink(), k=max_group_snps, J=5, group=g, verbose=false);
```


```julia
#check result
correct_position = findall(!iszero, true_b)
compare_model = DataFrame(
    position = correct_position,
    correct_β = true_b[correct_position],
    ungrouped_IHT_β = ungrouped.beta[correct_position], 
    grouped_IHT_β = variable_group.beta[correct_position])
@show compare_model
println("\n")

#clean up. Windows user must do this step manually (outside notebook/REPL)
rm("tmp.bed", force=true)
```

    compare_model = 15×4 DataFrame
     Row │ position  correct_β  ungrouped_IHT_β  grouped_IHT_β
         │ Int64     Float64    Float64          Float64
    ─────┼─────────────────────────────────────────────────────
       1 │      126        0.2         0.193695       0.179699
       2 │     5999       -0.2        -0.238721      -0.221097
       3 │     6000       -0.2        -0.139758      -0.145219
       4 │     6344       -0.2        -0.210029      -0.204669
       5 │     6359        0.2         0.212363       0.220925
       6 │     6360       -0.2        -0.182878      -0.186936
       7 │     7050       -0.2        -0.203551      -0.109019
       8 │     7051       -0.2        -0.286369      -0.270932
       9 │     7058       -0.2        -0.216709       0.0
      10 │     7059        0.2         0.185836       0.0
      11 │     7188        0.2         0.0            0.136334
      12 │     7190       -0.2         0.0           -0.147534
      13 │     7192        0.2         0.173384       0.173011
      14 │     7195       -0.2        -0.233133      -0.225417
      15 │     7198        0.2         0.0            0.131244
    
    


**Conclusion:** Grouped IHT found 1 extra SNP, but ungrouped IHT also recovered 2 SNPs that grouped IHT didn't find. 

## Example 6: Linear Regression with prior weights

In this example, we show how to include (predetermined) prior weights for each SNP. You can check out [our paper](https://www.biorxiv.org/content/biorxiv/early/2019/11/19/697755.full.pdf) for references of why/how to choose these weights. In this case, we mimic our paper and randomly set $10\%$ of all SNPs to have a weight of $2.0$. Other predictors have weight of $1.0$. All causal SNPs have weights of $2.0$. Under this scenario, SNPs with weight $2.0$ is twice as likely to enter the model identified by IHT. 

Our model is simulated as:

$$y_i \sim \mathbf{x}_i^T\mathbf{\beta} + \epsilon_i$$
$$x_{ij} \sim \rm Binomial(2, \rho_j)$$
$$\rho_j \sim \rm Uniform(0, 0.5)$$
$$\epsilon_i \sim \rm N(0, 1)$$
$$\beta_i \sim \rm N(0, 0.25)$$


```julia
d = Normal
l = IdentityLink()
n = 1000
p = 10000
k = 10

#random seed
Random.seed!(4)

# construct snpmatrix, covariate files, and true model b
x = simulate_random_snparray("tmp.bed", n, p)
X = convert(Matrix{Float64}, x, center=true, scale=true)
intercept = 1.0
    
#define true_b 
true_b = zeros(p)
true_b[1:10] .= rand(Normal(0, 0.25), k)
shuffle!(true_b)
correct_position = findall(!iszero, true_b)

#simulate phenotypes (e.g. vector y)
prob = GLM.linkinv.(l, intercept .+ X * true_b)
clamp!(prob, -20, 20)
y = [rand(d(i)) for i in prob]
y = Float64.(y);

# construct weight vector
w = ones(p)
w[correct_position] .= 2.0
one_tenth = round(Int, p/10)
idx = rand(1:p, one_tenth)
w[idx] .= 2.0; #randomly set ~1/10 of all predictors to 2
```


```julia
#run weighted and unweighted IHT
unweighted = fit_iht(y, X, k=10, d=Normal(), l=IdentityLink(), verbose=false)
weighted   = fit_iht(y, X, k=10, d=Normal(), l=IdentityLink(), verbose=false, weight=w)

#check result
compare_model = DataFrame(
    position    = correct_position,
    correct     = true_b[correct_position],
    unweighted  = unweighted.beta[correct_position], 
    weighted    = weighted.beta[correct_position])
@show compare_model
println("\n")

#clean up. Windows user must do this step manually (outside notebook/REPL)
rm("tmp.bed", force=true)
```

    compare_model = 10×4 DataFrame
     Row │ position  correct     unweighted  weighted
         │ Int64     Float64     Float64     Float64
    ─────┼─────────────────────────────────────────────
       1 │     1264   0.252886     0.272761   0.282661
       2 │     1506  -0.0939841    0.0       -0.119236
       3 │     4866  -0.227394    -0.242687  -0.232847
       4 │     5778  -0.510488    -0.512337  -0.501374
       5 │     5833  -0.311969    -0.327575  -0.322659
       6 │     5956  -0.0548168    0.0        0.0
       7 │     6378  -0.0155173    0.0        0.0
       8 │     7007  -0.123301     0.0        0.0
       9 │     7063   0.0183886    0.0        0.0
      10 │     7995  -0.102122    -0.118633  -0.132814
    
    


**Conclusion**: weighted IHT found 1 extra predictor than non-weighted IHT.

## Example 7: Multivariate IHT

When there is multiple quantitative traits, analyzing them jointly is known to be superior than conducting multiple univariate-GWAS ([ref1](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0095923), [ref2](https://www.nature.com/articles/srep38837)). When `MendelIHT.jl` performs a multivariate analysis, 

+ IHT estimates effect of every SNP (covariate) conditioned on every other SNP across traits
+ IHT outputs an estimated covariate matrix among traits
+ IHT estimates proportion of trait variance explained by the genetic predictors


### First simulate data

With $r$ traits, each sample's phenotype $\mathbf{y}_{i} \in \mathbb{R}^{n \times 1}$ is simulated under

$$\mathbf{y}_{i}^{r \times 1} \sim N(\mathbf{B}^{r \times p}\mathbf{x}_{i}^{p \times 1}, \ \ \Sigma_{r \times r})$$

This model assumes each sample is independent. The covariance among traits is specified by $\Sigma$.


```julia
n = 1000  # number of samples
p = 10000 # number of SNPs
k = 10    # number of causal SNPs
r = 2     # number of traits

# set random seed for reproducibility
Random.seed!(2021)

# simulate `.bed` file with no missing data
x = simulate_random_snparray("multivariate.bed", n, p)
xla = SnpLinAlg{Float64}(x, model=ADDITIVE_MODEL, impute=false, center=true, scale=true) 

# intercept is the only nongenetic covariate
z = ones(n, 1)
intercepts = randn(r)' # each trait have different intercept

# simulate response y, true model b, and the correct non-0 positions of b
Y, true_Σ, true_b, correct_position = simulate_random_response(xla, k, r, Zu=z*intercepts, overlap=0)
writedlm("multivariate.trait.cov", true_Σ, ',')

# create `.bim` and `.bam` files using phenotype
make_bim_fam_files(x, Y, "multivariate")

# also save phenotypes in separate file
open("multivariate.phen", "w") do io
    for i in 1:n
        println(io, Y[i, 1], ",", Y[i, 2])
    end
end
```

For multivariate IHT, one can store multiple phenotpyes as extra columns in the `.fam` file. The first 10 rows of such a file is visualized below:


```julia
;head multivariate.fam
```

    1	1	0	0	1	0.11302744016863553	-0.7554260335256895
    2	1	0	0	1	1.9891964726499531	-0.45289178000961794
    3	1	0	0	1	-3.439363162809635	1.842833018537565
    4	1	0	0	1	4.04029968770823	3.4869907320499474
    5	1	0	0	1	2.6565963705920983	0.8105429321467232
    6	1	0	0	1	-0.16399924513126818	3.7682978263463855
    7	1	0	0	1	2.274455154523604	-0.3711839247250286
    8	1	0	0	1	-2.0092329751410896	-0.5206796904236644
    9	1	0	0	1	-3.204538512643233	2.6179242790617323
    10	1	0	0	1	-3.8119298244977333	3.212156674633338


Phenotypes can also be stored in a separate file. In this case, we require each subject's phenotype to occupy a different row. The file should not include a header line. Each row should be listed in the same order as in the PLINK and (for multivariate analysis) be comma separated. For example, the first 10 rows of such a file looks like:


```julia
;head multivariate.phen
```

    0.11302744016863553,-0.7554260335256895
    1.9891964726499531,-0.45289178000961794
    -3.439363162809635,1.842833018537565
    4.04029968770823,3.4869907320499474
    2.6565963705920983,0.8105429321467232
    -0.16399924513126818,3.7682978263463855
    2.274455154523604,-0.3711839247250286
    -2.0092329751410896,-0.5206796904236644
    -3.204538512643233,2.6179242790617323
    -3.8119298244977333,3.212156674633338


### Run multivariate IHT

The values specified in `path` corresponds to the total number of non-zero `k` to be tested in cross validation. Since we simulated 10 true genetic predictors, $k_{true} = 10$. Because non-genetic covariates are not specified, an intercept with automatically be included. Below give 3 ways of doing the same thing.


```julia
# genotypes stored in multivariate.bed and phenotypes in multivariate.phen
mses = cross_validate("multivariate", MvNormal, phenotypes="multivariate.phen", path=1:20);

# use columns 6 and 7 of .fam as phenotypes
# mses = cross_validate("multivariate", MvNormal, phenotypes=[6, 7], path=1:20)

# run directly with xla and Y (note: transpose is necessary to make samples into columns)
# mses = cv_iht(Matrix(Y'), Transpose(xla), path=1:20)
```

    ****                   MendelIHT Version 1.4.1                  ****
    ****     Benjamin Chu, Kevin Keys, Chris German, Hua Zhou       ****
    ****   Jin Zhou, Eric Sobel, Janet Sinsheimer, Kenneth Lange    ****
    ****                                                            ****
    ****                 Please cite our paper!                     ****
    ****         https://doi.org/10.1093/gigascience/giaa044        ****
    


    [32mCross validating...100%|████████████████████████████████| Time: 0:00:03[39m


    
    
    Crossvalidation Results:
    	k	MSE
    	1	2894.951542220578
    	2	2404.2611566806236
    	3	2118.3458041809804
    	4	2003.0321765449573
    	5	1836.0954694153666
    	6	1810.8565487650512
    	7	1778.2006202357584
    	8	1739.5526656101028
    	9	1756.8768982533495
    	10	1749.0196878126512
    	11	1758.6127874414663
    	12	1780.6413839078918
    	13	1769.9360596010902
    	14	1802.66488874727
    	15	1802.0456455884719
    	16	1805.1748761415956
    	17	1834.8654353415632
    	18	1811.30688836247
    	19	1809.0070993669078
    	20	1813.2736422827502
    
    Best k = 8
    


The best MSE is achieved at $k=8$. Let's run IHT with this estimate of $k$. Similarly, there are multiple ways to do so:


```julia
# genotypes stored in multivariate.bed and phenotypes in multivariate.phen
result = iht("multivariate", 8, MvNormal, phenotypes="multivariate.phen")

# genotypes stored in multivariate.bed use columns 6 and 7 of .fam as phenotypes
# result = iht("multivariate", 8, MvNormal, phenotypes=[6, 7])

# run cross validation directly with xla and Y (note: transpose is necessary to make samples into columns)
# result = fit_iht(Matrix(Y'), Transpose(xla), k=8)
```

    ****                   MendelIHT Version 1.4.1                  ****
    ****     Benjamin Chu, Kevin Keys, Chris German, Hua Zhou       ****
    ****   Jin Zhou, Eric Sobel, Janet Sinsheimer, Kenneth Lange    ****
    ****                                                            ****
    ****                 Please cite our paper!                     ****
    ****         https://doi.org/10.1093/gigascience/giaa044        ****
    
    Running sparse Multivariate Gaussian regression
    Number of threads = 8
    Link functin = IdentityLink()
    Sparsity parameter (k) = 8
    Prior weight scaling = off
    Doubly sparse projection = off
    Debias = off
    Max IHT iterations = 200
    Converging when tol < 0.0001 and iteration ≥ 5:
    
    Iteration 1: loglikelihood = -2488.6435040107954, backtracks = 0, tol = 0.7246072304337687
    Iteration 2: loglikelihood = -2434.7808475264533, backtracks = 0, tol = 0.17873069127511898
    Iteration 3: loglikelihood = -2433.091980726226, backtracks = 0, tol = 0.029208315165883344
    Iteration 4: loglikelihood = -2433.0687518437962, backtracks = 0, tol = 0.0034098472530974555
    Iteration 5: loglikelihood = -2433.067802424958, backtracks = 0, tol = 0.0009427567101978172
    Iteration 6: loglikelihood = -2433.0677416028657, backtracks = 0, tol = 0.00025792112221606603
    Iteration 7: loglikelihood = -2433.067737220254, backtracks = 0, tol = 7.04657718794652e-5





    
    Compute time (sec):     0.11915302276611328
    Final loglikelihood:    -2433.067737220254
    Iterations:             7
    Trait 1's SNP PVE:      0.6029987163717704
    Trait 2's SNP PVE:      0.07348235785776043
    
    Estimated trait covariance:
    [1m2×2 DataFrame[0m
    [1m Row [0m│[1m trait1    [0m[1m trait2    [0m
    [1m     [0m│[90m Float64   [0m[90m Float64   [0m
    ─────┼──────────────────────
       1 │ 4.7186     0.0303161
       2 │ 0.0303161  3.72355
    
    Trait 1: IHT estimated 6 nonzero SNP predictors
    [1m6×2 DataFrame[0m
    [1m Row [0m│[1m Position [0m[1m Estimated_β [0m
    [1m     [0m│[90m Int64    [0m[90m Float64     [0m
    ─────┼───────────────────────
       1 │      134    -0.442256
       2 │      442    -1.17973
       3 │      450    -1.48389
       4 │     1891    -1.44399
       5 │     2557     0.828121
       6 │     3243    -0.803224
    
    Trait 1: IHT estimated 1 non-genetic predictors
    [1m1×2 DataFrame[0m
    [1m Row [0m│[1m Position [0m[1m Estimated_β [0m
    [1m     [0m│[90m Int64    [0m[90m Float64     [0m
    ─────┼───────────────────────
       1 │        1    -0.119153
    
    Trait 2: IHT estimated 2 nonzero SNP predictors
    [1m2×2 DataFrame[0m
    [1m Row [0m│[1m Position [0m[1m Estimated_β [0m
    [1m     [0m│[90m Int64    [0m[90m Float64     [0m
    ─────┼───────────────────────
       1 │     1014    -0.391318
       2 │     5214     0.376128
    
    Trait 2: IHT estimated 1 non-genetic predictors
    [1m1×2 DataFrame[0m
    [1m Row [0m│[1m Position [0m[1m Estimated_β [0m
    [1m     [0m│[90m Int64    [0m[90m Float64     [0m
    ─────┼───────────────────────
       1 │        1     0.862081




The convergence criteria can be tuned by keywords `tol` and `min_iter`. 

### Check answers

Estimated vs true first beta


```julia
β1 = result.beta[1, :]
true_b1_idx = findall(!iszero, true_b[:, 1])
[β1[true_b1_idx] true_b[true_b1_idx, 1]]
```




    7×2 Matrix{Float64}:
     -0.442256  -0.388067
     -1.17973   -1.24972
     -1.48389   -1.53835
      0.0       -0.0034339
     -1.44399   -1.47163
      0.828121   0.758756
     -0.803224  -0.847906



Estimated vs true second beta


```julia
β2 = result.beta[2, :]
true_b2_idx = findall(!iszero, true_b[:, 2])
[β2[true_b2_idx] true_b[true_b2_idx, 2]]
```




    3×2 Matrix{Float64}:
     -0.391318  -0.402269
      0.376128   0.296183
      0.0        0.125965



Estimated vs true non genetic covariates (intercept)


```julia
[result.c intercepts']
```




    2×2 Matrix{Float64}:
     -0.119153  -0.172668
      0.862081   0.729135



Estimated vs true covariance matrix


```julia
[vec(result.Σ) vec(true_Σ)]
```




    4×2 Matrix{Float64}:
     4.7186     4.96944
     0.0303161  0.162057
     0.0303161  0.162057
     3.72355    3.74153



**Conclusion:** 
+ IHT found 9 true positives: 6/7 causal SNPs for trait 1 and 2/3 causal SNPs for trait 2
+ Estimates for non-genetic covariates are close to the true values. 
+ Estimated trait covariance matrix closely match the true covariance
+ The proportion of phenotypic trait variances explained by genotypes are 0.6 and 0.07.

## Other examples and functionalities

Additional features are available as optional parameters in the [fit_iht](https://github.com/OpenMendel/MendelIHT.jl/blob/master/src/fit.jl#L37) function, but they should be treated as **experimental** features. Interested users are encouraged to explore them and please file issues on GitHub if you encounter a problem.
