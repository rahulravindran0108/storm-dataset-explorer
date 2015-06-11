library(shiny)
library(ggplot2)
library(data.table)
library(maps)
library(rCharts)
library(reshape2)
library(markdown)
library(mapproj)
library(dplyr)

states_map <- map_data("state")
dt <- fread('data/events.agg.csv')
dt$EVTYPE <- tolower(dt$EVTYPE)
evtypes <<- sort(unique(dt$EVTYPE))
tmp <- merge(
  data.table(STATE=sort(unique(dt$STATE))),
  dt[
    YEAR >= 1950 & YEAR <= 2011,
    list(
      COUNT=sum(COUNT),
      INJURIES=sum(INJURIES),
      FATALITIES=sum(FATALITIES),
      PROPDMG=round(sum(PROPDMG), 2),
      CROPDMG=round(sum(CROPDMG), 2)
    ),
    by=list(STATE)],
  by=c('STATE'), all=TRUE
)

states <- unique(dt$STATE)

shinyServer(function(input, output) {
  
  gray.colors <- function(n) gray(rev(0:(n - 1))/n)
  defaultColors <- gray.colors(50)
  #defaultColors <- c("#3366cc", "#dc3912", "#ff9900", "#109618", "#990099", "#0099c6", "#dd4477")
  series <- structure(
    lapply(defaultColors, function(color) { list(color=color) }),
    names = states
  )
  
    dt.agg <- reactive({
        tmp <- merge(
            data.table(STATE=sort(unique(dt$STATE))),
            dt[
                YEAR >= input$range[1] & YEAR <= input$range[2],
                list(
                    COUNT=sum(COUNT),
                    INJURIES=sum(INJURIES),
                    FATALITIES=sum(FATALITIES),
                    PROPDMG=round(sum(PROPDMG), 2),
                    CROPDMG=round(sum(CROPDMG), 2)
                ),
                by=list(STATE)],
            by=c('STATE'), all=TRUE
        )
        tmp[is.na(tmp)] <- 0
        tmp
    })
    
    dt.agg.year <- reactive({
        dt[
            YEAR >= input$range[1] & YEAR <= input$range[2],
            list(
                COUNT=sum(COUNT),
                INJURIES=sum(INJURIES),
                PROPDMG=round(sum(PROPDMG), 2),
                FATALITIES=sum(FATALITIES),
                CROPDMG=round(sum(CROPDMG), 2)
            ),
            by=list(YEAR)
        ]
    })
        
   
    output$populationImpactByState <- renderPlot({
        data <- dt.agg()
        if(input$populationCategory == 'both') {
            data$Affected <- data$INJURIES + data$FATALITIES
        } else if(input$populationCategory == 'fatalities') {
            data$Affected <- data$FATALITIES
        } else {
            data$Affected <-data$INJURIES
        }
        
        title <- paste("Population impact", input$range[1], "-", input$range[2], "(number of affected)")
        p <- ggplot(data, aes(map_id = STATE))
        p <- p + geom_map(aes(fill = Affected), map = states_map, colour='black') + expand_limits(x = states_map$long, y = states_map$lat)
        p <- p + coord_map() + theme_bw()
        p <- p + labs(x = "Long", y = "Lat", title = title)
        print(p)
    })
    
    output$economicImpactByState <- renderPlot({
        data <- dt.agg()
        
        if(input$economicCategory == 'both') {
            data$Damages <- data$PROPDMG + data$CROPDMG
        } else if(input$economicCategory == 'crops') {
            data$Damages <- data$CROPDMG
        } else {
            data$Damages <- data$PROPDMG
        }
        
        title <- paste("Economic impact", input$range[1], "-", input$range[2], "(Million USD)")
        p <- ggplot(data, aes(map_id = STATE))
        p <- p + geom_map(aes(fill = Damages), map = states_map, colour='black') + expand_limits(x = states_map$long, y = states_map$lat)
        p <- p + coord_map() + theme_bw()
        p <- p + labs(x = "Long", y = "Lat", title = title)
        print(p)
    })
    
    #output$evtypeControls <- renderUI({
    #    if(1) {
    #        checkboxGroupInput('evtypes', 'Event types', evtypes, selected=evtypes)
    #    }
    #})
    
    dataTable <- reactive({
        dt.agg()[, list(
            State=state.abb[match(STATE, tolower(state.name))],
            Count=COUNT,
            Injuries=INJURIES,
            Fatalities=FATALITIES,
            Property.damage=PROPDMG,
            Crops.damage=CROPDMG)
        ]   
    })
    
    output$table <- renderDataTable(
        {dataTable()}, options = list(bFilter = FALSE, iDisplayLength = 50))
    
    output$eventsByYear <- renderChart({
        data <- dt.agg.year()[, list(COUNT=sum(COUNT)), by=list(YEAR)]
        setnames(data, c('YEAR', 'COUNT'), c("Year", "Count"))
 
        eventsByYear <- nPlot(
            Count ~ Year,
            data = data[order(data$Year)],
            type = "lineChart", dom = 'eventsByYear', width = 650
        )
        
        eventsByYear$chart(margin = list(left = 100))
        eventsByYear$yAxis( axisLabel = "Count", width = 80)
        eventsByYear$xAxis( axisLabel = "Year", width = 70)
        return(eventsByYear)
    })
    
  yearData <- reactive({
    # Filter to the desired year, and put the columns
    # in the order that Google's Bubble Chart expects
    # them (name, x, y, color, size). Also sort by region
    # so that Google Charts orders and colors the regions
    # consistently.
    dt$STATE<-as.factor(dt$STATE)
    dt$Affected<-dt$FATALITIES+dt$INJURIES+dt$PROPDMG
    df <- dt %>%
      filter(YEAR == as.integer(input$year)) %>%
      select(EVTYPE,COUNT,Affected,STATE,INJURIES) %>%
      arrange(STATE)
      
  })
  
    output$chart <- reactive({
      # Return the data and options
      list(
        data = googleDataTable(yearData()),
        options = list(
          title = sprintf(
            "Number of events vs Total Damages, %s",
            input$year),
          series = series
        )
      )
    })
  
  output$image1<-renderUI({
    
    img(src = "1.png")
    
  })
  
  output$image2<-renderUI({
    img(src = "2.png")
  })
    
    output$populationImpact <- renderChart({
        data <- melt(
            dt.agg.year()[, list(Year=YEAR, Injuries=INJURIES, Fatalities=FATALITIES)],
            id='Year'
        )
        populationImpact <- nPlot(
            value ~ Year, group = 'variable', data = data[order(-Year, variable, decreasing = T)],
            type = 'stackedAreaChart', dom = 'populationImpact', width = 650
        )
        
        populationImpact$chart(margin = list(left = 100))
        populationImpact$yAxis( axisLabel = "Affected", width = 80)
        populationImpact$xAxis( axisLabel = "Year", width = 70)
        
        return(populationImpact)
    })
    
    output$economicImpact <- renderChart({
        data <- melt(
            dt.agg.year()[, list(Year=YEAR, Propety=PROPDMG, Crops=CROPDMG)],
            id='Year'
        )
        economicImpact <- nPlot(
            value ~ Year, group = 'variable', data = data[order(-Year, variable, decreasing = T)],
            type = 'stackedAreaChart', dom = 'economicImpact', width = 650
        )
        economicImpact$chart(margin = list(left = 100))
        economicImpact$yAxis( axisLabel = "Total damage (Million USD)", width = 80)
        economicImpact$xAxis( axisLabel = "Year", width = 70)
        
        return(economicImpact)
    })
  
    output$downloadData <- downloadHandler(
        filename = 'data.csv',
        content = function(file) {
            write.csv(dataTable(), file, row.names=FALSE)
        }
    )
})


