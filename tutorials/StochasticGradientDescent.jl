### A Pluto.jl notebook ###
# v0.19.16

using Markdown
using InteractiveUtils

# ╔═╡ f58f28fe-c3d8-11ec-0acb-e948605dd63f
md"""
# Stochastic Gradient Descent

This tutorial illustrates how to use the [`stochastic_gradient_descent`](https://manoptjl.org/stable/solvers/stochastic_gradient_descent.html)
solver and different [`DirectionUpdateRule`](https://manoptjl.org/stable/solvers/gradient_descent.html#Direction-Update-Rules-1)s in order to introduce
the average or momentum variant, see [Stochastic Gradient Descent](https://en.wikipedia.org/wiki/Stochastic_gradient_descent).

Computationally, we look at a very simple but large scale problem,
the Riemannian Center of Mass or [Fréchet mean](https://en.wikipedia.org/wiki/Fréchet_mean):
for given points ``p_i ∈\mathcal M``, ``i=1,…,N`` this optimization problem reads

```math
\operatorname*{arg\,min}_{x∈\mathcal M} \frac{1}{2}\sum_{i=1}^{N}
  \operatorname{d}^2_{\mathcal M}(x,p_i),
```

which of course can be (and is) solved by a gradient descent, see the introductionary tutorial or [Statistics in Manifolds.jl](https://juliamanifolds.github.io/Manifolds.jl/stable/features/statistics.html).
If ``N`` is very large, evaluating the complete gradient might be quite expensive.
A remedy is to evaluate only one of the terms at a time and choose a random order for these.

We first initialize the packages
"""

# ╔═╡ af01fd4c-82e2-495e-8475-49de5039bed5
md"""
## Setup

If you open this notebook in Pluto locally it switches between two modes.
If the tutorial is within the `Manopt.jl` repository, this notebook tries to use the local package in development mode.
Otherwise, the file uses the Pluto pacakge management version.
In this case, the includsion of images might be broken. unless you create a subfolder `optimize` and activate `asy`-rendering.
"""

# ╔═╡ b4fd5dc2-2fca-4b48-8293-b0fc92aaafa9
# hideall
_nb_mode = :auto;

# ╔═╡ 5037f0a4-a269-4724-a2b8-17960a1a3d55
# hideall
begin
	if _nb_mode === :auto || _nb_mode === :development
		import Pkg
		curr_folder = pwd()
		parent_folder = dirname(curr_folder)
		manopt_file = joinpath(parent_folder,"src","Manopt.jl")
		# the tutorial is still in the package and not standalone
		_in_package =  endswith(curr_folder,"tutorials") && isfile(manopt_file)
		if _in_package
			eval(:(Pkg.develop(path=parent_folder)))  # directory of MyPkg
		end
	else
		_in_package = false
	end;
	using Manopt, Manifolds, Random, Colors, PlutoUI, BenchmarkTools
end

# ╔═╡ 8a8be09a-49e9-4563-9afc-ae72bd05d26d
md"""
Since the loading is a little complicated, we show, which versions of packages were installed in the following.
"""

# ╔═╡ c815327e-a2bb-40a1-8a13-5d8ef723c5c2
with_terminal() do
	Pkg.status()
end

# ╔═╡ 84528b83-f11d-42de-9e86-fc9f3d451500
md"and we define some colors from [Paul Tol](https://personal.sron.nl/~pault/)"

# ╔═╡ c104cad0-c489-42f8-b896-986811eebfef
begin
    black = RGBA{Float64}(colorant"#000000")
    TolVibrantOrange = RGBA{Float64}(colorant"#EE7733") # Start
    TolVibrantBlue = RGBA{Float64}(colorant"#0077BB") # a path
    TolVibrantTeal = RGBA{Float64}(colorant"#009988") # points
end;

# ╔═╡ 11ffe7e1-22f5-4098-9830-d56ff59745ee
md"We next generate a (little) large(r) data set"

