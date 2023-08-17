require(R6)
require(RMariaDB)
require(DBI)

source("GPSTime.R")

GLOBAL.USER = "bacnp"
GLOBAL.PASSWORD = "#Phuongbac2"
GLOBAL.PORT = 3306
GLOBAL.HOST = "127.0.0.1"


AbtractDBClass <- R6Class(
  "AbtractDBClass",
  public = list(
    con = NULL,
    initialize = function() {
      stop("This method should be overridden by subclasses.")
    },
    finalize = function() {
      stop("This method should be overridden by subclasses.")
    },
    getDBConnection = function() {
      stop("This method should be overridden by subclasses.")
    },
    updateTime = function() {
      stop("This method should be overridden by subclasses.")
    },
    getTable = function() {
      stop("This method should be overridden by subclasses.")
    }
  )
)

GR30DBClass = R6Class(
  "GR30DBClass",
  inherit = AbtractDBClass,
  public = list(
    con = NULL,
    week= NULL,
    initialize = function() {
      if (is.null(self$week)) 
        self$week = UTCTimestampToGPSWeek(as.numeric(Sys.time()))
      self$con <-
        dbConnect(
          RMariaDB::MariaDB(),
          host = GLOBAL.HOST,
          port = GLOBAL.PORT,
          dbname = "GR30",
          user = GLOBAL.USER,
          password = GLOBAL.PASSWORD
        )
      
      query <-
        paste0("CREATE TABLE IF NOT EXISTS W",self$week," (time INT, rtcm_msg BLOB(2048));")
      dbExecute(self$con, query)
    }, 
    
    getDBConnection = function() {
      if (!dbIsValid(self$con))
        self$finalize()
        self$initialize()
      return(self$con)
    },
    
    updateTime = function(UTCtimestamp, GPSepoch) {
      week = UTCTimestampToGPSWeek(UTCtimestamp)
      if (week != self$week & GPSepoch <= 24*60*60) {
        self$week = week
        self$initialize()
      }
    },
    
    getTable = function() {
      return(self$week)
    },
    
    finalize = function() {
      dbDisconnect(self$con)
    }
  )
)

PolarisAlphaDBClass = R6Class(
  "PolarisAlphaDBClass",
  inherit = AbtractDBClass,
  public = list(
    con = NULL,
    week= NULL,
    initialize = function() {
      if (is.null(self$week))
        self$week = UTCTimestampToGPSWeek(as.numeric(Sys.time()))
      self$con <-
        dbConnect(
          RMariaDB::MariaDB(),
          host = GLOBAL.HOST,
          port = GLOBAL.PORT,
          dbname = "PolarisAlpha",
          user = GLOBAL.USER,
          password = GLOBAL.PASSWORD
        )
      
      query <-
        paste0("CREATE TABLE IF NOT EXISTS W",self$week," (time INT, msg BLOB(4096));")
      dbExecute(self$con, query)
    }, 
    
    getDBConnection = function() {
      if (!dbIsValid(self$con))
        self$initialize()
      return(self$con)
    },
    
    updateTime = function(GpsTimestamp) {
      week = GPSTimestampToGPSWeek(GpsTimestamp)
      if (week != self$week) {
        self$week = week
        self$finalize()
        self$initialize()
      }
    },
    
    getTable = function() {
      return(self$week)
    },
    
    finalize = function() {
      dbDisconnect(self$con)
    }
  )
)

AuxiliaryDBClass = R6Class(
  "AuxiliaryDBClass",
  inherit = AbtractDBClass,
  public = list(
    con = NULL,
    year= NULL,
    initialize = function() {
      if (is.null(self$year))
        self$year <- year(Sys.time())
      self$con <-
        dbConnect(
          RMariaDB::MariaDB(),
          host = GLOBAL.HOST,
          port = GLOBAL.PORT,
          dbname = "Auxiliary",
          user = GLOBAL.USER,
          password = GLOBAL.PASSWORD
        )
      
      query <-
        paste0(
          "CREATE TABLE IF NOT EXISTS Y",self$year," (time BIGINT, soil_moisture float(10,2), temperature float(10,2), EC float(10,2), pH float(10,2), N float(10,2), P float(10,2), K float(10,2), salinity float(10,2), TDS float(10,2), wind_speed float(10,2), wind_direction INT, atmos_pressure float(10,2), humidity float(10,2));"
        )
      dbExecute(self$con, query)
    }, 
    finalize = function() {
      dbDisconnect(self$con)
    },
    getDBConnection = function() {
      if (!dbIsValid(self$con))
        self$initialize()
      return(self$con)
    },
    
    updateTime = function(UTCtimestamp) {
      stopifnot(is.numeric(UTCtimestamp))
      y = year(as_datetime(UTCtimestamp))
      if (y != self$year) {
        self$year <- y
        self$finalize()
        self$initialize()
      }
    },
    
    getTable = function() {
      return(self$year)
    }
  )
)