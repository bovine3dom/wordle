#!/bin/julia
import Unicode: normalize
import Random: shuffle!, shuffle
words = readlines("google-10000-english.txt")

# For French we need to remove all accents, and shuffle because it's in alphabetical order
# TODO: find french word list sorted by frequency
# words = (readlines("fr.txt") .|> x -> normalize(x, stripmark=true, casefold=true)) |> shuffle!

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

score(word) = sum(freqs[c] for c in word |> unique)

# Get five letter words
five_char_words = filter(w->length(w)==5, words)

# Make pairs of three

tuple_iterator = Iterators.product(five_char_words |> shuffle, five_char_words |> shuffle, five_char_words |> shuffle)

answers = []
max_score = 0
max_tries = 1_000_000
tries = 0
for word_tuple in tuple_iterator
    this_score = score(word_tuple |> join)
    if (this_score > max_score)
        push!(answers, (word_tuple, this_score))
        max_score = this_score
    end
    tries += 1
    if tries > max_tries
        break
    end
end
sort!(answers, by=p->p[2], rev=true)
