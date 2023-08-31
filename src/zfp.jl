"""
    CompressedArraySeq{T,Nx}

A mutable structure for storing time-dependent arrays in a compressed format.

# Fields
- `data::Vector{UInt8}`: Compressed data in byte form.
- `headpositions::Vector{Int64}`: Positions of the beginning of each time slice in `data`.
- `tailpositions::Vector{Int64}`: Positions of the end of each time slice in `data`.
- `spacedim::NTuple{Nx,Int32}`: Dimensions of the spatial grid.
- `timedim::Int32`: Number of time steps.
- `eltype::Type{T}`: Element type of the uncompressed array.

# Example
```jldoctest
julia> using SequentialCompression

julia> compArray = CompressedArraySeq(Float64, 4, 4)
CompressedArraySeq{Float64, 2}(UInt8[], [0], [0], (4, 4), 0, Float64)

julia> compArray.timedim
0
```
"""
mutable struct CompressedArraySeq{T,Nx}
    data::Vector{UInt8}
    headpositions::Vector{Int64}
    tailpositions::Vector{Int64}
    spacedim::NTuple{Nx,Int32}
    timedim::Int32
    eltype::Type{T}

    function CompressedArraySeq(dtype::DataType, spacedim::Integer...)
        data = Vector{UInt8}()
        headpositions = Int64[0]
        tailpositions = Int64[0]
        eltype = dtype
        timedim = 0
        return new{dtype, length(spacedim)}(data, headpositions, tailpositions, spacedim, timedim, eltype)
    end
end

Base.size(compArray::CompressedArraySeq) = (compArray.spacedim..., compArray.timedim)
Base.ndims(compArray::CompressedArraySeq) = length(compArray.spacedim) + 1
Base.IndexStyle(::Type{<:CompressedArraySeq}) = IndexLinear()

Base.@propagate_inbounds function Base.getindex(compArray::CompressedArraySeq, timeidx::Int)
    @boundscheck timeidx <= compArray.timedim || throw(BoundsError(compArray, timeidx))

    decompArray = zeros(compArray.eltype, compArray.spacedim...)
    @inbounds zfp_decompress!(decompArray,
                              compArray.data[compArray.tailpositions[timeidx+1]:compArray.headpositions[timeidx+1]])
    return decompArray
end

function Base.getindex(compArray::CompressedArraySeq, timeidx::Colon)
    decompArray = zeros(compArray.eltype, compArray.spacedim..., compArray.timedim)
    for i in 1:length(compArray.tailpositions)-1
        auxArray = zeros(compArray.eltype, compArray.spacedim...)
        @inbounds zfp_decompress!(auxArray, compArray.data[compArray.tailpositions[i+1]:compArray.headpositions[i+1]])
        decompArray[:,:,i] = auxArray
    end
    return decompArray
end

"""
append!(compArray::CompressedArraySeq{T,N}, array::AbstractArray{T,N})

Append a new time slice to compArray, compressing array in the process.

# Arguments

    compArray::CompressedArraySeq{T,N}: Existing compressed array.
    array::AbstractArray{T,N}: Uncompressed array to append.

# Example

```jldoctest
julia> using SequentialCompression

julia> compArray = CompressedArraySeq(Float64, 4, 4);

julia> append!(compArray, ones(4, 4));

julia> compArray[1]
4×4 Matrix{Float64}:
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0

julia> compArray.timedim
1
```
"""
function Base.append!(compArray::CompressedArraySeq{T,N}, array::AbstractArray{T,N}) where {T<:AbstractFloat, N}
    data = zfp_compress(array, write_header=false)
    fileSize = length(data)
    append!(compArray.data, data)
    push!(compArray.tailpositions, compArray.headpositions[end]+1)
    push!(compArray.headpositions, compArray.headpositions[end]+fileSize)
    compArray.timedim += 1
    return nothing
end

function CompressedArraySeq(array::AbstractArray{<:AbstractFloat})
    compArray = CompressedArraySeq(eltype(array), size(array)...)
    append!(compArray, array)
    return compArray
end
