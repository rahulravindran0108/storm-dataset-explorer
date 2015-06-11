
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
# 
# http://www.rstudio.com/shiny/
#

library(shiny)
library(rCharts)
library(googleCharts)

xlim <- list(
  min = 0,
  max = 1000
)

ylim <- list(
  min = 0,
  max = 1000
)

shinyUI(
    navbarPage("Storm Database Explorer",
        
        tabPanel("Results",
                 fluidPage(
                   
                   includeMarkdown("include.md"),
                    tabsetPanel(
                        
                        # Data by state
                        tabPanel('By state',
                            
                              shiny::column(6,
                                  wellPanel(
                                    radioButtons(
                                        "populationCategory",
                                        "Population impact category:",
                                        c("Both" = "both", "Injuries" = "injuries", "Fatalities" = "fatalities"))
                                  )
                              ),
                              shiny::column(6,
                                wellPanel(
                                    radioButtons(
                                        "economicCategory",
                                        "Economic impact category:",
                                        c("Both" = "both", "Property damage" = "property", "Crops damage" = "crops"))
                                )
                            ),
                            shiny::column(6,
                                plotOutput("populationImpactByState")
                                
                            ),
                            shiny::column(6,
                                   plotOutput("economicImpactByState")
                            ),
                            shiny::column(4,offset = 4,
                                   sliderInput("range", 
                                               "Year:", 
                                               min = 1950, 
                                               max = 2011, 
                                               value = c(1993, 2011),sep=""
                                   )),
                            shiny::column(12,
                                          includeMarkdown("states.md")),
                            br(),
                            shiny::column(12,
                            googleChartsInit(),
                            
                            # Use the Google webfont "Source Sans Pro"
                            tags$link(
                              href=paste0("http://fonts.googleapis.com/css?",
                                          "family=Source+Sans+Pro:300,600,300italic"),
                              rel="stylesheet", type="text/css"),
                            tags$style(type="text/css",
                                       "body {font-family: 'Source Sans Pro'}"
                            ),
                            
                            h2("Is the increase in number of events over the years related to climate change?"),
                            
                            googleBubbleChart("chart",
                                              width="100%", height = "475px",
                                              # Set the default options for this chart; they can be
                                              # overridden in server.R on a per-update basis. See
                                              # https://developers.google.com/chart/interactive/docs/gallery/bubblechart
                                              # for option documentation.
                                              options = list(
                                                fontName = "Source Sans Pro",
                                                fontSize = 13,
                                                # Set axis labels and ranges
                                                hAxis = list(
                                                  title = "Number Of Events",
                                                  viewWindow = xlim
                                                ),
                                                vAxis = list(
                                                  title = "Total Loss to Population",
                                                  viewWindow = ylim
                                                ),
                                                # The default padding is a little too spaced out
                                                chartArea = list(
                                                  top = 50, left = 75,
                                                  height = "75%", width = "75%"
                                                ),
                                                # Allow pan/zoom
                                                explorer = list(),
                                                # Set bubble visual props
                                                bubble = list(
                                                  opacity = 0.4, stroke = "none",
                                                  # Hide bubble label
                                                  textStyle = list(
                                                    color = "none"
                                                  )
                                                ),
                                                # Set fonts
                                                titleTextStyle = list(
                                                  fontSize = 16
                                                ),
                                                tooltip = list(
                                                  textStyle = list(
                                                    fontSize = 14
                                                  )
                                                )
                                              )
                            ),
                            fluidRow(
                              shiny::column(4, offset = 4,
                                            sliderInput("year", "Year",step = 1,
                                                        min = min(dt$YEAR), max = max(dt$YEAR),
                                                        value = min(dt$YEAR),  animate = TRUE,sep="")
                              )
                            )
                            ),
                            shiny::column(12,
                              p("There is a high increase in the number of events occuring over the years causing great damage to property and life. These are the signs that our environment is degrading and with our current lifestyle, we have much to lose than gain. If the above visualisation wasn't clear, have a look at the graph below."),
                              h4('Number of events by year', align = "center"),
                              showOutput("eventsByYear", "nvd3")
                            ),
                            shiny::column(4,
                              h4('Population impact by year', align = "center"),
                              showOutput("populationImpact", "nvd3")
                            ),
                            shiny::column(4, offset = 2,
                              h4('Economic impact by year', align = "center"),
                              showOutput("economicImpact", "nvd3")
                            ),
                            shiny::column(12,
                                h4("What are the events that cause the most damages to property and health?")
                                
                            ),
                            shiny::column(6,
                                    uiOutput("image1")
                                          
                            ),
                            shiny::column(6,
                                          uiOutput("image2")
                                          
                            )
                        ),
                        
                        # Data 
                        tabPanel('Data',
                            dataTableOutput(outputId="table"),
                            downloadButton('downloadData', 'Download')
                        )
                    )
                
            
        ))
        
    )
    
)
