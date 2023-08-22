for(i in 1:23){
  plot(BasinsObs[[as.character(i)]]$DatesR, BasinsObs[[as.character(i)]]$precipitation, type = "l", main=i)
}
  
library(dplyr)
df <- bind_rows(BasinsObs)

df2 <- mutate(df, DatesR = DatesR) %>% 
  group_by(DatesR) %>% 
  summarise(preciptation = mean(precipitation))

par(mfrow = c(1,1))
plot(df2$DatesR, df2$preciptation, type = "l")