# ╔═╡ f3a29d0e-91a5-437f-8681-5b72072b9cdf
begin
    n = 5000
    σ = π / 12
    M = Sphere(2)
    x = 1 / sqrt(2) * [1.0, 0.0, 1.0]
    Random.seed!(42)
    data = [exp(M, x,  σ * rand(M; vector_at=x)) for i in 1:n]
    localpath = join(splitpath(@__FILE__)[1:(end - 1)], "/") # files folder
    image_prefix = localpath * "/stochastic_gradient_descent"
    _in_package && @info image_prefix
    render_asy = false # on CI or when you do not have asymptote, this should be false
end

# ╔═╡ 4f527a26-dc55-4eb9-ab1b-62a4712182d5
render_asy && asymptote_export_S2_signals(
    image_prefix * "/center_and_large_data.asy";
    points=[[x], data],
    colors=Dict(:points => [TolVibrantBlue, TolVibrantTeal]),
    dot_sizes=[2.5, 1.0],
    camera_position=(1.0, 0.5, 0.5),
);

# ╔═╡ 8baf553d-8d22-4f13-9741-43531b080998
render_asy && render_asymptote(image_prefix * "/center_and_large_data.asy"; render=2);

# ╔═╡ daf0dc47-cba2-4264-84d9-47137924addd
PlutoUI.LocalResource(image_prefix * "/center_and_large_data.png")

# ╔═╡ 30f0a209-afde-40c4-a8ab-3f40fd374d3c
md"""
Note that due to the construction of the points as zero mean tangent vectors, the mean should
be very close to our initial point `x`.

In order to use the stochastic gradient, we now need a function that returns the vector of gradients.
There are two ways to define it in `Manopt.jl`: either as a single function that returns a vector, or as a vector of functions.

The first variant is of course easier to define, but the second is more efficient when only evaluating one of the gradients.

For the mean, the gradient is

```math
 gradF(x) = \sum_{i=1}^N \operatorname{grad}f_i(x) \quad \text{where} \operatorname{grad}f_i(x) = -\log_x p_i
```

which we define in `Manopt.jl` in two different ways:
either as one function returning all gradients as a vector (see `gradF`), or – maybe more fitting for a large scale problem, as a vector of small gradient functions (see `gradf`)
"""

# ╔═╡ 12a60ec6-cd18-4eea-a0af-0cabd43686b8
F(M, x) = 1 / (2 * n) * sum(map(p -> distance(M, x, p)^2, data))

# ╔═╡ d76aa8ef-b234-40d6-940b-cfc5db38cee8
gradF(M, x) = [grad_distance(M, p, x) for p in data]

# ╔═╡ d41271a4-cbbe-46a3-b350-fce79d860671
gradf = [(M, x) -> grad_distance(M, p, x) for p in data];

# ╔═╡ 2d977c61-c556-4d58-8ca6-de0f7977cd30
md"""
The calls are only slightly different, but notice that accessing the 2nd gradient element
requires evaluating all logs in the first function.
So while you can use both `gradF` and `gradf` in the following call, the second one is (much) faster:
"""

# ╔═╡ 2b1ed0d6-d64c-41a2-b396-c3bb243af79c
x_opt1 = stochastic_gradient_descent(M, gradF, x)

# ╔═╡ a6d7707d-8d8b-4136-b058-60c1a33b182d
@benchmark stochastic_gradient_descent($M, $gradF, $x)

# ╔═╡ 201d9ab2-2848-472e-abd6-826301c328e3
x_opt2 = stochastic_gradient_descent(M, gradf, x)

# ╔═╡ ce5e6f7b-f101-401f-9470-74ae94b87096
@benchmark stochastic_gradient_descent($M, $gradf, $x)

# ╔═╡ b463184b-3b66-4c1d-810c-bb398d918e2a
x_opt2

