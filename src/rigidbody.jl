# export
#     orientation,
#     linear_velocity,
#     angular_velocity

@inline Base.size(model::RigidBody{<:UnitQuaternion}) = 13, control_dim(model)
@inline Base.size(model::RigidBody) = 12, control_dim(model)

function Base.rand(model::RigidBody{D}) where {D}
    n,m = size(model)
    r = @SVector rand(3)
    q = rand(D)
    v = @SVector rand(3)
    ω = @SVector rand(3)
    x = build_state(model, r, q, v, ω)
    u = @SVector rand(m)  # NOTE: this is type unstable
    return x,u
end

function Base.zeros(model::RigidBody{D}) where D
    n,m = size(model)
    r = @SVector zeros(3)
    q = zero(D)
    v = @SVector zeros(3)
    ω = @SVector zeros(3)
    x = build_state(model, r, q, v, ω)
    u = @SVector rand(m)  # NOTE: this is type unstable
    return x,u
end

@inline rotation_type(::RigidBody{D}) where D = D


@inline Base.position(model::RigidBody, x) = SVector{3}(x[1],x[2],x[3])
orientation(model::RigidBody{R}, x::AbstractVector{T}, renorm=false) where {R,T} =
    R(x[4],x[5],x[6])
@inline linear_velocity(model::RigidBody, x) = SVector{3}(x[7],x[8],x[9])
@inline angular_velocity(model::RigidBody, x) = SVector{3}(x[10],x[11],x[12])

function orientation(model::RigidBody{<:UnitQuaternion}, x::AbstractVector,
        renorm=false)
    q = UnitQuaternion(x[4],x[5],x[6],x[7], renorm)
    return q
end
@inline linear_velocity(model::RigidBody{<:UnitQuaternion}, x) = SVector{3}(x[8],x[9],x[10])
@inline angular_velocity(model::RigidBody{<:UnitQuaternion}, x) = SVector{3}(x[11],x[12],x[13])

function flipquat(model::RigidBody{<:UnitQuaternion}, x)
    return @SVector [x[1], x[2], x[3], -x[4], -x[5], -x[6], -x[7],
        x[8], x[9], x[10], x[11], x[12], x[13]]
end

function parse_state(model::RigidBody, x, renorm=false)
    r = position(model, x)
    p = orientation(model, x, renorm)
    v = linear_velocity(model, x)
    ω = angular_velocity(model, x)
    return r, p, v, ω
end

function build_state(model::RigidBody{R}, x, q::Rotation, v, ω) where R <: Rotation
    q = Rotations.params(R(q))
    build_state(model, x, q, v, ω)
end

function build_state(model::RigidBody{R}, x, q::SVector{4}, v, ω) where R <: Rotation
    @SVector [x[1], x[2], x[3],
              q[1], q[2], q[3], q[4],
              v[1], v[2], v[3],
              ω[1], ω[2], ω[3]]
end

function build_state(model::RigidBody{R}, x, q::StaticVector{3}, v, ω) where R <: Rotation
    @SVector [x[1], x[2], x[3],
              q[1], q[2], q[3],
              v[1], v[2], v[3],
              ω[1], ω[2], ω[3]]
end

function build_state(model::RigidBody{R}, x, q::Vector, v, ω) where R <: Rotation
    @SVector [x[1], x[2], x[3],
              q[1], q[2], q[3],
              v[1], v[2], v[3],
              ω[1], ω[2], ω[3]]
end

function build_state(model::RigidBody{<:UnitQuaternion}, x, q::Vector, v, ω) where R <: Rotation
    if length(q) == 3
        push!(q,q[1])
    end
    @SVector [x[1], x[2], x[3],
              q[1], q[2], q[3], q[4],
              v[1], v[2], v[3],
              ω[1], ω[2], ω[3]]
end

function fill_state(model::RigidBody{<:UnitQuaternion}, x::Real, q::Real, v::Real, ω::Real)
    @SVector [x,x,x, q,q,q,q, v,v,v, ω,ω,ω]
