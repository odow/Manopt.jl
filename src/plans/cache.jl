#
# A Simple Cache for Objectives
#
@doc raw"""
     SimpleCachedManifoldObjective{O<:AbstractManifoldGradientObjective{E,TC,TG}, P, T,C} <: AbstractManifoldGradientObjective{E,TC,TG}

Provide a simple cache for an [`AbstractManifoldGradientObjective`](@ref) that is for a given point `p` this cache
stores a point `p` and a gradient ``\operatorname{grad} f(p)`` in `X` as well as a cost value ``f(p)`` in `c`.

Both `X` and `c` are accompanied by booleans to keep track of their validity.

# Constructor

    SimpleCachedManifoldObjective(M::AbstractManifold, obj::AbstractManifoldGradientObjective; kwargs...)

## Keyword
* `p` (`rand(M)`) – a point on the manifold to initialize the cache with
* `X` (`get_gradient(M, obj, p)` or `zero_vector(M,p)`) – a tangent vector to store the gradient in, see also `initialize`
* `c` (`get_cost(M, obj, p)` or `0.0`) – a value to store the cost function in `initialize`
* `initialized` (`true`) – whether to initialize the cached `X` and `c` or not.
"""
mutable struct SimpleCachedManifoldObjective{
    E<:AbstractEvaluationType,TC,TG,O<:AbstractManifoldGradientObjective{E,TC,TG},P,T,C
} <: AbstractDecoratedManifoldObjective{E,O}
    objective::O
    p::P # a point
    X::T # a vector
    X_valid::Bool
    c::C # a value for the cost
    c_valid::Bool
end

function SimpleCachedManifoldObjective(
    M::AbstractManifold,
    obj::O;
    initialized=true,
    p=rand(M),
    X=initialized ? get_gradient(M, obj, p) : zero_vector(M, p),
    c=initialized ? get_cost(M, obj, p) : 0.0,
) where {E<:AbstractEvaluationType,TC,TG,O<:AbstractManifoldGradientObjective{E,TC,TG}}
    q = copy(M, p)
    return SimpleCachedManifoldObjective{E,TC,TG,O,typeof(q),typeof(X),typeof(c)}(
        obj, q, X, initialized, c, initialized
    )
end
# Default implementations
function get_cost(M::AbstractManifold, sco::SimpleCachedManifoldObjective, p)
    scop_neq_p = sco.p != p
    if scop_neq_p || !sco.c_valid
        # else evaluate cost, invalidate grad if p changed
        sco.c = get_cost(M, sco.objective, p)
        # if we switched points, invalidate X
        scop_neq_p && (sco.X_valid = false)
        copyto!(M, sco.p, p)
        sco.c_valid = true
    end
    return sco.c
end
get_cost_function(sco::SimpleCachedManifoldObjective) = get_cost_function(sco.objective)
function get_gradient(M::AbstractManifold, sco::SimpleCachedManifoldObjective, p)
    scop_neq_p = sco.p != p
    if scop_neq_p || !sco.X_valid
        get_gradient!(M, sco.X, sco.objective, p)
        # if we switched points, invalidate c
        scop_neq_p && (sco.c_valid = false)
        copyto!(M, sco.p, p)
        sco.X_valid = true
    end
    return copy(M, p, sco.X)
end
function get_gradient!(M::AbstractManifold, X, sco::SimpleCachedManifoldObjective, p)
    scop_neq_p = sco.p != p
    if scop_neq_p || !sco.X_valid
        get_gradient!(M, sco.X, sco.objective, p)
        scop_neq_p && (sco.c_valid = false)
        copyto!(M, sco.p, p)
        # if we switched points, invalidate c
        sco.X_valid = true
    end
    copyto!(M, X, sco.p, sco.X)
    return X
end
function get_gradient_function(sco::SimpleCachedManifoldObjective)
    return get_gradient_function(sco.objective)
end