# ╔═╡ f2093d02-a6e0-49f3-ad39-55d9d88e75d0
md"""This result is reasonably close. But we can improve it by using a `DirectionUpdateRule`, namely:

On the one hand [`MomentumGradient`](https://manoptjl.org/stable/solvers/gradient_descent.html#Manopt.MomentumGradient), which requires both the manifold and the initial value,  in order to keep track of the iterate and parallel transport the last direction to the current iterate.
You can also set a `vector_transport_method`, if `ParallelTransport()` is not
available on your manifold. Here, we simply do
"""

# ╔═╡ 22c66c8a-3db1-4584-8cb1-93fbbeb34d4e
x_opt3 = stochastic_gradient_descent(
    M, gradf, x; direction=MomentumGradient(M, x; direction=StochasticGradient(M; X=zero_vector(M, x)))
)

# ╔═╡ dbefa2af-d68f-4918-8ab0-4af257425686
MG = MomentumGradient(M, x; direction=StochasticGradient(M; X=zero_vector(M, x)));

# ╔═╡ 5d5122b6-ba71-48ef-b459-d676ad4cca0d
@benchmark stochastic_gradient_descent($M, $gradf, $x; direction=$MG)

# ╔═╡ d7526835-73d3-40e6-8f8d-1711519ee57a
md"""
And on the other hand the [`AverageGradient`](https://manoptjl.org/stable/solvers/gradient_descent.html#Manopt.AverageGradient) computes an average of the last `n` gradients, i.e.
"""

# ╔═╡ a23ee4d6-6e9b-413a-a3ee-75367c9ea943
x_opt4 = stochastic_gradient_descent(
    M, gradf, x; direction=AverageGradient(M, x; n=10, direction=StochasticGradient(M; X=zero_vector(M, x)))
);

# ╔═╡ b0daf769-f8ea-4d7d-9bd4-48748bc02346
AG = AverageGradient(M, x; n=10, direction=StochasticGradient(M; X=zero_vector(M, x)));

# ╔═╡ 8b7cbfc8-7ec5-4297-b8f1-d3691725578e
@benchmark stochastic_gradient_descent($M, $gradf, $x; direction=$AG)

# ╔═╡ 5a3cb657-b25b-4622-a5a1-c4e93a17204f
md"""
Note that the default `StoppingCriterion` is a fixed number of iterations which helps the comparison here.

For both update rules we have to internally specify that we are still in the stochastic setting (since both rules can also be used with the `IdentityUpdateRule` within [`gradient_descent`](file:///Users/ronny/Repositories/Julia/Manopt.jl/docs/build/solvers/gradient_descent.html).

For this not-that-large-scale example we can of course also use a gradient descent with `ArmijoLinesearch`, but it will be a little slower usually
"""

# ╔═╡ b60b65a4-a46f-4f12-a416-48a716fa7386
fullGradF(M, x) = sum(grad_distance(M, p, x) for p in data)

# ╔═╡ ed9d3864-9a24-4c9a-938b-c2d3c59bb97e
x_opt5 = gradient_descent(M, F, fullGradF, x; stepsize=ArmijoLinesearch(M))

# ╔═╡ f292c401-365e-4d86-8784-b060aea8012a
AL = ArmijoLinesearch(M);

# ╔═╡ dba33908-3a1b-491a-abd8-497a00d85230
@benchmark gradient_descent($M, $F, $fullGradF, $x; stepsize=$AL)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
Manifolds = "1cead3c2-87b3-11e9-0ccd-23c62b72b94e"
Manopt = "0fc0a36d-df90-57f3-8f93-d78a9fc72bb5"
Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[compat]
BenchmarkTools = "~1.3.2"
Colors = "~0.12.10"
Manifolds = "~0.8.42"
Manopt = "~0.3.51, 0.4"
PlutoUI = "~0.7.49"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.4"
manifest_format = "2.0"
project_hash = "d9759c278ba1d25e2261547e030cb76f94913908"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "69f7020bd72f069c219b5e8c236c1fa90d2cb409"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.2.1"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "195c5505521008abea5aee4f96930717958eac6f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.4.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.ArrayInterfaceCore]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "14c3f84a763848906ac681f94cf469a851601d92"
uuid = "30b0a656-2188-435a-8636-2ec0e6a096e2"
version = "0.1.28"

