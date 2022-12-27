#
# Define a global problem and ist constructors
#
# ---

@doc raw"""
    AbstractManoptProblem{M<:AbstractManifold}

Describe a Riemannian optimization problem with all static (not-changing) properties.

The most prominent features that should always be stated here are

* the `AbstractManifold` ``\mathcal M`` (cf. [ManifoldsBase.jl#AbstractManifold](https://juliamanifolds.github.io/ManifoldsBase.jl/stable/types.html#The-AbstractManifold))
* the cost function ``f\colon \mathcal M → ℝ``

Usually the cost should be within an [`AbstractManifoldObjective`](@ref).
"""
abstract type AbstractManoptProblem{M<:AbstractManifold} end

@doc raw"""
    DefaultManoptProblem{TM <: AbstractManifold, Objective <: AbstractManifoldObjective}

Model a default manifold problem, that (just) consists of the domain of optimisation,
that is an `AbstractManifold` and an [`AbstractManifoldObjective`](@ref)
"""
struct DefaultManoptProblem{TM<:AbstractManifold,Objective<:AbstractManifoldObjective} <:
       AbstractManoptProblem{TM}
    manifold::TM
    objective::Objective
end

"""
    evaluation_type(mp::AbstractManoptProblem)

Get the [`AbstractEvaluationType`](@ref) of the objective in [`AbstractManoptProblem`](@ref)
`mp`.
"""
evaluation_type(mp::AbstractManoptProblem) = evaluation_type(get_objective(mp))
"""
    evaluation_type(::AbstractManifoldObjective{Teval})

Get the [`AbstractEvaluationType`](@ref) of the objective.
"""
evaluation_type(::AbstractManifoldObjective{Teval}) where {Teval} = Teval

@doc raw"""
    get_manifold(mp::AbstractManoptProblem)

return the manifold stored within an [`AbstractManoptProblem`](@ref)
"""
get_manifold(::AbstractManoptProblem)

get_manifold(mp::DefaultManoptProblem) = mp.manifold

@doc raw"""
    get_objective(mp::AbstractManoptProblem)

return the objective [`AbstractManifoldObjective`](@ref) stored within an [`AbstractManoptProblem`](@ref).
"""
get_objective(::AbstractManoptProblem)

get_objective(mp::DefaultManoptProblem) = mp.objective

@doc raw"""
    get_cost(mp::AbstractManoptProblem, p)

evaluate the cost function `f` stored within the [`AbstractManifoldObjective`](@ref) of an
[`AbstractManoptProblem`](@ref) `mp` at the point `p`.
"""
function get_cost(mp::AbstractManoptProblem, p)
    return get_cost(get_manifold(mp), get_objective(mp), p)
end

@doc raw"""
    get_cost(M::AbstractManifold, obj::AbstractManifoldObjective, p)

evaluate the cost function `f` defined on `M` stored within the [`AbstractManifoldObjective`](@ref) at the point `p`.
"""
get_cost(::AbstractManifold, ::AbstractManifoldObjective, p)

@doc raw"""
    get_cost_function(p::AbstractManoptProblem)

access the cost function from within the [`AbstractManoptProblem`](@ref).
    By default this forwards to getting the const function from the internal [`AbstractManifoldObjective`](@ref).
"""
get_cost_function(p::AbstractManoptProblem) = get_cost_function(get_objective(p))

@doc raw"""
    get_cost_function(obj::AbstractManifoldObjective)

access the cost function from within the [`AbstractManoptProblem`](@ref).
By default this returns `obj.cost`.
"""
get_cost(obj::AbstractManifoldObjective) = obj.cost
