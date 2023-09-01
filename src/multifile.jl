mutable struct CompressedMultiFileArraySeq{T,Nx}
    files::Vector{IOStream}
    headpositions::Vector{Int64}
    tailpositions::Vector{Int64}
    spacedim::NTuple{Nx,Int32}
    timedim::Int32
    eltype::Type{T}
    tol::Float32
    precision::Float32
    rate::Int64

    function CompressedMultiFileArraySeq(dtype::DataType, spacedim::Integer...;
                                         rate::Int=0, tol::Real=0, precision::Real=0,
                                         filepaths::Union{Vector{String}, String}="/tmp/seqcomp")

        let nth = Threads.nthreads()

          if typeof(filepaths) == String
              filepaths_ = fill(filepaths, Threads.nthreads())
              # create a vector like ["/tmp/seqcomp", "/tmp/seqcomp", ...]
          else
              filepaths_ = filepaths
          end
          files = map(filepaths_) do path
              mkpath(path)
              mktemp(path, cleanup=true) |> last
          end # creates a [IOStream, IOStream, ...]

          headpositions = zeros(Int64, nth) # trick to avoid checking for the first iteration in the append! function
          tailpositions = zeros(Int64, nth) # which means the timedim = length(tailpositions) - 1
          eltype = dtype
          timedim = 0

          return new{dtype, length(spacedim)}(files, headpositions, tailpositions, spacedim, timedim, eltype, tol, precision, rate)

        end
    end
end

ax(A) = map(N->1:N, A.spacedim)
dims(region) = map(r -> r[end] - r[1] + 1, region)

Base.@propagate_inbounds function Base.getindex(compArray::CompressedMultiFileArraySeq, timeidx::Int)
    @boundscheck timeidx <= compArray.timedim || throw(BoundsError(compArray, timeidx))

    let nth = Threads.nthreads()

      decompArray = zeros(compArray.eltype, compArray.spacedim...)

      i = 1
      for region in SplitAxes(ax(compArray), nth)
          seek(compArray.files[i], compArray.headpositions[timeidx*nth+i]-1)
          compressedVector = read(compArray.files[i], compArray.tailpositions[(timeidx)*nth+i] - compArray.headpositions[(timeidx)*nth+i] + 1)
          decomp = zeros(compArray.eltype, dims(region))
          zfp_decompress!(decomp, compressedVector;
                          tol=compArray.tol, precision=compArray.precision, rate=compArray.rate)
          decompArray[region...] = decomp
          i+=1
      end

      return decompArray

    end
end

function Base.append!(compArray::CompressedMultiFileArraySeq{T,N}, array::AbstractArray{T,N}) where {T<:AbstractFloat, N}

    let nth = Threads.nthreads()

      auxHeadPosition = Vector{Int64}(undef, nth)
      auxTailPosition = Vector{Int64}(undef, nth)

      i = 1
      for region in SplitAxes(ax(compArray), nth)
          data = zfp_compress(array[region...],
                              write_header=false,
                              tol=compArray.tol, precision=compArray.precision, rate=compArray.rate,
                              nthreads=nth)
          fileSize = length(data)
          seekend(compArray.files[i])
          write(compArray.files[i], data)
          auxHeadPosition[i] = compArray.headpositions[end-nth+i] + 1
          auxTailPosition[i] = compArray.headpositions[end-nth+i] + fileSize
          i+=1
      end

      append!(compArray.headpositions, auxHeadPosition)
      append!(compArray.tailpositions, auxTailPosition)
      compArray.timedim += 1
      return nothing

    end
end
