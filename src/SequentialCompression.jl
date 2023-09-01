module SequentialCompression

using ZfpCompression: zfp_compress, zfp_decompress!
using TiledIteration: SplitAxes
using Base.Threads: @threads, nthreads

abstract type AbstractCompArraySeq end

include("seqcomp.jl")
include("multifile.jl")

export CompressedArraySeq, CompressedMultiFileArraySeq

end
