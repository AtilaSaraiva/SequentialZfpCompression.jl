struct CompressedTimeArray{T,N}
    data::Vector{UInt8}
    headpositions::Vector{Int64}
    tailpositions::Vector{Int64}
    dims::NTuple{N,Int32}
    eltype::Type{T}

    function CompressedTimeArray(dtype::DataType, spacedim::Integer...; timedim::Integer)
        data = Vector{UInt8}()
        headpositions = Vector{Int64}()
        tailpositions = Vector{Int64}()
        eltype = dtype
        dims = (timedim, spacedim...)
        return new{dtype, length(dims)}(data, headpositions, tailpositions, dims, eltype)
    end
end

Base.size(compArray::CompressedTimeArray) = compArray.dims
Base.IndexStyle(::Type{<:CompressedTimeArray}) = IndexCartesian()
function Base.getindex(compArray::CompressedTimeArray{T,N}, timeidx::Int, spaceidx::Vararg{Int}) where {T,N}
    decompArray = zeros(T, compArray.dims[begin+1:end])
    zfp_decompress!(decompArray, compArray.data[compArray.tailpositions[timeidx]:compArray.headpositions[timeidx]])
    return decompArray[spaceidx...]
end

function Base.getindex(compArray::CompressedTimeArray{T,N}, timeidx::Int, spaceidx::Vararg{Colon}) where {T,N}
    decompArray = zeros(T, compArray.dims[begin+1:end])
    zfp_decompress!(decompArray, compArray.data[compArray.tailpositions[timeidx]:compArray.headpositions[timeidx]])
    return decompArray
end

function CompressedTimeArray(array::AbstractArray{<:AbstractFloat}; timedim::Integer=1)
    compArray = CompressedTimeArray(eltype(array), size(array)..., timedim=timedim)

    data = zfp_compress(array, write_header=false)
    fileSize = length(data)
    append!(compArray.data, data)
    push!(compArray.tailpositions, 1)
    push!(compArray.headpositions, fileSize)

    return compArray
end
