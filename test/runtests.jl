import SequentialZfpCompression as sc
using Test
import Random

@testset "in memory compression" begin
    for dtype in [ Float32, Float64 ]
        for dims in ((100, 100), (50,50,50))
            B = rand(dtype, dims...,3)

            Bc = sc.SeqCompressor(dtype, dims..., inmemory=true)

            for i = 1:3
                append!(Bc, selectdim(B, ndims(B), i) |> copy)
            end

            @test size(Bc) == (dims..., 3)
            @test ndims(Bc) == ndims(B)

            @test Bc[1] == selectdim(B, ndims(B), 1)
            @test Bc[2] == selectdim(B, ndims(B), 2)
            @test Bc[3] == selectdim(B, ndims(B), 3)

            @test Bc[:] == B

            path, _ = mktemp(cleanup=true)
            sc.save(path, Bc)
            Bcloaded = sc.load(path)

            @test Bcloaded[:] == B
        end
    end
end

@testset "multifile compression" begin
    Random.seed!(3)
    for dtype in [ Float32, Float64 ]
        for dims in ((100, 100), (50,50,50))
            for nth in (-1,  rand() * Threads.nthreads() |> floor |> Int16)
                B = rand(dtype, dims...,3)

                Bc = sc.SeqCompressor(dtype, dims..., inmemory=false)

                for i = 1:3
                    append!(Bc, selectdim(B, ndims(B), i) |> copy)
                end

                @test size(Bc) == (dims..., 3)
                @test ndims(Bc) == ndims(B)

                @test Bc[1] == selectdim(B, ndims(B), 1)
                @test Bc[2] == selectdim(B, ndims(B), 2)
                @test Bc[3] == selectdim(B, ndims(B), 3)

                @test Bc[:] == B

                metadatapath, _ = mktemp(cleanup=true)
                datapath = [ mktemp(cleanup=true) |> first for i in 1:Bc.nth ]

                # Giving the data path as a vector
                sc.save(metadatapath, datapath,  Bc)
                Bcloaded = sc.load(metadatapath)

                @test Bcloaded[:] == B

                # Infering the data path from the metadata path
                sc.save(metadatapath, Bc)
                Bcloaded = sc.load(metadatapath)

                @test Bcloaded[:] == B
            end
        end
    end
end
