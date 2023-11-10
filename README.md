# WADER Tweed Hydrology

Hydrological and pollution modelling for Wader using several approaches

## Background

Initial attempts were made to model the data inside GRASS GIS using Topmodel but this proved problematic with different file formats. The aim is to do everything inside R although seamless integration has yet to be achieved. There is a topmodel package in R but this is poorly supported. Two components are needed:

-   Hydrology modelling - minimum will be river flows down the Tweed, but overland flow might also be needed.

-   Pollution modelling - initially nitrogen, but would be good to include phosphorus

A fully-distributed approach to hydrology modelling, such as SHE, is avoided as this will be too slow and requires huge numbers of parameters. Semi-distributed methods better, but even here there is a "data bottleneck" in that processing spatio-temporal data to get daily average temperature, potential evapotranspiration etc. for each sub-catchment is very slow. These have therefore been calculated separately. A related issue is the size of the resultant data files: these are often too big for GitHub to handle, and so local storage / OneDrive is being used as an interim step.

***Eventual aim**:* Ideally a shiny app showing river flows and predicted pollution for different land use scenarios in Tweed catchment.

## Files and models

## `airGRiwrm.R`

The AirGR approach may be a viable alternative to Topmodel, especially with the [airGRiwrm: airGR based Integrated Water Resource Management R package](https://airgriwrm.g-eau.fr/) which allows for semi-distributed subcatchment models. In practice there has been a problem that observed and predicted values have drifted apart further downstream.

## `calc_reach_data.R`

This attempts to calculate rainfall, PET and flow (Qmm) for the Tweed's 23 reaches used in Jarvie's INCA paper. The data are stored in `data\BasinObs_01.RDS` to `data\BasinObs_23.RDS` after calculation, which is slow. Rain and PET from published datasets. Qmm estimated by observed percentage flow differences for the Tweed along the 23 reaches, as published by Jarvie Fig. 6 to produce a simple, but well-fitting model.

## `check_rain.R`

Utility rainfall script, probably not needed

## `chess.R`

Used to check some of the outputs of AirGR. Given problems of AirGR, probably not needed. \## `data\` Main processed data storage folder. \## `data_preprocess.R` Although written for AirGR, this contains useful functions for handling MORECS data from CEH. \## `hydromad.R` This needs further work. Jarvie use the IHACRES model to estimate effective rainfall and flowrates in the Tweed. The R hydromad package contains an implementation of IHACRES, which runs, but then fails to print results due to a POSIXct error. It is likely that the date or timestamp is incorrectly setup. IHACRES has been run externally from R as an interim measure.

## `inca.R`

This will run the INCA model described by Whitehead with the parameters presented by Jarvie. It is almost certain it will have to call external R source files containing extra functions as it will become too long. This is the core program for the modelling approach as it integrates the hydrology and nitrogen.

## `jarvie_fig4.R`

Jarvie splits the Tweed into two areas (broadly upland and lowland) against which to calculate flowrates and effective rainfall from IHACRES. This takes the outputs from IHACRES, stored in `data/upper_calib_sim.csv` and `data/lower_calib_sim.csv`, plots the observed and predicted river flows using the same graphics as presented in Fig. 4 of Jarvie. Results are almost identical giving confidence in IHACRES.

## `nitrate_preprocess.R`

Utility script to read N monitoring data for Tweed. Unclear when or if this is needed. \## `nrfa_check.R` Extracts all the available National Rivers Flow Archive data for Tweed at reach level. Unfortunately not all 23 reaches have NRFA gauging stations, and some of the stations have incomplete data for the whole time period.

## `README.md`

This file

## `upper_lower_stats.R`

This is slow to run. It gets the CEH CHESS rainfall and PET data, plus Qmm, for the "upper" and "lower" parts of the Tweed catchment defined by Jarvie (to reach 12 and 23). Output data stored in `data/BasinObs_upper.RDS` and `data/BasinObs_lower.RDS` and similarly-named .CSV files. The latter are used for the external run of IHACRES, whose outputs are visualised in `jarvie_fig4.R` and provide the main input into `inca.R`

## `wader_airgr.Rproj`

The R project. Both the project name and GitHub repository should really be re-named now that IHACRES+INCA are main line of attack.

## `WARNING.txt`

Just to remind me that none of the files in `data\` are not backed up on GitHub, as the whole of the `data\` folder is listed in `.gitignore`. Hopefully this can be resolved soon.
