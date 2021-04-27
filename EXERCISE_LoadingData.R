library(raster)
library(sf)
setwd("C:/Users/acheesem/Desktop/ESF/Classes Taught/Geospatial Analysis in R/Exercise_1_Answers")
ras<-raster("moon.tif")
plot(ras)

x<-runif(25,0,350)
y<-runif(25,0,500)
df<-data.frame(x=x,y=y)
points<-st_as_sf(df, coords = c("x", "y"), crs = crs(ras))


plot(ras)
plot(points,add=T,pch=16)


