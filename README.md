# ArraysInStruct

Experimental package for storing statically-sized arrays directly in structures

``` julia
julia> using ArraysInStruct

julia> @arraysinstruct mutable struct Foo
           a::Int
           x[4]::UInt8
       end

julia> @show fieldnames(Foo)
fieldnames(Foo) = (:a, :x_1, :x_2, :x_3, :x_4)
(:a, :x_1, :x_2, :x_3, :x_4)

julia> a = Foo(1,2,3,4,5)
Foo(1, 0x02, 0x03, 0x04, 0x05)

julia> a.x[2] = 42
42

julia> @show a.x
a.x = UInt8[0x02, 0x2a, 0x04, 0x05]
4-element ArraysInStruct.Accesor{Foo, UInt8, :x}:
 0x02
 0x2a
 0x04
 0x05

julia> @show a.x[1]
a.x[1] = 0x02
0x02

julia> copy(a.x)
4-element Vector{UInt8}:
 0x02
 0x2a
 0x04
 0x05

julia> a.x .= [1,2,3,6]
4-element ArraysInStruct.Accesor{Foo, UInt8, :x}:
 0x01
 0x02
 0x03
 0x06
```
