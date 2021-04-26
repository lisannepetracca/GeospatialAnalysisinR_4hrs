#Let's run through some steps to make sure we are good to go for the workshop
#First, let's install some packages

#then we will install other packages that *are* in the CRAN library
#***IF IT ASKS TO RESTART R, YOU CAN SAY YES***
install.packages(c("sp", "sf", "raster", "rgeos", "ggplot2", "units", "rnaturalearth",  "rnaturalearthdata", 
                   "rgbif","viridis","ggspatial","ellipsis","fansi","utf8"),dependencies = TRUE)
#***RED TEXT DOES NOT MEAN IT DIDN'T WORK. THERE IS ONLY AN ISSUE IF YOU SEE SOMETHING LIKE "Error in install.packages>"***

#now let's get these packages loaded into R
library(sp)
library(sf)
library(raster)
library(rgeos)
library(ggplot2)
library(units)
library(rgbif)
library(viridis)
library(ggspatial)
library(rnaturalearth)
library(rnaturalearthdata)


#we are ALL GOOD on packages if you do not get any error messages after running these "library" lines

#now we will set our working directory
#don't forget to keep the / syntax in the directory location (\ does not work)
setwd("C:/Users/lspetrac/Desktop/Geospatial_Analysis_in_R") 
      #CHANGE DIRECTORY TO WHERE YOUR "Geospatial_Analysis_in_R" FOLDER IS
      #Hint you can find the directory in file explorer and copy/paste 

#and then read in two types of geospatial data
elev <- raster("aster_image_20160624.tif") 
honduras_boundary <- st_read("Honduras_Border.shp")

#if no errors, then WHOOO HOOO! WE'RE DONE!
