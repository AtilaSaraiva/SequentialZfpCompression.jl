function SeqCompressor(dtype::DataType, spacedim::Integer...;
                       rate::Int=0, tol::Real=0, precision::Real=0,
                       filepaths::Union{Vector{String}, String}="",
                       envVarPath::String="")

    if filepaths == ""
        if envVarPath != ""
            filepaths = ENV[envVarPath]
        else
            return CompressedArraySeq(dtype, spacedim...; rate=rate, tol=tol, precision=precision)
        end
    end

    return CompressedMultiFileArraySeq(dtype, spacedim...;
                                       rate=rate, tol=tol, precision=precision, filepaths=filepaths)
end
