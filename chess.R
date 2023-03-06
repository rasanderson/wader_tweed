library(stars)
library(sf)
library(ncdf4)
library(terra)
library(rnrfa)

# This scripts checks that airGR is working for subcatch 1 to 6 lumped together
# as subcatch 6 is the first one that is NRFA gauged.

rm(list = ls())

subcatch_no <- 6

# ID 21005 Lyneford   = INCA 6
stn_gdf <- gdf(id = "21005")

inca23 <- read_sf("data/inca23.gpkg")
inca_sub <- inca23[inca23$reach_no <= subcatch_no,]
plot(inca_sub["reach_no"])

# Merge subcatch 1 to 6 into single polygon
inca_sub <- st_union(inca_sub)
plot(inca_sub)


rain_files <- list.files("data/chess-met_precip/", full.names = TRUE)
pet_files  <- list.files("data/chess-pe_pet/", full.names = TRUE)

no_of_months <- length(rain_files)
# no_of_months <- 1

BasinObs <- data.frame(matrix(ncol = 4, nrow = 0))
colnames(BasinObs) <- c("DatesR", "P", "E", "Qmm")

for(month_no in 1:no_of_months){
  rain <- terra::rast(rain_files[month_no])  
  pet  <- terra::rast(pet_files[month_no])

  crs(rain) <- crs("+init=epsg:27700")
  crs(pet) <- crs("+init=epsg:27700")
  
    for(day in 1:dim(rain)[3]){
    rain_1day <- rain[[day]]
    pet_1day  <- pet[[day]]
    # day_rain_sub <- terra::extract(rain_1day, vect(inca_sub["reach_no"]))
    # day_pet_sub  <- terra::extract(pet_1day,  vect(inca_sub["reach_no"]))
    # day_rain_sub <- crop(mask(rain_1day, vect(inca_sub)), vect(inca_sub)) # returns map of just target area
    day_rain_sub <- terra::extract(rain_1day, vect(inca_sub))
    day_pet_sub  <- terra::extract(pet_1day,  vect(inca_sub))
    daily_rain_mean <- mean(day_rain_sub[,2]) * 24 * 60 * 60 # Convert to mm / day
    daily_pet_mean  <- mean(day_pet_sub[,2])  * 24 * 60 * 60
    rain_stats <- data.frame(DatesR = time(rain_1day),
                             P      = daily_rain_mean,
                             E      = daily_pet_mean,
                             Qmm    = stn_gdf[time(rain_1day)])
    BasinObs <- rbind(BasinObs, rain_stats)
  }
  
}


