# Try and run for multiple reaches. Try just 1 to 6 initially as we know that
# reach 6 is guaged

library(ggplot2)
library(rnrfa)
library(sf)

rm(list=ls())

# Flow rates along reaches based on Fig. 6 of Jarvie
flow_fig6 <- read.csv("data/fig_6.csv")

ggplot(flow_fig6, aes(x = x, y = y)) +
  geom_point() +
  geom_smooth(se=FALSE, method = "lm", formula = y ~ x - 1, fullrange = TRUE) +
  xlab("Distance from source (km)") +
  ylab("River flow cumecs/s") +
  xlim(0, 150) +
  theme_classic()

flow_lm <- lm(y ~ x - 1, data=flow_fig6)
summary(flow_lm)
fitted(flow_lm) # Use these to predict the mean river flows for each reach
fig_lengths <- flow_fig6$x[2:23] - flow_fig6$x[1:22] # Distance between each pair of reaches
reach_length <- c(7000, 7000, 7000, 7500, 6000, 4500, 8750, 8500, 6000,
                  6500, 7000, 1500, 2500, 2500, 6500, 8500, 7000, 7500,
                  6500, 8000, 8000, 4000, 6000)
plot(fig_lengths, reach_length[2:23]/1000) # very close match

# Use the percentage decline of flow from guaged downstream reaches to aid
# calibration of ungauged upstream ones. e.g. reach 1 has predicted 4.849
# flow vs 27.153, from fitted(flow_lm) i.e. 17.8% of flow. Take the airGR
# OutputsModel$Qsim values or the observed reach 6 guaged values to do
# initial calibration of reach 1 etc.
flow_pct_diff <- data.frame(reach_no=1:6, pct=NA)
guaged_reach_no <- 6
for(i in 1:6){
  flow_pct_diff$pct[i] <- fitted(flow_lm)[i] / fitted(flow_lm)[guaged_reach_no]
}
# To build up the data, work with reach no. 6 first to create the airGRiwrm
# inputs for it first. Ones Qmm defined, use the adjusted values from there to
# calibrate the upstream catchments
# Reach 6 
# ID 21005 Lyneford   = INCA 6
stn_gdf <- gdf(id = "21005")
inca23 <- read_sf("data/inca23.gpkg")
inca_sub <- inca23[inca23$reach_no == guaged_reach_no,]
plot(inca_sub["reach_no"])

rain_files <- list.files("data/chess-met_precip/", full.names = TRUE)
pet_files  <- list.files("data/chess-pe_pet/", full.names = TRUE)

no_of_months <- length(rain_files)
# no_of_months <- 1

#BasinObs <- data.frame(matrix(ncol = 4, nrow = 0))
#colnames(BasinObs) <- c("DatesR", "P", "E", "Qmm")

BasinObs <- data.frame(DatesR = as.Date(character()), P = numeric(), E = numeric(),  Qmm = numeric())

# Next bit is slow
for(month_no in 1:no_of_months){
  print(round(month_no / no_of_months * 100), 2)
  rain <- terra::rast(rain_files[month_no])  
  pet  <- terra::rast(pet_files[month_no])
  
  terra::crs(rain) <- terra::crs("+init=epsg:27700")
  terra::crs(pet) <- terra::crs("+init=epsg:27700")
  
  for(day in 1:dim(rain)[3]){
    cat(".")
    rain_1day <- rain[[day]]
    pet_1day  <- pet[[day]]
    # day_rain_sub <- terra::extract(rain_1day, vect(inca_sub["reach_no"]))
    # day_pet_sub  <- terra::extract(pet_1day,  vect(inca_sub["reach_no"]))
    # day_rain_sub <- crop(mask(rain_1day, vect(inca_sub)), vect(inca_sub)) # returns map of just target area
    day_rain_sub <- terra::extract(rain_1day, terra::vect(inca_sub))
    day_pet_sub  <- terra::extract(pet_1day,  terra::vect(inca_sub))
    daily_rain_mean <- mean(day_rain_sub[,2]) * 24 * 60 * 60 # Convert to mm / day
    daily_pet_mean  <- mean(day_pet_sub[,2])
    rain_stats <- data.frame(DatesR = terra::time(rain_1day),
                             P      = daily_rain_mean,
                             E      = daily_pet_mean,
                             Qmm    = stn_gdf[terra::time(rain_1day)])
    BasinObs <- rbind(BasinObs, rain_stats)
  }
  
}
BasinObs$DatesR <- as.POSIXct(BasinObs$DatesR)
saveRDS(BasinObs, file = paste0("data/BasinObs_", guaged_reach_no, ".RDS"))

# Repeat the process for the ungaugaed reaches 1 to 5
# Adjust the Qmm in accordance with values from earlier linear model
# Need to put all this in a function or simplify at some point
# As it is so slow will try as a function and parallise it (Linux-only)

library(tictoc)
create_reach_info <- function(reach_no){
  tic("initial setup")
  #print(paste0("Reach number:", reach_no))
  inca_sub <- inca23[inca23$reach_no == reach_no,]
  plot(inca_sub["reach_no"])
  
  BasinObs <- data.frame(DatesR = as.Date(character()), P = numeric(), E = numeric(),  Qmm = numeric())
  
  # Next bit is slow
  for(month_no in 1:no_of_months-82){
    tic("start of month_no")
    #print(round(month_no / no_of_months * 100), 2)
    rain <- terra::rast(rain_files[month_no])  
    pet  <- terra::rast(pet_files[month_no])
    
    terra::crs(rain) <- terra::crs("+init=epsg:27700")
    terra::crs(pet) <- terra::crs("+init=epsg:27700")
    
    for(day in 1:dim(rain)[3]-22){
      tic("day loop")
      #cat(".")
      rain_1day <- rain[[day]]
      pet_1day  <- pet[[day]]
      day_rain_sub <- terra::extract(rain_1day, terra::vect(inca_sub))
      day_pet_sub  <- terra::extract(pet_1day,  terra::vect(inca_sub))
      daily_rain_mean <- mean(day_rain_sub[,2]) * 24 * 60 * 60 # Convert to mm / day
      daily_pet_mean  <- mean(day_pet_sub[,2])
      rain_stats <- data.frame(DatesR = terra::time(rain_1day),
                               P      = daily_rain_mean,
                               E      = daily_pet_mean,
                               Qmm    = stn_gdf[terra::time(rain_1day)] * flow_pct_diff$pct[reach_no])
      tic("rbindlist")
      BasinObs <- data.table::rbindlist(list(BasinObs, rain_stats))
    }
    
  }
  BasinObs$DatesR <- as.POSIXct(BasinObs$DatesR)
  tic("saveRDS")
  saveRDS(BasinObs, file = paste0("data/BasinObs_", reach_no, ".RDS"))
  toc()
}

library(parallel)
library(pbapply)
pblapply(1, create_reach_info, cl=20)


# It isn't easy to calculate delay times from reaches and cumecs as it depends
# on width of river. We'll assume a constant value for all reaches, since
# reach length is roughly the same at source vs Berwick. Use 2 days initially
# as default in airGR semi-distributed model.
delay_days <- 2