mutable struct Monkey
    id::Int
    items::Vector{BigInt}
    op::Function
    test::Function
    inspections::Int
end

function keepaway(infile)
    monkeygang = Monkey[]

    function mypunct(c)
        c ≠ '*' && c |> ispunct
    end
    function nextline(input)
        input |> readline |> lowercase |> lstrip
    end
    function getwords(line)
        split(line, x-> isspace(x) || mypunct(x), keepempty = false)
    end
    function relief(n::BigInt)
        n ÷ 3
    end

    function getmonkey(input)
        mold = Dict()
        while (line = nextline(input)) |> !isempty
            words = line |> getwords
            c = words[1] |> first
            if c=='m'
                monkey_id = parse(Int, words |> last)
                push!(mold, "id" => monkey_id)
            elseif c=='s'
                items = parse.(BigInt, words[3:end])
                push!(mold, "items" => items)
            elseif c=='o'
                id = mold["id"]
                replace!(words, "old" => "big(old)")
                ["op$(id)(old)", last(words, 4)...] |> join |> Meta.parse |> eval
                push!(mold, "op" => ("op$(id)" |> Meta.parse |> eval))
            elseif c=='t'
                id = mold["id"]
                teststem = ["test$(id)(item) = item % ", last(words), " |> sign |> Bool |> (!) ? "] |> join
                cond1 = nextline(input) |> getwords
                @assert "true" ∈ cond1
                trueval = parse(Int, last(cond1))
                cond2 = nextline(input) |> getwords
                @assert "false" ∈ cond2
                falseval = parse(Int, last(cond2))
                testends = join(string.([trueval, falseval]), " : ")
                # println([teststem, testends] |> join)
                [teststem, testends] |> join |> Meta.parse |> eval
                push!(mold, "test" => ("test$(id)" |> Meta.parse |> eval))
            end
        end
        get!(mold, "insp_ct", 0)
        return Monkey(mold["id"], mold["items"], mold["op"], mold["test"], mold["insp_ct"])
    end

    open(infile) do input
        while !eof(input)
            newmonkey = getmonkey(input)
            push!(monkeygang, newmonkey)
        end
    end

    function turn(monkey::Monkey)
        while !isempty(monkey.items)
            item = popfirst!(monkey.items)
            worry = item |> monkey.op
            target_index = worry |> relief |> monkey.test
            # Correction for 0-based naming
            target_index += 1
            push!(monkeygang[target_index].items, worry)
            monkey.inspections += 1
        end
    end

    for round in 1:20
        for monkey in monkeygang
            monkey |> turn
        end
    end

    activity = [monkey.inspections for monkey in monkeygang]
    return prod(last(sort(activity), 2))
end