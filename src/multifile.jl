"""
    CompressedMultiFileArraySeq{T,Nx}

A compressed time-dependent array that is stored in multiple files, one per thread.

# Fields
- `files::Vector{IOStream}`: IO object for each array slice.
- `headpositions::Vector{Int64}`: Positions of the beginning of each time slice in `data`.
- `tailpositions::Vector{Int64}`: Positions of the end of each time slice in `data`.
- `spacedim::NTuple{Nx,Int32}`: Dimensions of the spatial grid.
- `timedim::Int32`: Number of time steps.
- `eltype::Type{T}`: Element type of the uncompressed array.
- tol::Float32: [Mean absolute error that is tolerated](https://zfp.readthedocs.io/en/release0.5.5/modes.html#fixed-accuracy-mode).
- precision::Float32: [Controls the precision, bounding a weak relative error](https://zfp.readthedocs.io/en/release0.5.5/modes.html#fixed-precision-mode).
- rate::Int64: [Fixes the bits used per value](https://zfp.readthedocs.io/en/release0.5.5/modes.html#fixed-rate-mode).

# Arguments exclusive for the constructor
- `filepaths::Union{Vector{String}, String}="/tmp/seqcomp"`: Path(s) to the files where the compressed data will be stored. If only one string is passed, the same path will be used for all threads.
"""
mutable struct CompressedMultiFileArraySeq{T,Nx} <: AbstractCompArraySeq
    files::Vector{IOStream}
    headpositions::Vector{Int64}
    tailpositions::Vector{Int64}
    spacedim::NTuple{Nx,Int32}
    timedim::Int32
    eltype::Type{T}
    tol::Float32
    precision::Int64
    rate::Int64
    nth::Int16

    function CompressedMultiFileArraySeq(dtype::DataType, spacedim::Integer...;
                                         rate::Int=0, tol::Real=0, precision::Int=0,
                                         filepaths::Union{Vector{String}, String}="/tmp/seqcomp")

        nth = min(Threads.nthreads(), spacedim[end]) |> Int16

        function correctNumberOfThreads(nth::Integer, N::Integer)
            step = ceil(Int, N/nth)
            len = ceil(N/step) |> Int
            return len
        end

        nth = correctNumberOfThreads(nth, last(spacedim))

        if typeof(filepaths) == String
            filepaths_ = fill(filepaths, nth)
            # create a vector like ["/tmp/seqcomp", "/tmp/seqcomp", ...]
        else
            filepaths_ = filepaths
        end
        files = map(filepaths_) do path
            mkpath(path)
            mktemp(path, cleanup=true) |> last
        end # creates a [IOStream, IOStream, ...]

        headpositions = zeros(Int64, nth) # trick to avoid checking for the first iteration in the append! function
        tailpositions = zeros(Int64, nth) # which means the timedim = length(tailpositions) - Threads.nthreads()
        eltype = dtype
        timedim = 0

        return new{dtype, length(spacedim)}(files, headpositions, tailpositions, spacedim, timedim, eltype, tol, precision, rate, nth)
    end

    # For custom outer constructors
    function CompressedMultiFileArraySeq(
        files::Vector{IOStream},
        headpositions::Vector{Int64},
        tailpositions::Vector{Int64},
        spacedim::NTuple{Nx,Int32},
        timedim::Int32,
        eltype::DataType,
        tol::Float32,
        precision::Int64,
        rate::Int64,
        nth::Int16) where Nx

        return new{eltype, length(spacedim)}(files, headpositions, tailpositions, spacedim, timedim, eltype, tol, precision, rate, nth)
    end
end

ax(A) = map(N->1:N, A.spacedim)
dims(region) = map(r -> r[end] - r[1] + 1, region)
posIdx(timeidx, threadidx, nth) = (timeidx-1)*nth + threadidx

Base.@propagate_inbounds function Base.getindex(compArray::CompressedMultiFileArraySeq, timeidx::Int)
    @boundscheck timeidx <= compArray.timedim || throw(BoundsError(compArray, timeidx))

    let nth = compArray.nth

      decompArray = zeros(compArray.eltype, compArray.spacedim...)

      for (i, region) in collect(enumerate(SplitAxes(ax(compArray), nth)))
          seek(compArray.files[i], compArray.tailpositions[posIdx(timeidx+1, i, nth)]-1)
          compressedVector = read(compArray.files[i], compArray.headpositions[(timeidx)*nth+i] - compArray.tailpositions[(timeidx)*nth+i] + 1)
          decomp = zeros(compArray.eltype, dims(region))
          zfp_decompress!(decomp, compressedVector;
                          tol=compArray.tol, precision=compArray.precision, rate=compArray.rate)
          decompArray[region...] = decomp
      end

      return decompArray

    end
end

function Base.getindex(compArray::AbstractCompArraySeq, timeidx::Colon)
    decompArray = zeros(compArray.eltype, compArray.spacedim..., compArray.timedim)
    ndimensions = ndims(compArray)
    for i in 1:compArray.timedim
        selectdim(decompArray, ndimensions , i) .= compArray[i]
    end
    return decompArray
end

function Base.append!(compArray::CompressedMultiFileArraySeq{T,N}, array::AbstractArray{T,N}) where {T<:AbstractFloat, N}

    let nth = compArray.nth

      auxHeadPosition = Vector{Int64}(undef, nth)
      auxTailPosition = Vector{Int64}(undef, nth)

      @threads for (i, region) in collect(enumerate(SplitAxes(ax(compArray), nth)))
          data = zfp_compress(array[region...],
                              write_header=false,
                              tol=compArray.tol, precision=compArray.precision, rate=compArray.rate)
          fileSize = length(data)
          seekend(compArray.files[i])
          write(compArray.files[i], data)
          auxTailPosition[i] = compArray.headpositions[end-nth+i] + 1
          auxHeadPosition[i] = compArray.headpositions[end-nth+i] + fileSize
      end

      append!(compArray.headpositions, auxHeadPosition)
      append!(compArray.tailpositions, auxTailPosition)
      compArray.timedim += 1
      return nothing

    end
end
