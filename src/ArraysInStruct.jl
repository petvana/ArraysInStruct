module ArraysInStruct

import Base: getproperty, getindex, setindex!, length, size
export @arraysinstruct

struct Accesor{S,D,X}  <: AbstractArray{D,1} 
    ref::S
end

_symbol(basename, idx) = Symbol("$(basename)_$(idx)")
_first(X, S) = findfirst(isequal(_symbol(X, 1)), fieldnames(S))
@generated _offset(::S, ::Val{X}) where {S,X} = fieldoffset(S, _first(X, S))
@generated _isarray(::S, ::Val{X}) where {S,X} = _symbol(X, 1) in fieldnames(S)
@generated _type(::S, ::Val{X}) where {S,X} = fieldtype(S, _symbol(X, 1))

@generated function _length(::Accesor{S,D,X}) where {S,D,X}
    len = 0
    while _symbol(X, len+1) in fieldnames(S)
        len += 1
    end
    return len
end

length(a::Accesor) = _length(a)
size(a::Accesor) = (_length(a),)

function getindex(a::Accesor{S,D,X}, idx) where {S,D,X}
    @boundscheck checkbounds(a, idx)
    b = Base.unsafe_convert(Ptr{D}, pointer_from_objref(a.ref) + _offset(a.ref, Val(X)))
    GC.@preserve a unsafe_load(b, idx)
end

function setindex!(a::Accesor{S,D,X}, value, idx) where {S,D,X}
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
                    isconcretetype(eval(type)) || throw("Type of $(name) must be concrete (currently is $(type))")
                end
            elseif true
                if field.head == :ref
                    name, count = field.args
                    throw("Type of $(name) must be concrete")
                end
            end
        end
        if isarray
            for i in 1:count
                ex = Expr(:(::), _symbol(name, i), type)
                push!(expr.args[3].args, ex)
            end
        else
            push!(expr.args[3].args, field)
        end
    end

    S = expr.args[2]
    VA = []
    if S isa Expr && S.head == :curly
        for t in S.args[2:end]
            push!(VA, :($(esc(t))))
        end
    end

    functions = quote
        # Update Base.getproperty to register new array fields
        function ($(esc(:(Base.getproperty))))(obj::$(esc(S)), sym::Symbol) where {$(VA...)}
            if _isarray(obj, Val(sym))
                TYPE = _type(obj, Val(sym))
                return Accesor{$(esc(S)), TYPE, sym}(obj)
            else
                return getfield(obj, sym)
            end
        end
        # TODO constructor to initialize by array
        #($(esc(:(f))))(a::$(esc(S)), sym::Symbol) = Accesor{$(esc(S)), UInt8, sym}(a)
    end

    quote
        Base.@__doc__($(esc(expr)))
        $functions
    end
end

end # module
