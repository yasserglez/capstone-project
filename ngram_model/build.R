# Build an N-Gram Prediction Model

words_file <- "google-10000-english.txt"
if (!file.exists(words_file)) {
    words_file_url <- "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english.txt"
    download.file(words_file_url, words_file, method = "curl")
}

options(java.parameters = "-Xmx6g")
source("ngram_model.R")


# Cleanup the training documents and cache the results.

corpus_path <- function(name, lang) {
    stopifnot(name %in% c("blogs", "news", "twitter"))
    stopifnot(lang %in% c("de_DE", "en_US", "fi_FI", "ru_RU"))
    lang_dir <- file.path("../data", lang)
    file_name <- paste0(lang, ".", name, ".txt")
    file.path(lang_dir, file_name)
}

for (name in c("blogs", "news", "twitter")) {
    output_file <- paste0(name, ".rds")
    if (!file.exists(output_file)) {
        input_file <- corpus_path(name, "en_US")
        lines <- clean_lines(read_lines(input_file))
        saveRDS(lines, file = output_file)
    }
}


# Build the model.

set.seed(12345)
lines <- unlist(lapply(
    c("blogs", "news", "twitter"),
    function(name) {
        lines <- readRDS(paste0(name, ".rds"))
        sample(lines, 0.1 * length(lines))
    }))

max_ngram_size <- 4
model <- build_model(lines, max_ngram_size)
save_model(model, "model.rds")
