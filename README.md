# SequentialCompression

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://AtilaSaraiva.github.io/SequentialCompression.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://AtilaSaraiva.github.io/SequentialCompression.jl/dev/)
[![Build Status](https://github.com/AtilaSaraiva/SequentialCompression.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/AtilaSaraiva/SequentialCompression.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/AtilaSaraiva/SequentialCompression.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/AtilaSaraiva/SequentialCompression.jl)

This package aims to provide a nice interface for compression of multiple arrays of the same size in
sequence. These arrays can be up to 4D. The intended application is to store snapshots of a iterative
process such as a simulation or optimization process. Since sometimes these processes may require a lot of iterations, having compression might save you some RAM. This package uses the [ZFP compression algorithm](https://zfp.io/) algorithm.

## Example

Here is an simple example of its usage. Imagine these A1 till A3 arrays are snapshots of a iterative process.

```julia
using SequentialCompression
using Test

# Lets define a few arrays to compress
A1 = rand(100,100)
A2 = rand(100,100)
A3 = rand(100,100)

# Initializing the compressed array sequence
compSeq = CompressedArraySeq(A1)

# Compressing a the rest of the arrays
append!(compSeq, A2)
append!(compSeq, A3)

# Asserting the decompressed array is the same
@test compSeq[1] == A1
@test compSeq[2] == A2
@test compSeq[3] == A3
```

## TODO

- [X] Add bound checking
- [X] Add documentation for each method
- [ ] Add support for compression rate, tolerance and precision
- [ ] Add support for parallel compression
