#install.packages(c("sf","raster","ggplot2", "viridis","ggspatial"))

#let's set our working directory first
setwd("C:/Users/acheesem/Desktop/ESF/Workshop Taught/GIS in R workshop")#Change to your working directory path

#and let's load all the libraries we need
library(sf)
library(ggplot2)
library(raster)
library(viridis)
library(ggspatial)

# ---- LET'S HAVE SOME FUN WITH MAPPING! ----

# ---- VECTOR ONLY ----

#we will return to our Zimbabwe data for the vector mapping
#first, let's read in our shapefile of Hwange NP (polygon)
HwangeNP <- st_read("Example_Zimbabwe/Hwange_NP.shp")
#then our roads (line)
roads <- st_read("Example_Zimbabwe/ZWE_roads.shp")
#then our waterholes (point)
waterholes <- st_read("Example_Zimbabwe/waterholes.shp")

#do the coordinate systems match? let's see
crs(HwangeNP)
crs(roads)
crs(waterholes)

#roads do not match. let's project roads to WGS 1984 UTM Zone 35S to match the others
roads <- st_transform(roads, crs = 32735)

#and now let's select the roads that intersect Hwange NP
roads_isect <- roads[HwangeNP,]

#and now let's plot what we have
ggplot() +
  geom_sf(data = HwangeNP, color = "darkgreen", fill = "white", size=2) +
  geom_sf(data=roads_isect, color = "black", size=1)+
  geom_sf(data=waterholes, color= "blue", size=3)+
  ggtitle("Roads and Waterholes in Hwange NP", subtitle = "2020")+
  coord_sf()

#let's add a legend object, with "TYPE" of waterhole in the legend
#how can we see unique values of "waterhole type?
unique(waterholes$TYPE)

#we are making two small changes here
#the "aes" argument tells ggplot to apply a different color to each value of waterhole TYPE
#"labs" in this case gives a title to the legend
ggplot() +
  geom_sf(data = HwangeNP, color = "darkgreen", fill = "white", size=2) +
  geom_sf(data=waterholes, aes(color=factor(TYPE)), size=3)+
  labs(color = 'Waterhole type')+
  ggtitle("Waterhole types in Hwange NP", subtitle = "2020")
  

#what if we don't like these colors? how can we change them?
#can see color options here: http://www.stat.columbia.edu/~tzheng/files/Rcolor.pdf
waterhole_colors <- c("purple", "orange", "deepskyblue3")

#now we basically need to tell ggplot to use these colors with "scale_color_manual"
ggplot() +
  geom_sf(data = HwangeNP, color = "darkgreen", fill = "white", size=2) +
  geom_sf(data=roads_isect, color = "black", size=1)+
  geom_sf(data=waterholes, aes(color=factor(TYPE)), size=3)+
  scale_color_manual(values=waterhole_colors)+
  labs(color = 'Waterhole type')+
  ggtitle("Waterhole types in Hwange NP", subtitle = "2020")+
  coord_sf()

#we can change other aspects of the legend using theme()
ggplot() +
  geom_sf(data = HwangeNP, color = "darkgreen", fill = "white", size=2) +
  geom_sf(data=roads_isect, color = "black", size=1)+
  geom_sf(data=waterholes, aes(color=factor(TYPE)), size=3)+
  scale_color_manual(values=waterhole_colors)+
  labs(color = 'Waterhole type')+
  ggtitle("Waterhole Types in Hwange NP")+
  theme(plot.title = element_text(size=20), #this changes size of plot title
        legend.position="bottom", #changes legend position
        legend.title=element_text(size=16), #changes size of legend title
        legend.text = element_text(size = 16), #changes size of element text in legend
        legend.box.background = element_rect(size = 1)) + #adds a legend box of width 1
  coord_sf()

#ok, so that's great for plotting a single shapefile
#what if we are interested in plotting multiple shapefiles?

#let's go back to our original map with the polygon, lines, and points
ggplot() +
  geom_sf(data = HwangeNP, color = "darkgreen", fill = "white", size=2) +
  geom_sf(data=roads_isect, color = "black", size=1)+
  geom_sf(data=waterholes, color= "blue", size=3)+
  ggtitle("Roads and Waterholes in Hwange NP", subtitle = "2020")+
  coord_sf()

#and let's say we want to have waterhole type AND roads in the legend
#each vector needs an aes & scale argument
ggplot() +
  geom_sf(data = HwangeNP, color = "darkgreen", fill = "white", size=2) +
  geom_sf(data=roads_isect, aes(fill = F_CODE_DES), size=1)+
  geom_sf(data=waterholes, aes(color=factor(TYPE)), size=3)+
  scale_color_manual(values = waterhole_colors, name = "Waterhole type") +
  scale_fill_manual(values = "black", name = "")+
  ggtitle("Roads and Waterholes in Hwange NP", subtitle = "2020")+
  coord_sf()

#Let's make the waterholes diamonds instead of circles
#see https://ggplot2.tidyverse.org/articles/ggplot2-specs.html for a lot of ggplot aesthetics

