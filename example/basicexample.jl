module T

using ArraysInStruct
using BenchmarkTools

@arraysinstruct mutable struct Foo
    a::Int
    x[4]::UInt8
end

@show fieldnames(Foo)

@arraysinstruct mutable struct Foo2
    a::Int
    x[4]
end

@show fieldnames(Foo2)

a = @btime Foo($1,$2,$3,$2,$4)

@show xx = a.x

xx[1] = 6

@show xx[1]
@show length(xx)
@show size(xx)

@btime length(xx)

@show typeof(xx)
@btime $xx[$1]
@btime @inbounds $xx[$1]

f(a, i) = a.x[i]

@btime $f($a, $1)

@show a.a


end