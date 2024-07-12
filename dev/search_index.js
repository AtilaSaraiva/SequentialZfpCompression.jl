var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = SequentialZfpCompression","category":"page"},{"location":"#SequentialZfpCompression","page":"Home","title":"SequentialZfpCompression","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for SequentialZfpCompression.","category":"page"},{"location":"","page":"Home","title":"Home","text":"This package aims to provide a nice interface for compression of multiple arrays of the same size in sequence. These arrays can be up to 4D. The intended application is to store snapshots of a iterative process such as a simulation or optimization process. Since sometimes these processes may require a lot of iterations, having compression might save you some RAM. This package uses the ZFP compression algorithm algorithm.","category":"page"},{"location":"#A-few-comments-before-you-start-reading-the-code.","page":"Home","title":"A few comments before you start reading the code.","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This code implements an vector like interface to access compressed arrays at different time indexes, so to understand the code you need to first read the julia documentation on indexing interfaces. Basically, I had to implement a method for the Base.getindex function which governs if an type can be indexed like an array or vector. I also wrote a method for the function Base.append! to  add new arrays to the sequential collection of compressed arrays.","category":"page"},{"location":"","page":"Home","title":"Home","text":"I also use functions like fill and map, so reading the documentation on these functions might also help.","category":"page"},{"location":"#Example","page":"Home","title":"Example","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Here is an simple example of its usage. Imagine these A1 till A3 arrays are snapshots of a iterative process.","category":"page"},{"location":"","page":"Home","title":"Home","text":"using SequentialZfpCompression\nusing Test\n\n# Lets define a few arrays to compress\nA1 = rand(Float32, 100,100,100)\nA2 = rand(Float32, 100,100,100)\nA3 = rand(Float32, 100,100,100)\n\n# Initializing the compressed array sequence\ncompSeq = SeqCompressor(Float32, 100, 100, 100)\n\n# Compressing the arrays\nappend!(compSeq, A1)\nappend!(compSeq, A2)\nappend!(compSeq, A3)\n\n# Asserting the decompressed array is the same\n@test compSeq[1] == A1\n@test compSeq[2] == A2\n@test compSeq[3] == A3\n\n# Dumping to a file\nsave(\"myarrays.szfp\", compSeq)\n\n# Reading it back\ncompSeq2 = load(\"myarrays.szfp\")\n\n# Asserting the loaded type is the same\n@test compSeq[:] == compSeq2[:]\n\n# output\n\nTest Passed","category":"page"},{"location":"#Lossy-compression","page":"Home","title":"Lossy compression","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Lossy compression is achieved by specifying additional keyword arguments for SeqCompressor, which are tol::Real, precision::Int, and rate::Real. If none are specified (as in the example above) the compression is lossless (i.e. reversible). Lossy compression parameters are","category":"page"},{"location":"","page":"Home","title":"Home","text":"tol defines the maximum absolute error that is tolerated.\nprecision controls the precision, bounding a weak relative error, see this FAQ\nrate fixes the bits used per value.","category":"page"},{"location":"#Multi-file-out-of-core-parallel-compression-and-decompression","page":"Home","title":"Multi file out-of-core parallel compression and decompression","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package has two workflows for compression. It can compress the array into a Vector{UInt8} and keep it in memory, or it can slice the array and compress each slice, saving each slice to different files, one per thread.","category":"page"},{"location":"","page":"Home","title":"Home","text":"To use this out-of-core approach, you have four options:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Use the inmemory=false keyword to SeqCompressor. This will create the files for you in tmpdir(),\nSpecify filepaths::Vector{String} keyword argument with a list of folders, one for each thread,\nSpecify filepaths::String keyword argument with just one folder that will hold all the files,\nSpecify envVarPath::String keyword argument with the name of a environment variable that holds the path to the folder that will hold all the files. This might be useful if you are using a SLURM cluster, that allows you to access the local node storage via the SLURM_TMPDIR environment variable.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [SequentialZfpCompression]","category":"page"},{"location":"#SequentialZfpCompression.CompressedArraySeq","page":"Home","title":"SequentialZfpCompression.CompressedArraySeq","text":"CompressedArraySeq{T,Nx}\n\nA mutable structure for storing time-dependent arrays in a compressed format.\n\nFields\n\ndata::Vector{UInt8}: Compressed data in byte form.\nheadpositions::Vector{Int64}: Positions of the beginning of each time slice in data.\ntailpositions::Vector{Int64}: Positions of the end of each time slice in data.\nspacedim::NTuple{Nx,Int32}: Dimensions of the spatial grid.\ntimedim::Int32: Number of time steps.\neltype::Type{T}: Element type of the uncompressed array.\ntol::Float32: Mean absolute error that is tolerated.\nprecision::Float32: Controls the precision, bounding a weak relative error.\nrate::Int64: Fixes the bits used per value.\n\n\n\n\n\n","category":"type"},{"location":"#SequentialZfpCompression.CompressedMultiFileArraySeq","page":"Home","title":"SequentialZfpCompression.CompressedMultiFileArraySeq","text":"CompressedMultiFileArraySeq{T,Nx}\n\nA compressed time-dependent array that is stored in multiple files, one per thread.\n\nFields\n\nfiles::Vector{IOStream}: IO object for each array slice.\nheadpositions::Vector{Int64}: Positions of the beginning of each time slice in data.\ntailpositions::Vector{Int64}: Positions of the end of each time slice in data.\nspacedim::NTuple{Nx,Int32}: Dimensions of the spatial grid.\ntimedim::Int32: Number of time steps.\neltype::Type{T}: Element type of the uncompressed array.\ntol::Float32: Mean absolute error that is tolerated.\nprecision::Float32: Controls the precision, bounding a weak relative error.\nrate::Int64: Fixes the bits used per value.\n\nArguments exclusive for the constructor\n\nfilepaths::Union{Vector{String}, String}=\"/tmp/seqcomp\": Path(s) to the files where the compressed data will be stored. If only one string is passed, the same path will be used for all threads.\n\n\n\n\n\n","category":"type"},{"location":"#Base.append!-Union{Tuple{N}, Tuple{T}, Tuple{SequentialZfpCompression.CompressedArraySeq{T, N}, AbstractArray{T, N}}} where {T<:AbstractFloat, N}","page":"Home","title":"Base.append!","text":"append!(compArray::CompressedArraySeq{T,N}, array::AbstractArray{T,N})\n\nAppend a new time slice to compArray, compressing array in the process.\n\nArguments\n\ncompArray::CompressedArraySeq{T,N}: Existing compressed array.\narray::AbstractArray{T,N}: Uncompressed array to append.\n\n```\n\n\n\n\n\n","category":"method"},{"location":"#Base.getindex-Tuple{SequentialZfpCompression.CompressedArraySeq, Int64}","page":"Home","title":"Base.getindex","text":"getindex(compArray::AbstractCompArraySeq, timeidx::Int)\n\nRetrieve and decompress a single time slice from compArray at timeidx.\n\n\n\n\n\n","category":"method"},{"location":"#Base.ndims-Tuple{SequentialZfpCompression.AbstractCompArraySeq}","page":"Home","title":"Base.ndims","text":"ndims(compArray::AbstractCompArraySeq)\n\nReturns the number of dimensions of the uncompressed array, including the time dimension.\n\n\n\n\n\n","category":"method"},{"location":"#Base.size-Tuple{SequentialZfpCompression.AbstractCompArraySeq}","page":"Home","title":"Base.size","text":"size(compArray::AbstractCompArraySeq)\n\nReturns the dimensions of the uncompressed array, with the last dimension being the time dimension.\n\n\n\n\n\n","category":"method"},{"location":"#SequentialZfpCompression.SeqCompressor-Tuple{DataType, Vararg{Integer}}","page":"Home","title":"SequentialZfpCompression.SeqCompressor","text":"SeqCompressor(dtype::DataType, spacedim::Integer...;\n              rate::Int=0, tol::Real=0, precision::Real=0,\n              filepaths::Union{Vector{String}, String}=\"\",\n              envVarPath::String=\"\")\n\nConstruct a CompressedArraySeq or CompressedMultiFileArraySeq depending on the arguments.\n\nArguments\n\ndtype::DataType: the type of the array to be compressed\nspacedim::Integer...: the dimensions of the array to be compressed\ninmemory::Bool=true: whether the compressed data will be stored in memory or in disk\nrate::Int64: Fixes the bits used per value.\ntol::Float32: Mean absolute error that is tolerated.\nprecision::Float32: Controls the precision, bounding a weak relative error.\nfilepaths::Union{Vector{String}, String}=\"\": the path(s) to the files to be compressed\nenvVarPath::String=\"\": the name of the environment variable that contains the path to the files to be compressed\n\nYou have the option of passing an environment variable, a file path, a vector of file paths, or nothing. If you pass a vector of file paths, the number of paths must be equal to the number of threads. If you pass a single file path, the same path will be used for all threads. If you pass an environment variable, the file path will be extracted from it. It might be useful if you are using a SLURM job scheduler, for example, since the local disk of the node can be accessed by ENV[\"SLURM_TMPDIR\"].\n\nExample\n\njulia> using SequentialZfpCompression\n\njulia> A = SeqCompressor(Float64, 4, 4)\nSequentialZfpCompression.CompressedArraySeq{Float64, 2}(UInt8[], [0], [0], (4, 4), 0, Float64, 0.0f0, 0, 0)\n\njulia> A.timedim\n0\n\njulia> size(A)\n(4, 4, 0)\n\njulia> append!(A, ones(Float64, 4, 4));\n\njulia> A[1]\n4×4 Matrix{Float64}:\n 1.0  1.0  1.0  1.0\n 1.0  1.0  1.0  1.0\n 1.0  1.0  1.0  1.0\n 1.0  1.0  1.0  1.0\n\njulia> size(A)\n(4, 4, 1)\n\n\n\n\n\n","category":"method"},{"location":"#SequentialZfpCompression.totalsize-Tuple{SequentialZfpCompression.CompressedMultiFileArraySeq}","page":"Home","title":"SequentialZfpCompression.totalsize","text":"totalsize(compArray::CompressedMultiFileArraySeq)\n\nReturns the total size of the compressed data in bytes.\n\n\n\n\n\n","category":"method"}]
}
