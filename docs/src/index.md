```@meta
CurrentModule = SequentialZfpCompression
```

# SequentialZfpCompression

Documentation for [SequentialZfpCompression](https://github.com/AtilaSaraiva/SequentialZfpCompression.jl).

This package aims to provide a nice interface for compression of multiple arrays of the same size in
sequence. These arrays can be up to 4D. The intended application is to store snapshots of a iterative
process such as a simulation or optimization process. Since sometimes these processes may require a lot of iterations, having compression might save you some RAM. This package uses the [ZFP compression algorithm](https://zfp.io/) algorithm.

##  A few comments before you start reading the code.

This code implements an vector like interface to access compressed
arrays at different time indexes, so to understand the code you need
to first read [the julia documentation on indexing
interfaces](https://docs.julialang.org/en/v1/manual/interfaces/#Indexing).
Basically, I had to implement a method for the `Base.getindex` function which governs if an type
can be indexed like an array or vector. I also wrote a method for the function `Base.append!` to
 add new arrays to the sequential collection of compressed arrays.

I also use functions like [`fill`](https://docs.julialang.org/en/v1/base/arrays/#Base.fill) and
[`map`](https://docs.julialang.org/en/v1/base/collections/#Base.map), so reading the documentation
on these functions might also help.


## Example

Here is an simple example of its usage. Imagine these A1 till A3 arrays are snapshots of a iterative process.

```jldoctest
using SequentialZfpCompression
using Test

# Lets define a few arrays to compress
A1 = rand(Float32, 100,100,100)
A2 = rand(Float32, 100,100,100)
A3 = rand(Float32, 100,100,100)

# Initializing the compressed array sequence
compSeq = SeqCompressor(Float32, 100, 100, 100)

# Compressing the arrays
append!(compSeq, A1)
append!(compSeq, A2)
append!(compSeq, A3)

# Asserting the decompressed array is the same
@test compSeq[1] == A1
@test compSeq[2] == A2
@test compSeq[3] == A3

# Dumping to a file
save("myarrays.szfp", compSeq)

# Reading it back
compSeq2 = load("myarrays.szfp")

# Asserting the loaded type is the same
@test compSeq[:] == compSeq2[:]

# output

Test Passed
```

## Lossy compression

Lossy compression is achieved by specifying additional keyword arguments
for `SeqCompressor`, which are `tol::Real`, `precision::Int`, and `rate::Real`.
If none are specified (as in the example above) the compression is lossless
(i.e. reversible). Lossy compression parameters are

- [`tol` defines the maximum absolute error that is tolerated.](https://zfp.readthedocs.io/en/release0.5.5/modes.html#fixed-accuracy-mode)
- [`precision` controls the precision, bounding a weak relative error](https://zfp.readthedocs.io/en/release0.5.5/modes.html#fixed-precision-mode), see this [FAQ](https://zfp.readthedocs.io/en/develop/faq.html#q-relerr)
- [`rate` fixes the bits used per value.](https://zfp.readthedocs.io/en/release0.5.5/modes.html#fixed-rate-mode)

## Multi file out-of-core parallel compression and decompression

This package has two workflows for compression. It can compress the array into a `Vector{UInt8}` and
keep it in memory, or it can slice the array and compress each slice, saving each slice to different
files, one per thread.

To use this out-of-core approach, you have four options:
+ Use the `inmemory=false` keyword to `SeqCompressor`. This will create the files for you in `tmpdir()`,
+ Specify `filepaths::Vector{String}` keyword argument with a list of folders, one for each thread,
+ Specify `filepaths::String` keyword argument with just one folder that will hold all the files,
+ Specify `envVarPath::String` keyword argument with the name of a environment variable that holds
  the path to the folder that will hold all the files. This might be useful if you are using a SLURM
  cluster, that allows you to access the local node storage via the `SLURM_TMPDIR` environment variable.



```@index
```

```@autodocs
Modules = [SequentialZfpCompression]
```
