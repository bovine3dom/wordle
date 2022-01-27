#!/bin/julia
import Unicode: normalize
import Random: shuffle!, shuffle
using ProgressMeter
words = readlines("google-10000-english.txt")

# For French we need to remove all accents, and shuffle because it's in alphabetical order
# TODO: find french word list sorted by frequency
# words = (readlines("fr.txt") .|> x -> normalize(x, stripmark=true, casefold=true))

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

# Make pairs of three
N = length(five_char_words)

array_lock = ReentrantLock()
answers = []
max_score = 0
max_tries = 1_000_000
@time Threads.@threads for i in 1:max_tries
    word_tuple = five_char_words[rand(1:N, 3)]
    this_score = score(word_tuple |> join)
    if (this_score > max_score)
        lock(array_lock)
        push!(answers, (word_tuple, this_score))
        global max_score = this_score
        # Showing answers while it works makes me feel better about progress
        @show word_tuple
        unlock(array_lock)
    end
end
sort!(answers, by=p->p[2], rev=true)
