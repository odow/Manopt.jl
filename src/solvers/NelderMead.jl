@doc raw"""
    NelderMeadState <: AbstractManoptSolverState

Describes all parameters and the state of a Nealer-Mead heuristic based
optimization algorithm.

# Fields

The naming of these parameters follows the [Wikipedia article](https://en.wikipedia.org/wiki/Nelder–Mead_method)
of the Euclidean case. The default is given in brackets, the required value range
after the description

* `population` – an `Array{`point`,1}` of ``n+1`` points ``x_i``, ``i=1,…,n+1``, where ``n`` is the
  dimension of the manifold.
* `stopping_criterion` – ([`StopAfterIteration`](@ref)`(2000)`) a [`StoppingCriterion`](@ref)
* `α` – (`1.`) reflection parameter (``α > 0``)
* `γ` – (`2.`) expansion parameter (``γ > 0``)
* `ρ` – (`1/2`) contraction parameter, ``0 < ρ ≤ \frac{1}{2}``,
* `σ` – (`1/2`) shrink coefficient, ``0 < σ ≤ 1``
* `p` – (`copy(population[1])`) - a field to collect the current best value (initialized to _some_ point here)
* `retraction_method` – (`default_retraction_method(M)`) the rectraction to use.
* `inverse_retraction_method` - (`default_inverse_retraction_method(M)`) an inverse retraction to use.

# Constructors

    NelderMead(M[, population]; kwargs...)

construct a Nelder-Mead Option with a default popultion (if not provided) of set of `dimension(M)+1` random points.

In the constructor all fields (besides the population) are keyword arguments.
"""
mutable struct NelderMeadState{
    T,
    S<:StoppingCriterion,
    Tα<:Real,
    Tγ<:Real,
    Tρ<:Real,
    Tσ<:Real,
    TR<:AbstractRetractionMethod,
    TI<:AbstractInverseRetractionMethod,
} <: AbstractManoptSolverState
    population::Vector{T}
    stop::S
    α::Tα
    γ::Tγ
    ρ::Tρ
    σ::Tσ
    p::T
    costs::Vector{Float64}
    retraction_method::TR
    inverse_retraction_method::TI
    function NelderMeadState(
        M::AbstractManifold,
        population::Vector{T};
        stopping_criterion::StoppingCriterion=StopAfterIteration(2000),
        α=1.0,
        γ=2.0,
        ρ=1 / 2,
        σ=1 / 2,
        retraction_method::AbstractRetractionMethod=default_retraction_method(M),
        inverse_retraction_method::AbstractInverseRetractionMethod=default_inverse_retraction_method(
            M
        ),
        p::T=copy(M, population[1]),
    ) where {T}
        return new{
            T,
            typeof(stopping_criterion),
            typeof(α),
            typeof(γ),
            typeof(ρ),
            typeof(σ),
            typeof(retraction_method),
            typeof(inverse_retraction_method),
        }(
            population,
            stopping_criterion,
            α,
            γ,
            ρ,
            σ,
            p,
            [],
            retraction_method,
            inverse_retraction_method,
        )
    end
end
function NelderMeadState(M::AbstractManifold; kwargs...)
    population = [random_point(M) for i in 1:(manifold_dimension(M) + 1)]
    return NelderMeadState(M, population; kwargs...)
end
get_iterate(O::NelderMeadState) = O.p
function set_iterate!(O::NelderMeadState, p)
    O.p = p
    return O
end

@doc raw"""
    NelderMead(M, f [, population])
perform a Nelder-Mead minimization problem for the cost function ``f\colon \mathcal M`` on the
manifold `M`. If the initial population `p` is not given, a random set of
points is chosen.

This algorithm is adapted from the Euclidean Nelder-Mead method, see
[https://en.wikipedia.org/wiki/Nelder–Mead_method](https://en.wikipedia.org/wiki/Nelder–Mead_method)
and
[http://www.optimization-online.org/DB_FILE/2007/08/1742.pdf](http://www.optimization-online.org/DB_FILE/2007/08/1742.pdf).

# Input

* `M` – a manifold ``\mathcal M``
* `f` – a cost function to minimize
* `population` – (n+1 `random_point(M)`s) an initial population of ``n+1`` points, where ``n``
  is the dimension of the manifold `M`.

# Optional

* `stopping_criterion` – ([`StopAfterIteration`](@ref)`(2000)`) a [`StoppingCriterion`](@ref)
* `α` – (`1.`) reflection parameter (``α > 0``)
* `γ` – (`2.`) expansion parameter (``γ``)
* `ρ` – (`1/2`) contraction parameter, ``0 < ρ ≤ \frac{1}{2}``,
* `σ` – (`1/2`) shrink coefficient, ``0 < σ ≤ 1``
* `retraction_method` – (`default_retraction_method(M)`) the rectraction to use
* `inverse_retraction_method` - (`default_inverse_retraction_method(M)`) an inverse retraction to use.

and the ones that are passed to [`decorate_options`](@ref) for decorators.

!!! note
    The manifold `M` used here has to either provide a `mean(M, pts)` or you have to
    load `Manifolds.jl` to use its statistics part.

# Output

the obtained (approximate) minimizer ``x^*``, see [`get_solver_return`](@ref) for details
"""
function NelderMead(
    M::AbstractManifold,
    f::TF,
    population=[random_point(M) for i in 1:(manifold_dimension(M) + 1)];
    kwargs...,
) where {TF}
    res_population = copy.(Ref(M), population)
    return NelderMead!(M, f, res_population; kwargs...)
