struct CompressedTimeArray{T,N}
    data::Vector{UInt8}
    positions::Vector{Int64}
    dims::NTuple{N,Int32}
    eltype::Type{T}

    function CompressedTimeArray(dtype::DataType, spacedim::Integer...; timedim::Integer)
        data = Vector{UInt8}()
        positions = Vector{Int64}()
        eltype = dtype
        dims = (spacedim..., timedim)
        return new{dtype, length(dims)}(data, positions, dims, eltype)
    end
end