[[deps.ArrayInterfaceStaticArraysCore]]
deps = ["Adapt", "ArrayInterfaceCore", "LinearAlgebra", "StaticArraysCore"]
git-tree-sha1 = "93c8ba53d8d26e124a5a8d4ec914c3a16e6a0970"
uuid = "dd5226c6-a4d4-4bc7-8575-46859f9c95b9"
version = "0.1.3"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "d9a9701b899b30332bbcb3e1679c41cce81fb0e8"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.3.2"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "e7ff6cadf743c098e08fca25c91103ee4303c9bb"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.6"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "38f7a08f19d8810338d4f5085211c7dfa5d5bdd8"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.4"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Random", "SnoopPrecompile"]
git-tree-sha1 = "aa3edc8f8dea6cbfa176ee12f7c2fc82f0608ed3"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.20.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "600cc5508d66b78aae350f7accdb58763ac18589"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.10"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "00a2cccc7f098ff3b66806862d275ca3db9e6e5a"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.5.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.1+0"

[[deps.CovarianceEstimation]]
deps = ["LinearAlgebra", "Statistics", "StatsBase"]
git-tree-sha1 = "3c8de95b4e932d76ec8960e12d681eba580e9674"
uuid = "587fd27a-f159-11e8-2dae-1979310e6154"
version = "0.2.8"

[[deps.DataAPI]]
git-tree-sha1 = "e8119c1a33d267e16108be441a287a6981ba1630"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.14.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "a7756d098cbabec6b3ac44f369f74915e8cfd70a"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.79"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.Einsum]]
deps = ["Compat"]
git-tree-sha1 = "4a6b3eee0161c89700b6c1949feae8b851da5494"
uuid = "b7d42ee7-0b51-5a75-98ca-779d3107e4c0"
version = "0.4.1"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "9a0472ec2f5409db243160a8b030f94c380167a3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.13.6"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "6872f5ec8fd1a38880f027a26739d42dcda6691f"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.2"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "ba2d094a88b6b287bd25cfa86f301e7693ffae2f"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.7.4"

[[deps.HybridArrays]]
deps = ["LinearAlgebra", "Requires", "StaticArrays"]
git-tree-sha1 = "0de633a951f8b5bd32febc373588517aa9f2f482"
uuid = "1baab800-613f-4b0a-84e4-9cd3431bfbb9"
version = "0.4.13"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions", "Test"]
git-tree-sha1 = "709d864e3ed6e3545230601f94e11ebc65994641"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.11"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.Inflate]]
git-tree-sha1 = "5cd07aab533df5170988219191dfad0519391428"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.3"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "49510dfcb407e572524ba94aeae2fced1f3feb0f"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.8"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.Kronecker]]
deps = ["LinearAlgebra", "NamedDims", "SparseArrays", "StatsBase"]
git-tree-sha1 = "78d9909daf659c901ae6c7b9de7861ba45a743f4"
uuid = "2c470bb0-bcc8-11e8-3dad-c9649493f05e"
version = "0.5.3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LinearMaps]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics"]
git-tree-sha1 = "d1b46faefb7c2f48fdec69e6f3cc34857769bc15"
uuid = "7a12625a-238d-50fd-b39a-03d52299707e"
version = "3.8.0"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "946607f84feb96220f480e0422d3484c49c00239"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.19"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

