module SequentialCompression

using ZfpCompression: zfp_compress, zfp_decompress!
using Mmap: mmap, sync!
using TiledIteration: SplitAxes

include("seqcomp.jl")
include("multifile.jl")

export CompressedArraySeq, CompressedMultiFileArraySeq

end
