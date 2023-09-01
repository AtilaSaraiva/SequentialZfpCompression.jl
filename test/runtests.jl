using SequentialCompression
using Test

@testset "in memory compression" begin
    for dtype in [ Float32, Float64 ]
        for (n, m) in [[100, 100], [1000, 1000]]
            B = rand(dtype, n,m,3)

            Bc = CompressedArraySeq(dtype, n,m)

            for i = 1:3
                append!(Bc, B[:,:,i])
            end

            @test size(Bc) == (n, m, 3)
            @test ndims(Bc) == 3

            @test Bc[1] == B[:,:,1]
            @test Bc[2] == B[:,:,2]
            @test Bc[3] == B[:,:,3]

            @test Bc[:] == B
        end
    end
end

@testset "multifile compression" begin
    for dtype in [ Float32, Float64 ]
        for (n, m) in [[100, 100], [1000, 1000]]
            B = rand(dtype, n,m,3)

            Bc = CompressedMultiFileArraySeq(dtype, n,m)

            for i = 1:3
                append!(Bc, B[:,:,i])
            end

            @test size(Bc) == (n, m, 3)
            @test ndims(Bc) == 3

            @test Bc[1] == B[:,:,1]
            @test Bc[2] == B[:,:,2]
            @test Bc[3] == B[:,:,3]

            @test Bc[:] == B
        end
    end
end
