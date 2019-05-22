using Revise
using MendelIHT
using SnpArrays
using DataFrames
using Distributions
using DelimitedFiles
using BenchmarkTools
using Random
using LinearAlgebra
using GLM
# using Plots

#simulat data with k true predictors, from distribution d and with link l.
n = 1000
p = 10000
k = 10
d = Normal
l = canonicallink(d())
# l = LogLink()

#set random seed
# Random.seed!(1111)

#construct SnpArraym, snpmatrix, and non genetic covariate (intercept)
x = simulate_random_snparray(n, p, "test1.bed")
xbm = SnpBitMatrix{Float64}(x, model=ADDITIVE_MODEL, center=true, scale=true); 
z = ones(n, 1)

# simulate response, true model b, and the correct non-0 positions of b
true_b = zeros(p)
true_b[1:10] .= collect(0.1:0.1:1.0)
shuffle!(true_b)
correct_position = findall(x -> x != 0, true_b)

#simulate phenotypes (e.g. vector y)
if d == Normal || d == Poisson || d == Bernoulli
    prob = linkinv.(l, xbm * true_b)
    clamp!(prob, -20, 20)
    y = [rand(d(i)) for i in prob]
elseif d == NegativeBinomial
    nn = 10
    μ = linkinv.(l, xbm * true_b)
    clamp!(μ, -20, 20)
    prob = 1 ./ (1 .+ μ ./ nn)
    y = [rand(d(nn, i)) for i in prob] #number of failtures before nn success occurs
elseif d == Gamma
    μ = linkinv.(l, xbm * true_b)
    β = 1 ./ μ # here β is the rate parameter for gamma distribution
    y = [rand(d(α, i)) for i in β] # α is the shape parameter for gamma
end
y = Float64.(y)
histogram(y)

#run IHT
result = L0_reg(x, xbm, z, y, 1, k, d(), l, debias=false, init=false, use_maf=false)

#check result
compare_model = DataFrame(
    position    = correct_position,
    true_β      = true_b[correct_position], 
    estimated_β = result.beta[correct_position])
println("Total iteration number was " * string(result.iter))
println("Total time was " * string(result.time))
println("Total found predictors = " * string(length(findall(!iszero, result.beta[correct_position]))))

#clean up
rm("test1.bed", force=true)




#BELOW ARE SIMULATION FOR normal, bernoulli, and poisson
using Revise
using MendelIHT
using SnpArrays
using DataFrames
using Distributions
using DelimitedFiles
using BenchmarkTools
using Random
using LinearAlgebra
using GLM

#simulat data with k true predictors, from distribution d and with link l.
n = 1000
p = 10000
k = 10
d = Normal
l = canonicallink(d())
# l = LogLink()

#set random seed
# Random.seed!(1111)

#construct SnpArraym, snpmatrix, and non genetic covariate (intercept)
x = simulate_random_snparray(n, p, "test1.bed")
xbm = SnpBitMatrix{Float64}(x, model=ADDITIVE_MODEL, center=true, scale=true); 
z = ones(n, 1)
# z[:, 2] .= randn(n)

# simulate response, true model b, and the correct non-0 positions of b
y, true_b, correct_position = simulate_random_response(x, xbm, k, d, l)
# maximum(y)

# specify weights 
weight = ones(p + 1)
weight[1:p] .= maf_weights(x)
# group = ones(Int, p + 1)
# J = 1
# v = IHTVariables(x, z, y, J, k, group, weight)
# @code_warntype v.b
# weight[correct_position] .= 2.0

#run IHT
result = L0_reg(x, xbm, z, y, 1, k, d(), l, debias=true, init=false, use_maf=false)
# @benchmark L0_reg(x, xbm, z, y, 1, k, d(), l, debias=true, init=false, show_info=false) seconds=60
# @code_warntype L0_reg(x, xbm, z, y, 1, k, d(), l, debias=false, init=false, show_info=false)

# make_bim_fam_files(x, y, "tmp")

#check result
compare_model = DataFrame(
    position    = correct_position,
    true_β      = true_b[correct_position], 
    estimated_β = result.beta[correct_position])
println("Total iteration number was " * string(result.iter))
println("Total time was " * string(result.time))
println("Total found predictors = " * string(length(findall(!iszero, result.beta[correct_position]))))