end

function fill_state(model::RigidBody, x::Real, q::Real, v::Real, ω::Real)
    @SVector [x,x,x, q,q,q, v,v,v, ω,ω,ω]
end

function fill_error_state(model::RigidBody, x::Real, q::Real, v::Real, ω::Real)
    @SVector [x,x,x, q,q,q, v,v,v, ω,ω,ω]
end

# function fill_error_state(model::RigidBody{UnitQuaternion{T,IdentityMap}},
#         x::Real, q::Real, v::Real, ω::Real) where T
#     @SVector [x,x,x, q,q,q,q, v,v,v, ω,ω,ω]
# end

############################################################################################
#                                DYNAMICS
############################################################################################
function dynamics(model::RigidBody{D}, x, u) where D

    r,q,v,ω = parse_state(model, x)

    F,τ = wrenches(model, x, u)
    M = mass_matrix(model, x, u)
    J = inertia(model, x, u)
    Jinv = inertia_inv(model, x, u)

    xdot = v
    qdot = Rotations.kinematics(q,ω)
    vdot = M\F
    ωdot = Jinv*(τ - ω × (J*ω))

    build_state(model, xdot, qdot, vdot, ωdot)
end

function wrenches(model::RigidBody, x::SVector, u::SVector)
    F = forces(model, x, u)
    M = moments(model, x, u)
    return F,M
end

@inline mass_matrix(::RigidBody, x, u) = throw(ErrorException("Not Implemented"))
@inline forces(::RigidBody, x, u)::SVector{3} = throw(ErrorException("Not implemented"))
@inline moments(::RigidBody, x, u)::SVector{3} = throw(ErrorException("Not implemented"))
@inline inertia(::RigidBody, x, u)::SMatrix{3,3} = throw(ErrorException("Not implemented"))
@inline inertia_inv(::RigidBody, x, u)::SMatrix{3,3} = throw(ErrorException("Not implemented"))


############################################################################################
#                          STATE DIFFERENTIAL METHODS
############################################################################################
@inline get_error_map(::RigidBody) = CayleyMap()

function state_diff(model::RigidBody, x::SVector{N}, x0::SVector{N}) where {N}
    r,q,v,ω = parse_state(model, x)
    r0,q0,v0,ω0 = parse_state(model, x0)
    δr = r - r0
    δq = q ⊖ q0
    δv = v - v0
    δω = ω - ω0
    build_state(model, δr, δq, δv, δω)
end

function state_diff_jacobian(model::RigidBody{<:UnitQuaternion},
        x0::SVector)
    q0 = orientation(model, x0)
    G = Rotations.∇differential(q0)
    I1 = @SMatrix [1 0 0 0 0 0 0 0 0 0 0 0;
                   0 1 0 0 0 0 0 0 0 0 0 0;
                   0 0 1 0 0 0 0 0 0 0 0 0;
                   0 0 0 G[1] G[5] G[ 9] 0 0 0 0 0 0;
                   0 0 0 G[2] G[6] G[10] 0 0 0 0 0 0;
                   0 0 0 G[3] G[7] G[11] 0 0 0 0 0 0;
                   0 0 0 G[4] G[8] G[12] 0 0 0 0 0 0;
                   0 0 0 0 0 0 1 0 0 0 0 0;
                   0 0 0 0 0 0 0 1 0 0 0 0;
                   0 0 0 0 0 0 0 0 1 0 0 0;
                   0 0 0 0 0 0 0 0 0 1 0 0;
                   0 0 0 0 0 0 0 0 0 0 1 0;
                   0 0 0 0 0 0 0 0 0 0 0 1.]
end

