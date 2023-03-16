@doc raw"""
    ManifoldDifferenceOfConvexObjective{E} <: AbstractManifoldCostObjective{E}

Specify an objetive for a [`difference_of_convex`](@ref) algorithm.

The objective ``f: \mathcal M \to ℝ`` is given as

```math
    f(p) = g(p) - h(p)
```

where both ``g`` and ``h`` are convex, lsc. and proper.
Furthermore we assume that the subdifferential ``∂h`` of ``h`` is given.

# Fields

* `cost` – an implementation of ``f(p) = g(p)-h(p)``
* `∂h!!` – a deterministic version of ``∂h: \mathcal M → T\mathcal M``,
  i.e. calling `∂h(M, p)` returns a subgradient of ``h`` at `p` and if there is more than
  one, it returns a deterministic choice.

Note that the subdifferential might be given in two possible signatures
* `∂h(M,p)` which does an [`AllocatingEvaluation`](@ref)
* `∂h!(M, X, p)` which does an [`InplaceEvaluation`](@ref) in place of `X`.
"""
struct ManifoldDifferenceOfConvexObjective{E,TCost,TSubGrad} <:
       AbstractManifoldCostObjective{E,TCost}
    cost::TCost
    ∂h!!::TSubGrad
    function ManifoldDifferenceOfConvexObjective(
        cost::TC, ∂h::TSH; evaluation::AbstractEvaluationType=AllocatingEvaluation()
    ) where {TC,TSH}
        return new{typeof(evaluation),TC,TSH}(cost, ∂h)
    end
end

"""
    get_subgradient(p, q)
    get_subgradient!(p, X, q)

Evaluate the (sub)gradient of a [`ManifoldDifferenceOfConvexObjective`](@ref)` p` at the point `q`.

The evaluation is done in place of `X` for the `!`-variant.
The `T=`[`AllocatingEvaluation`](@ref) problem might still allocate memory within.
When the non-mutating variant is called with a `T=`[`InplaceEvaluation`](@ref)
memory for the result is allocated.
"""
function get_subgradient(
    M::AbstractManifold, doco::ManifoldDifferenceOfConvexObjective{AllocatingEvaluation}, p
)
    return doco.∂h!!(M, p)
end
function get_subgradient(
    M::AbstractManifold, doco::ManifoldDifferenceOfConvexObjective{InplaceEvaluation}, p
)
    X = zero_vector(M, p)
    return doco.∂h!!(M, X, p)
end
function get_subgradient!(
    M::AbstractManifold,
    doco::ManifoldDifferenceOfConvexObjective{AllocatingEvaluation},
    X,
    p,
)
    return copyto!(M, p, X, doco.∂h!!(M, p))
end
function get_subgradient!(
    M::AbstractManifold, doco::ManifoldDifferenceOfConvexObjective{InplaceEvaluation}, X, p
)
    return doco.∂h!!(M, X, p)
end

@doc raw"""
    LinearizedDCCost

A functor `(M,q) → ℝ` to represent the inner problem of a [`ManifoldDifferenceOfConvexObjective`](@ref),
i.e. a cost function of the form

```math
    F_{p_k,X_k}(p) = g(p) - ⟨X_k, \log_p_kp⟩
```
for a point `p_k` and a tangent vector `X_k` at `p_k` (e.g. outer iterates)
that are stored within this functor as well.

# Fields

* `g` a function
* `p` a point on a manifold
* `X` a tangent vector at `p`
"""
mutable struct LinearizedDCCost{P,T,TG}
    g::TG
    pk::P
    Xk::T
end
(F::LinearizedDCCost)(M, p) = F.f(p) - inner(M, F.pk, F.Xk, log(M, F.pk, p))

function set_manopt_parameter!(ldc::LinearizedDCCost, ::Val{:p}, ρ)
    return ldc.pk .= p
    return ldc
end
function set_manopt_parameter!(ldc::LinearizedDCCost, ::Val{:X}, X)
    ldc.Xk = X
    return ldc
end