#clean up
rm("test1.bed", force=true)






#testing if IHT finds intercept and/or nongenetic covariates, normal response
using Revise
using MendelIHT
using SnpArrays
using DataFrames
using Distributions
using BenchmarkTools
using Random
using LinearAlgebra
using GLM

#simulat data with k true predictors, from distribution d and with link l.
n = 1000
p = 10000
k = 10
d = Normal
l = canonicallink(d())

#set random seed
Random.seed!(1111)

#construct snpmatrix, covariate files, and true model b
x = simulate_random_snparray(n, p, "tmp.bed")
xbm = SnpBitMatrix{Float64}(x, model=ADDITIVE_MODEL, center=true, scale=true); 
z = ones(n, 2) # the intercept
z[:, 2] .= randn(n)

#define true_b and true_c
true_b = zeros(p)
true_b[1:k-2] = randn(k-2)
shuffle!(true_b)
correct_position = findall(!iszero, true_b)
true_c = [0.1; 0.1]

#add weight vector
weight = ones(p + 2)
weight[correct_position] .= 2.0
weight[p + 1:end] .= 19.0

#simulate phenotype
prob = linkinv.(l, xbm * true_b .+ z * true_c)
y = [rand(d(i)) for i in prob]

#run result
result = L0_reg(x, xbm, z, y, 1, k, d(), l, debias=false, weight=weight)

#compare with correct answer
compare_model = DataFrame(
    position    = correct_position,
    true_β      = true_b[correct_position], 
    estimated_β = result.beta[correct_position])

compare_model = DataFrame(
    true_c      = true_c[1:2], 
    estimated_c = result.c[1:2])

#clean up
rm("tmp.bed", force=true)












#BELOW ARE SIMULATION FOR binomial
using Revise
using MendelIHT
using SnpArrays
using DataFrames
using Distributions
using BenchmarkTools
using Random
using LinearAlgebra
using GLM

#simulat data with k true predictors, from distribution d and with link l.
n = 1000
p = 10000
k = 10
d = Binomial
l = CloglogLink()
nn = 10 #number of tries for binomial/negative-binomial

#set random seed
Random.seed!(2019)

#construct snpmatrix, covariate files, and true model b
x = simulate_random_snparray(n, p, "tmp.bed")
xbm = SnpBitMatrix{Float64}(x, model=ADDITIVE_MODEL, center=true, scale=true); 
z = ones(n, 1) # the intercept
true_b = zeros(p)
true_b[1:k] = randn(k)
shuffle!(true_b)
correct_position = findall(x -> x != 0, true_b)

#simulate phenotypes (e.g. vector y) 
μ = linkinv.(l, xbm * true_b)
prob = μ ./ nn
y = [rand(d(nn, i)) for i in prob]
y = Float64.(y)

#run IHT
result = L0_reg(x, xbm, z, y, 1, k, d(), l, debias=false, init=false, show_info=false, convg=true)
# @benchmark L0_reg(x, xbm, z, y, 1, k, d(), l, debias=false, init=false, show_info=false, convg=true) seconds = 60

#check result
compare_model = DataFrame(
    true_β      = true_b[correct_position], 
    estimated_β = result.beta[correct_position])
println("Total iteration number was " * string(result.iter))
println("Total time was " * string(result.time))
println("Total found predictors = " * string(length(findall(!iszero, result.beta[correct_position]))))

#clean up
rm("tmp.bed", force=true)





#BELOW ARE SIMULATION FOR gamma
using Revise
using MendelIHT
using SnpArrays
using DataFrames
using Distributions
using BenchmarkTools
using Random
using LinearAlgebra
using GLM

#simulat data with k true predictors, from distribution d and with link l.
n = 1000
p = 10000
k = 10
d = Gamma
# l = canonicallink(d())
l = LogLink()
θ = 1 #scale parameter for gamma

#set random seed
Random.seed!(2019)

#construct snpmatrix, covariate files, and true model b
x = simulate_random_snparray(n, p, "tmp.bed")
xbm = SnpBitMatrix{Float64}(x, model=ADDITIVE_MODEL, center=true, scale=true); 
z = ones(n, 1) # the intercept
true_b = zeros(p)
# true_b[1:k] = randn(k)
true_b[1:k] = rand(Normal(0, 1.0), k)
shuffle!(true_b)
correct_position = findall(x -> x != 0, true_b)