end
@doc raw"""
    NelderMead(M, F [, population])
perform a Nelder Mead minimization problem for the cost function `f` on the
manifold `M`. If the initial population `population` is not given, a random set of
points is chosen. If it is given, the computation is done in place of `population`.

For more options see [`NelderMead`](@ref).
"""
function NelderMead!(
    M::AbstractManifold,
    f::TF,
    population=[random_point(M) for i in 1:(manifold_dimension(M) + 1)];
    stopping_criterion::StoppingCriterion=StopAfterIteration(200000),
    α=1.0,
    γ=2.0,
    ρ=1 / 2,
    σ=1 / 2,
    retraction_method::AbstractRetractionMethod=default_retraction_method(M),
    inverse_retraction_method::AbstractInverseRetractionMethod=default_inverse_retraction_method(
        M
    ),
    kwargs..., #collect rest
) where {TF}
    mp = DefaultManoptProblem(M, ManifoldCostObjective(f))
    o = NelderMeadState(
        M,
        population;
        stopping_criterion=stopping_criterion,
        α=α,
        γ=γ,
        ρ=ρ,
        σ=σ,
        retraction_method=retraction_method,
        inverse_retraction_method=inverse_retraction_method,
    )
    o = decorate_options(o; kwargs...)
    solve!(mp, o)
    return get_solver_return(o)
end
#
# Solver functions
#
function initialize_solver!(mp::AbstractManoptProblem, o::NelderMeadState)
    # init cost and x
    o.costs = get_cost.(Ref(mp), o.population)
    return o.x = o.population[argmin(o.costs)] # select min
end
function step_solver!(mp::AbstractManoptProblem, o::NelderMeadState, ::Any)
    M = get_manifold(mp)
    m = mean(M, o.population)
    ind = sortperm(o.costs) # reordering for cost and p, i.e. minimizer is at ind[1]
    ξ = inverse_retract(M, m, o.population[last(ind)], o.inverse_retraction_method)
    # reflect last
    xr = retract(M, m, -o.α * ξ, o.retraction_method)
    Costr = get_cost(mp, xr)
    # is it better than the worst but not better than the best?
    if Costr >= o.costs[first(ind)] && Costr < o.costs[last(ind)]
        # store as last
        o.population[last(ind)] = xr
        o.costs[last(ind)] = Costr
    end
    # --- Expansion ---
    if Costr < o.costs[first(ind)] # reflected is better than fist -> expand
        xe = retract(M, m, -o.γ * o.α * ξ, o.retraction_method)
        Coste = get_cost(mp, xe)
        # successful? use the expanded, otherwise still use xr
        o.population[last(ind)] .= Coste < Costr ? xe : xr
        o.costs[last(ind)] = min(Coste, Costr)
    end
    # --- Contraction ---
    if Costr > o.costs[ind[end - 1]] # even worse than second worst
        s = (Costr < o.costs[last(ind)] ? -o.ρ : o.ρ)
        xc = retract(M, m, s * ξ, o.retraction_method)
        Costc = get_cost(mp, xc)
        if Costc < o.costs[last(ind)] # better than last ? -> store
            o.population[last(ind)] = xc
            o.costs[last(ind)] = Costc
        end
    end
    # --- Shrink ---
    for i in 2:length(ind)
        retract!(
            M,
            o.population[ind[i]],
            o.population[ind[1]],
            inverse_retract(
                M, o.population[ind[1]], o.population[ind[i]], o.inverse_retraction_method
            ),
            o.σ,
            o.retraction_method,
        )
        # update cost
        o.costs[ind[i]] = get_cost(mp, o.population[ind[i]])
    end
    # store best
    return o.x = o.population[argmin(o.costs)]
end