@doc raw"""
    LinearizedDCGrad

A functor `(M,X,p) → ℝ` to represent the gradient of the inner problem of a [`ManifoldDifferenceOfConvexObjective`](@ref),
i.e. for a cost function of the form

```math
    F_{p_k,X_k}(p) = f(p) - ⟨X_k, \log_p_kp⟩
```

its gradient is given by using ``F=F_1(F_2(p))``, where ``F_1(X) = ⟨X_k,X⟩`` and ``F_2(p) = \log_p_kp``
and the chain rule as well as the [`adjoint_differential_log_argument`](@ref) for ``D^*F_2(p)``

```math
    \operatorname{grad} F(q) = \operatorname{grad} f(q) - DF_2^*(q)[X]
```

for a point `pk` and a tangent vector `Xk` at `pk` (the outer iterates) that are stored within this functor as well

# Fields

* `grad_g!!` the gradient of ``g`` (see [`LinearizedSubProblem`](@ref)) as
* `pk` a point on a manifold
* `Xk` a tangent vector at `pk`

# Constructor
    LinearizedDCGrad(grad_g, p, X; evaluation=AllocatingEvaluation())

Where you specify whether `grad_g` is [`AllocatingEvaluation`](@ref) or [`InplaceEvaluation`](@ref),
while this function still provides _both_ signatures.
"""
mutable struct LinearizedDCGrad{E<:AbstractEvaluationType,P,T,TG}
    grad_g!!::TG
    pk::P
    Xk::T
    function LinearizedDCGrad(
        grad_g!!::TG, pk::P, Xk::T; evaluation::E=AllocatingEvaluation()
    ) where {TG,P,T,E<:AbstractEvaluationType}
        return new{E,P,T,TG}(grad_g, pk, Xk)
    end
end
function (grad_F::LinearizedDCGrad{AllocatingEvaluation})(M, p)
    return grad_F.grad_g!!(M, p) .-
           adjoint_differential_log_argument(M, grad_F.pk, p, grad_F.Xk)
end
function (grad_F::LinearizedDCGrad{AllocatingEvaluation})(M, X, p)
    copyto!(
        M,
        X,
        p,
        grad_F.grad_g!!(M, p) .-
        adjoint_differential_log_argument(M, grad_F.pk, p, grad_F.Xk),
    )
    return X
end
function (grad_F!::LinearizedDCGrad{InplaceEvaluation})(M, X, p)
    grad_F!.grad_g!!(M, X, p)
    X .-= adjoint_differential_log_argument(M, grad_F!.pk, p, grad_F!.Xk)
    return X
end
function (grad_F!::LinearizedDCGrad{InplaceEvaluation})(M, p)
    X = zero_vector(M, p)
    grad_F!.grad_g!!(M, X, p)
    X .-= adjoint_differential_log_argument(M, grad_F!.pk, p, grad_F!.Xk)
    return X
end

function set_manopt_parameter!(ldcg::LinearizedDCGrad, ::Val{:p}, ρ)
    return ldcg.pk .= p
    return ldcg
end
function set_manopt_parameter!(ldcg::LinearizedDCGrad, ::Val{:X}, X)
    ldcg.Xk = X
    return ldcg
end

#
# Difference of Convex Proximal Algorithm plan
#
@doc raw"""
    ManifoldDifferenceOfConvexProximalObjective <: Problem

Specify an objective [`difference_of_convex_proximal`](@ref) algorithm.
The problem is of the form
```math
    \operatorname*{argmin}_{p\in \mathcal M} g(p) - h(p)
```
where both ``g`` and ``h`` are convex, lsc. and proper.
# Fields

* `cost` – (`nothing`) implementation of ``f(p) = g(p)-h(p)`` (optional)
* `gradient` - the gradient of the cost
* `grad_h!!` – a function ``\operatorname{grad}h: \mathcal M → T\mathcal M``,

Note that both the gradients miht be given in two possible signatures
as allocating or Inplace.

 # Constructor

    ManifoldDifferenceOfConvexProximalObjective(gradh; cost=norhting, gradient=nothing)

an note that neither cost nor gradient are required for the algorithm,
just for eventual debug or stopping criteria.
"""
struct ManifoldDifferenceOfConvexProximalObjective{
    E<:AbstractEvaluationType,THGrad,TCost,TGrad
} <: AbstractManifoldGradientObjective{E,TCost,TGrad}
    cost::TCost
    gradient!!::TGrad
    grad_h!!::THGrad
    function ManifoldDifferenceOfConvexProximalObjective(
        grad_h::THG; cost::TC=nothing, gradient::TG=nothing, e::ET=AllocatingEvaluation()
    ) where {ET<:AbstractEvaluationType,TC,TG,THG}
        return new{ET,THG,TC,TG}(cost, gradient, grad_h)
    end
end

@doc raw"""
    X = get_subtrahend_gradient(M::AbstractManifold, dcpo::DifferenceOfConvexProxProblem, p)
    get_subtrahend_gradient!(M::AbstractManifold, X, dcpo::DifferenceOfConvexProxProblem, p)

Evaluate the gradient of the subtrahend ``h`` from within
a [`DifferenceOfConvexProxProblem`](@ref)` `P` at the point `p` (in place of X).
"""
get_subtrahend_gradient(
    M::AbstractManifold, dcpo::ManifoldDifferenceOfConvexProximalObjective, x
)

function get_subtrahend_gradient(
    M::AbstractManifold,
    dcpo::ManifoldDifferenceOfConvexProximalObjective{AllocatingEvaluation},
    p,
)
    return dcpo.grad_h!!(M, p)
