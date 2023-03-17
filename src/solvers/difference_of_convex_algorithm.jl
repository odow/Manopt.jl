
@doc raw"""
    DifferenceOfConvexState{Pr,St,P,T,SC<:StoppingCriterion} <:
               AbstractManoptSolverState

A struct to store the current state of the [`difference_of_convex_algorithm`])(@ref).
It comes in two forms, depending on the realisation of the `subproblem`.

# Fields

* `p` – the current iterate, i.e. a point on the manifold
* `X` – the current subgradient, i.e. a tangent vector to `p`.
* `sub_problem` – problem for the subsolver
* `sub_state` – state of the subproblem
* `stop` – a functor inheriting from [`StoppingCriterion`](@ref) indicating when to stop.

For the sub task, we need a method to solve

```math
    \operatorname*{argmin}_{q∈\mathcal M} g(p) - ⟨X, \log_p q⟩
```

besides a problem and options, one can also provide a function and
an [`AbstractEvaluationType`](@ref), respectively, to indicate
a closed form solution for the sub task.

# Constructors

    DifferenceOfConvexState(M, p, sub_problem, sub_state; kwargs...)
    DifferenceOfConvexState(M, p, sub_solver; evaluation=InplaceEvaluation(), kwargs...)

Generate the state either using a solver from Manopt, given by
an [`AbstractManoptProblem`](@ref) `sub_problem` and an [`AbstractManoptSolverState`](@ref) `sub_state`,
or a closed form solution `sub_solver` for the sub-problem, where by default its [`AbstractEvaluationType`](@ref) `evaluation` is in-place,
i.e. the function is of the form `(M, p, X) -> q` or `(M, q, p, X) -> q`,
such that the current iterate `p` and the subgradient `X` of `h` can be passed to that function and the
result if `q`.

## Further keyword Arguments

* `initial_vector=zero_vector` (`zero_vectoir(M,p)`) how to initialize the inner gradient tangent vector
* `stopping_criterion` – [`StopAfterIteration`](@ref)`(200)` a stopping criterion

"""
mutable struct DifferenceOfConvexState{Pr,St,P,T,SC<:StoppingCriterion} <:
               AbstractManoptSolverState
    p::P
    X::T
    sub_problem::Pr
    sub_state::St
    stop::SC
    function DifferenceOfConvexState(
        M::AbstractManifold,
        p::P,
        sub_problem::Pr,
        sub_state::St;
        initial_vector::T=zero_vector(M, p),
        stopping_criterion::SC=StopAfterIteration(200),
    ) where {
        P,Pr<:AbstractManoptProblem,St<:AbstractManoptSolverState,T,SC<:StoppingCriterion
    }
        return new{Pr,St,P,T,SC}(
            p, initial_vector, sub_problem, sub_state, stopping_criterion
        )
    end
    function DifferenceOfConvexState(
        M::AbstractManifold,
        p::P,
        sub_problem::S;
        initial_vector::T=zero_vector(M, p),
        stopping_criterion::SC=StopAfterIteration(200),
        evaluation=AllocatingEvaluation(),
    ) where {P,S<:Function,T,SC<:StoppingCriterion}
        return new{S,typeof(evaluation),P,T,SC}(
            p, initial_vector, sub_problem, evaluation, stopping_criterion
        )
    end
end
get_iterate(dcs::DifferenceOfConvexState) = dcs.p
function set_iterate!(dcs::DifferenceOfConvexState, p)
    dcs.p = p
    return dcs
end
get_gradient(dcs::DifferenceOfConvexState) = dcs.X

