# Semi-distributed version of airGR
rm(list = ls())

library(sf)
library(ncdf4)
library(raster)
library(leaflet)

# INCA-N 23 reaches in Tweed ####
inca23 <- read_sf("data/inca23.gpkg")
inca23
plot(inca23)

# NRFA stations ####
stations_cdf <- nc_open("data/morecs/MaRIUS_G2G_NRFAStationIDGrid.nc")
stations_cdf # print out information
nc_close(stations_cdf)
stations_sp <- raster("data/morecs/MaRIUS_G2G_NRFAStationIDGrid.nc", ncdf=TRUE,
                      varname = "ID")
crs(stations_sp) <-crs("+init=epsg:27700")
# Convert to vector
stations_df <- cbind(coordinates(stations_sp), as.vector(stations_sp))
colnames(stations_df)[3] <- "ID"
stations_df <- data.frame(stations_df)
stations_sf <- st_as_sf(stations_df, coords=c("x","y"), crs = crs("+init=epsg:27700"))
stations_sf <- stations_sf[!is.na(stations_sf$ID), ]
stations_sf <- stations_sf[stations_sf$ID != 0,]
plot(stations_sf)

# NRFA stations in Tweed (INCA boundaries)
nrfa_tweed <- st_intersection(inca23, stations_sf)
saveRDS(nrfa_tweed, "data/nrfa_stations_tweed.RDS")
nrfa_tweed_ll <- st_transform(nrfa_tweed, "EPSG:4326")
inca23_ll <- st_transform(inca23, "EPSG:4326")
leaflet() %>% 
  addTiles() %>% 
  addPolygons(data = inca23_ll) %>% 
  addMarkers(data = nrfa_tweed_ll, label = ~ID)


# MORECS data ####
# https://doi.org/10.5285/e911196a-b371-47b1-968c-661eb600d83b
library(ncdf4)
library(raster)

# Note: the .nc files are so big that stars automatically reads them as
# stars_proxy objects https://r-spatial.github.io/stars/articles/stars2.html

# Check the files
# Catchment area Area draining each G2G grid box ####
area_cdf <- nc_open("data/morecs/MaRIUS_G2G_CatchmentAreaGrid.nc")
area_cdf # Print out information about nc file
nc_close(area_cdf)
area_sp <- raster("data/morecs/MaRIUS_G2G_CatchmentAreaGrid.nc", ncdf=TRUE,
                  varname = "area")
crs(area_sp) <-crs("+init=epsg:27700")

library(leaflet)
area_sp_ll <- projectRaster(area_sp, crs=crs("+init=epsg:4326"))
qpal <- colorQuantile("Blues", area_sp_ll$Catchment_area, n = 7, na.color = NA)
leaflet() %>% 
  addTiles() %>% 
  addRasterImage(area_sp_ll, colors = qpal)


# MORECS monthly summaries of daily flow and soil moisture ####
# MORECS monthly mean daily flow 1960 to 2015 1 km scale
flow_cdf <- nc_open("data/morecs/G2G_MORECS_flow_1960_2015.nc")
flow_cdf
nc_close(flow_cdf)
library(stars)
library(tidyverse)
# If you just read in e.g. 35 months it doesn't need to be a stars_proxy
# flow_stars <- read_ncdf("morecs/G2G_MORECS_flow_1960_2015.nc",
#                         var = "flow",
#                         ncsub = cbind(start=c(1,1,1), count = c(700,1000,35)),
#                         proxy = FALSE)
# Full dataset from Jan 1960 to Dec 2015 (672 months) is a stars_proxy
flow_stars <- read_ncdf("data/morecs/G2G_MORECS_flow_1960_2015.nc", var="flow")
st_crs(flow_stars) <- 27700

# Interactive plot of a few dates
flow_stars_JanFeb2015 <- flow_stars[,,,661:662]
library(tmap)
tmap_leaflet(
  tm_shape(flow_stars_JanFeb2015) + 
    tm_raster() + 
    tm_facets(as.layers = TRUE)
)


# MORECS Monthly mean daily soil moisture oil 1960 to 2015 1km scale
# Units are mm water per metre soil
soil_cdf <- nc_open("data/morecs/G2G_MORECS_soil_1960_2015.nc")
soil_cdf
nc_close(soil_cdf)
soil_stars <- read_ncdf("data/morecs/G2G_MORECS_soil_1960_2015.nc", var = "soil")
st_crs(soil_stars) <- 27700
# Interactive plot of a few dates
soil_stars_JanFeb2015 <- soil_stars[,,,661:662]
plot(soil_stars_JanFeb2015)


tmap_leaflet(
  tm_shape(soil_stars_JanFeb2015) + 
    tm_raster() + 
    tm_facets(as.layers = TRUE)
)

