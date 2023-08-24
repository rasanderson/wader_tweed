# Calc upland and lowland data
# According to Jarvie et al the Tweed was divided into 'upper' and 'lower'
# reaches to simulate the Hydrologically Effective Rainfall:
# upper = Reaches 1 to 12
# lower = Reaches 13 to 23
# which was calibrated using precipitation, air temperature and observed
# streamflow at Boleside (Reach 12) and Noreham (Reach 23).
# Presumably total precipitation calculated for 1-12 and 13-23, divided by
# the total areas. Assume mean temperature.
# According to NRFA site flow is in cumecs (m3/second) so will need rescaling to
# mm/day for IHACERS model

library(ggplot2)
library(rnrfa)
library(sf)
library(zoo)

rm(list=ls())

# Upper reaches

# ID 21006 Boleside  = INCA 12
station_id <- 21006
catchment_area_km2 <- 150 # taken from NRFA site
min_reach <- 1
max_reach <- 12
stn_gdf <- gdf(id = station_id)
plot(stn_gdf) # OK
flow <- get_ts(station_id, type = "gdf") # GDF = gauged daily flow
flow_sub <- subset(flow, index(flow) >= "1994-01-01" & index(flow) <= "2000-12-31")
flow_sub <- convert_flow(flow_sub, catchment_area_km2) # convert cumecs to mm/day
# Get daily temperature and rainfall data
inca23 <- read_sf("data/inca23.gpkg")
inca_sub <- inca23[inca23$reach_no >= min_reach & inca23$reach_no <= max_reach,]
plot(inca_sub["reach_no"])
inca_sub <- st_union(inca_sub)
rain_files <- list.files("data/chess-met_precip/", full.names = TRUE)
tas_files  <- list.files("data/chess-met_tas/",    full.names = TRUE)
no_of_months <- length(rain_files)
BasinObs <- data.frame(DatesR = as.Date(character()),
                       P = numeric(),
                       TAS = numeric(),
                       Qmm = numeric())

# Next bit is slow
for(month_no in 1:no_of_months){
  print(round(month_no / no_of_months * 100), 2)
  rain <- terra::rast(rain_files[month_no])  
  tas  <- terra::rast(tas_files[month_no])
  
  terra::crs(rain) <- terra::crs("+init=epsg:27700")
  terra::crs(tas)  <- terra::crs("+init=epsg:27700")
  
  for(day in 1:dim(rain)[3]){
    cat(".")
    rain_1day <- rain[[day]]
    tas_1day  <- tas[[day]]
    day_rain_sub <- terra::extract(rain_1day, terra::vect(inca_sub))
    day_tas_sub  <- terra::extract(tas_1day,  terra::vect(inca_sub))
    daily_rain_mean <- mean(day_rain_sub[,2]) * 24 * 60 * 60 # Convert to mm / day
    daily_tas_mean  <- mean(day_tas_sub[,2])
    rain_stats <- data.frame(DatesR = terra::time(rain_1day),
                             P      = daily_rain_mean,
                             TAS    = daily_tas_mean,
                             Q      = stn_gdf[terra::time(rain_1day)])
    BasinObs <- rbind(BasinObs, rain_stats)
  }
  
}
# Rain is in kg m-2 s-1
# TAS is in Kelvin
BasinObs$DatesR <- as.POSIXct(BasinObs$DatesR)
saveRDS(BasinObs, file = paste0("data/BasinObs_upper.RDS"))
