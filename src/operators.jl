

function removesubtype(typ)
    if typ isa Expr && typ.head == :(<:) 
        typ.args[1]
    else
        typ
    end
end

function adjtype(Atyp) 
    if Atyp isa Expr && Atyp.args[1] == :QuasiAdjoint 
        removesubtype(Atyp.args[3])
    else
        :(QuasiAdjoint{<:Any,<:$Atyp}) 
    end
end

macro simplify(qt)
    qt.head == :function || qt.head == :(=) || error("Must start with a function")
    @assert qt.args[1].head == :call
    if qt.args[1].args[1] == :(*)
        mat = qt.args[2]
        @assert qt.args[1].args[2].head == :(::)
        Aname,Atyp = qt.args[1].args[2].args
        Aadj = adjtype(Atyp)
        Bname,Btyp = qt.args[1].args[3].args
        Badj = adjtype(Btyp)
        if length(qt.args[1].args) == 3
            ret = quote
                ContinuumArrays.simplifiable(::typeof(*), A::$Atyp, B::$Btyp) = Val(true)
                function ContinuumArrays.mul($Aname::$Atyp, $Bname::$Btyp)
                    $mat
                end
            end
            if Aadj ≠ Btyp 
                @assert Atyp ≠ Badj
                ret = quote
                    $ret
                    ContinuumArrays.simplifiable(::typeof(*), ::$Badj, A::$Aadj) = Val(true)
                    ContinuumArrays.mul(Bc::$Badj, Ac::$Aadj) = ContinuumArrays.mul(Ac', Bc')'
                end
            end
            
            esc(ret)
        else
            @assert length(qt.args[1].args) == 4
            Cname,Ctyp = qt.args[1].args[4].args
            esc(quote
                ContinuumArrays.simplifiable(::typeof(*), ::$Atyp, ::$Btyp, ::$Ctyp) = Val(true)
                function ContinuumArrays._simplify(::typeof(*), $Aname::$Atyp, $Bname::$Btyp, $Cname::$Ctyp)
                    $mat
                end
                Base.copy(M::ContinuumArrays.QMul3{<:$Atyp,<:$Btyp,<:$Ctyp}) = ContinuumArrays.simplify(M)
            end)
        end
    end
end



struct DiracDelta{T,A} <: LazyQuasiVector{T}
    x::T
    axis::A
    DiracDelta{T,A}(x, axis) where {T,A} = new{T,A}(x,axis)
end

DiracDelta{T}(x, axis::A) where {T,A<:AbstractQuasiVector} = DiracDelta{T,A}(x, axis)
DiracDelta{T}(x, domain) where T = DiracDelta{T}(x, Inclusion(domain))
DiracDelta(x, domain) = DiracDelta{eltype(x)}(x, Inclusion(domain))
DiracDelta(axis::AbstractQuasiVector) = DiracDelta(zero(float(eltype(axis))), axis)
DiracDelta(domain) = DiracDelta(Inclusion(domain))

axes(δ::DiracDelta) = (δ.axis,)
IndexStyle(::Type{<:DiracDelta}) = IndexLinear()

==(a::DiracDelta, b::DiracDelta) = a.axis == b.axis && a.x == b.x

function getindex(δ::DiracDelta{T}, x::Number) where T
    x ∈ δ.axis || throw(BoundsError())
    x == δ.x ? inv(zero(T)) : zero(T)
end


@simplify *(A::QuasiAdjoint{<:Any,<:DiracDelta}, B::AbstractQuasiVector) = B[parent(A).x]
@simplify *(A::QuasiAdjoint{<:Any,<:DiracDelta}, B::AbstractQuasiMatrix) = B[parent(A).x,:]

#########
# Derivative
#########


struct Derivative{T,D} <: LazyQuasiMatrix{T}
    axis::Inclusion{T,D}
end

Derivative{T}(axis::A) where {T,A<:Inclusion} = Derivative{T,A}(axis)
Derivative{T}(domain) where T = Derivative{T}(Inclusion(domain))
Derivative(axis) = Derivative{Float64}(axis)

axes(D::Derivative) = (D.axis, D.axis)
==(a::Derivative, b::Derivative) = a.axis == b.axis
copy(D::Derivative) = Derivative(copy(D.axis))

function diff(d::AbstractQuasiVector)
    x = axes(d,1)
    Derivative(x)*d
end

^(D::Derivative, k::Integer) = ApplyQuasiArray(^, D, k)

# struct Multiplication{T,F,A} <: AbstractQuasiMatrix{T}
#     f::F
#     axis::A
# end


const Identity{T,D} = QuasiDiagonal{T,Inclusion{T,D}}

Identity(d::Inclusion) = QuasiDiagonal(d)
