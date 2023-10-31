# GPS DATETIME
require(lubridate)

GLOBAL.LEAP_SECOND = 18

#* @param timestamp the POSIXct timestamp

UTCTimestampToGPSWeek <- function(timestamp) {
  stopifnot(is.numeric(timestamp))
  gps_week <- floor((timestamp - 315964800 - GLOBAL.LEAP_SECOND) / 7/60/60/24)
  return(gps_week)
}

#* @param GPSweek the number of week from 1980-1-6
#* @param GPSms   the mini second from start of week
#* @param output  2 output type avaiable is: ["ts"] mean timestamp and ["dt"] is datetime
GPSTimeToUTCTime <- function(GPSweek, GPSms, output = "ts") {
  if (output=="ts") 
    gps.epoch <- 315964800
  else 
    gps.epoch <- ymd_hms("1980-01-06 00:00:00")
    
  timestamp <-
    gps.epoch + GPSweek * 7 * 24 * 60 * 60 + GPSms / 1000 - GLOBAL.LEAP_SECOND
  return(timestamp)
}

GPSTimestampToGPSWeek = function(GPSTimestamp) {
  return(floor(GPSTimestamp / 604800))
}

UTCtimeToGPStime = function(utcTimestamp) {
  utcTimestamp - 315964800 - GLOBAL.LEAP_SECOND
}
