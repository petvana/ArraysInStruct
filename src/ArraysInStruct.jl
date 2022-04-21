module ArraysInStruct

import Base: getproperty, getindex, setindex!, length, size
export @arraysinstruct

struct ArraysInStructAccessor{T, D, X}  <: AbstractArray{D,1} 
    ref::T
end

@generated function _isarrayinstruct(a::T, ::Val{X}) where {T,X}
    Symbol("$(X)_1") in fieldnames(T)
end

@generated function _offset(a::ArraysInStructAccessor{T, D, X}) where {T, D, X}
    fieldoffset(T, findfirst(isequal(Symbol("$(X)_1")), fieldnames(T)))
end

@generated function _length(a::ArraysInStructAccessor{T, D, X}) where {T, D, X}
    len = 0
    while Symbol("$(X)_$(len+1)") in fieldnames(T)
        len += 1
    end
    return len
end

@generated function _offset(a::T, ::Val{X}) where {T,X}
    # TODO
    fieldoffset(T, findfirst(isequal(Symbol("$(X)_1")), fieldnames(T)))
end

@generated function _type(a::T, ::Val{X}) where {T,X}
    # TODO
    fieldtype(T, Symbol("$(X)_1"))
end

length(a::ArraysInStructAccessor) = _length(a)
size(a::ArraysInStructAccessor) = (length(a),)

function getindex(a::ArraysInStructAccessor{T, D, X}, idx) where {T, D, X}
    @boundscheck checkbounds(a, idx)
    b = Base.unsafe_convert(Ptr{D}, pointer_from_objref(a.ref) + _offset(a.ref, Val(X)))
    GC.@preserve a unsafe_load(b, idx)
end

function setindex!(a::ArraysInStructAccessor{T, D, X}, value, idx) where {T, D, X}
    @boundscheck checkbounds(a, idx)
    b = Base.unsafe_convert(Ptr{D}, pointer_from_objref(a.ref) + _offset(a.ref, Val(X)))
    GC.@preserve a unsafe_store!(b, value, idx)
end

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
                    name, count = exp[1].args
                    type = exp[2]
                end
            elseif true
                if field.head == :ref
                    isarray = true
                    name, count = field.args
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
    # Define getproperty
    functions = quote
        function ($(esc(:(Base.getproperty))))(obj::$(esc(T)), sym::Symbol) 
            if _isarrayinstruct(obj, Val(sym))
                TYPE = _type(obj, Val(sym))
                return ArraysInStructAccessor{$(esc(T)), TYPE, sym}(obj)
            else
                return getfield(obj, sym)
            end
        end
        # TODO constructor to initialize by array
        #($(esc(:(f))))(a::$(esc(T)), sym::Symbol) = ArraysInStructAccessor{$(esc(T)), UInt8, sym}(a)
    end

    quote
        Base.@__doc__($(esc(expr)))
        $functions
    end
end

end # module
