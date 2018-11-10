module QuasiArrays
using Base, LinearAlgebra, LazyArrays
import Base: getindex, size, axes, length, ==, isequal, iterate, CartesianIndices, LinearIndices,
                Indices, IndexStyle, getindex, setindex!, parent, vec, convert, similar, zero,
                map, eachindex, eltype, first, last, firstindex, lastindex
import Base: @_inline_meta, DimOrInd, OneTo, @_propagate_inbounds_meta, @_noinline_meta,
                DimsInteger, error_if_canonical_getindex, @propagate_inbounds, _return_type, _default_type,
                _maybetail, tail, _getindex, _maybe_reshape, index_ndims, _unsafe_getindex,
                index_shape, to_shape, unsafe_length, @nloops, @ncall, Slice, unalias
import Base: ViewIndex, Slice, ScalarIndex, RangeIndex, view, viewindexing, ensure_indexable, index_dimsum,
                check_parent_index_match, reindex, _isdisjoint, unsafe_indices,
                parentindices
import Base: *, /, \, +, -, inv
import Base: exp, log, sqrt,
          cos, sin, tan, csc, sec, cot,
          cosh, sinh, tanh, csch, sech, coth,
          acos, asin, atan, acsc, asec, acot,
          acosh, asinh, atanh, acsch, asech, acoth
import Base: Array, Matrix, Vector

import Base.Broadcast: materialize

import LinearAlgebra: transpose, adjoint, checkeltype_adjoint, checkeltype_transpose, Diagonal,
                        AbstractTriangular

import LazyArrays: MemoryLayout, UnknownLayout, Mul2

export AbstractQuasiArray, AbstractQuasiMatrix, AbstractQuasiVector, materialize

abstract type AbstractQuasiArray{T,N} end
AbstractQuasiVector{T} = AbstractQuasiArray{T,1}
AbstractQuasiMatrix{T} = AbstractQuasiArray{T,2}
AbstractQuasiVecOrMat{T} = Union{AbstractQuasiVector{T}, AbstractQuasiMatrix{T}}


cardinality(d) = length(d)

size(A::AbstractQuasiArray) = cardinality.(axes(A))
axes(A::AbstractQuasiArray) = error("Override axes for $(typeof(A))")

include("indices.jl")
include("abstractquasiarray.jl")
include("multidimensional.jl")
include("subquasiarray.jl")
include("matmul.jl")

include("quasiadjtrans.jl")
include("quasidiagonal.jl")

end