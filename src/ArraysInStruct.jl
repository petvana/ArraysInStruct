module ArraysInStruct

import Base: getproperty, getindex, length, size
export @arraysinstruct

macro arraysinstruct(expr)
    @assert expr.head == :struct
    old_fields = copy(expr.args[3].args)
    empty!(expr.args[3].args)

    for field in old_fields
        isarray = false
        if field isa Expr
            if field.head == :(::)
                exp = field.args
                if exp[1] isa Expr && exp[1].head == :ref
                    isarray = true
                    name = exp[1].args[1]
                    count = exp[1].args[2]
                    type = exp[2]
                end
            elseif true
                if field.head == :ref
                    isarray = true
                    name = field.args[1]
                    count = field.args[2]
                    type = :Any
                end
            end
        end
        if isarray
            for i in 1:count
                ex = Expr(:(::), Symbol("$(name)_$(i)"), type)
                push!(expr.args[3].args, ex)
            end
        else
            push!(expr.args[3].args, field)
        end
    end

    T = expr.args[2]
    if T isa Expr && T.head === :<:
        T = T.args[1]
    end
    # This is inspired by Base.@kwdef
    # TODO: Prepare constructor using arrays
    # constructor = :(($(esc(T)))() = 3)
    newfce = :((f)() = 2)

    quote
        Base.@__doc__($(esc(expr)))
        # $constructor
        $newfce
    end
end

struct ArraysInStructAccessor{T, D, X}  <: AbstractArray{D,1} 
    ref::T
end

@generated function _offset(a::ArraysInStructAccessor{T, D, X}) where {T, D, X}
    fieldoffset(T, findfirst(isequal(Symbol("$(X)_1")), fieldnames(T)))
end

@generated function _length(a::ArraysInStructAccessor{T, D, X}) where {T, D, X}
    len = 1
    while Symbol("$(X)_$(len+1)") in fieldnames(T)
        len += 1
    end
    return len
end

length(a::ArraysInStructAccessor) = _length(a)
size(a::ArraysInStructAccessor) = (length(a),)

@generated function _offset(a::T) where T
    fieldoffset(T, findfirst(isequal(Symbol("x_1")), fieldnames(T)))
end

function getindex(a::ArraysInStructAccessor{T, D, X}, idx) where {T, D, X}
    @boundscheck checkbounds(a, idx)
    b = Base.unsafe_convert(Ptr{D}, pointer_from_objref(a.ref) + _offset(a.ref))
    GC.@preserve a unsafe_load(b, idx)
end

#=
function Base.getproperty(obj::Foo, sym::Symbol)
    if sym === :x
        return ArraysInStructAccessor{Foo, UInt8, sym}(obj)
    else # fallback to getfield
        return getfield(obj, sym)
    end
end
=#

end # module
