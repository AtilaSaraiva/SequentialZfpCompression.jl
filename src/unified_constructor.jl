"""
    SeqCompressor(dtype::DataType, spacedim::Integer...;
                  rate::Int=0, tol::Real=0, precision::Real=0,
                  filepaths::Union{Vector{String}, String}="",
                  envVarPath::String="")

Construct a `CompressedArraySeq` or `CompressedMultiFileArraySeq` depending on the arguments.

# Arguments
- `dtype::DataType`: the type of the array to be compressed
- `spacedim::Integer...`: the dimensions of the array to be compressed
- `inmemory::Bool=true`: whether the compressed data will be stored in memory or in disk
- `rate::Int64`: [Fixes the bits used per value](https://zfp.readthedocs.io/en/release0.5.5/modes.html#fixed-rate-mode).
- `tol::Float32`: [Mean absolute error that is tolerated](https://zfp.readthedocs.io/en/release0.5.5/modes.html#fixed-accuracy-mode).
- `precision::Float32`: [Controls the precision, bounding a weak relative error](https://zfp.readthedocs.io/en/release0.5.5/modes.html#fixed-precision-mode).
- `filepaths::Union{Vector{String}, String}=""`: the path(s) to the files to be compressed
- `envVarPath::String=""`: the name of the environment variable that contains the path to the files to be compressed

You have the option of passing an environment variable, a file path, a vector of file paths, or nothing.
If you pass a vector of file paths, the number of paths must be equal to the number of threads.
If you pass a single file path, the same path will be used for all threads.
If you pass an environment variable, the file path will be extracted from it. It might be useful if you are
using a SLURM job scheduler, for example, since the local disk of the node can be accessed by ENV["SLURM_TMPDIR"].

# Example
```jldoctest
julia> using SequentialZfpCompression

julia> A = SeqCompressor(Float64, 4, 4)
SequentialZfpCompression.CompressedArraySeq{Float64, 2}(UInt8[], [0], [0], (4, 4), 0, Float64, 0.0f0, 0, 0)

julia> A.timedim
0

julia> size(A)
(4, 4, 0)

julia> append!(A, ones(Float64, 4, 4));

julia> A[1]
4×4 Matrix{Float64}:
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0

julia> size(A)
(4, 4, 1)
```
"""
function SeqCompressor(dtype::DataType, spacedim::Integer...;
                       inmemory::Bool=true,
                       rate::Int=0, tol::Real=0, precision::Real=0,
                       filepaths::Union{Vector{String}, String}="",
                       envVarPath::String="", nthreads::Integer=-1, nt::Integer=1)

    if inmemory && filepaths == "" && envVarPath == ""
        return CompressedArraySeq(dtype, spacedim...; rate=rate, tol=tol, precision=precision, nt=nt)
    end

    if filepaths == ""
        return CompressedMultiFileArraySeq(dtype, spacedim...;
                                           rate=rate, tol=tol, precision=precision, nthreads=nthreads)
    end

    if envVarPath != ""
        filepaths = ENV[envVarPath]
    end

    return CompressedMultiFileArraySeq(dtype, spacedim...;
                                       rate=rate, tol=tol, precision=precision, filepaths=filepaths, nthreads=nthreads)
end
