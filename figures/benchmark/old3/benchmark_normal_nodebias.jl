using MendelIHT
using SnpArrays
using DataFrames
using Distributions
using BenchmarkTools
using Random
using LinearAlgebra
using GLM

function time_normal_response(
    n :: Int64,  # number of cases
    p :: Int64,  # number of predictors (SNPs)
    k :: Int64,  # number of true predictors per group
    debias :: Bool # whether to debias
)
	d = Normal
	l = canonicallink(d())
	Random.seed!(1111)

	#construct snpmatrix, covariate files, and true model b
	x, = simulate_random_snparray(n, p, undef)
	xbm = SnpBitMatrix{Float64}(x, model=ADDITIVE_MODEL, center=true, scale=true); 
	z = ones(n, 1) # the intercept

	# simulate response, true model b, and the correct non-0 positions of b
	y, true_b, correct_position = simulate_random_response(x, xbm, k, d, l)

    #free memory from xbm.... does this work like I think it works?
	xbm = nothing
	GC.gc()

	#time the result and return
    result = @timed L0_reg(x, xbm, z, y, 1, k, d(), l, debias=debias, init=false, use_maf=false)
    iter = result[1].iter
    runtime = result[2]      # seconds
    memory = result[3] / 1e6 # MB

    return iter, runtime, memory
end

function main(n :: Int64, i :: Int64)
	p = 1000000
	k = 10
	debias = false
	response = "normal"

	#run result: first run on super small data to force compile, then run result
	iter, runtime, memory = time_normal_response(100, 100, k, debias)
	iter, runtime, memory = time_normal_response(n, p, k, debias)

	#write result to corresponding file
	if debias
		dir = response * "_results/"
	else
		dir = response * "_results_nodebias/"
	end
	file = string(n) * "_by_" * string(p) * "_run$i"
	open(dir * file, "w") do f
		write(f, "time (seconds), memory (MB), iteration\n")
		write(f, string(runtime) * ", " * string(memory) * ", " * string(iter))
	end
end

# arguments passed from command line
n = parse(Int64, ARGS[1])
i = parse(Int64, ARGS[2])

main(n, i)

