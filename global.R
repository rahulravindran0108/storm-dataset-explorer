library(data.table)
dt <- fread('data/events.agg.csv')
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