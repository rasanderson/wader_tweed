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
names(BasinsObs) <- nodes$gauge_id[6:1] # in reverse order to match nodes

# If I understand the tutorial correctly, have to calculate some values for
# all basins. 
# DatesR: all the dates
# PrecipTot, PotEvapTot, Qobs: each column is value from one basin, and 
#      each row a date
DatesR <- BasinsObs[[1]]$DatesR
PrecipTot <- cbind(sapply(BasinsObs, function(x) {x$precipitation}))
PotEvapTot <- cbind(sapply(BasinsObs, function(x) {x$peti}))
Qobs <- cbind(sapply(BasinsObs, function(x) {x$discharge_spec}))

# These meteorological data consist in mean precipitation and PE for each basin.
# However, the model needs mean precipitation and PE at sub-basin scale. The
# function ConvertMeteoSD calculates these values for downstream sub-basins:
# The next function isn't working
# ConvertMeteoSD.character <- function(x, griwrm, meteo, ...) {
#   upperBasins <- !is.na(griwrm$down) & griwrm$down == x
#   if(all(!upperBasins)) {
#     return(meteo[,x])
#   }
#   upperIDs <- griwrm$id[upperBasins]
#   areas <- griwrm$area[match(c(x, upperIDs), griwrm$id)]
#   output <- ConvertMeteoSD(
#     meteo[,c(x, upperIDs), drop = FALSE],
#     areas = areas
#   )
#   return(output)
# }

Precip  <- ConvertMeteoSD(griwrm, PrecipTot)
PotEvap <- ConvertMeteoSD(griwrm, PotEvapTot)

# Generation of the GRiwrmInputsModel object ####
# The GRiwrmInputsModel object is a list of airGR InputsModel objects. The
# identifier of the sub-basin is used as a key in the list which is ordered from
# upstream to downstream.

# The airGR CreateInputsModel function is extended in order to handle the GRiwrm
# object that describes the basin diagram:
  
InputsModel <- CreateInputsModel(griwrm, DatesR, Precip, PotEvap)

# Calibration of model ####
# GRiwrmRunOptions object
# The CreateRunOptions() function allows to prepare the options required for
# the RunModel() function.
#
# The user must at least define the following arguments:
#   
# InputsModel: the associated input data
# IndPeriod_Run: the period on which the model is run
# Below, we define a one-year warm up period and we start the run period just after the warm up period.

IndPeriod_Run <- seq(
  which(InputsModel[[1]]$DatesR == (InputsModel[[1]]$DatesR[1] + 365*24*60*60)), # Set aside warm-up period
  length(InputsModel[[1]]$DatesR) # Until the end of the time series
)
IndPeriod_WarmUp <- seq(1, IndPeriod_Run[1] - 1)

# Arguments of the CreateRunOptions function for airGRiwrm are the same as for
# the function in airGR and are copied for each node running a rainfall-runoff
# model.

RunOptions <- CreateRunOptions(
  InputsModel,
  IndPeriod_WarmUp = IndPeriod_WarmUp,
  IndPeriod_Run = IndPeriod_Run
)

# GRiwrmInputsCrit object
# The CreateInputsCrit() function allows to prepare the input in order to
# calculate a criterion. We use composed criterion with a parameter
# regularization based on @delavenneRegularizationApproachImprove2019.
#
# It needs the following arguments:
#  
# InputsModel: the inputs of the GRiwrm network previously prepared by the
#               CreateInputsModel() function
# FUN_CRIT: the name of the error criterion function (see the available
#               functions description in the airGR package)
# RunOptions: the options of the GRiwrm network previously prepared by
#               the CreateRunOptions() function
# Qobs: the observed variable time series (e.g. the discharge expressed in
#               mm/time step)
# AprioriIds: the list of the sub-catchments IDs where to apply a parameter
#               regularization based on the parameters of an upstream
#               sub-catchment (e.g. in Severn example the parameters of the
#               sub-catchment “54057” is regulated by the parameters of the
#               sub-catchment “54032”)
# transfo: a transformation function applied on the flow before calculation of
#               the criterion (square-root transformation is recommended for
#               the De Lavenne regularization)
# k: coefficient used for the weighted average between the performance criterion
#               and the gap between the optimized parameter set and an a priori
#               parameter set (a value equal to 0.15 is recommended for the De
#               Lavenne regularization)
InputsCrit <- CreateInputsCrit(
  InputsModel = InputsModel,
  FUN_CRIT = ErrorCrit_KGE2,
  RunOptions = RunOptions,
  Obs = Qobs[IndPeriod_Run, ],
  AprioriIds = c(
    "6" = "5",
    "5" = "4",
    "4" = "3",
    "3" = "2",
    "2" = "1"
  ),
  transfo = "sqrt",
  k = 0.15
)
str(InputsCrit)

# GRiwrmCalibOptions object
# Before using the automatic calibration tool, the user needs to prepare the
# calibration options with the CreateCalibOptions() function. The
# GRiwrmInputsModel argument contains all the necessary information:
CalibOptions <- CreateCalibOptions(InputsModel)

# Calibration
# The airGR calibration process is applied on each node of the GRiwrm network
# from upstream nodes to downstream nodes.
OutputsCalib <- suppressWarnings(
  Calibration(InputsModel, RunOptions, InputsCrit, CalibOptions))
ParamMichel <- sapply(OutputsCalib, "[[", "ParamFinalR")

# Run the model with the optimized model parameters
OutputsModels <- RunModel(
  InputsModel,
  RunOptions = RunOptions,
  Param = ParamMichel
)

# Plot the results for each basin
plot(OutputsModels, Qobs = Qobs[IndPeriod_Run,])

# The resulting flows of each node in m3/s are directly available
Qm3s <- attr(OutputsModels, "Qm3s")
plot(Qm3s[1:365,]) # 1995
