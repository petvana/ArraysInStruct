using ArraysInStruct
using Test

@testset "UInt8" begin
    @arraysinstruct mutable struct FooM
        a::Int
        x[4]::UInt8
    end

    o = FooM(1, 2, 3, 4, 5)
    @test o.a == 1
    @test o.x[1] == 2
    @test o.x[2] == 3
    @test o.x[3] == 4
    @test o.x[4] == 5

    o.x[2] = 7
    @test o.x[2] == 7

    @test all(o.x .== [2, 7, 4, 5])

    get2(o) = o.x[2]
    get2(o) # compilation
    @test (@allocated get2(o)) == 0
end

@testset "Abstract" begin
    @arraysinstruct mutable struct FooA
        a::Int
        x[4]
    end

    o = FooA(1, 2, 3, 4, 5)
    @test o.a == 1
    @test o.x[1] == 2
    @test o.x[2] == 3
    @test o.x[3] == 4
    @test o.x[4] == 5

    o.x[2] = 7
    @test o.x[2] == 7

    @test all(o.x .== [2, 7, 4, 5])

    get2(o) = o.x[2]
    get2(o) # compilation
    @test (@allocated get2(o)) == 0
end