#simulate phenotypes (e.g. vector y) 
μ = linkinv.(l, xbm * true_b)
y = [rand(d(i, 1)) for i in μ] # here assuming unit scale parameter (θ) for gamma distribution

#run IHT
result = L0_reg(x, xbm, z, y, 1, k, d(), l, debias=false, init=false, show_info=false)
# @benchmark L0_reg(x, xbm, z, y, 1, k, d(), l, debias=false, init=false, show_info=false, convg=true) seconds = 60

#check result
compare_model = DataFrame(
    true_β      = true_b[correct_position], 
    estimated_β = result.beta[correct_position])
println("Total iteration number was " * string(result.iter))
println("Total time was " * string(result.time))
println("Total found predictors = " * string(length(findall(!iszero, result.beta[correct_position]))))

#clean up
rm("tmp.bed", force=true)






#BELOW ARE SIMULATION FOR inverse Gaussian
using Revise
using MendelIHT
using SnpArrays
using DataFrames
using Distributions
using BenchmarkTools
using Random
using LinearAlgebra
using GLM

#simulat data with k true predictors, from distribution d and with link l.
n = 1000
p = 10000
k = 10
d = InverseGaussian
l = LogLink()
λ = 1 # shape parameter for inverse gaussian

#set random seed
Random.seed!(2019)

#construct snpmatrix, covariate files, and true model b
x = simulate_random_snparray(n, p, "tmp.bed")
xbm = SnpBitMatrix{Float64}(x, model=ADDITIVE_MODEL, center=true, scale=true); 
z = ones(n, 1) # the intercept
true_b = zeros(p)
true_b[1:k] = randn(k)
# true_b[1:k] = rand(Normal(0, 0.3), k)
shuffle!(true_b)
correct_position = findall(x -> x != 0, true_b)

#simulate phenotypes (e.g. vector y) 
μ = linkinv.(l, xbm * true_b)
mean_parameter = 1 ./ μ #mean parameter for inverse gaussian distribution
y = [rand(d(i, λ)) for i in mean_parameter]

#run IHT
result = L0_reg(x, xbm, z, y, 1, k, d(), l, debias=false, init=false, show_info=false)
# @benchmark L0_reg(x, xbm, z, y, 1, k, d(), l, debias=false, init=false, show_info=false, convg=true) seconds = 60

#check result
compare_model = DataFrame(
    true_β      = true_b[correct_position], 
    estimated_β = result.beta[correct_position])
println("Total iteration number was " * string(result.iter))
println("Total time was " * string(result.time))
println("Total found predictors = " * string(length(findall(!iszero, result.beta[correct_position]))))

#clean up
rm("tmp.bed", force=true)








############## CROSS VALIDATION SIMULATION for normal, bernoulli, and Poisson

#first add workers
using Distributed
addprocs(4)
nprocs()

#load packages into all worker
using Revise
using MendelIHT
using SnpArrays
using DataFrames
using Distributions
using BenchmarkTools
using Random
using LinearAlgebra
using BenchmarkTools
using GLM

#simulat data
n = 1000
p = 10000
k = 10 # number of true predictors
d = Normal
l = canonicallink(d())

#set random seed
Random.seed!(2018)

#construct snpmatrix, covariate files, and true model b
x = simulate_random_snparray(n, p, "tmp.bed")
xbm = SnpBitMatrix{Float64}(x, model=ADDITIVE_MODEL, center=true, scale=true); 
z = ones(n, 1) # the intercept
true_b = zeros(p)
d == Poisson ? true_b[1:k] = rand(Normal(0, 0.3), k) : true_b[1:k] = randn(k)
shuffle!(true_b)
correct_position = findall(x -> x != 0, true_b)

#simulate phenotypes (e.g. vector y) 
y_temp = xbm * true_b
prob = linkinv.(l, y_temp)
y = [rand(d(i)) for i in prob]
y = Float64.(y)

#specify path and folds
path = collect(1:20)
num_folds = 4
folds = rand(1:num_folds, size(x, 1))

#compute cross validation
mses = cv_iht(d(), l, x, z, y, 1, path, num_folds, folds=folds, use_maf=false, debias=true, parallel=true);

