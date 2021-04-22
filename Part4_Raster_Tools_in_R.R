# ---- RASTER TOOLS IN R ----

#let's set our working directory first
setwd("C:/Users/lspetrac/Desktop/Geospatial_Analysis_in_R")

#let's load all the libraries we need
library(sf)
library(sp)
library(ggplot2)
library(dplyr)
library(raster)
library(rgeos)


# ---- EXAMPLE: HWANGE NATIONAL PARK, ZIMBABWE ----

#first, let's read in our shapefile of Hwange NP
Hwange <- st_read("Example_Zimbabwe/Hwange_NP.shp")
#and do a simple plot
plot(Hwange[c("NAME")])
#or
plot(Hwange[1])

#create random points
#let's create 1000 random points within the PA for vegetation sampling
Hwange_pts <- st_sample(Hwange, 1000, type="random")

#what does this look like?
ggplot() +
  geom_sf(data = Hwange, color = "darkgreen", size=1.5) +
  geom_sf(data=Hwange_pts, color = "black", size=2)+
  ggtitle("1000 Random Points in Hwange NP")

#now let's bring in our waterholes and roads (again using package sf)

roads <- st_read("Example_Zimbabwe/ZWE_roads.shp")
waterholes <- st_read("Example_Zimbabwe/waterholes.shp")

#let's plot those vectors within Hwange
ggplot() +
  geom_sf(data = Hwange, color = "darkgreen", size=1.5) +
  geom_sf(data=roads, color = "black", size=1)+
  geom_sf(data=waterholes, color= "blue", size=3)+
  ggtitle("Roads and Waterholes in Hwange NP")

#checking the coordinate systems reveals our "roads" layer is WGS 1984. 
crs(roads)
#How can we convert to WGS 1984 UTM Zone 35S?
roads_UTM <- st_transform(roads, crs = 32735)

#now let's read in the elevation (it's an aster image)
elev <- raster("Example_Zimbabwe/aster_image_20160624.tif") 

#how can we get an overview of the imported raster?
elev

#this is great, but can we get more stats beyond min/max?
#how can we get, say, quartiles of the data?
#turns out it's the same for any vector or data frame column in R
summary(elev)    #WARNING MESSAGE IS OK

#if you want it to use ALL the values in the dataset, use
summary(elev, maxsamp = ncell(elev))
#not much of a difference, eh? may notice larger changes w bigger rasters

#what if we want the mean of the whole raster?
#cellStats can also be used on a raster stack (something we will cover later)
#in that case, will produce a vector where each value is associated with a raster from the stack
(mean <- cellStats(elev, mean))

#here is a relatively fast, simple means of plotting a raster
plot(elev)

#what is the coordinate system? 
crs(elev)
#it's WGS84

#let's add Hwange to the elevation tile (Hwange border needs to be converted to WGS84 first)
#normally I like projecting layers to the same projected coordinate system (esp when working with distances
#and/or areas), but in this instance I will convert the Hwange boundary to WGS because it is faster
#and we are just doing a quick visualization
Hwange_WGS <- st_transform(Hwange, crs=4326)
plot(Hwange_WGS[1], add=T)

#ok, so there is a lot of extra raster that we don't want to work with
#let's crop it to make raster processing a bit faster
elev_crop <- crop(elev, Hwange_WGS)

#let's see what it looks like now!
#we will plot with the Hwange boundary in WGS 84
plot(elev_crop)
plot(Hwange_WGS[1], border="black",col=NA,lwd=2,add=T)

#what's the coordinate system of the elevation raster again?
crs(elev_crop)
#it's WGS 84

#now that the raster is of smaller size, we can convert this to a projected coordinate system
#to match the vector data
#let's project using projectRaster
#we need to present our crs in a slightly different way than we're used to in package sf

#goes really fast! this resolution will match our resolution for percent veg cover
elev_crop_UTM <- projectRaster(elev_crop, res=250, crs="+init=epsg:32735")

#let's make sure it looks ok with our Hwange shapefile in UTM coordinates
plot(elev_crop_UTM)
plot(Hwange[1], border="black",col=NA, lwd=2,add=T)
#ok, we are good!

#we are going to write this raster to file so we can use it later
#set the GeoTIFF tag for NoDataValue to -9999, the National Ecological Observatory Network’s (NEON) standard NoDataValue
writeRaster(elev_crop_UTM, "Example_Zimbabwe/elev_Hwange.tif", format="GTiff", overwrite=T, NAflag=-9999)

#let's read in percent vegetation now
percveg <- raster("Example_Zimbabwe/PercVegCover_2016.tif")
crs(percveg)

plot(percveg)
#ok, this plot is weird bc we are seeing values >100, which represent various forms of NA

