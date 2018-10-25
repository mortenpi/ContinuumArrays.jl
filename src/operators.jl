

struct DiracDelta{T,A} <: AbstractQuasiVector{T}
    x::T
    axis::A
end

DiracDelta{T}(x, axis::A) where {T,A} = DiracDelta{T,A}(x, axis)
DiracDelta(axis) = DiracDelta(zero(float(eltype(axis))), axis)

axes(δ::DiracDelta) = (δ.axis,)
IndexStyle(::Type{<:DiracDelta}) = IndexLinear()

function getindex(δ::DiracDelta{T}, x::Real) where T
    x ∈ δ.axis || throw(BoundsError())
    x == δ.x ? inv(zero(T)) : zero(T)
end


function materialize(M::Mul{<:Any,<:Any,<:Any,<:QuasiArrays.Adjoint{<:Any,<:DiracDelta},<:AbstractQuasiVector})
    A, B = M.A, M.B
    axes(A,2) == axes(A,1) || throw(DimensionMismatch())
    B[parent(A).x]
end

function materialize(M::Mul{<:Any,<:Any,<:Any,<:QuasiArrays.Adjoint{<:Any,<:DiracDelta},<:AbstractQuasiMatrix})
    A, B = M.A, M.B
    axes(A,2) == axes(B,1) || throw(DimensionMismatch())
    B[parent(A).x,:]
end
