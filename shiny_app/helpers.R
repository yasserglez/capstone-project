library("hash")
library("magrittr")
library("stringi")

words <- readRDS("data/words_5k.rds")
model <- readRDS("data/model_0.1_4_trimmed.rds")

predict_next_words <- function(text, num_words) {
    lines <- clean_lines(text)
    text <- lines[length(lines)]
    text_words <- if (length(text) > 0) stri_split(text, fixed = " ")[[1]] else character(0)
    if (length(text_words) > 0)
        text_words <- text_words[has.key(text_words, words)]

    next_words <- character(0)
    probabilities <- numeric(0)
    for (word in keys(words)) {
        probability <- ngram_probability(model, word, text_words)
        next_words <- c(next_words, word)
        probabilities <- c(probabilities, probability)
        if (length(next_words) > num_words) {
            ord <- order(probabilities, decreasing = TRUE)[1:num_words]
            next_words <- next_words[ord]
            probabilities <- probabilities[ord]
        }
    }

    next_words
}

clean_lines <- function(lines) {
    # Remove characters that won't be used to identify the n-grams.
    lines <- lines %>%
        stri_replace_all(" ", regex = "[^a-zA-Z’'.,;]") %>%
        stri_replace_all("'", fixed = "’")

    # Split on the punctuation chars and remove additional whitespace.
    lines <- lines %>%
        stri_split(regex = "[.,;]") %>% unlist %>%
        stri_replace_all(" ", regex = "\\s+") %>%
        stri_trim_both %>%
        .[stri_length(.) > 0]

    # Transform to lower case.
    stri_trans_tolower(lines)
}

ngram_probability <- function(model, next_word, previous_words) {
    prefix_size <- min(length(model$count) - 1, length(previous_words))
    prefix_words <- character(0)
    if (prefix_size > 0) {
        i <- length(previous_words) - prefix_size + 1
        j <- length(previous_words)
        prefix_words <- previous_words[seq(from = i, to = j)]
    }

    ngram_words <- c(prefix_words, next_word)
    ngram_size <- prefix_size + 1
    ngram <- paste(ngram_words, collapse = " ")
    num <- model$count[[ngram_size]][[ngram]]
    if (is.null(num)) num <- 0

    if (prefix_size > 0) {
        prefix <- paste(prefix_words, collapse = " ")
        den <- model$count[[prefix_size]][[prefix]]
        if (is.null(den)) den <- 0
    } else {
        den <- model$total[1]
    }

    num / den
}

