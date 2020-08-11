module RobotDynamics

using Rotations
using StaticArrays
using LinearAlgebra
using ForwardDiff
using UnsafeArrays

using Rotations: skew

export
    AbstractModel,
    DynamicsExpansion,
    dynamics,
    jacobian!,
    discrete_dynamics,
    discrete_jacobian!,
    linearize,
    linearize!,
    state_dim,
    control_dim,
    state_diff_size,
    rollout!

# rigid bodies
export
    LieGroupModel,
    RigidBody,
    RBState,
    orientation,
    linear_velocity,
    angular_velocity

# linear model
export
    AbstractLinearModel,
    DiscreteLinearModel,
    DiscreteLTV,
    DiscreteLTI,
    DiscreteLinearQuadrature,
    ContinuousLinearModel,
    ContinuousLTV,
    ContinuousLTI,
    get_A,
    get_B,
    get_d,
    is_affine,
    is_time_varying


# knotpoints
export
    AbstractKnotPoint,
    KnotPoint,
    StaticKnotPoint,
    state,
    control,
    states,
    controls,
    set_states!,
    set_controls!

# integration
export
    QuadratureRule,
    RK2,
    RK3,
    RK4,
    HermiteSimpson


include("rbstate.jl")
include("jacobian.jl")
include("knotpoint.jl")
include("model.jl")
include("liestate.jl")
include("rigidbody.jl")
include("integration.jl")
include("linearmodel.jl")

end # module