#compute l0 result using best estimate for k
k_est = argmin(mses)
result = L0_reg(x, xbm, z, y, 1, k_est, d(), l, debias=false, init=false, show_info=false)

#check result
compare_model = DataFrame(
    true_β      = true_b[correct_position], 
    estimated_β = result.beta[correct_position])
println("Total iteration number was " * string(result.iter))
println("Total time was " * string(result.time))
println("Total found predictors = " * string(length(findall(!iszero, result.beta[correct_position]))))

#clean up
rm("tmp.bed", force=true)


############## RUNNING A BUNCH OF MODELS for normal, bernoulli, and Poisson

#first add workers
using Distributed
addprocs(4)
nprocs()

#load packages into all worker
using Revise
using MendelIHT
using SnpArrays
using DataFrames
using Distributions
using BenchmarkTools
using Random
using LinearAlgebra
using BenchmarkTools
using GLM

#simulat data
n = 2000
p = 10000
k = 10 # number of true predictors
d = Normal
l = canonicallink(d())

#set random seed
Random.seed!(2019)

#construct snpmatrix, covariate files, and true model b
x = simulate_random_snparray(n, p, "tmp.bed")
xbm = SnpBitMatrix{Float64}(x, model=ADDITIVE_MODEL, center=true, scale=true); 
z = ones(n, 1) # the intercept
true_b = zeros(p)
d == Poisson ? true_b[1:k] = rand(Normal(0, 1.0), k) : true_b[1:k] = randn(k)
shuffle!(true_b)
correct_position = findall(x -> x != 0, true_b)

#simulate phenotypes (e.g. vector y) 
y_temp = xbm * true_b
prob = linkinv.(l, y_temp)
y = [rand(d(i)) for i in prob]
y = Float64.(y)

#specify path (i.e. all models `k` you want to test)
path = collect(1:20)

#run results
result = iht_run_many_models(d(), l, x, z, y, 1, path, parallel=true, debias=true);
@benchmark iht_run_many_models(d(), l, x, z, y, 1, path, parallel=true, debias=true) seconds=60


#clean up
rm("tmp.bed", force=true)



#RUN IHT with all CPU available
using Distributed
addprocs(4)
nprocs()

using Revise
using MendelIHT
using SnpArrays
using DataFrames
using Distributions
using BenchmarkTools
using Random
using LinearAlgebra
using GLM

#simulat data with k true predictors, from distribution d and with link l.
n = 1000
p = 10000
k = 10
d = Bernoulli
l = canonicallink(d())
# l = LogLink()

#set random seed
Random.seed!(33)

#construct snpmatrix, covariate files, and true model b
x = simulate_random_snparray(n, p, undef)
xbm = SnpBitMatrix{Float64}(x, model=ADDITIVE_MODEL, center=true, scale=true); 
z = ones(n, 1) # the intercept

# simulate response, true model b, and the correct non-0 positions of b
y, true_b, correct_position = simulate_random_response(x, xbm, k, d, l)

#specify path and folds
path = collect(1:20)
num_folds = 3
folds = rand(1:num_folds, size(x, 1))

# run threaded IHT
# result = iht_run_many_models(d(), l, x, z, y, 1, path);
mses = cv_iht(d(), l, x, z, y, 1, path, num_folds, folds=folds, init=false, use_maf=false, debias=true, parallel=true)

#benchmarking
@benchmark cv_iht(d(), l, x, z, y, 1, path, num_folds, folds=folds, init=false, use_maf=false, debias=true, parallel=true) seconds=60


#run IHT
result = L0_reg(x, xbm, z, y, 1, argmin(mses), d(), l, debias=true, init=false, use_maf=false)
# @benchmark L0_reg(x, xbm, z, y, 1, k, d(), l, debias=false, init=false, show_info=false) seconds=60
# @code_warntype L0_reg(x, xbm, z, y, 1, k, d(), l, debias=false, init=false, show_info=false)

#check result
compare_model = DataFrame(
    position    = correct_position,
    true_β      = true_b[correct_position], 
    estimated_β = result.beta[correct_position])
println("Total iteration number was " * string(result.iter))
println("Total time was " * string(result.time))
println("Total found predictors = " * string(length(findall(!iszero, result.beta[correct_position]))))

#clean up
rm("tmp.bed", force=true)
