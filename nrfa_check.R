# Get the NRFA for Tweed

library(rnrfa)
library(sf)
# Tweed lat-lon bbox
inca23 <- read_sf("data/inca23.gpkg")
inca23_ll <- st_transform(inca23, "EPSG:4326")
tweed_bbox <- st_bbox(inca23_ll)
nrfa_bbox <- list(lon_min = tweed_bbox$xmin,
                  lon_max = tweed_bbox$xmax,
                  lat_min = tweed_bbox$ymin,
                  lat_max = tweed_bbox$ymax)
tmp <- catalogue(nrfa_bbox, column_name = "river", column_value = "Tweed")
nrfa_tweed_official <- tmp[is.na(tmp$closed),]

# Note difference between number of stations in catchment vs on Tweed itself
# The nrfa_tweed list also includes closed stations and subcatchments
nrfa_tweed_official$id
nrfa_tweed <- readRDS("data/nrfa_stations_tweed.RDS")
sort(unique(nrfa_tweed[["ID"]]))

# Guaged Daily Flow River Tweed only ####
# ID 21014 Kingledores = INCA 3
# stn_gdf <- gdf(id = "21014")
# plot(stn_gdf) # Data missing from late 1980s onwards so no use

# ID 21005 Lyneford   = INCA 6
stn_gdf <- gdf(id = "21005")
plot(stn_gdf) # OK
# ID 21003 Peebles/Scots Mill = INCA 7
stn_gdf <- gdf(id = "21003")
plot(stn_gdf) # OK
# ID 21006 Boleside  = INCA 12
stn_gdf <- gdf(id = "21006")
plot(stn_gdf) # OK
# ID 21021 Sprouston = INCA 19
stn_gdf <- gdf(id = "21021")
plot(stn_gdf) # OK
# ID 21009 Noreham   = INCA 23
stn_gdf <- gdf(id = "21009")
plot(stn_gdf) # OK

# Guaged Daily Flow including subcatchments
# NRFA stations 21005, 21003, 21006, 21021 and 21009 plus from
sort(unique(nrfa_tweed[["ID"]]))
stn_gdf <- gdf(id = "21007")
plot(stn_gdf) # OK
stn_gdf <- gdf(id = "21008")
plot(stn_gdf) # OK
# stn_gdf <- gdf(id = "21010")
# plot(stn_gdf) # No - stops in 1982
stn_gdf <- gdf(id = "21011")
plot(stn_gdf) # OK
stn_gdf <- gdf(id = "21012")
plot(stn_gdf) # OK
stn_gdf <- gdf(id = "21013")
plot(stn_gdf) # OK
# stn_gdf <- gdf(id = "21014")
# plot(stn_gdf) # No - stops in 1988
stn_gdf <- gdf(id = "21015")
plot(stn_gdf) # OK
stn_gdf <- gdf(id = "21017")
plot(stn_gdf) # OK
stn_gdf <- gdf(id = "21018")
plot(stn_gdf) # OK
stn_gdf <- gdf(id = "21019")
plot(stn_gdf) # OK
stn_gdf <- gdf(id = "21020")
plot(stn_gdf) # One year missing 2008
stn_gdf <- gdf(id = "21023")
plot(stn_gdf) # OK
stn_gdf <- gdf(id = "21024")
plot(stn_gdf) # OK
stn_gdf <- gdf(id = "21025")
plot(stn_gdf) # OK
stn_gdf <- gdf(id = "21026")
plot(stn_gdf) # Two years missing 2009-2010
stn_gdf <- gdf(id = "21030")
plot(stn_gdf) # OK
# stn_gdf <- gdf(id = "21031")
# plot(stn_gdf) # No - stops in 1980
stn_gdf <- gdf(id = "21032")
plot(stn_gdf) # Coverage between 1990-2009 so use for calibration only
stn_gdf <- gdf(id = "21034")
plot(stn_gdf) # OK




