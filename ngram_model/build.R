# Build an N-Gram Prediction Model

words_file <- "google-10000-english.txt"
if (!file.exists(words_file)) {
    words_file_url <- "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english.txt"
    download.file(words_file_url, words_file, method = "curl")
}

source("ngram_model.R")


# Cleanup the training documents and cache the results.

corpus_path <- function(name, lang) {
    stopifnot(name %in% c("blogs", "news", "twitter"))
    stopifnot(lang %in% c("de_DE", "en_US", "fi_FI", "ru_RU"))
    lang_dir <- file.path("../data", lang)
    file_name <- paste0(lang, ".", name, ".txt")
    file_path <- file.path(lang_dir, file_name)
    file_path
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

lines <- unlist(lapply(
    c("blogs", "news", "twitter"),
    function(name) readRDS(paste0(name, ".rds"))))

max_ngram_size <- 5
model <- build_model(lines, max_ngram_size)
save_model(model, "model.rds")

cat("The model was built using", format(length(lines), big.mark = ","), "lines.")
for (ngram_size in 1:max_ngram_size) {
    cat(sprintf("Number of %d-grams: %s.\n",
                ngram_size, format(length(model[[ngram_size]]), big.mark = ",")))

}
