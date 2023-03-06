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
    daily_pet_mean  <- mean(day_pet_sub[,2])
    rain_stats <- data.frame(DatesR = time(rain_1day),
                             P      = daily_rain_mean,
                             E      = daily_pet_mean,
                             Qmm    = stn_gdf[time(rain_1day)])
    BasinObs <- rbind(BasinObs, rain_stats)
  }
  
}
BasinObs$DatesR <- as.POSIXct(BasinObs$DatesR)

library(airGR)
# 2. Prepare various function inputs
# From https://hydrogr.github.io/airGR/page_1_get_started.html 
# 2.1 InputsModel: prepare input data
InputsModel <- CreateInputsModel(FUN_MOD = RunModel_GR4J, DatesR = BasinObs$DatesR,
                                 Precip = BasinObs$P, PotEvap = BasinObs$E)
str(InputsModel)
# 2.2 Setup options for running model, which are the actual model functions
Ind_Run <- seq(which(format(BasinObs$DatesR, format = "%Y-%m-%d") == "1995-01-01"), 
               which(format(BasinObs$DatesR, format = "%Y-%m-%d") == "2000-12-31"))
str(Ind_Run)
RunOptions <- CreateRunOptions(FUN_MOD = RunModel_GR4J,
                               InputsModel = InputsModel, IndPeriod_Run = Ind_Run,
                               IniStates = NULL, IniResLevels = NULL, IndPeriod_WarmUp = NULL)
str(RunOptions)
# 2.3 Define the error criterion
InputsCrit <- CreateInputsCrit(FUN_CRIT = ErrorCrit_NSE, InputsModel = InputsModel, 
                               RunOptions = RunOptions, VarObs = "Q", Obs = BasinObs$Qmm[Ind_Run])
str(InputsCrit)
# 2.4 Define model calibration
CalibOptions <- CreateCalibOptions(FUN_MOD = RunModel_GR4J, FUN_CALIB = Calibration_Michel)
str(CalibOptions)
# 3 Criteria
# The evaluation of the quality of a simulation is estimated through the calculation of criteria. These criteria can be used both as objective-functions during the calibration of the model, or as a measure for evaluating its performance on a control period.
# 
# The package offers the possibility to use different criteria:
#   
#   ErrorCrit_RMSE(): Root mean square error (RMSE)
# ErrorCrit_NSE(): Nash-Sutcliffe model efficiency coefficient (NSE)
# ErrorCrit_KGE(): Kling-Gupta efficiency criterion (KGE)
# ErrorCrit_KGE2(): modified Kling-Gupta efficiency criterion (KGE’)
# It is also possible to create user-defined criteria. For doing that, it is only necessary to define the function in R following the same syntax as the criteria functions included in airGR
# 4. Calibration
OutputsCalib <- Calibration_Michel(InputsModel = InputsModel, RunOptions = RunOptions,
                                   InputsCrit = InputsCrit, CalibOptions = CalibOptions,
                                   FUN_MOD = RunModel_GR4J)
Param <- OutputsCalib$ParamFinalR
Param
# 5 Control
# This step assesses the predictive capacity of the model. Control is defined as the estimation of the accuracy of the model on data sets that are not used in its construction, and in particular its calibration. The classical way to perform a control is to keep data from a period separated from the calibration period. If possible, this control period should correspond to climatic situations that differ from those of the calibration period in order to better point out the qualities and weaknesses of the model. This exercise is necessary for assessing the robustness of the model, that is to say its ability to keep stable performances outside of the calibration conditions.
# 
# Performing a model control with airGR is similar to running a simulation (see below), followed by the computation of one or several performance criteria.
# 6. Simulation
# 6.1 Simulation run
OutputsModel <- RunModel_GR4J(InputsModel = InputsModel, RunOptions = RunOptions, Param = Param)
str(OutputsModel)
# 6.2 Results preview
# Although it is possible for the user to design its own graphics from the outputs of the RunModel*() functions, the airGR package offers the possibility to make use of the plot() function. This function returns a dashboard of results including various graphs (depending on the model used):
#   
#   time series of total precipitation and simulated discharge (and observed discharge if provided)
# interannual average daily simulated discharge (and daily observed discharge if provided) and interannual average monthly precipitation
# cumulative frequency plot for simulated discharge (and for observed discharge if provided)
# correlation plot between simulated and observed discharge (if observed discharge provided)
plot(OutputsModel, Qobs = BasinObs$Qmm[Ind_Run])
# 6.3 Model efficiency
OutputsCrit <- ErrorCrit_NSE(InputsCrit = InputsCrit, OutputsModel = OutputsModel)
str(OutputsCrit)
OutputsCrit <- ErrorCrit_KGE(InputsCrit = InputsCrit, OutputsModel = OutputsModel)
str(OutputsCrit)
