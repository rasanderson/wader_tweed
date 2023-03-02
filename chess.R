library(stars)
library(sf)
library(ncdf4)
library(terra)

rm(list = ls())

subcatch_no <- 2

inca23 <- read_sf("data/inca23.gpkg")
inca_sub <- inca23[inca23$reach_no == subcatch_no,]
plot(inca_sub["reach_no"])


rain <- terra::rast("data/chess-met_precip/chess-met_precip_gb_1km_daily_19940101-19940131.nc")
crs(rain) <- crs("+init=epsg:27700")
# plot(rain[[5]]) # e.g. map of 5th day of month
pet <- terra::rast("data/chess-pe_pet/chess-pe_pet_gb_1km_daily_19940101-19940131.nc")
crs(pet) <- crs("+init=epsg:27700")


daily_subcatch_rain_pet <- data.frame(matrix(ncol = 3, nrow = 0))
colnames(daily_subcatch_rain_pet) <- c("date", "rain", "pet")
for(day in 1:dim(rain)[3]){
  rain_1day <- rain[[day]]
  pet_1day  <- pet[[day]]
  day_rain_sub <- terra::extract(rain_1day, vect(inca_sub["reach_no"]))
  day_pet_sub  <- terra::extract(pet_1day,  vect(inca_sub["reach_no"]))
  daily_rain_mean <- mean(day_rain_sub[,2]) * 24 * 60 * 60 # Convert to mm / day
  daily_pet_mean  <- mean(day_pet_sub[,2])  * 24 * 60 * 60
  rain_stats <- data.frame(date = time(rain_1day),
                           rain = daily_rain_mean,
                           pet  = daily_pet_mean)
  daily_subcatch_rain_pet <- rbind(daily_subcatch_rain_pet, rain_stats)
}



# daily temperature if needed
# tmp3 <- terra::rast("data/chess-met_tas/chess-met_tas_gb_1km_daily_19931201-19931231.nc")
# crs(tmp3) <- crs("+init=epsg:27700")
# tmp3
# summary(tmp3)
# plot(tmp3[[15]]) # 15th day