#### ---- INCLUDING RASTER DATA ----####

#let's return to plotting elevation in Hwange NP
#let's read in that cropped elevation file we already made

elev <- raster("Example_Zimbabwe/elev_Hwange.tif")

#and let's see it quickly using the plot function in raster
plot(elev)

#to plot a raster in ggplot, remember that we need to convert it to a data frame first
elev_df <- as.data.frame(elev, xy=TRUE)
#see what the data frame looks like
head(elev_df)   #IT IS OK THAT THERE ARE NAs

#now we can get started

#man, we have NA values. where are they? 
#we can use "na.value = "color"" to show where those pixels are
ggplot() +
  geom_raster(data = elev_df  , aes(x = x, y = y,fill=elev_df[,3])) +
  scale_fill_viridis_c(na.value = 'red') 

#ok, they are some border cells
#can use trim() argument in raster package to get rid of these cells, but we're ok for now
#trim gets rid of NAs in the outer rows and columns 

#one trick of getting around NAs is removing those rows where the raster value is NA
#otherwise NA will show up in the legend & this is annoying
elev_df <- elev_df[!is.na(elev_df[,3]), ]

ggplot() +
  geom_raster(data = elev_df_fourgroups_noNA, aes(x = x, y = y, fill = elev_df[,3]))+
  scale_fill_viridis_c(na.value = 'red') 


#we are using the viridis color palette for the continuous surface
ggplot() +
  geom_raster(data = elev_df, aes(x = x, y = y, fill=elev_df[,3])) +
  scale_fill_viridis_c(option="H") 

#and how would we change some aesthetics?
#let's change legend name
#move legend theme to bottom
#adjust size of legend name and labels
ggplot() +
  geom_raster(data = elev_df, aes(x = x, y = y, fill=elev_df[,3])) +
  scale_fill_viridis_c(option="H",name = "Elevation (m)") +
  theme(axis.title = element_blank(),
        legend.position = "bottom",
        legend.title=element_text(size=12),
        legend.text = element_text(size = 10), 
        legend.box.background = element_rect(size = 1))

#now let's place the elevation raster in a map with Hwange NP and waterholes
#order matters!
#layers that should be on the bottom go first
#notice that the fill for Hwange is now "NA" so we can see underlying elevation
ggplot() +
  geom_raster(data = elev_df, aes(x = x, y = y, fill=elev_df[,3])) +
  #add Hwange
  geom_sf(data = HwangeNP, color = "black", fill = NA, size=2) +
  #add waterholes
  geom_sf(data=waterholes, aes(color=factor(TYPE)), size=3)+
  scale_fill_viridis_c(option='H',name = "Elevation (m)")+
  scale_color_manual(values = waterhole_colors, name = "Waterhole type") +
  coord_sf()


#Okay lets make it look a bit nicer by adding lat and long lines
#and making the elevation colors a bit less intense
#and giving gg plot a nicer looking theme to work off of
ggplot() +
  geom_raster(data = elev_df, aes(x = x, y = y, fill=elev_df[,3])) +
  geom_sf(data = HwangeNP, color = "black", fill = NA, size=2) +
  geom_sf(data=waterholes, aes(color=factor(TYPE)), size=3)+
  #lets make the backgorund a bit less bright by changing the alpha values
    scale_fill_viridis_c(option='H',name = "Elevation (m)",alpha=0.7)+
  scale_color_manual(values = waterhole_colors, name = "Waterhole type") +
  #ggplot has a number of standard themes - I like theme_bw as a template
  #see https://ggplot2.tidyverse.org/reference/ggtheme.html for full list of themes
  theme_bw()+
  #add grid lines for lat and long 
  theme(
        #lets add grid lines!!
        panel.grid.major =
        element_line(color = gray(.5), 
        linetype = 'dashed', size = 0.5))+
  coord_sf()

#And the last thing wee need is a north arrow and a scale bar to make our map official 
ggplot() +
  geom_raster(data = elev_df, aes(x = x, y = y, fill=elev_df[,3])) +
  geom_sf(data = HwangeNP, color = "black", fill = NA, size=2) +
  geom_sf(data=waterholes, aes(color=factor(TYPE)), size=3)+
  scale_fill_viridis_c(option='H',name = "Elevation (m)",alpha=0.7)+
  scale_color_manual(values = waterhole_colors, name = "Waterhole type") +
  #Let's add the scale bar
  annotation_scale(
    height=unit(.5,"cm"),
    pad_x = unit(1, "cm"),
    pad_y = unit(0.7, "cm"))+
  #Let's add the North arrow
  annotation_north_arrow(
    height=unit(1.5, "cm"),
    width=unit(1.25, "cm"),
    pad_x = unit(9.5, "cm"),
    pad_y = unit(8, "cm"))+
  theme_bw()+
  theme(
        panel.grid.major =
          element_line(color = gray(.5), 
                       linetype = 'dashed', size = 0.5))+
  coord_sf()
#wowzers! that is one excellent-looking map

