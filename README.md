# wader_tweed
Hydrological modelling for WADER in catchment of Tweed

## Background
Clear for some time that the INCA approach is likely to be most fruitful, given that many parameters have been estimated. Main challenge has been to get the hydrology running smoothly. Three approaches have been investigated, all semi-distributed:

### TopModel
Definitely the most powerful of the three, but also the most difficult to implement in practice. The R topmodel package is not properly maintained, and whilst it runs effectively, and is actively maintained, in GRASS GIS, this requires external configuration. GRASS 8 and R currently do not integrate well.

### AirGR
Whilst the original AirGR is a simple lumped model, a newer semi-distributed model AirGR-IWRM has been released [airGRiwrm: airGR based Integrated Water Resource Management R package](https://airgriwrm.g-eau.fr/) . In theory this would be a good solution, as it is entirely R-based, but in practice the errors from one subcatchment to the next cascade down the Tweed, and output simulations diverge progressively further down the river.

### IHACRES
Identification of unit Hydrographs And Component flows from Rainfall, Evapotranspiration and Streamflow data model. Available as a standalone eWater Toolkit (Java) from Sydney, or as one of the models in the R hydromad package. 

Currently the IHACRES approach looks most promising. Once this is resolved, the N transport component can be incorporated.
