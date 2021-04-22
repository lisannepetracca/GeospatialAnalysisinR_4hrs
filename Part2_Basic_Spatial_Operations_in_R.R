#install.packages(c("sp", "sf", "raster"))
library(sp)
library(sf)
library(raster)
setwd("C:/Users/acheesem/Desktop/ESF/Workshop Taught/GIS in R workshop")#Change to your working directory path

###CAN WORK WITH SPATIAL DATA AS DATA FRAME 
##create unprojected spatial data 
  #NO PROJECTION - NOT GOOD
data<-data.frame(long=c(-76.13332,-76.86515,-76.851651), # c() concatenates values separated by commas 
                 lat=c(42.85632,42.65465,42.51311))
data#Inspect to see what data looks like

#plot spatial data
plot(data)

#########################################################################
##### SPATIAL DATA TYPES SP, SF AND RASTER

##Create projected spatial data with sp
#define coordinate system using EPSG code
crdref <- crs("+init=epsg:4326")
#inspect the CRS
crdref

#create spatial points class object names pts from data
pts <- SpatialPoints(cbind(data$long,data$lat), proj4string=crdref)

#inspect pts
pts
plot(pts)

##Create spatialpointsdataframe
#Create attributes corresponding to the row from data 
  #(alternitively you would pull from your database/csv etc.)
  # here creating sites pond, river, and forest, and ID for each row in data
att<-data.frame(site=c("Pond","River","Forest"),ID=1:nrow(data))
#look at att
att

#use SpatialPointsDataFrame() function to add attributes to points
#how do we do this?
?SpatialPointsDataFrame# use the ? before a function to see which arguments are needed and their format!! 
#really great for determining if sp or sf objects are required
spdf<-SpatialPointsDataFrame(pts,data=att,proj4string = crdref)


#look at spdf
spdf
#plot(spdf)

#write spdf to a shapefile using function shapefile () in the raster package
shapefile(spdf,"myshapefile.shp",overwrite=T)

#read in myshapefile using the shapefile() function in the raster package
shp<-shapefile("myshapefile.shp")

#Inspect and check loaded shapefile
class(shp)#look at class
head(shp)#look at data
str(shp)#look at structure
crs(shp)#look at coordinate reference system - note can be saved to object & applied to other datasets
plot(shp)#plot shapefile


##Convert the shp to data frame
geo_data<-data.frame(shp)

#look at geo_data
geo_data

### create spatial class using sf package and geo_data
?st_as_sf # see what arguments are required for st_as_sf
sf.pts<-st_as_sf(geo_data, coords = c("coords.x1", "coords.x2"), crs = crs(shp))

#inspect
sf.pts


#alternatively we could convert directly from sp object
st_as_sf(shp)

#read .shp with as sf using st_read() function
nc <- st_read("myshapefile.shp")

#write  sf to .shp with st_write() function
st_write(nc, "myshapefile.shp", append=F)



#####Raster package
#create raster - define columns, rows, and crs 
?raster #see what argumnets are required to make a raster
r <- raster(ncol=13, nrow=10,crs=crs(shp))

#assign values to raster
values(r) <- c(rep(0,16),1,rep(0,5),1,rep(0,7),1,0,0,
               0,1,rep(0,7),rep(1,7),0,0,0,0,0,1,1,0,1,1,1,0,1,1,0,0,0,rep(1,11),
               0,0,1,0,rep(1,7),0,1,0,0,1,0,1,rep(0,5),1,0,1,0,0,0,0,0,1,1,0,
               1,1,rep(0,17))
#inspect raster
r

#plot raster
plot(r,col=c("black","green"))

#save raster to file
writeRaster(r,"myraster.tif",overwrite=T)

#load raster from file
r2 <- raster("myraster.tif")

#plot raster to inspect
plot(r2,col=c("black","purple"))

