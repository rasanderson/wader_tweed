# INCA hydrology and nitrogen model
# Attempts to follow various papers by Javie, Wade, Whitehead
# 
# Hydrology model ####
# Jarvis use 'upper' and 'lower' Tweed (reaches 1 to 12 and 13 to 23) for
# hydrologically effective rainfall and flow. This has been done outside R
# using IHACRES model.
# All papers are unclear on:
# 1. How they predict river flow in ungauged reaches
# 2. Exactly how inputs and outpus of flow into a reach are handled
# Will assume that best predictor of flow in ungauged reaches is based on %
# decline based on Fig. 6 of Jarvie. These 'observed' flows have been
# calculated in 'calc_reach_data.R'
# The IHACRES results stored in upper_calib_sim.csv and lower_calib_sim.csv
# and key piece of info needed from these files is HER hydrologically effective
# rainfall. Calibrated 1994-1997 and simulated 1998-2000 inclusive to match
# Jarvie approach.
# SMD also needs soil moisture deficit. Various ways of calculating this but
# simplest is PET - HER. May need this as a % -100 to +100.

# Coefficients from Jarvie
coef_a <- 0.02
coef_b <- 0.67
# Reach lengths and base flow index Jarvie Table 2
reach_length <- c(7000, 7000, 7000, 7500, 6000, 4500, 8750, 8500, 6000,
                  6500, 7000, 1500, 2500, 2500, 6500, 8500, 7000, 7500,
                  6500, 8000, 8000, 4000, 6000)
reach_BFI <- c(0.45, 0.45, 0.50, 0.50, 0.50,
               0.56, 0.55, 0.52, 0.52, 0.52,
               0.52, 0.51, 0.52, 0.52, 0.52,
               0.52, 0.52, 0.52, 0.52, 0.52,
               0.52, 0.52, 0.52)
# Soil water time constants Jarvie Appendix; units are days
coef_T1 <- 2.3 # soil_water_time_constant Whitehead 1998
coef_T2 <- 23  # ground_water_time_constant Whitehead 1998

her_upper <- read.csv("data/upper_calib_sim.csv", row.names = NULL)
her_upper <- her_upper[, -7] # Trailing , results in NA column
colnames(her_upper) <- c("date", "obs_rain", "tas", "obs_Q", "HER", "mod_Q")
her_upper$date <- as.Date(her_upper$date)
# Add HER to data for each upper reach
# Just test on one reach for now, then use list structure for everything
reach_no <- 1
#for(reach_no in 1:12){
  reach_data <- readRDS(paste0("data/BasinObs_", reach_no ,".RDS"))
  reach_data <- data.frame(cbind(reach_data, HER = her_upper$HER))
  # Constrain to -100 to +100
  for(i in 1:nrow(reach_data)){
    reach_data$SMD[i] = min(max(reach_data$E[i] - reach_data$HER[i], -100), 100)
  }
  
  # Flow velocity V
  reach_data$V <- coef_a * reach_data$Qmm ^ coef_b # Eqn (1)
#}

# Now model each day
for(day_no in 1: nrow(reach_data)){
  U1 <- reach_data$HER
  T1 <- coef_T1
  # Whitehead gives
  # x1 = outflow from soil store
  # dx1/dt = (U1 - x1) / T1
  # If we integrate and ignore c this gives (hopefully!!)
  # NEED TO REVISE MY SCHOOL MATHS!!
  # x1  <- ??
}
