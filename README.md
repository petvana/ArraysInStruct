# ArraysInStruct

Experimental package for storing statically-sized arrays directly in structures

``` julia
julia> using ArraysInStruct

julia> @arraysinstruct mutable struct Foo{X,Y}
           a::Int
           x[2]::X
           y[2]::Pair{X,Y}
       end

julia> o = Foo{UInt8, Float16}(1, 2, 3, 4 => 5, 6 => 7)
Foo{UInt8, Float16}(1, 0x02, 0x03, 0x04 => Float16(5.0), 0x06 => Float16(7.0))

julia> fieldnames(Foo{UInt8, Float16})
(:a, :x_1, :x_2, :y_1, :y_2)

julia> o.x[2] = 42
42

julia> @show o.x
o.x = UInt8[0x02, 0x2a]
2-element ArraysInStruct.Accesor{Foo{UInt8, Float16}, UInt8, :x}:
 0x02
 0x2a

julia> @show o.x[1]
o.x[1] = 0x02
0x02

julia> o.x .= [1,2]
2-element ArraysInStruct.Accesor{Foo{UInt8, Float16}, UInt8, :x}:
 0x01
 0x02

julia> copy(o.y)
2-element Vector{Pair{UInt8, Float16}}:
 0x04 => 5.0
 0x06 => 7.0
```
### Known limitations

| :exclamation:  The array types need to be of a concrete type!   |
|-----------------------------------------|

Otherwise, the GC would remove the content, leading to errors. Therefore, it is not possible to implement, for example, B-tree using this package for now.