#
# CostGradImplementation
#
function get_cost(
    M::AbstractManifold,
    sco::SimpleCachedManifoldObjective{
        AllocatingEvaluation,TC,TG,<:ManifoldCostGradientObjective
    },
    p,
) where {TC,TG}
    scop_neq_p = sco.p != p
    if scop_neq_p || !sco.c_valid
        sco.c, sco.X = sco.objective.costgrad!!(M, p)
        copyto!(M, sco.p, p)
        sco.X_valid = true
        sco.c_valid = true
    end
    return sco.c
end
function get_cost(
    M::AbstractManifold,
    sco::SimpleCachedManifoldObjective{
        InplaceEvaluation,TC,TG,<:ManifoldCostGradientObjective
    },
    p,
) where {TC,TG}
    scop_neq_p = sco.p != p
    if scop_neq_p || !sco.c_valid
        sco.c, _ = sco.objective.costgrad!!(M, sco.X, p)
        copyto!(M, sco.p, p)
        sco.X_valid = true
        sco.c_valid = true
    end
    return sco.c
end
function get_gradient(
    M::AbstractManifold,
    sco::SimpleCachedManifoldObjective{
        AllocatingEvaluation,TC,TG,<:ManifoldCostGradientObjective
    },
    p,
) where {TC,TG}
    scop_neq_p = sco.p != p
    if scop_neq_p || !sco.X_valid
        sco.c, sco.X = sco.objective.costgrad!!(M, p)
        copyto!(M, sco.p, p)
        # if we switched points, invalidate c
        sco.X_valid = true
        sco.c_valid = true
    end
    return copy(M, p, sco.X)
end
function get_gradient(
    M::AbstractManifold,
    sco::SimpleCachedManifoldObjective{
        InplaceEvaluation,TC,TG,<:ManifoldCostGradientObjective
    },
    p,
) where {TC,TG}
    scop_neq_p = sco.p != p
    if scop_neq_p || !sco.X_valid
        sco.c, _ = sco.objective.costgrad!!(M, sco.X, p)
        copyto!(M, sco.p, p)
        # if we switched points, invalidate c
        sco.X_valid = true
        sco.c_valid = true
    end
    return sco.X
end
function get_gradient!(
    M::AbstractManifold,
    X,
    sco::SimpleCachedManifoldObjective{
        AllocatingEvaluation,TC,TG,<:ManifoldCostGradientObjective
    },
    p,
) where {TC,TG}
    scop_neq_p = sco.p != p
    if scop_neq_p || !sco.X_valid
        sco.c, sco.X = sco.objective.costgrad!!(M, p)
        copyto!(M, sco.p, p)
        sco.X_valid = true
        sco.c_valid = true
    end
    copyto!(M, X, sco.p, sco.X)
    return X
end
function get_gradient!(
    M::AbstractManifold,
    X,
    sco::SimpleCachedManifoldObjective{
        InplaceEvaluation,TC,TG,<:ManifoldCostGradientObjective
    },
    p,
) where {TC,TG}
    scop_neq_p = sco.p != p
    if scop_neq_p || !sco.X_valid
        sco.c, _ = sco.objective.costgrad!!(M, sco.X, p)
        sco.p = p
        sco.X_valid = true
        sco.c_valid = true
    end
    copyto!(M, X, sco.p, sco.X)
    return X
end

#
# CachedManifoldObjective constructor which errors by default since we can only define init
# for LRU Caches
#
@doc raw"""
    CachedManifoldObjective{E,P,O<:AbstractManifoldObjective{<:E},C<:NamedTuple{}} <: AbstractDecoratedManifoldObjective{E,P}

Create a cache for an objective, based on a `NamedTuple` that stores `LRUCaches` for

# Constructor

    CachedManifoldObjective(M, o::AbstractManifoldObjective, caches::Vector{Symbol}; kwargs...)

Create a cache for the [`AbstractManifoldObjective`](@ref) where the Symbols in `caches` indicate,
which function evaluations to cache.

# Keyword Arguments
* `p`           - (`rand(M)`) the type of the keys to be used in the caches. Defaults to the default representation on `M`.
* `v`           - (`get_cost(M, objective, p)`) the type of values for numeric values in the cache, e.g. the cost
* `X`           - (`zero_vector(M,p)`) the type of values to be cached for gradient and Hessian calls.
* `cache`       - (`[:Cost]`) a vector of symbols indicating which function calls should be cached.
* `cache_size`  - (`10`) number of (least recently used) calls to cache
* `cache_sizes` – (`Dict{Symbol,Int}()`) a named tuple or dictionary specifying the sizes individually for each cache.
"""
struct CachedManifoldObjective{E,P,O<:AbstractManifoldObjective{<:E},C<:NamedTuple{}} <:
       AbstractDecoratedManifoldObjective{E,P}
    objective::O
    cache::C
