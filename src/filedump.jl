function save(filename::String, data::CompressedArraySeq)
    isCompressedArraySeq = true
    open(filename, "w") do io
        write(io, isCompressedArraySeq)
        serialize(io, data)
    end
    return nothing
end

function convertTypeToInt(eltype::DataType)
    if eltype == Float32
        return Int8(1)
    elseif eltype == Float64
        return Int8(2)
    elseif eltype == Int32
        return Int8(3)
    elseif eltype == Int64
        return Int8(4)
    end
end

function convertIntToType(eltype::Int8)
    if eltype == 1
        return Float32
    elseif eltype == 2
        return Float64
    elseif eltype == 3
        return Int32
    elseif eltype == 4
        return Int64
    end
end

function vectorToCommaSeparatedString(vector::Vector{String})
    string = ""
    for i in 1:length(vector)-1
        string *= vector[i]
        string *= ","
    end
    string *= vector[end]
    return string
end

function save(metadataFilepath::String, data::CompressedMultiFileArraySeq)
    nameWithoutExtension = split(metadataFilepath, ".")[1]
    dataFilepath = map(1:length(data.files)) do i
        nameWithoutExtension * "_data_" * string(i) * ".bin"
    end

    save(metadataFilepath, dataFilepath, data)

    return nothing
end

function save(metadataFilepath::String, dataFilepath::Vector{String},
              data::CompressedMultiFileArraySeq)

    isCompressedArraySeq = false
    open(metadataFilepath, "w") do io
        write(io, isCompressedArraySeq)
        write(io, data.timedim)
        write(io, Int8(length(data.spacedim)))
        for i in 1:length(data.spacedim)
            write(io, data.spacedim[i])
        end
        write(io, data.nth)
        write(io, data.tol)
        write(io, data.rate)
        write(io, data.precision)
        write(io, convertTypeToInt(data.eltype))
        write(io, data.headpositions)
        write(io, data.tailpositions)
        dataFilepathString = vectorToCommaSeparatedString(dataFilepath)
        write(io, dataFilepathString)
    end

    for i in 1:length(dataFilepath)
        open(dataFilepath[i], "w") do io
            seekstart(data.files[i])
            write(io, read(data.files[i]))
        end
    end
    return nothing
end

function loadCompressedMultiFileArraySeq(io)
    timedim = read(io, Int32)
    ndims = read(io, Int8)
    spacedim = zeros(Int32, ndims)
    for i in 1:ndims
        spacedim[i] = read(io, Int32)
    end
    spacedim = Tuple(spacedim)
    nth = read(io, Int16)
    tol = read(io, Float32)
    rate = read(io, Int64)
    precision = read(io, Int64)
    eltype = read(io, Int8) |> convertIntToType
    headpositions = zeros(Int64, (timedim+1)*nth)
    tailpositions = zeros(Int64, (timedim+1)*nth)
    read!(io, headpositions)
    read!(io, tailpositions)
    dataFilepathString = read(io, String)
    dataFilepath = split(dataFilepathString, ",")

    files = map(dataFilepath) do path
        open(path, "r+")
    end # creates a [IOStream, IOStream, ...]

    return CompressedMultiFileArraySeq(
              files,
              headpositions,
              tailpositions,
              spacedim,
              timedim,
              eltype,
              tol,
              precision,
              rate,
              nth
           )
end

function load(filename::String)
    open(filename, "r") do io
        isCompressedArraySeq = read(io, Bool)
        if isCompressedArraySeq
            return deserialize(io)
        else
            return loadCompressedMultiFileArraySeq(io)
        end
    end
end