#let's set all values >100 to NA and plot it
percveg[percveg > 100] <- NA
plot(percveg)

#let's see what it looks like with Hwange NP
plot(Hwange[1], border="black",col=NA, lwd=2,add=T)

#let's crop it to Hwange NP
veg_crop <- crop(percveg, Hwange)

#let's see what it looks like now!
plot(veg_crop)
plot(Hwange[1], border="black",col=NA,lwd=2,add=T)

#let's try to make a raster stack of vegetation and elevation
stack <- stack(veg_crop, elev_crop_UTM)
#ERROR ab different extents!
#let's check out the extents of each

extent(veg_crop)
extent(elev_crop_UTM)

#the extents are slightly different here, even though they are the same resolution
#this could be from pixels having a different lower left origin, for instance
#we will need to realign extents here through the resample tool
elev <- resample(elev_crop_UTM, veg_crop, method="bilinear")
stack <- stack(veg_crop, elev)
#yay, it works now!

#let's move on to getting distances from roads and waterholes
#first, let's clip roads to hwange extent
roads_hwange <- st_intersection(roads_UTM, Hwange)
#IGNORE WARNING
#let's plot the roads
plot(roads_hwange[1])

#for distance to linear features (roads), let's use rgeos package and its gDistance function
#the steps may seem convoluted, but they get the job done
#first, we create empty raster of a certain resolution & extent such that we can *eventually* store our distances there
dist_road <-  raster(extent(veg_reclass), res=250, crs="+init=epsg:32735")
#need to make roads a spatial object in package sp
roads_sp <- as(roads_hwange,"Spatial")
#let's see what they look like
plot(roads_sp)
#now we'll use gDistance to calculate the distance between the given geometries
#here, it is taking the distance from each road to all the pixels in the extent
#takes ~ 1 min+
distroad_matrix <- gDistance(as(dist_road,"SpatialPoints"), roads_sp,  byid=T)
#IGNORE WARNING - the layers have the same proj4 strings
#with these dimensions, we can see that each raster cell has a distance value to each of the 107 road features
#each row is a road, and each column is a distance to each of the 432165 raster cells
dim(distroad_matrix) 
#but we *really* only want the minimum distance from each raster cell to the nearest road
#so we will take the minimum across columns
distroad_min <-  apply(distroad_matrix,2,min)
#now we give these distances to the empty road matrix (woof! we're nearly done!)
dist_road[] <- distroad_min
#we're done! let's plot the output
plot(dist_road)
plot(roads_hwange[1], col="black",lwd=2,add=T)

#now let's calculate distance from points in package raster
#creating another empty raster
s <- raster(extent(veg_reclass), res=250, crs="+init=epsg:32735")
#calculating distance from points (waterholes) using "distanceFromPoints" function
dist_waterhole <- distanceFromPoints(s, st_coordinates(waterholes))
#plotting the output
plot(dist_waterhole)
plot(waterholes[1], col="black",lwd=2,add=T)

#let's write this to raster to we can use it later
writeRaster(dist_waterhole, "Dist_Waterhole_Hwange.tif", overwrite=T)

#now we are able to make a raster stack of all four rasters! 
stack <- stack(veg_crop, elev, dist_road, dist_waterhole )
#what does the stack look like?
stack
#names are ambiguous. let's assign names
names(stack) <- c("perc_veg", "elev", "dist_road", "dist_waterhole")
stack

#cool. now we will use the "extract" tool to extract values for each of our 1000 random points
#from each of our four raster layers

#first, we need to convert to a Spatial* object (a "SpatialPoints" class for package sp)
Hwange_pts_sp <- as(Hwange_pts,"Spatial")

#then we extract values -- this step goes *so* super fast
#there are a number of arguments that one can make w this function; we are keeping it simple
#df=T just means we are returning the output as a data frame (otherwise will return a list)
#a note that this doesn't have to be used with just points; can be used with polygons (e.g. buffers) too - in that case,
#extract() will extract all of the pixels within those polygons
#you may want to add a "FUN = mean" or some other operation to summarize the pixel values for each polygon
values <- extract(stack, Hwange_pts_sp, df=T)
#let's write this to .csv!
write.csv(values, "extracted_raster_values.csv")

#how can we save a single raster layer?
#set the GeoTIFF tag for NoDataValue to -9999, the National Ecological Observatory Network’s (NEON) standard NoDataValue
writeRaster(elev, "elevation.tif", format="GTiff", overwrite=T, NAflag=-9999)

#how can we save a raster stack?
writeRaster(stack, "raster_stack.tif", options="INTERLEAVE=BAND", overwrite=TRUE)
#THEN, in order to re-import the stack and use the individual raster layers, you can use
stack_import<- stack("raster_stack.tif")
elev <- subset(stack_import,subset=2)
plot(elev)