end
function CachedManifoldObjective(
    M::AbstractManifold,
    objective::O,
    caches::AbstractVector{<:Symbol}=[:Cost];
    p::P=rand(M),
    v::R=get_cost(M, objective, p),
    X::T=zero_vector(M, p),
    cache_size=10,
    cache_sizes=Dict{Symbol,Int}(),
) where {E,O<:AbstractManifoldObjective{E},R,P,T}
    c = init_caches(
        M, caches; p=p, v=v, X=X, cache_size=cache_size, cache_sizes=cache_sizes
    )
    return CachedManifoldObjective{E,O,O,typeof(c)}(objective, c)
end
function CachedManifoldObjective(
    M::AbstractManifold,
    objective::O,
    caches::AbstractVector{<:Symbol}=[:Cost];
    p::P=rand(M),
    v::R=get_cost(M, objective, p),
    X::T=zero_vector(M, p),
    cache_size=10,
    cache_sizes=Dict{Symbol,Int}(),
) where {E,O2,O<:AbstractDecoratedManifoldObjective{E,O2},R,P,T}
    c = init_caches(
        M, caches; p=p, v=v, X=X, cache_size=cache_size, cache_sizes=cache_sizes
    )
    return CachedManifoldObjective{E,O2,O,typeof(c)}(objective, c)
end

"""
    init_caches(M::AbstractManifold, caches, T; kwargs...)

Given a vector of symbols `caches`, this function sets up the
`NamedTuple` of caches for points/vectors on `M`,
where `T` is the type of cache to use.
"""
function init_caches(M, caches, T=Nothing; kwargs...)
    return throw(DomainError(
        T,
        """
        No function `init_caches` available for a caches $T.
        For a good default load `LRUCache.jl`, for example:
        Enter `using LRUCache`.
        """,
    ))
end

get_gradient_function(co::CachedManifoldObjective) = get_gradient_function(co.objective)
get_cost_function(co::CachedManifoldObjective) = get_cost_function(co.objective)

#
# Default implementations - (a) check if field exists (b) try to get cache
function get_cost(M::AbstractManifold, co::CachedManifoldObjective, p)
    !(haskey(co.cache, :Cost)) && return get_cost(M, co.objective, p)
    return get!(co.cache[:Cost], p) do
        get_cost(M, co.objective, p)
    end
end

function get_gradient(M::AbstractManifold, co::CachedManifoldObjective, p)
    !(haskey(co.cache, :Gradient)) && return get_gradient(M, co.objective, p)
    return get!(co.cache[:Gradient], p) do
        get_gradient(M, co.objective, p)
    end
end
function get_gradient!(M::AbstractManifold, X, co::CachedManifoldObjective, p)
    !(haskey(co.cache, :Gradient)) && return get_gradient!(M, X, co.objective, p)
    copyto!(
        M,
        X,
        p,
        get!(co.cache[:Gradient], p) do
            get_gradient!(M, X, co.objective, p)
        end,
    )
    return X
end

#
# CostGradImplementation
function get_cost(
    M::AbstractManifold, co::CachedManifoldObjective{E,<:ManifoldCostGradientObjective}, p
) where {E<:AbstractEvaluationType}
    #Neither cost not grad cached -> evaluate
    all(.!(haskey.(Ref(co.cache), [:Cost, :Gradient]))) &&
        return get_cost(M, co.objective, p)
    return get!(co.cache[:Cost], p) do
        c, X = get_cost_and_gradient(M, co.objective, p)
        #if this is evaluated, we can also set X
        haskey(co.cache, :Gradient) && setindex!(co.cache[:Gradient], X, p)
        c #but we also set the new cost here
    end
