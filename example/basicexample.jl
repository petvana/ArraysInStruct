module T

using ArraysInStruct
using BenchmarkTools

@arraysinstruct mutable struct Foo
    a::Int
    x[4]::UInt8
end

@show fieldnames(Foo)
@show sizeof(Foo)

@arraysinstruct mutable struct Foo2
    a::Int
    x[4]
end

@show fieldnames(Foo2)
@show sizeof(Foo2)

a = @btime Foo($1,$2,$3,$2,$4)

@show a

xx = T.a.x

@show xx
@show xx[1]
@show length(xx)
@show size(xx)

@btime length(xx)

@show typeof(xx)
@btime $xx[$1]
@btime @inbounds $xx[$1]

end