@doc raw"""
    difference_of_convex_algorithm(M, f, g, ∂h, p=rand(M); kwargs...)

Compute the difference of convex algorithm [^FerreiraSantosSouza2021] to minimize

```math
    \operatorname*{arg\,min}_{p∈\mathcal M} g(p) - h(p)
```

where you need to provide ``f(p) = g(p) - h(p)``, ``g`` and the subdifferential ``∂h``.

This algorithm performs the following steps given a start point `p`= ``p^{(0)}``.
Then repeat for ``k=0,1,\ldots``

1. Take ``X^{(k)}  ∈ ∂h(p^{(k)})``
2. Set the next iterate to the solution of the subproblem
```math
  p^{(k+1)} \in \operatorname*{argmin}_{q\in \mathcal M} g(q) - ⟨X^{(k)}, \log_{p^{(k)}}q⟩
```

until the `stopping_criterion` is fulfilled.

For more details on the sub problem, see the `sub_problem=` keyword.

# Optional parameters

* `evaluation` – ([`AllocatingEvaluation`](@ref)) specify whether the gradient works by
  allocation (default) form `grad_f(M, p)` or [`InplaceEvaluation`](@ref) form `grad_f!(M, X, x)`
* `gradient` (`nothing`) – specify ``\operatorname{grad} f``, for debug / analysis or enhancing `stopping_criterion=`
* `grad_g` (`nothing`) – specify the gradient of `g`. If specified, a full subsolver is automatically set up.
* `initial_vector` (`zero_vector(M, p)`) initialise the inner tangent vecor to store the subgradient result.
* `stopping_criterion` ([`StopAfterIteration`](@ref)`(200) | `[`StopWhenChangeLess`](@ref)`(1e-8)`)
    a [`StoppingCriterion`](@ref) for the algorithm – includes a [`StopWhenGradienNormLess`](@ref)`(1e-8)`, when a `gradient` is provided.
* `sub_cost` ([`LinearizedDCCost`](@ref)`(g, p, initial_vector)`) cost to be used within the default `sub_problem`
  use this if you have a more efficient version than using `g` from above.
* `sub_grad` ([`LinearizedSubProblemGrad`](@ref)`(grad_g, p, initial_vector; evaluation=evaluation)`gradient to be used within the default `sub_problem`.
  use this if you have a more efficient version than using grad_g` from above
* `sub_hess` – (a fininte difference approximation by default) specify a Hessian of the subproblem, e.g. to run a trust region algorithm.
  set this to nothing to just use a [`ManifoldGradientObjective`](@ref) in the `subobjective=`
* `sub_kwargs` (`[]`) pass keyword arguments to the `sub_state`, in form of a `Dict(:kwname=>value)`,
  unless you set the `sub_state` directly.
* `sub_objective` (a gradient or hessian objetive based on the last 3 keywords)
  provide the objective used within `sub_problem` (if that is not specified by the user)
* `sub_problem` ([`DefaultManifoldProblem`](@ref)`(M, sub_objective)` specify a manopt problem for the sub-solver runs.
  You can also provide a function for a closed form solution. Then `evaluation=` is taken into account for the form of this function.
* `sub_state` (default: decorated gradient descent) – set the options for the sub task using the other keyword arguments for the sub task setup
* `sub_stopping_criterion` ([`StopAfterIteration`](@ref)`(300) | `[`StopWhenStepsizeLess`](@ref)`(1e-8) | `[`StopWhenGradientNormLess`](@ref)`(1e-8)`)
  a stopping crierion used withing the default `sub_state=`
* `sub_stepsize` ([`ArmijoLinesearch`](@ref)`(M)`) specify a step size used within the `sub_state`

...all others are passed on to decorate the inner [`DifferenceOfConvexState`](@ref).

# Output

the obtained (approximate) minimizer ``p^*``, see [`get_solver_return`](@ref) for details

[^FerreiraSantosSouza2021]:
    > Ferreira, O. P., Santos, E. M., Souza, J. C. O.:
    > _The difference of convex algorithm on Riemannian manifolds_,
    > 2021, arXiv: [2112.05250](http://arxiv.org/abs/2112.05250).
"""
function difference_of_convex_algorithm(M::AbstractManifold, f, g, ∂h, p=rand(M); kwargs...)
    q = copy(M, p)
    return difference_of_convex_algorithm!(M, f, g, ∂h, q; kwargs...)
end

