# N-Gram Prediction Model

library("hash")
library("magrittr")
library("stringi")
library("RWeka")

# The model predicts words from the 5,000 most common English words,
# as determined by n-gram frequency analysis of the Google's Trillion
# Word Corpus: https://github.com/first20hours/google-10000-english.
WORDS <- hash(readLines("google-10000-english.txt", n = 5000), 1:5000)

read_lines <- function(file_path) {
    readLines(file_path, encoding = "UTF-8", warn = FALSE, skipNul = TRUE)
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


build_model <- function(lines, max_ngram_size = 1, print_every = 10000) {
    message(sprintf("Processing %d lines...", length(lines)))

    count <- lapply(1:max_ngram_size, function(ngram_size) hash())

    for (ngram_size in 1:max_ngram_size) {
        message(sprintf("Generating %d-ngrams...", ngram_size))
        control <- Weka_control(min = ngram_size, max = ngram_size, delimiters = " ")
        freq_table <- as.data.frame(table(NGramTokenizer(lines, control)), stringsAsFactors = FALSE)
        names(freq_table) <- c("ngram", "freq")

        message(sprintf("Processing %d %d-grams...", nrow(freq_table), ngram_size))
        for (i in seq(from = 1, to = nrow(freq_table))) {
            ngram <- freq_table$ngram[i]
            ngram_words <- stri_split(ngram, fixed = " ")[[1]]
            if (all(has.key(ngram_words, WORDS)))
                count[[ngram_size]][[ngram]] <- freq_table$freq[i]
            if (i %% print_every == 0)
                message(sprintf("Processed %d/%d ngrams...", i, nrow(freq_table)))
        }
    }

    message("Done.")

    list(count = count, total = sapply(count, length))
}


trim_model <- function(model, min_count) {
    max_ngram_size = length(model$count)
    count <- rep(list(NULL), max_ngram_size)
    for (ngram_size in 1:max_ngram_size) {
        k <- keys(model$count[[ngram_size]])
        v <- values(model$count[[ngram_size]])
        count[[ngram_size]] <- hash(k[v >= min_count], v[v >= min_count])
    }
    list(count = count, total = sapply(count, length))
}


save_model <- function(model, file_path) {
    saveRDS(model, file = file_path, compress = FALSE)
}


load_model <- function(file_path) {
    readRDS(file_path)
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


predict_next_words <- function(model, text, num_words = 1) {
    lines <- clean_lines(text)
    text <- lines[length(lines)]
    text_words <- if (length(text) > 0) stri_split(text, fixed = " ")[[1]] else character(0)
    text_words <- text_words[has.key(text_words, WORDS)]

    next_words <- character(0)
    probabilities <- numeric(0)
    for (word in keys(WORDS)) {
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
