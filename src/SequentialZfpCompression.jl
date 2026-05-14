module SequentialZfpCompression

using ZfpCompression: zfp_compress, zfp_decompress!
using TiledIteration: SplitAxes
using Base.Threads: @threads, nthreads
using Serialization: serialize, deserialize
using Mmap

abstract type AbstractCompArraySeq end

include("seqcomp.jl")
include("multifile.jl")
include("mmapfile.jl")
include("unified_constructor.jl")
include("filedump.jl")

export SeqCompressor, save, load, totalsize, cleanup!, CompressedMmapArraySeq

end
