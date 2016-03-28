# N-Gram Prediction Model

library("hash")
library("magrittr")
library("stringi")
library("RWeka")

# The model predicts words from the 10,000 most common English words,
# as determined by n-gram frequency analysis of the Google's Trillion
# Word Corpus: https://github.com/first20hours/google-10000-english.
WORDS <- hash(readLines("google-10000-english.txt"), 1:10000)

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
        stri_replace("", regex = "^ ") %>%
        stri_replace("", regex = " $") %>%
        .[stri_length(.) > 0]

    # Transform to lower case.
    stri_trans_tolower(lines)
}

count_ngrams <- function(lines, max_ngram_size) {
    control <- Weka_control(min = 1, max = max_ngram_size, delimiters = " ")
    freq_table <- table(NGramTokenizer(lines, control))
    freq_table
}

build_model <- function(lines, max_ngram_size = 1) {
    model <- lapply(1:max_ngram_size, function(ngram_size) hash())

    freq_table <- count_ngrams(lines, max_ngram_size)
    for (ngram in dimnames(freq_table)[[1]]) {
        ngram_words <- stri_split(ngram, fixed = " ")[[1]]
        valid_ngram <- all(has.key(ngram_words, WORDS))
        if (valid_ngram) {
            ngram_size <- length(ngram_words)
            model[[ngram_size]][[ngram]] <- freq_table[ngram]
        }
    }

    model
}


save_model <- function(model, file_path) {
    saveRDS(model, file = file_path)
}


load_model <- function(file_path) {
    readRDS(file_path)
}
