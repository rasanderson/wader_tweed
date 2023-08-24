# Hydromad which uses IHACRES approach for hydrologically effective rainfall
# or HER. This was used in INCA paper (Jakeman et al 1990). Hydromad implements
# basic approach. There is a standalone Java package which has more advanced
# facilities, but would have to be used outside R
# 

rm(list=ls())

library(hydromad)
library(zoo)

basin <- readRDS("data/BasinObs_12.RDS")
basin_area <- 471 /10
colnames(basin)[4] <- "Q" # not sure how fussy hydromad is on colnames
basin <- zoo(basin[,c(2,4,3)], basin$DatesR, frequency = 1)
# Not sure if areal conversion needed
basin$Q <- convertFlow(basin$Q, from = "ML", area.km2 = basin_area)
xyplot(basin, screens = c("Streamflow (mm/day)",
                          "Areal rain (mm/day)",
                          "Temperature or Evap. (deg. C)"),
       xlab = NULL)
summary(basins)

# Calculate runoff ratio; typical average should be around 0.37
ok <- complete.cases(basin[, 1:2])
with(basin, sum(Q[ok])/sum(P[ok]))

# Delay between rain and runoff
estimateDelay(data.frame(U = basin$P, Q = basin$Q))
x <- rollccf(basin)
xyplot.rollccf(x)

ts_calib <- window(basin, start = "1994-01-01", end = "1997-12-31")
ts_sim   <- window(basin, start = "1998-01-01", end = "2000-12-31")

basinsMod <- hydromad(ts_calib, sma = "cwi") #, routing = "expuh",
                      #tau_s = c(5,100), tau_q = c(0,5), v_s = c(0,1))
# print(basinsMod) Error, refuses to print with POSIX error
# basinsMod <- update(basinsMod, routing = "armax", rfit = list("sriv", order = c(n=2, m=1)))
# Next line fails to converge and runs out of system memory.
basinsFit <- fitByOptim(basinsMod)
xyplot(basinsFit, with.P = TRUE, xlim = as.Date(c("1994-01-01", "1997-12-31")))



# This works but output similar format
ts70s <- window(Cotter, start = "1970-01-01", end = "1979-12-31")
ts80s <- window(Cotter, start = "1980-01-01", end = "1989-12-31")
ts90s <- window(Cotter, start = "1990-01-01", end = "1999-12-31")
cotterMod <- hydromad(ts90s, sma = "cwi", routing = "expuh",
                      tau_s = c(5,100), tau_q = c(0,5), v_s = c(0,1))
print(cotterMod)
cotterMod <- update(cotterMod, routing = "armax", rfit = list("sriv", order = c(n=2, m=1)))
cotterFit <- fitByOptim(cotterMod, samples = 100, method = "PORT")
xyplot(cotterFit, with.P = TRUE, xlim = as.Date(c("1994-01-01", "1997-01-01")))
