# Try and run for multiple reaches. Try just 1 to 6 initially as we know that
# reach 6 is guaged

library(ggplot2)

# Flow rates along reaches based on Fig. 6 of Jarvie
flow_fig6 <- read.csv("data/fig_6.csv")

ggplot(flow_fig6, aes(x = x, y = y)) +
  geom_point() +
  geom_smooth(se=FALSE, method = "lm", formula = y ~ x - 1, fullrange = TRUE) +
  xlab("Distance from source (km)") +
  ylab("River flow cumecs/s") +
  xlim(0, 150) +
  theme_classic()

flow_lm <- lm(y ~ x - 1, data=flow_fig6)
summary(flow_lm)
fitted(flow_lm) # Use these to predict the mean river flows for each reach
fig_lengths <- flow_fig6$x[2:23] - flow_fig6$x[1:22] # Distance between each pair of reaches
reach_length <- c(7000, 7000, 7000, 7500, 6000, 4500, 8750, 8500, 6000,
                  6500, 7000, 1500, 2500, 2500, 6500, 8500, 7000, 7500,
                  6500, 8000, 8000, 4000, 6000)
plot(fig_lengths, reach_length[2:23]/1000) # very close match

# Use the percentage decline of flow from guaged downstream reaches to aid
# calibration of ungauged upstream ones. e.g. reach 1 has predicted 4.849
# flow vs 27.153, from fitted(flow_lm) i.e. 17.8% of flow. Take the airGR
# OutputsModel$Qsim values or the observed reach 6 guaged values to do
# initial calibration of reach 1 etc.

# It isn't easy to calculate delay times from reaches and cumecs as it depends
# on width of river. We'll assume a constant value for all reaches, since
# reach length is roughly the same at source vs Berwick. Use 2 days initially
# as default in airGR semi-distributed model.
delay_days <- 2