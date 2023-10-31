#
# This is a Plumber API. In RStudio 1.2 or newer you can run the API by
# clicking the 'Run API' button above.
#
# In RStudio 1.1 or older, see the Plumber documentation for details
# on running the API.
#
# Find out more about building APIs with Plumber here:
#
#    https://www.rplumber.io/
#
library(plumber)
library(R6)
library(RMariaDB)
require(DBI)
library(wkb)
library(future)
source("AuxiliaryClass.R")
plan("multisession")
#* @apiTitle Plumber API for MariaDB on EphemerisNAS

gr30DB = GR30DBClass$new()
auxDB = AuxiliaryDBClass$new()
polarisalpha = PolarisAlphaDBClass$new()

#* post meteo data
#* @param time:int              The sending timestamp
#* @param soil_moisture:float   The soil moisture value
#* @param temperature:float     The atmospheric temperature value
#* @param EC:float              The Electric Conductivity value
#* @param pH:float              The pH value
#* @param N:float               The Nitrogen value in the soil
#* @param P:float               The Phosphorus value in the soil
#* @param K:float               The Kalium value in the soil
#* @param salinity:float        The soil salinity value
#* @param TDS:float             The soil TDS value
#* @param wind_speed:float      The speed of the wind value
#* @param wind_direction:float  The direction of the wind value
#* @param atmos_pressure:float  The atmospheric pressure value
#* @param humidity:float        The atmospheric humidity value
#* @post /upload_aux
function(time = -1,
         soil_moisture = -1,
         temperature = -1,
         EC = -1,
         pH = -1,
         N = -1,
         P = -1,
         K = -1,
         salinity = -1,
         TDS = -1,
         wind_speed = -1,
         wind_direction = -1,
         atmos_pressure = -1,
         humidity = -1) {
  promises::future_promise({
    auxDB$updateTime(as.numeric(time))
    dbExecute(
      auxDB$getDBConnection(),
      paste0(
        "INSERT into Y",
        auxDB$getTable(),
        " (time, soil_moisture, temperature, EC, pH, N, P, K, salinity, TDS, wind_speed, wind_direction, atmos_pressure, humidity) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
      ),
      params = list(
        time,
        soil_moisture,
        temperature,
        EC,
        pH,
        N,
        P,
        K,
        salinity,
        TDS,
        wind_speed,
        wind_direction,
        atmos_pressure,
        humidity
      )
    )
  })
}


#* post GR30 RTCM3 msm7+ ephemeris message
#* @param UTCtime:int    The sent UNIX timestamp
#* @param GPSepoch      The received message epoch
#* @param rtcm_msg:raw  The corresponding message in RTCM format
#* @post  /rtcm_upload
function(UTCtime, GPSepoch, rtcm_msg) {
  promises::future_promise({
    rtcm_msg = hex2raw(rtcm_msg)
    gr30DB$updateTime(as.numeric(UTCtime), GPSepoch)
    dbExecute(
      gr30DB$getDBConnection(),
      paste0("insert into W", gr30DB$getTable(), " values(?, ?)"),
      params = list(UTCtime, list(rtcm_msg))
    )
  })
}


#* post skytraq ephemeris message
#* @param GpsWeek:numeric         The GPS week
#* @param GpsTow:numeric    The sent tow
#* @param skytraq:string          The corresponding message in RTCM format
#* @post  /skytraq_upload
function(GpsWeek, GpsTow, skytraq) {
  promises::future_promise({
    skytraq = hex2raw(skytraq)
    polarisalpha$updateTime(as.numeric(GpsWeek))
    dbExecute(
      polarisalpha$getDBConnection(),
      paste0("insert into W", polarisalpha$getTable(), " values(?, ?)"),
      params = list(GpsTow, list(skytraq))
    )
  })
}

#* get skytraq ephemeris message
#* @param from:numeric  from epoch UTM
#* @param to:numeric    to epoch UTM
#* @serializer contentType list(type="application/rds")
#* @return
#* @get /alpha_get
function(from, to, res) {
  promises::future_promise({
    from = as.numeric(from)
    to = as.numeric(to)
    stopifnot(as.numeric(from) | as.numeric(to))
    w.from = UTCTimestampToGPSWeek(from)
    w.to = UTCTimestampToGPSWeek(to)
    tow.from = UTCtimeToGPStime(from) %% (7 * 24 * 60 * 60)
    tow.to = UTCtimeToGPStime(to) %% (7 * 24 * 60 * 60)
    res = lapply(
      X = seq(w.from, w.to),
      FUN = function(w) {
        a = dbGetQuery(
          polarisalpha$getDBConnection(),
          paste0(
            "select msg from PolarisAlpha.W",
            w,
            "  where tow between ",
            tow.from,
            " and ",
            tow.to,
            ";"
          )
        )
      }
    ) %>% unlist() %>% as.raw()
    return (res)
  })
}
