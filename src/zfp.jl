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
        timedim = 1
        return new{dtype, length(spacedim)}(data, headpositions, tailpositions, spacedim, timedim, eltype)
    end
end

Base.size(compArray::CompressedArraySeq) = (compArray.spacedim..., compArray.timedim)
Base.ndims(compArray::CompressedArraySeq) = length(compArray.spacedim) + 1
Base.IndexStyle(::Type{<:CompressedArraySeq}) = IndexLinear()

function Base.getindex(compArray::CompressedArraySeq, timeidx::Int)
    decompArray = zeros(compArray.eltype, compArray.spacedim...)
    zfp_decompress!(decompArray, compArray.data[compArray.tailpositions[timeidx+1]:compArray.headpositions[timeidx+1]])
    return decompArray
end

function Base.getindex(compArray::CompressedArraySeq, timeidx::Colon)
    decompArray = zeros(compArray.eltype, compArray.spacedim..., timedim)
    @views for i in 1:length(compArray.tailpositions)
        zfp_decompress!(decompArray[:,:,i], compArray.data[compArray.tailpositions[i+1]:compArray.headpositions[i+1]])
    end
    return decompArray
end

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