function state_diff_jacobian(model::RigidBody, x0::SVector)
    q0 = orientation(model, x0)
    G = Rotations.∇differential(q0)
    return @SMatrix [
        1 0 0 0 0 0 0 0 0 0 0 0;
        0 1 0 0 0 0 0 0 0 0 0 0;
        0 0 1 0 0 0 0 0 0 0 0 0;
        0 0 0 G[1] G[4] G[7] 0 0 0 0 0 0;
        0 0 0 G[2] G[5] G[8] 0 0 0 0 0 0;
        0 0 0 G[3] G[6] G[9] 0 0 0 0 0 0;
        0 0 0 0 0 0 1 0 0 0 0 0;
        0 0 0 0 0 0 0 1 0 0 0 0;
        0 0 0 0 0 0 0 0 1 0 0 0;
        0 0 0 0 0 0 0 0 0 1 0 0;
        0 0 0 0 0 0 0 0 0 0 1 0;
        0 0 0 0 0 0 0 0 0 0 0 1;
    ]
    # return I # I1 = Diagonal(@SVector ones(N))
end

state_diff_size(::RigidBody) = 12

function ∇²differential(model::RigidBody,
        x::SVector, dx::AbstractVector)
      q = orientation(model, x)
      dq = Rotations.params(orientation(model, dx, false))
      G2 = Rotations.∇²differential(q, dq)
      return @SMatrix [
            0 0 0 0 0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0 0 0 0 0;
            0 0 0 G2[1] G2[4] G2[7] 0 0 0 0 0 0;
            0 0 0 G2[2] G2[5] G2[8] 0 0 0 0 0 0;
            0 0 0 G2[3] G2[6] G2[9] 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0 0 0 0 0;
      ]
end

function inverse_map_jacobian(model::RigidBody{<:UnitQuaternion},
        x::SVector)
    q = orientation(model, x)
    G = Rotations.inverse_map_jacobian(q)
    return @SMatrix [
            1 0 0 0 0 0 0 0 0 0 0 0 0;
            0 1 0 0 0 0 0 0 0 0 0 0 0;
            0 0 1 0 0 0 0 0 0 0 0 0 0;
            0 0 0 G[1] G[4] G[7] G[10] 0 0 0 0 0 0;
            0 0 0 G[2] G[5] G[8] G[11] 0 0 0 0 0 0;
            0 0 0 G[3] G[6] G[9] G[12] 0 0 0 0 0 0;
            0 0 0 0 0 0 0 1 0 0 0 0 0;
            0 0 0 0 0 0 0 0 1 0 0 0 0;
            0 0 0 0 0 0 0 0 0 1 0 0 0;
            0 0 0 0 0 0 0 0 0 0 1 0 0;
            0 0 0 0 0 0 0 0 0 0 0 1 0;
            0 0 0 0 0 0 0 0 0 0 0 0 1;
    ]
end

# function ∇²differential(model::RigidBody{UnitQuaternion{T,IdentityMap}},
#         x::SVector, dx::SVector) where T
#     return I*0
# end
#
function inverse_map_jacobian(model::RigidBody, x::SVector)
    return I
end

function inverse_map_∇jacobian(model::RigidBody{<:UnitQuaternion},
        x::SVector, b::SVector)
    q = orientation(model, x)
    bq = @SVector [b[4], b[5], b[6]]
    ∇G = Rotations.inverse_map_∇jacobian(q, bq)
    return @SMatrix [
        0 0 0 0 0 0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0 0 0 0 0 0;
        0 0 0 ∇G[1] ∇G[5] ∇G[ 9] ∇G[13] 0 0 0 0 0 0;
        0 0 0 ∇G[2] ∇G[6] ∇G[10] ∇G[14] 0 0 0 0 0 0;
        0 0 0 ∇G[3] ∇G[7] ∇G[11] ∇G[15] 0 0 0 0 0 0;
        0 0 0 ∇G[4] ∇G[8] ∇G[12] ∇G[16] 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0 0 0 0 0 0;
    ]

end

function inverse_map_∇jacobian(model::RigidBody,
        x::SVector, b::SVector)
    return I*0
end
