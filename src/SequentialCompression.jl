module SequentialCompression

using ZfpCompression: zfp_compress, zfp_decompress!
using TiledIteration: SplitAxes
using Base.Threads: @threads, nthreads
using Serialization: serialize, deserialize

abstract type AbstractCompArraySeq end

include("seqcomp.jl")
include("multifile.jl")
include("unified_constructor.jl")
include("filedump.jl")

export SeqCompressor, save, load, totalsize

end
