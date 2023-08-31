module SequentialCompression

using ZfpCompression: zfp_compress, zfp_decompress!

include("zfp.jl")

export CompressedArraySeq

end
