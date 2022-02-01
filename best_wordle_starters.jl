#!/bin/julia
import Unicode: normalize
import Random: shuffle!, shuffle
using ProgressMeter
# words = readlines("google-10000-english.txt")

# For French we need to remove all accents, and shuffle because it's in alphabetical order
# TODO: find french word list sorted by frequency
words = (readlines("fr.txt") .|> x -> normalize(x, stripmark=true, casefold=true))

freqs = Dict{Char,Float64}()
for w in words
    for l in w
        freqs[l] = get(freqs,l,0.0)+1
    end
end

# take the square root so that outliers (i.e. a and t) don't steal the show
#   if you don't do this one of the best triples of three words to play is "the", "the" and "the"
for (k,v) in freqs
    freqs[k] = sqrt(v)
end


# sort(collect(freqs),by=x->x[2],rev=true)

# We want:
# - three five letter words
# - score per word = sum of unique frequency scores of each letter

score(word; inv=false) = sum(inv ? 1/freqs[c] : freqs[c] for c in word |> unique)

# Get five letter words
five_char_words = filter(w->length(w)==5, words)

freqs2d = Dict()
for w in five_char_words
    for p in enumerate(w)
        freqs2d[p] = get(freqs2d,p,0.0)+1
    end
end
for (k,v) in freqs2d
    freqs2d[k] = sqrt(v)
end

score2d(word) = sum(get(freqs2d,p,0.0) for p in enumerate(word))

# Make pairs of three
N = length(five_char_words)

array_lock = ReentrantLock()
answers = []
max_score = 0
max_tries = 1_000_000
THRESHOLD = 0
@time Threads.@threads for i in 1:max_tries
    word_tuple = five_char_words[rand(1:N, 2)]
    word_squish = join(word_tuple)
    if (word_squish |> length) > (word_squish |> unique |> length) + THRESHOLD
        continue
    end
    this_score = sum(score2d, word_tuple)
    if (this_score > max_score * 0.99)
        lock(array_lock)
        push!(answers, (word_tuple, this_score))
        global max_score = max(this_score, max_score)
        # Showing answers while it works makes me feel better about progress
        @show (word_tuple, this_score)
        unlock(array_lock)
    end
end

function next_best_word(current_word; threshold=0)
    answers = []
    current = unique(current_word)|>join
    @show current
    max_score = 0
    for w in five_char_words
        if (length(join([w, current]) |> unique) + threshold < length(join([w,current])))
            continue
        end
        this_score = score(join(w, current),inv=false)
        if (this_score > max_score)
            max_score = this_score
            push!(answers, (w, this_score))
        end
    end
    sort!(answers, by=x->x[2], rev=true)
end