end
function get_gradient(
    M::AbstractManifold, co::CachedManifoldObjective{E,<:ManifoldCostGradientObjective}, p
) where {E<:AllocatingEvaluation}
    all(.!(haskey.(Ref(co.cache), [:Cost, :Gradient]))) &&
        return get_gradient(M, co.objective, p)
    return get!(co.cache[:Gradient], p) do
        c, X = get_cost_and_gradient(M, co.objective, p)
        #if this is evaluated, we can also set c
        haskey(co.cache, :Cost) && setindex!(co.cache[:Cost], c, p)
        X #but we also set the new cost here
    end
end
function get_gradient!(
    M::AbstractManifold,
    X,
    co::CachedManifoldObjective{E,<:ManifoldCostGradientObjective},
    p,
) where {E}
    All(!(haskey.(Ref(co.cache), [:Cost, :Gradient]))) &&
        return get_gradient!(M, X, co.objective, p)
    return copyto!(
        M,
        X,
        p,
        get!(co.cache[:Gradient], p) do
            c, _ = get_cost_and_gradient!(M, X, co.objective, p)
            #if this is evaluated, we can also set c
            haskey(co.cache, :Cost) && setindex!(co.cache[:Cost], c, p)
            X
        end,
    )
end

#
# Factory
#
@doc raw"""
    objective_cache_factory(M::AbstractManifold, o::AbstractManifoldObjective, cache::Symbol)

Generate a cached variant of the [`AbstractManifoldObjective`](@ref) `o`
on the `AbstractManifold M` based on the symbol `cache`.

The following caches are available

* `:Simple` generates a [`SimpleCachedManifoldObjective`](@ref)
* `:LRU` generates a [`CachedManifoldObjective`](@ref) where you should use the form
  `(:LRU, [:Cost, :Gradient])` to specify what should be cached or
  `(:LRU, [:Cost, :Gradient], 100)` to specify the cache size.
  Here this variant defaults to `(:LRU, [:Cost, :Gradient], 100)`,
  i.e. to cache up to 100 cost and gradient values.[^1]

[^1] this cache requires [`LRUCache.jl`](https://github.com/JuliaCollections/LRUCache.jl) to be loaded as well.
"""
function objective_cache_factory(M, o, cache::Symbol)
    (cache === :Simple) && return SimpleCachedManifoldObjective(M, o)
    (cache === :LRU) &&
        return CachedManifoldObjective(M, o, [:Cost, :Gradient]; cache_size=100)
    return o
end

@doc raw"""
    objective_cache_factory(M::AbstractManifold, o::AbstractManifoldObjective, cache::Tuple{Symbol, Array, Array})
    objective_cache_factory(M::AbstractManifold, o::AbstractManifoldObjective, cache::Tuple{Symbol, Array})

Generate a cached variant of the [`AbstractManifoldObjective`](@ref) `o`
on the `AbstractManifold M` based on the symbol `cache[1]`,
where the second element `cache[2]` is are further arguments to  the cache and
the optional third is passed down as keyword arguments.

For all available caches see the simpler variant with symbols.
"""
function objective_cache_factory(M, o, cache::Tuple{Symbol,<:AbstractArray,<:AbstractArray})
    (cache[1] === :Simple) && return SimpleCachedManifoldObjective(M, o; cache[3]...)
    if (cache[1] === :LRU)
        if (cacge[3] isa Integer)
            return CachedManifoldObjective(M, o, cache[2]; cache_size=cache[3])
        else
            return CachedManifoldObjective(M, o, cache[2]; cache[3]...)
        end
    end
    return o
end
function objective_cache_factory(M, o, cache::Tuple{Symbol,<:AbstractArray})
    (cache[1] === :Simple) && return SimpleCachedManifoldObjective(M, o)
    (cache[1] === :LRU) && return objective_cache_factory(M, o, Val(:LRU), cache[2])
    return o
end