end
function get_subtrahend_gradient(
    M::AbstractManifold,
    dcpo::ManifoldDifferenceOfConvexProximalObjective{InplaceEvaluation},
    p,
)
    X = zero_vector(M, p)
    dcpo.grad_h!!(M, X, p)
    return X
end
function get_subtrahend_gradient!(
    M::AbstractManifold,
    X,
    dcpo::ManifoldDifferenceOfConvexProximalObjective{AllocatingEvaluation},
    p,
)
    return copyto!(M, X, x, dcpo.grad_h!!(p.M, x))
end
function get_subtrahend_gradient!(
    M::AbstractManifold,
    X,
    dcpo::ManifoldDifferenceOfConvexProximalObjective{InplaceEvaluation},
    p,
)
    dcpo.grad_h!!(M, X, p)
    return X
end

@doc raw"""
    ProximalDCCost

A functor `(M, p) → ℝ` to represent the inner cost function of a [`ManifoldDifferenceOfConvexProximalObjective`](@ref),
i.e. the cost function of the proximal map of `g`.

```math
    F_{p_k}(p) = \frac{1}{2λ}d_{\mathcal M}(p_k,p)^2 + g(p)
```

for a point `pk` and a proximal parameter ``λ``.

# Fields

* `g`  - a function
* `pk` - a point on a manifold
* `λ`  - the prox parameter

# Constructor
    ProximalDCCost(g, p, λ)
"""
mutable struct ProximalDCCost{P,TG,R}
    g::TG
    pk::P
    λ::R
end
(F::ProximalDCCost)(M, p) = 1 / (2 * F.λ) * distance(M, p, F.pk)^2 + F - g(M, p)

function set_manopt_parameter!(pdcc::ProximalDCCost, ::Val{:p}, ρ)
    return pdcc.pk .= p
    return pdcc
end
function set_manopt_parameter!(pdcc::ProximalDCCost, ::Val{:λ}, λ)
    pdcc.λ = λ
    return pdcc
end

@doc raw"""
    ProximalDCGrad

A functor `(M,X,p) → ℝ` to represent the gradient of the inner cost function of a [`ManifoldDifferenceOfConvexProximalObjective`](@ref),
i.e. the gradient function of the proximal map cost function of `g`, i.e. of

```math
    F_{p_k}(p) = \frac{1}{2λ}d_{\mathcal M}(p_k,p)^2 + g(p)
```

which reads

```math
    \operatorname{grad} F_{p_k}(p) = \operatorname{grad} g(p) - \frac{1}{λ}\log_p p_k
```

for a point `pk` and a proximal parameter `λ`.

# Fields

* `grad_g`  - a gradient function
* `pk` - a point on a manifold
* `λ`  - the prox parameter

# Constructor
    ProximalDCGrad(grad_g, pk, λ; evaluation=AllocatingEvaluation())

Where you specify whether `grad_g` is [`AllocatingEvaluation`](@ref) or [`InplaceEvaluation`](@ref),
while this function still always provides _both_ signatures.
"""
mutable struct ProximalDCGrad{E<:AbstractEvaluationType,P,TG,R}
    grad_g!!::TG
    pk::P
    λ::R
    function LinearizedDCGrad(
        grad_g::TG, pk::P, λ::R; evaluation::E=AllocatingEvaluation()
    ) where {TG,P,R,E<:AbstractEvaluationType}
        return new{E,P,TG,R}(grad_g, pk, λ)
    end
end
function (grad_F::ProximalDCGrad{AllocatingEvaluation})(M, p)
    return 1 / (2 * grad_F.λ) * distance(M, p, grad_F.pk)^2 + grad_F.grad_g!!(M, p)
end
function (grad_F::ProximalDCGrad{AllocatingEvaluation})(M, X, p)
    copyto!(
        M, X, p, 1 / (2 * grad_F.λ) * distance(M, p, grad_F.pk)^2 + grad_F.grad_g!!(M, p)
    )
    return X
end
function (grad_F!::ProximalDCGrad{InplaceEvaluation})(M, X, p)
    gradF!.grad_g!!(M, X, p)
    X .-= 1 / gradF!.λ * log(M, p, grad_F!.pk)
    return X
end
function (grad_F!::ProximalDCGrad{InplaceEvaluation})(M, p)
    X = zero_vector(M, p)
    gradF!.grad_g!!(M, X, p)
    X .-= 1 / gradF!.λ * log(M, p, grad_F!.pk)
    return X
end
function set_manopt_parameter!(pdcg::ProximalDCGrad, ::Val{:p}, ρ)
    return pdcg.pk .= p
    return pdcg
end
function set_manopt_parameter!(pdcg::ProximalDCGrad, ::Val{:λ}, λ)
    pdcg.λ = λ
    return pdcg
end
