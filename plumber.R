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

#* @apiTitle Plumber API for MariaDB on EphemerisNAS
# decalre R6 class for the general connection
library(R6)

DBClass = R6Class(
  "DBClass",
  public = list(
    con = NULL,
    initialize = function() {
      self$con <-
        dbConnect(
          RMariaDB::MariaDB(),
          host = "127.0.0.1",
          port = 3036,
          dbname = "Station_BG",
          user = "bacnp",
          password = "#Phuongbac2"
        )
      
      query <-
        paste(
          "CREATE TABLE IF NOT EXISTS Meteo (time BIGINT, soil_moisture float(10,2), temperature float(10,2), EC float(10,2), pH float(10,2), N float(10,2), P float(10,2), K float(10,2), salinity float(10,2), TDS float(10,2), wind_speed float(10,2), wind_direction INT, atmos_pressure float(10,2), humidity float(10,2));"
        )
      dbExecute(self$con, query)
      query <-
        paste("CREATE TABLE IF NOT EXISTS GR30 (time INT, rtcm_msg BLOB(2048));")
      dbExecute(self$con, query)
    },
    getDBConnection = function() {
      if (!dbIsValid(self$con))
        self$initialize
      return(self$con)
    },
    finalize = function() {
      dbDisconnect(self$con)
    }
  )
)

db = DBClass$new()
db$getDBConnection()

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
#* @post /meteo_upload
function(time,
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
         humidity) {
  dbExecute(
    db$getDBConnection(),
    "INSERT into Meteo (time, soil_moisture, temperature, EC, pH, N, P, K, salinity, TDS, wind_speed, wind_direction, atmos_pressure, humidity) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
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
}


#* post GR30 RTCM3 msm7+ ephemeris message
#* @param time:int      The sent time
#* @param rtcm_msg:raw  The corresponding message in RTCM format
#* @post  /rtcm_upload
function(time, rtcm_msg) {
  if (class(rtcm_msg) == "character")
    rtcm_msg = charToRaw(rtcm_msg)
  dbExecute(db$getDBConnection(),
            "insert into GR30 values(?, ?)",
            params = list(time, list(rtcm_msg)))
}
