rm(list = ls())
data(Severn)
nodes <- Severn$BasinsInfo[, c("gauge_id", "downstream_id", "distance_downstream", "area")]
nodes$distance_downstream <- nodes$distance_downstream
nodes$model <- "RunModel_GR4J"
griwrm <- CreateGRiwrm(nodes, list(id = "gauge_id", down = "downstream_id", length = "distance_downstream"))
BasinsObs <- Severn$BasinsObs
DatesR <- BasinsObs[[1]]$DatesR
PrecipTot <- cbind(sapply(BasinsObs, function(x) {x$precipitation}))
PotEvapTot <- cbind(sapply(BasinsObs, function(x) {x$peti}))
Qobs <- cbind(sapply(BasinsObs, function(x) {x$discharge_spec}))
Precip <- ConvertMeteoSD(griwrm, PrecipTot)
PotEvap <- ConvertMeteoSD(griwrm, PotEvapTot)
InputsModel <- CreateInputsModel(griwrm, DatesR, Precip, PotEvap)

IndPeriod_Run <- seq(
  which(InputsModel[[1]]$DatesR == (InputsModel[[1]]$DatesR[1] + 365*24*60*60)), # Set aside warm-up period
  length(InputsModel[[1]]$DatesR) # Until the end of the time series
)
IndPeriod_WarmUp <- seq(1, IndPeriod_Run[1] - 1)

RunOptions <- CreateRunOptions(
  InputsModel,
  IndPeriod_WarmUp = IndPeriod_WarmUp,
  IndPeriod_Run = IndPeriod_Run
)

InputsCrit <- CreateInputsCrit(
  InputsModel = InputsModel,
  FUN_CRIT = ErrorCrit_KGE2,
  RunOptions = RunOptions,
  Obs = Qobs[IndPeriod_Run, ],
  AprioriIds = c(
    "54057" = "54032",
    "54032" = "54001",
    "54001" = "54095"
  ),
  transfo = "sqrt",
  k = 0.15
)
str(InputsCrit)

CalibOptions <- CreateCalibOptions(InputsModel)

OutputsCalib <- suppressWarnings(
  Calibration(InputsModel, RunOptions, InputsCrit, CalibOptions))

ParamMichel <- sapply(OutputsCalib, "[[", "ParamFinalR")

OutputsModels <- RunModel(
  InputsModel,
  RunOptions = RunOptions,
  Param = ParamMichel
)

plot(OutputsModels, Qobs = Qobs[IndPeriod_Run,])

Qm3s <- attr(OutputsModels, "Qm3s")
plot(Qm3s[1:150,])


data(Severn)
library(tmap)
sf_Severn <- sf::st_as_sf(Severn$BasinsInfo, coords = c("gauge_lon", "gauge_lat"),
                          crs = sf::st_crs(4326))
tmap_mode("view")
tm_shape(sf_Severn) + 
  tm_symbols(size = 0.5,
             popup.vars = c("Nom" = "gauge_name", "Surf (km²)" = "area",
                            "Aval" = "downstream_id", 
                            "Distance" = "distance_downstream")) + 
  tm_text(text = "gauge_id", size = 1, auto.placement = TRUE) + 
  tm_basemap("Esri.WorldTopoMap")

