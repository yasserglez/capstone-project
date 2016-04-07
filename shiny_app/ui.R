library("shiny")

title <- "Complete Me!"

shinyUI(fluidPage(
    title = title,
    fluidRow(column(width = 4, offset = 4,
        h3(title, align = "center"),
        hr(),
        textInput("text", "Enter a Phrase", width = "100%"),
        HTML('<div class="form-group shiny-input-container" style="width: 100%;">
<span class="label label-primary" style="font-size: 1em">foo</span>
<span class="label label-primary" style="font-size: 1em">bar</span>
<span class="label label-primary" style="font-size: 1em">baz</span>
             </div>'),
        sliderInput("num_words", "Number of Suggestions", width = "100%",
                    min = 1, max = 10, value = 1)
    ))
))
