module SequentialCompression

using ZfpCompression: zfp_compress, zfp_decompress!

include("seqcomp.jl")

export CompressedArraySeq

end
