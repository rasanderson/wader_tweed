# Use the new airGRiwrm library for semi-distributed modelling
# Assume the relevant .RDS files have already been created (by airGRSD.R)
# prior to use.
# Test with Tweed reaches 1 to 6 initially

rm(list = ls())

library(airGRiwrm)

# Semi-distributed network description ####
no_of_reaches <- 6
nodes <- data.frame(gauge_id = character(no_of_reaches),
                    downstream_id = character(no_of_reaches),
                    distance_downstream = numeric(no_of_reaches),
                    area = numeric(no_of_reaches))
nodes$gauge_id <- c(as.character(no_of_reaches:1))
nodes$downstream_id <- c(NA, as.character(no_of_reaches:2))
# For speed, take reach lengths and areas from Jarvie for now, but later
# calculate directly from geographic files
# It is not quite clear from the example, but presumably the length of
# reach 1 (7000 m) is omitted. It is the length to the next reach that 
# matters. Could try running model with 
# Units are km
# nodes$distance_downstream <- c(NA, 6.00, 7.50, 7.0, 7.0, 7.0)
# to check for change
nodes$distance_downstream <- c(NA, 4.500, 6.000, 7.500, 7.000, 7.000)
# Area is in km2
nodes$area <- c(15, 159, 38, 87, 27, 21)
# Area must be cumulative sum
nodes$area <- cumsum(nodes$area[6:1])[6:1]
nodes$model <- "RunModel_GR4J"

# Create object of class GRiwrm
griwrm <- CreateGRiwrm(nodes, list(id = "gauge_id", down = "downstream_id",
                                   length = "distance_downstream"))
griwrm
plot(griwrm)

# Observation time series ####
# Observations (precipitation, potential evapotranspiration (PE) and flows)
# should be formatted in a separate data.frame with one column of data per
# sub-catchment.
# Read in previously saved info
basins_01 <- readRDS("data/BasinObs_1.RDS")
basins_02 <- readRDS("data/BasinObs_2.RDS")
basins_03 <- readRDS("data/BasinObs_3.RDS")
basins_04 <- readRDS("data/BasinObs_4.RDS")
basins_05 <- readRDS("data/BasinObs_5.RDS")
basins_06 <- readRDS("data/BasinObs_6.RDS")
# For simplicity, set column names to be same as Severn example
colnames(basins_01) <- c("DatesR", "precipitation", "peti", "discharge_spec")
colnames(basins_02) <- c("DatesR", "precipitation", "peti", "discharge_spec")
colnames(basins_03) <- c("DatesR", "precipitation", "peti", "discharge_spec")
colnames(basins_04) <- c("DatesR", "precipitation", "peti", "discharge_spec")
colnames(basins_05) <- c("DatesR", "precipitation", "peti", "discharge_spec")
colnames(basins_06) <- c("DatesR", "precipitation", "peti", "discharge_spec")
# Assemble into list object
BasinsObs <- list(basins_01,
                  basins_02,
                  basins_03,
                  basins_04,
                  basins_05,
                  basins_06)
names(BasinsObs) <- nodes$gauge_id[6:1]

# If I understand the tutorial correctly, have to calculate some values for
# all basins
DatesR <- BasinsObs[[1]]$DatesR
PrecipTot <- cbind(sapply(BasinsObs, function(x) {x$precipitation}))
PotEvapTot <- cbind(sapply(BasinsObs, function(x) {x$peti}))
Qobs <- cbind(sapply(BasinsObs, function(x) {x$discharge_spec}))

# These meteorological data consist in mean precipitation and PE for each basin.
# However, the model needs mean precipitation and PE at sub-basin scale. The
# function ConvertMeteoSD calculates these values for downstream sub-basins:
Precip  <- ConvertMeteoSD(griwrm, PrecipTot)
PotEvap <- ConvertMeteoSD(griwrm, PotEvapTot)

# Generation of the GRiwrmInputsModel object ####
# The GRiwrmInputsModel object is a list of airGR InputsModel objects. The
# identifier of the sub-basin is used as a key in the list which is ordered from
# upstream to downstream.

# The airGR CreateInputsModel function is extended in order to handle the GRiwrm
# object that describes the basin diagram:
  
InputsModel <- CreateInputsModel(griwrm, DatesR, Precip, PotEvap)
