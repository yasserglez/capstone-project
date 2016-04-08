library("shiny")

title <- "Next Word!"

shinyUI(fluidPage(
    title = title,
    fluidRow(column(width = 4, offset = 4,
        h3(title, align = "center"),
        hr(),
        textInput("text", "Enter a Phrase", width = "100%"),
        htmlOutput("next_words_div"),
        sliderInput("num_words", "Number of Suggestions", width = "100%", min = 1, max = 10, value = 1)
    ))
))
