@doc raw"""
    conjugate_gradient_descent(M, F, gradF, x)

perform a conjugate gradient based descent

````math
x_{k+1} = \operatorname{retr}_{x_k} \bigl( s_kδ_k \bigr),
````
where ``\operatorname{retr}`` denotes a retraction on the `Manifold` `M`
and one can employ different rules to update the descent direction ``δ_k`` based on
the last direction ``δ_{k-1}`` and both gradients ``\operatorname{grad}f(x_k)``,``\operatorname{grad}f(x_{k-1})``.
The [`Stepsize`](@ref) ``s_k`` may be determined by a [`Linesearch`](@ref).

Available update rules are [`SteepestDirectionUpdateRule`](@ref), which yields a [`gradient_descent`](@ref),
[`ConjugateDescentCoefficient`](@ref) (the default), [`DaiYuanCoefficient`](@ref), [`FletcherReevesCoefficient`](@ref),
[`HagerZhangCoefficient`](@ref), [`HeestenesStiefelCoefficient`](@ref),
[`LiuStoreyCoefficient`](@ref), and [`PolakRibiereCoefficient`](@ref).

They all compute ``β_k`` such that this algorithm updates the search direction as
````math
\delta_k=\operatorname{grad}f(x_k) + β_k \delta_{k-1}
````

# Input
* `M` : a manifold ``\mathcal M``
* `F` : a cost function ``F:\mathcal M→ℝ`` to minimize implemented as a function `(M,p) -> v`
* `gradF`: the gradient ``\operatorname{grad}F:\mathcal M → T\mathcal M`` of ``F`` implemented also as `(M,x) -> X`
* `x` : an initial value ``x∈\mathcal M``

# Optional
* `coefficient` : ([`ConjugateDescentCoefficient`](@ref) `<:` [`DirectionUpdateRule`](@ref))
  rule to compute the descent direction update coefficient ``β_k``,
  as a functor, i.e. the resulting function maps `(p,o,i) -> β`, where
  `p` is the current [`GradientProblem`](@ref), `o` are the
  [`ConjugateGradientDescentState`](@ref) `o` and `i` is the current iterate.
* `evaluation` – ([`AllocatingEvaluation`](@ref)) specify whether the gradient works by allocation (default) form `gradF(M, x)`
  or [`InplaceEvaluation`](@ref) in place, i.e. is of the form `gradF!(M, X, x)`.
* `retraction_method` - (`default_retraction_method(M`) a retraction method to use.
* `stepsize` - (`Constant(1.)`) A [`Stepsize`](@ref) function applied to the
  search direction. The default is a constant step size 1.
* `stopping_criterion` : (`stopWhenAny( stopAtIteration(200), stopGradientNormLess(10.0^-8))`)
  a function indicating when to stop.
* `vector_transport_method` – (`default_vector_transport_method(M)`) vector transport method to transport
  the old descent direction when computing the new descent direction.

# Output

the obtained (approximate) minimizer ``x^*``, see [`get_solver_return`](@ref) for details
"""
function conjugate_gradient_descent(
    M::AbstractManifold, F::TF, gradF::TDF, x; kwargs...
) where {TF,TDF}
    x_res = copy(M, x)
    return conjugate_gradient_descent!(M, F, gradF, x_res; kwargs...)
end
@doc raw"""
    conjugate_gradient_descent!(M, F, gradF, x)

perform a conjugate gradient based descent in place of `x`, i.e.
````math
x_{k+1} = \operatorname{retr}_{x_k} \bigl( s_k\delta_k \bigr),
````
where ``\operatorname{retr}`` denotes a retraction on the `Manifold` `M`

# Input
* `M` : a manifold ``\mathcal M``
* `F` : a cost function ``F:\mathcal M→ℝ`` to minimize
* `gradF`: the gradient ``\operatorname{grad}F:\mathcal M→ T\mathcal M`` of F
* `x` : an initial value ``x∈\mathcal M``

for more details and options, especially the [`DirectionUpdateRule`](@ref)s,
 see [`conjugate_gradient_descent`](@ref).
"""
function conjugate_gradient_descent!(
    M::AbstractManifold,
    F::TF,
    gradF::TDF,
    x;
    coefficient::DirectionUpdateRule=ConjugateDescentCoefficient(),
    evaluation::AbstractEvaluationType=AllocatingEvaluation(),
    stepsize::Stepsize=ConstantStepsize(M),
    retraction_method::AbstractRetractionMethod=default_retraction_method(M),
    stopping_criterion::StoppingCriterion=StopWhenAny(
        StopAfterIteration(500), StopWhenGradientNormLess(10^(-8))
    ),
    vector_transport_method=default_vector_transport_method(M),
    kwargs...,
) where {TF,TDF}
    p = GradientProblem(M, F, gradF; evaluation=evaluation)
    X = zero_vector(M, x)
    o = ConjugateGradientDescentState(
        M,
        x,
        stopping_criterion,
        stepsize,
        coefficient,
        retraction_method,
        vector_transport_method,
        X,
    )
    o = decorate_state(o; kwargs...)
    return get_solver_return(solve!(p, o))
end
function initialize_solver!(p::AbstractManoptProblem, o::ConjugateGradientDescentState)
    o.gradient = get_gradient(p, o.x)
    o.δ = -o.gradient
    return o.β = 0.0
end
function step_solver!(p::AbstractManoptProblem, o::ConjugateGradientDescentState, i)
    xOld = o.x
    retract!(p.M, o.x, o.x, get_stepsize(p, o, i, o.δ) * o.δ, o.retraction_method)
    get_gradient!(p, o.gradient, o.x)
    o.β = o.coefficient(p, o, i)
    vector_transport_to!(p.M, o.δ, xOld, o.δ, o.x, o.vector_transport_method)
    o.δ .= -o.gradient .+ o.β * o.δ
    return o.δ
end