@doc raw"""
    difference_of_convex_algorithm!(M, f, g, ∂h, p; kwargs...)

Run the difference of convex algorithm and perform the steps in place of `p`.
See [`difference_of_convex`](@ref) for more details.
"""
function difference_of_convex_algorithm!(
    M::AbstractManifold,
    f,
    g,
    ∂h,
    p;
    evaluation::AbstractEvaluationType=AllocatingEvaluation(),
    grad_g=nothing,
    gradient=nothing,
    initial_vector=zero_vector(M, p),
    stopping_criterion=if isnothing(gradient)
        StopAfterIteration(300) | StopWhenChangeLess(1e-8)
    else
        StopAfterIteration(300) | StopWhenChangeLess(1e-8) | StopWhenGradientNormLess(1e-8)
    end,
    # Subsolver Magic Cascade.
    sub_cost=LinearizedDCCost(g, p, initial_vector),
    sub_grad=if isnothing(grad_g)
        nothing
    else
        LinearizedDCGrad(grad_g, p, initial_vector; evaluation=evaluation)
    end,
    sub_hess=ApproxHessianFiniteDifference(M, copy(M, p), sub_grad; evaluation=evaluation),
    sub_kwargs=[],
    sub_stepsize=ArmijoLinesearch(M),
    sub_stopping_criterion=StopAfterIteration(300) |
                           StopWhenStepsizeLess(1e-8) |
                           StopWhenGradientNormLess(1e-8),
    sub_state::Union{AbstractManoptSolverState,AbstractEvaluationType}=decorate_state!(
        GradientDescentState(
            M, copy(M, p); stepsize=sub_stepsize, stopping_criterion=sub_stopping_criterion
        );
        sub_kwargs...,
    ),
    sub_objective=if isnothing(sub_cost) || isnothing(sub_grad)
        nothing
    else
        if isnothing(sub_hess)
            ManifoldGradientObjective(sub_cost, sub_grad; evaluation=evaluation)
        else
            ManifoldHessianObjective(sub_cost, sub_grad, sub_hess; evaluation=evaluation)
        end
    end,
    sub_problem::Union{AbstractManoptProblem,Function}=if isnothing(sub_objective)
        nothing
    else
        DefaultManoptProblem(M, sub_objective)
    end,
    kwargs..., #collect rest
)
    mdco = ManifoldDifferenceOfConvexObjective(
        f, ∂h; gradient=gradient, evaluation=evaluation
    )
    dmdco = decorate_objective!(M, mdco; kwargs...)
    dmp = DefaultManoptProblem(M, dmdco)
    # For now only subsolvers - TODO closed form solution init here

    if isnothing(sub_problem)
        error(
            """
            Subproblem not correctly intialized. Please provide _either_
            * a `sub_problem=` to be solved
            * a `sub_objective` to automatically generate the sub problem,
            * `sub_grad=` (as well as the usually given `sub_cost=`) to automatically generate the sub objective _or_
            * `grad_g=` keywords to automatically generate the sub problems gradient.
            """,
        )
    elseif sub_problem isa AbstractManoptProblem
        dcs = DifferenceOfConvexState(
            M,
            p,
            sub_problem,
            sub_state;
            stopping_criterion=stopping_criterion,
            initial_vector=initial_vector,
        )
    else
        dcs = DifferenceOfConvexState(
            M,
            p,
            sub_problem;
            evaluation=sub_state,
            stopping_criterion=stopping_criterion,
            initial_vector=initial_vector,
        )
    end
    ddcs = decorate_state!(dcs; kwargs...)
    return get_solver_return(solve!(dmp, ddcs))
end
function initialize_solver!(::AbstractManoptProblem, dcs::DifferenceOfConvexState)
    return dcs
end
function step_solver!(
    amp::AbstractManoptProblem,
    dcs::DifferenceOfConvexState{<:AbstractManoptProblem,<:AbstractManoptSolverState},
    i,
)
    M = get_manifold(amp)
    get_subtrahend_gradient!(amp, dcs.X, dcs.p)
    set_manopt_parameter!(dcs.sub_problem, :Cost, :p, dcs.p)
    set_manopt_parameter!(dcs.sub_problem, :Cost, :X, dcs.X)
    set_manopt_parameter!(dcs.sub_problem, :Gradient, :p, dcs.p)
    set_manopt_parameter!(dcs.sub_problem, :Gradient, :X, dcs.X)
    set_iterate!(dcs.sub_state, M, copy(M, dcs.p))
    solve!(dcs.sub_problem, dcs.sub_state) # call the subsolver
    # copy result from subsolver to current iterate
    copyto!(M, dcs.p, get_solver_result(dcs.sub_state))
    # small hack: store gradient_f in X at end of iteration for a check
    if !isnothing(get_gradient_function(get_objective(amp)))
        get_gradient!(amp, dcs.X, dcs.p)
    end
    return dcs
end
#
# Variant II: subtask is a mutating function providing a closed form soltuion
#
function step_solver!(
    amp::AbstractManoptProblem,
    dcs::DifferenceOfConvexState{<:Function,InplaceEvaluation},
    i,
)
    M = get_manifold(amp)
    get_subgradient!(amp, dcs.X, dcs.p) # evaluate grad F in place for O.X
    dcs.sub_problem(M, dcs.p, dcs.p, dcs.X) # evaluate the closed form solution and store the result in p
    return dcs
end
#
# Variant II: subtask is an allocating function providing a closed form soltuion
#
function step_solver!(
    amp::AbstractManoptProblem,
    dcs::DifferenceOfConvexState{<:Function,AllocatingEvaluation},
    i,
)
    M = get_manifold(amp)
    get_subgradient!(amp, dcs.X, dcs.p) # evaluate grad F in place for O.X
    # run the subsolver inplace of a copy of the current iterate and copy it back to the current iterate
    copyto!(M, dcs.p, dcs.sub_problem(M, copy(M, dcs.p), dcs.X))
    return dcs
end
get_solver_result(dcs::DifferenceOfConvexState) = dcs.p