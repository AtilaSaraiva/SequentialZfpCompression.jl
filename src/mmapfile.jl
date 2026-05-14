function finalizeMmapFile!(comp)
    comp.mmaps = Vector{UInt8}[]
    for (io, path) in zip(comp.files, comp.filePaths)
        if isopen(io)
            close(io)
        end
        if isfile(path)
            rm(path, force=true)
        end
    end
end


"""
    CompressedMmapArraySeq{T,Nx}

A compressed time-dependent array stored in per-thread temporary files, accessed via memory
mapping for zero-copy reads.

The write path is identical to `CompressedMultiFileArraySeq`: each `append!` call compresses
a spatial slice and writes it to the backing file with standard IO. After every write the mmap
views are refreshed to cover the grown file, so subsequent `getindex` calls read directly from
OS-mapped pages without an extra allocation or copy.

# Fields
- `files::Vector{IOStream}`: Write channel — one file per thread.
- `mmaps::Vector{Vector{UInt8}}`: Live mmap views into each file; refreshed after every `append!`.
- `headpositions::Vector{Int64}`: 1-indexed end byte of each (time, thread) chunk.
- `tailpositions::Vector{Int64}`: 1-indexed start byte of each (time, thread) chunk.
- `spacedim::NTuple{Nx,Int32}`: Spatial dimensions.
- `timedim::Int32`: Number of time steps appended so far.
- `eltype::Type{T}`: Element type of the uncompressed array.
- `tol::Float32`, `precision::Int64`, `rate::Int64`: ZFP compression parameters.
- `nth::Int16`: Number of threads (and files).
- `filePaths::Vector{String}`: Paths to the backing temporary files.

# Arguments exclusive for the constructor
- `filepaths::Union{Vector{String}, String}="/tmp/seqcomp"`: Directory (or per-thread paths)
  where temporary files are created.
"""
mutable struct CompressedMmapArraySeq{T,Nx} <: AbstractCompArraySeq
    files::Vector{IOStream}
    mmaps::Vector{Vector{UInt8}}
    headpositions::Vector{Int64}
    tailpositions::Vector{Int64}
    spacedim::NTuple{Nx,Int32}
    timedim::Int32
    eltype::Type{T}
    tol::Float32
    precision::Int64
    rate::Int64
    nth::Int16
    filePaths::Vector{String}

    function CompressedMmapArraySeq(dtype::DataType, spacedim::Integer...;
                                    rate::Int=0, tol::Real=0, precision::Int=0,
                                    filepaths::Union{Vector{String}, String}="/tmp/seqcomp",
                                    nthreads::Integer=-1)

        if nthreads > 0
            nth = min(Threads.nthreads(), spacedim[end], nthreads) |> Int16
        else
            nth = min(Threads.nthreads(), spacedim[end]) |> Int16
        end

        function correctNumberOfThreads(nth::Integer, N::Integer)
            step = ceil(Int, N/nth)
            len = ceil(N/step) |> Int
            return len
        end

        nth = correctNumberOfThreads(nth, last(spacedim))

        if typeof(filepaths) == String
            filepaths_ = fill(filepaths, nth)
        else
            filepaths_ = filepaths
        end

        pathAndIO = map(filepaths_) do path
            mkpath(path)
            mktemp(path, cleanup=true)
        end

        paths    = map(first, pathAndIO)
        ioVector = map(last,  pathAndIO)

        mmaps         = [Vector{UInt8}() for _ in 1:nth]
        headpositions = zeros(Int64, nth)
        tailpositions = zeros(Int64, nth)
        timedim       = 0

        obj = new{dtype, length(spacedim)}(
            ioVector, mmaps, headpositions, tailpositions,
            spacedim, timedim, dtype, tol, precision, rate, nth, paths
        )
        finalizer(finalizeMmapFile!, obj)
        return obj
    end
end


function refreshMmaps!(comp::CompressedMmapArraySeq)
    for i in 1:comp.nth
        flush(comp.files[i])
        sz = filesize(comp.filePaths[i])
        if sz > 0
            comp.mmaps[i] = Mmap.mmap(comp.filePaths[i], Vector{UInt8}, sz)
        end
    end
end


Base.@propagate_inbounds function Base.getindex(compArray::CompressedMmapArraySeq, timeidx::Int)
    @boundscheck timeidx <= compArray.timedim || throw(BoundsError(compArray, timeidx))

    let nth = compArray.nth
        decompArray = zeros(compArray.eltype, compArray.spacedim...)

        @threads for (i, region) in collect(enumerate(SplitAxes(ax(compArray), nth)))
            idx  = posIdx(timeidx+1, i, nth)   # == timeidx*nth + i
            tail = compArray.tailpositions[idx]
            head = compArray.headpositions[idx]
            decomp = zeros(compArray.eltype, dims(region))
            zfp_decompress!(decomp, @view(compArray.mmaps[i][tail:head]);
                            tol=compArray.tol, precision=compArray.precision, rate=compArray.rate)
            decompArray[region...] = decomp
        end

        return decompArray
    end
end


function Base.append!(compArray::CompressedMmapArraySeq{T,N}, array::AbstractArray{T,N}) where {T<:AbstractFloat, N}
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

        refreshMmaps!(compArray)
        return nothing
    end
end


"""
    totalsize(compArray::CompressedMmapArraySeq)

Returns the total size of the compressed data in bytes.
"""
function totalsize(compArray::CompressedMmapArraySeq)
    return sum(map(filesize, compArray.filePaths))
end


"""
    cleanup!(comp::CompressedMmapArraySeq)

Close file streams and remove all backing temporary files.
"""
function cleanup!(comp::CompressedMmapArraySeq)
    finalizeMmapFile!(comp)
end