[[deps.Manifolds]]
deps = ["Colors", "Distributions", "Einsum", "Graphs", "HybridArrays", "Kronecker", "LinearAlgebra", "ManifoldsBase", "Markdown", "MatrixEquations", "Quaternions", "Random", "RecipesBase", "RecursiveArrayTools", "Requires", "SimpleWeightedGraphs", "SpecialFunctions", "StaticArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "57300c1019bad5c89f398f198212fbaa87ff6b4a"
uuid = "1cead3c2-87b3-11e9-0ccd-23c62b72b94e"
version = "0.8.42"

[[deps.ManifoldsBase]]
deps = ["LinearAlgebra", "Markdown", "Random"]
git-tree-sha1 = "c92e14536ba3c1b854676ba067926dbffe3624a9"
uuid = "3362f125-f0bb-47a3-aa74-596ffd7ef2fb"
version = "0.13.28"

[[deps.Manopt]]
deps = ["ColorSchemes", "ColorTypes", "Colors", "DataStructures", "Dates", "LinearAlgebra", "ManifoldsBase", "Markdown", "Printf", "Random", "Requires", "SparseArrays", "StaticArrays", "Statistics", "Test"]
path = "/Users/ronnber/Repositories/Julia/Manopt.jl"
uuid = "0fc0a36d-df90-57f3-8f93-d78a9fc72bb5"
version = "0.4.0"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MatrixEquations]]
deps = ["LinearAlgebra", "LinearMaps"]
git-tree-sha1 = "3b284e9c98f645232f9cf07d4118093801729d43"
uuid = "99c1a7ee-ab34-5fd5-8076-27c950a045f4"
version = "2.2.2"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "a7c3d1da1189a1c2fe843a3bfa04d18d20eb3211"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.1"

[[deps.NamedDims]]
deps = ["AbstractFFTs", "ChainRulesCore", "CovarianceEstimation", "LinearAlgebra", "Pkg", "Requires", "Statistics"]
git-tree-sha1 = "cb8ebcee2b4e07b72befb9def593baef8aa12f07"
uuid = "356022a1-0364-5f58-8944-0da4b18d706f"
version = "0.2.50"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "cf494dca75a69712a72b80bc48f59dcf3dea63ec"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.16"

[[deps.Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "6466e524967496866901a78fca3f2e9ea445a559"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eadad7b14cf046de6eb41f13c9275e5aa2711ab6"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.49"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "97aa253e65b784fd13e83774cadc95b38011d734"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.6.0"

[[deps.Quaternions]]
deps = ["LinearAlgebra", "Random", "RealDot"]
git-tree-sha1 = "a3c34ce146e39c9e313196bb853894c133f3a555"
uuid = "94ee1d12-ae83-5a48-8b1c-48b8ff168ae0"
version = "0.7.3"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RealDot]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9f0a1b71baaf7650f4fa8a1d168c7fb6ee41f0c9"
uuid = "c1ae055f-0cd5-4b69-90a6-9a35b1a98df9"
version = "0.1.0"

[[deps.RecipesBase]]
deps = ["SnoopPrecompile"]
git-tree-sha1 = "18c35ed630d7229c5584b945641a73ca83fb5213"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.2"

[[deps.RecursiveArrayTools]]
deps = ["Adapt", "ArrayInterfaceCore", "ArrayInterfaceStaticArraysCore", "ChainRulesCore", "DocStringExtensions", "FillArrays", "GPUArraysCore", "IteratorInterfaceExtensions", "LinearAlgebra", "RecipesBase", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tables", "ZygoteRules"]
git-tree-sha1 = "66e6a85fd5469429a3ac30de1bd491e48a6bac00"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "2.34.1"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.SimpleWeightedGraphs]]
deps = ["Graphs", "LinearAlgebra", "Markdown", "SparseArrays", "Test"]
git-tree-sha1 = "a6f404cc44d3d3b28c793ec0eb59af709d827e4e"
uuid = "47aef6b3-ad0c-573a-a1e2-d07658019622"
version = "1.2.1"

