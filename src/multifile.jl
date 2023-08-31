mutable struct CompressedMultiFileArraySeq{T,Nx}
    files::Vector{IOStream}
    headpositions::Vector{Int64}
    tailpositions::Vector{Int64}
    spacedim::NTuple{Nx,Int32}
    timedim::Int32
    eltype::Type{T}
    tol::Float32
    precision::Float32
    rate::Int64

    function CompressedMultiFileArraySeq(dtype::DataType, spacedim::Integer...;
                                         rate::Int=0, tol::Real=0, precision::Real=0,
                                         filepaths::Union{Vector{String}, String}="/tmp/seqcomp")
        if typeof(filepaths) == String
            filepaths_ = fill(filepaths, Threads.nthreads())
            # create a vector like ["/tmp/seqcomp", "/tmp/seqcomp", ...]
        else
            filepaths_ = filepaths
        end
        files = map(filepaths_) do path
            mkpath(path)
            mktemp(path, cleanup=true) |> last
        end # creates a [IOStream, IOStream, ...]

        headpositions = Int64[0] # trick to avoid checking for the first iteration in the append! function
        tailpositions = Int64[0] # which means the timedim = length(tailpositions) - 1
        eltype = dtype
        timedim = 0

        return new{dtype, length(spacedim)}(files, headpositions, tailpositions, spacedim, timedim, eltype, tol, precision, rate)
    end
end
