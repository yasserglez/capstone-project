library("shiny")

source("helpers.R")

open_div <- '<div class="form-group shiny-input-container" style="width: 100%;">'
close_div <- '</div>'
open_span <- '<span class="label label-primary" style="font-size: 1em">'
close_span <- '</span>'

shinyServer(function(input, output) {
    next_words_div <- reactive({
        text <- input$text
        num_words <- input$num_words
        next_words <- predict_next_words(text, num_words)

        spans <- sapply(next_words, function (word) paste0(open_span, word, close_span))
        paste0(open_div, paste0(spans, collapse = " "), close_div)
    })
    output$next_words_div <- renderUI(HTML(next_words_div()))
})