[[deps.SnoopPrecompile]]
git-tree-sha1 = "f604441450a3c0569830946e5b33b78c928e1a85"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.1"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "d75bda01f8c31ebb72df80a46c88b25d1c79c56d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.7"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "6954a456979f23d05085727adb17c4551c19ecd1"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.12"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6b7ba252635a5eff6a0b0664a41ee140a1c9e72a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f9af7f195fb13589dd2e2d57fdb401717d2eb1f6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.5.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "HypergeometricFunctions", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "ab6083f09b3e617e34a956b43e9d51b824206932"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.1.1"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SymbolicIndexingInterface]]
deps = ["DocStringExtensions"]
git-tree-sha1 = "6b764c160547240d868be4e961a5037f47ad7379"
uuid = "2efcf032-c050-4f8e-a9bb-153293bab1f5"
version = "0.2.1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "c79322d36826aa2f4fd8ecfa96ddb47b174ac78d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.1"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.URIs]]
git-tree-sha1 = "ac00576f90d8a259f2c9d823e91d1de3fd44d348"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.ZygoteRules]]
deps = ["MacroTools"]
git-tree-sha1 = "8c1a8e4dfacb1fd631745552c8db35d0deb09ea0"
uuid = "700de1a5-db45-46bc-99cf-38207098b444"
version = "0.2.2"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╟─f58f28fe-c3d8-11ec-0acb-e948605dd63f
# ╟─af01fd4c-82e2-495e-8475-49de5039bed5
# ╠═b4fd5dc2-2fca-4b48-8293-b0fc92aaafa9
# ╠═5037f0a4-a269-4724-a2b8-17960a1a3d55
# ╠═8a8be09a-49e9-4563-9afc-ae72bd05d26d
# ╠═c815327e-a2bb-40a1-8a13-5d8ef723c5c2
# ╟─84528b83-f11d-42de-9e86-fc9f3d451500
# ╠═c104cad0-c489-42f8-b896-986811eebfef
# ╟─11ffe7e1-22f5-4098-9830-d56ff59745ee
# ╠═f3a29d0e-91a5-437f-8681-5b72072b9cdf
# ╠═4f527a26-dc55-4eb9-ab1b-62a4712182d5
# ╠═8baf553d-8d22-4f13-9741-43531b080998
# ╠═daf0dc47-cba2-4264-84d9-47137924addd
# ╟─30f0a209-afde-40c4-a8ab-3f40fd374d3c
# ╠═12a60ec6-cd18-4eea-a0af-0cabd43686b8
# ╠═d76aa8ef-b234-40d6-940b-cfc5db38cee8
# ╠═d41271a4-cbbe-46a3-b350-fce79d860671
# ╟─2d977c61-c556-4d58-8ca6-de0f7977cd30
# ╠═2b1ed0d6-d64c-41a2-b396-c3bb243af79c
# ╠═a6d7707d-8d8b-4136-b058-60c1a33b182d
# ╠═201d9ab2-2848-472e-abd6-826301c328e3
# ╠═ce5e6f7b-f101-401f-9470-74ae94b87096
# ╠═b463184b-3b66-4c1d-810c-bb398d918e2a
# ╟─f2093d02-a6e0-49f3-ad39-55d9d88e75d0
# ╠═22c66c8a-3db1-4584-8cb1-93fbbeb34d4e
# ╠═dbefa2af-d68f-4918-8ab0-4af257425686
# ╠═5d5122b6-ba71-48ef-b459-d676ad4cca0d
# ╟─d7526835-73d3-40e6-8f8d-1711519ee57a
# ╠═a23ee4d6-6e9b-413a-a3ee-75367c9ea943
# ╠═b0daf769-f8ea-4d7d-9bd4-48748bc02346
# ╠═8b7cbfc8-7ec5-4297-b8f1-d3691725578e
# ╟─5a3cb657-b25b-4622-a5a1-c4e93a17204f
# ╠═b60b65a4-a46f-4f12-a416-48a716fa7386
# ╠═ed9d3864-9a24-4c9a-938b-c2d3c59bb97e
# ╠═f292c401-365e-4d86-8784-b060aea8012a
# ╠═dba33908-3a1b-491a-abd8-497a00d85230
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002