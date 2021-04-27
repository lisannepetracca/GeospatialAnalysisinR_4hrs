#install.packages(c("sp","sf","raster","rgbif","ggplot2", "viridis","ggspatial","rnaturalearth","rnaturalearthdata"))

library(sp)
library(sf)
library(raster)
library(rgbif)
library(ggplot2)
library(viridis)
library(ggspatial)
library(rnaturalearth)
library(rnaturalearthdata)

##DO NOT COPY PASTE ENTIRE LINE FOR 17 NEED 'wd<-' PRESERVED!!!
#Make sure working directory is also saved as object wd
setwd("C:/Users/acheesem/Desktop/ESF/Workshop Taught/Geospatial Analysis in R")#Change to your working directory path

################################################################
################################################################
##Downloading shapefiles from URL

#here we are going to grab elevation and New York Sate boundaries 
  #we are going to do this using loops to practice

#get URLS from internet for zip files
files<-("http://gis.ny.gov/gisdata/fileserver/?DSID=927&file=NYS_Civil_Boundaries.shp.zip")

#get directory to save files
dir<-paste(getwd(),"/ny",sep="")
dir

#this might take a few minutes to run
  download.file(files,dir) #download file from internet

#unzip  file
  unzip(dir) #unzip the folder corresponding to wd + particular root 

#read in NY boundary shapefile & elevation raster
NY<-st_read("NYS_Civil_Boundaries_SHP/Counties_Shoreline.shp")#this one is nested in another folder
#Plot NY shapefile and view
plot(st_geometry(NY)) 

#read in from file
#NY<-st_read("NYS_Civil_Boundaries_SHP/Counties_Shoreline.shp")#this one is nested in another folder
###########################################################
######################GBIF Exercise ###Map species

#establish search criteria - searching for family Canidae
  #many search criteria available check out the rgbif guide
key <- name_backbone(name = 'Canidae', rank='family')$usageKey

#run search and download 2000 records with coordinates -->
###Download takes a moment so skip to line 124 if uploading csv

Canidae<-occ_search(taxonKey=key,limit=2000,hasCoordinate = TRUE)#this takes a bit of time

#inspect Canidae -returns output summary
Canidae

#inspect slots in Canidae - we want data
names(Canidae)

#save data as csv in working directory
write.csv(Canidae$data,"Canidae_occ.csv")

#data is in tibble which is a modified data frame- lets change it to data frame to be consistent and store it in candat
can<-data.frame(Canidae$data)

#candat<-read.csv("Example_Canidae/Canidae_occ.csv") #OR JUST READ IN CSV

#look at data
summary(can)
names(can)
str(can)
#gbif data has too many columns, we want:
  #lat=decimalLatitude
  #long=decimalLongitude
  #species=species

#convert data frame to simple feature
candat<-st_as_sf(can, coords = c("decimalLongitude" ,"decimalLatitude"), crs = CRS("+proj=longlat +datum=WGS84"))

#lets look at the data colored by species
plot(st_geometry(candat),col=as.factor(candat$species),pch=16)

#Well that is not a great looking map, lets make better ones using ggplot 

#load global country boundaries shapefile
world <- ne_countries(scale = "medium", returnclass = "sf")

#Or read in directly
#world<-st_read("Part 6 Data/world.shp")


##plot the world
ggplot(data = world)+
  #plot continents
  geom_sf(color = "black", fill = "antiquewhite", size=0.5) +
  #add scale
  annotation_scale(
    pad_x = unit(0, "cm"),
    pad_y = unit(0.05, "cm"))+
  #add North arrow
  annotation_north_arrow(
    style = north_arrow_fancy_orienteering,
    height=unit(1.5, "cm"),
    width=unit(1.5, "cm"),
    pad_x = unit(0.25, "cm"),
    pad_y = unit(1.7, "cm"))+
  #add grid lines
  theme(panel.grid.major = element_line(color = gray(.5), 
        linetype = 'dashed', size = 0.5),
        panel.background = element_rect(fill = 'aliceblue'))+               
  #add title and axis labels
  ggtitle("Map of the World")+
  xlab("Longitude") +
  ylab("Latitude")+
  #define plotting bounds
  scale_x_continuous(limits = c(-150,150), breaks=(seq(-180,180,50)))+
  scale_y_continuous(limits = c(-65,75), breaks=(seq(-180,180,50)))+
  #ensures everything in matching CRS
  coord_sf()


#plot Canidae Richness
ggplot(data = world)+
              geom_sf(color = "black", fill = "antiquewhite", size=0.5) +
              #convert points to binned hexagons
              stat_summary_hex(
                    data=can,aes(
                      x=decimalLongitude,
                      y=decimalLatitude,
                      z=speciesKey),
                    fun=function(z){length(unique(z))},
                    binwidth=c(4,4))+
              #color by viridis color scale G
              scale_fill_viridis("Richness",option='G',begin=0.25,end=.85,alpha=0.9)+
              annotation_scale(
                    pad_x = unit(0, "cm"),
                    pad_y = unit(0.05, "cm"))+
              annotation_north_arrow(
                  style = north_arrow_fancy_orienteering,
                  height=unit(1.5, "cm"),width=unit(1.5, "cm"),
                  pad_x = unit(0.25, "cm"),
                  pad_y = unit(1.7, "cm"))+
              theme(panel.grid.major = element_line(color = gray(.5), 
                  linetype = 'dashed', size = 0.5),
                  panel.background = element_rect(fill = 'aliceblue'))+               
              ggtitle("Canidae species richness")+
              xlab("Longitude") +
              ylab("Latitude")+
              scale_x_continuous(limits = c(-150,150), breaks=(seq(-180,180,50)))+
              scale_y_continuous(limits = c(-65,75), breaks=(seq(-180,180,50)))+
              coord_sf()

  
  
#For US only and add labels

#make lables
  world_points <- cbind(world, st_coordinates(st_centroid(world$geometry)))
  #ignore error here but ideally convert projection to meters 
  
ggplot(data = world)+
    geom_sf(color = "black", fill = "antiquewhite", size=0.5) +
    stat_summary_hex(data=can,aes(x=decimalLongitude,y=decimalLatitude,z=speciesKey),
      fun=function(z){length(unique(z))},
      binwidth=c(2,2))+
    scale_fill_viridis("Richness",option='G',begin=0.25,end=.85,alpha=0.75)+
    annotation_scale(
      pad_x = unit(0, "cm"),
      pad_y = unit(0.05, "cm"))+
    annotation_north_arrow(
      style = north_arrow_fancy_orienteering,
      height=unit(1.5, "cm"),width=unit(1.5, "cm"),
      pad_x = unit(0.25, "cm"),
      pad_y = unit(1.7, "cm"))+
    theme(panel.grid.major =
        element_line(color = gray(.5), 
        linetype = 'dashed', size = 0.5),
      panel.background = element_rect(fill = 'aliceblue'))+
    #add text for labels
    geom_text(data= world_points,aes(x=X, y=Y, label=name), 
      color = "gray20", size=4,
      fontface = "italic", check_overlap = TRUE) +
    ggtitle("Canidae species richness")+
    xlab("Longitude") +
    ylab("Latitude")+
    # Change limits
    scale_x_continuous(limits = c(-130,-55), breaks=(seq(-180,180,25)))+
    scale_y_continuous(limits = c(20,50), breaks=(seq(-180,180,10)))+
    coord_sf()
  
 #look through the maps in pdfs or in RStudio
