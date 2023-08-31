module SequentialCompression

using ZfpCompression: zfp_compress, zfp_decompress!
using Mmap: mmap, sync!

include("seqcomp.jl")

export CompressedArraySeq

end
