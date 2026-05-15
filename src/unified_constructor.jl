"""
    SeqCompressor(dtype::DataType, spacedim::Integer...;
                  inmemory::Bool=true, mmap::Bool=false,
                  rate::Int=0, tol::Real=0, precision::Real=0,
                  filepaths::Union{Vector{String}, String}="",
                  envVarPath::String="", nthreads::Integer=-1, nt::Integer=1)

Construct a compressed sequential array, choosing the backend based on the arguments:

| Condition | Backend |
|-----------|---------|
| `mmap=true` | `CompressedMmapArraySeq` — file-backed, zero-copy reads via mmap. Call `refreshMmaps!` once after all `append!` calls and before any indexing. |
| `inmemory=true` (default) | `CompressedArraySeq` — all data held in a `Vector{UInt8}` in RAM. |
| `inmemory=false` | `CompressedMultiFileArraySeq` — file-backed with standard seek/read IO. |

# Arguments
- `dtype::DataType`: element type of the arrays to compress (e.g. `Float32`, `Float64`).
- `spacedim::Integer...`: spatial dimensions of each time slice.
- `inmemory::Bool=true`: store compressed data in memory (ignored when `mmap=true`).
- `mmap::Bool=false`: use memory-mapped file backend for zero-copy reads.
- `rate::Int=0`: [fixed-rate mode](https://zfp.readthedocs.io/en/release0.5.5/modes.html#fixed-rate-mode) — bits per value.
- `tol::Real=0`: [fixed-accuracy mode](https://zfp.readthedocs.io/en/release0.5.5/modes.html#fixed-accuracy-mode) — maximum absolute error.
- `precision::Real=0`: [fixed-precision mode](https://zfp.readthedocs.io/en/release0.5.5/modes.html#fixed-precision-mode) — number of uncompressed bits per value.
- `filepaths::Union{Vector{String}, String}=""`: directory or per-thread file paths for
  file-backed backends. A single string is used as a directory for all threads; a vector
  must have one entry per thread. Ignored for `inmemory=true`.
- `envVarPath::String=""`: name of an environment variable whose value is used as the file
  path (useful with SLURM's `SLURM_TMPDIR`). Takes precedence over `filepaths`.
- `nthreads::Integer=-1`: maximum number of threads to use. Defaults to `Threads.nthreads()`.
- `nt::Integer=1`: expected number of time steps, used to pre-allocate the in-memory buffer.

# Examples

In-memory (default):
```jldoctest
julia> using SequentialZfpCompression

julia> A = SeqCompressor(Float64, 4, 4)
SequentialZfpCompression.CompressedArraySeq{Float64, 2}(UInt8[], [0], [0], (4, 4), 0, Float64, 0.0f0, 0, 0)

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

Memory-mapped (write all, then refresh once before reading):
```julia
A = SeqCompressor(Float32, 64, 64; mmap=true)
for t in 1:100
    append!(A, my_slice(t))
end
refreshMmaps!(A)   # map the completed files into memory
A[50]              # zero-copy read
```
"""
function SeqCompressor(dtype::DataType, spacedim::Integer...;
                       inmemory::Bool=true,
                       mmap::Bool=false,
                       rate::Int=0, tol::Real=0, precision::Real=0,
                       filepaths::Union{Vector{String}, String}="",
                       envVarPath::String="", nthreads::Integer=-1, nt::Integer=1)

    if mmap
        fp = envVarPath != "" ? ENV[envVarPath] : filepaths
        if fp == ""
            return CompressedMmapArraySeq(dtype, spacedim...;
                                          rate=rate, tol=tol, precision=precision, nthreads=nthreads)
        end
        return CompressedMmapArraySeq(dtype, spacedim...;
                                      rate=rate, tol=tol, precision=precision, filepaths=fp, nthreads=nthreads)
    end

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
