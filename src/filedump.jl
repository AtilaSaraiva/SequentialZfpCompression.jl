function save(filename::String, data::CompressedArraySeq)
    isCompressedArraySeq = true
    open(filename, "w") do io
        write(io, isCompressedArraySeq)
        serialize(io, data)
    end
    return nothing
end

function load(filename::String)
    open(filename, "r") do io
        isCompressedArraySeq = read(filename, Bool)
        seek(io, 1)
        if isCompressedArraySeq
            return deserialize(io)
        end
    end
end
