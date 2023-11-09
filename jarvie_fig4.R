# Compare INCA calibration results of my run of IHCRES model vs that in the
# Jarvie et al paper, specifically Figure 4.
# 

library(ggplot2)
library(tidyr)
library(dplyr)

# There is a trailing comma after the data in the CSV files read as 'blank'
# Fig. 4a Upper (1 to 12)
upper_dat <- read.csv("data/upper_calib_sim.csv",
                      col.names = c("date_time",
                                    "obs_rain_mm",
                                    "temp_celsius",
                                    "obs_stream",
                                    "eff_rain_mm",
                                    "mod_stream",
                                    "blank"))
upper_dat <- upper_dat[,1:6]
upper_dat$date_time <- as.Date(as.POSIXct(upper_dat$date_time, "%Y%m%d %h%m"))

upper_lng <- pivot_longer(upper_dat,
                          cols = c(obs_stream, mod_stream),
                          names_to = "stream_type",
                          values_to = "stream_flow") %>% 
  select(date_time, stream_type, stream_flow)

ggplot(upper_lng, aes(x = date_time, y = stream_flow, colour = stream_type)) +
  geom_line() +
  scale_colour_manual(values = c("red", "dark blue"), name = "Upper Tweed", labels = c("Predicted", "Observed")) +
  scale_x_date(date_breaks = "3 months", date_labels = "%b-%y",
               limits = as.Date(c("1994-01-01", "1998-01-01"))) +
  scale_y_continuous(limits = c(0, 600), breaks = seq(0, 600, by = 100)) +
  labs(y = expression("River flow (m"^{3}~"/s)")) +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) 


# Fig 4b
# There is a trailing comma after the data in the CSV files read as 'blank'
lower_dat <- read.csv("data/lower_calib_sim.csv",
                      col.names = c("date_time",
                                    "obs_rain_mm",
                                    "temp_celsius",
                                    "obs_stream",
                                    "eff_rain_mm",
                                    "mod_stream",
                                    "blank"))
lower_dat <- lower_dat[,1:6]
lower_dat$date_time <- as.Date(as.POSIXct(lower_dat$date_time, "%Y%m%d %h%m"))

lower_lng <- pivot_longer(lower_dat,
                          cols = c(obs_stream, mod_stream),
                          names_to = "stream_type",
                          values_to = "stream_flow") %>% 
  select(date_time, stream_type, stream_flow)

ggplot(lower_lng, aes(x = date_time, y = stream_flow, colour = stream_type)) +
  geom_line() +
  scale_colour_manual(values = c("red", "dark blue"), name = "Lower Tweed", labels = c("Predicted", "Observed")) +
  scale_x_date(date_breaks = "3 months", date_labels = "%b-%y",
               limits = as.Date(c("1994-01-01", "1998-01-01"))) +
  scale_y_continuous(limits = c(0, 800), breaks = seq(0, 800, by = 100)) +
  labs(y = expression("River flow (m"^{3}~"/s)")) +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) 
