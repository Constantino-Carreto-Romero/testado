############################################
#project name: Mapas con R (tmap)
#author: Constantino Carreto
#date: Jan 16, 2023

################# load libraries ####################

install.packages("readr") #load csv files
install.packages("tmap") #create maps
install.packages("dplyr") #manage databases
install.packages("rgdal") #load spatial objects
install.packages("sf") # manage spatial objects
install.packages("viridis") #colors
install.packages("RColorBrewer")  #colors

library(readr)
library(tmap)
library(dplyr)
library(rgdal)
library(sf)
library(viridis)
library(RColorBrewer)

################### directorios #####################
#directorios

project="C:/Users/tino_/Dropbox/PC/Documents/proyectos_R/"

data=paste0(project,"maps_with_R/data/")
figures=paste0(project,"maps_with_R/figures/")
shape_edos=paste0(project,"maps_with_R/shapefiles/shapefile_mx_estados/")

#################### cargar datos y shapefiles #####################

#tasa de desocupación
tasa<-read_csv(paste0(data,"tasa_desocupacion_yq_2005-2022.csv"))
head(tasa)
tasa1<-filter(tasa,fecha=="2022q3")
summary(tasa1$desocupacion)
head(tasa1)

#shapefile de entidades
edos <- readOGR(dsn=paste0(shape_edos, "marcogeoestatal2015_gw.shp"), layer="marcogeoestatal2015_gw", stringsAsFactors=F)
#a simple plot
plot(edos)

############## merge data and shapefiles #################

#transformar a sf objet, para que tmap puede reconocer y manejar el objecto espacial
class(edos)
edos_sf<-st_as_sf(edos)
class(edos_sf)
head(edos_sf)
View(edos_sf)
plot(edos_sf)
plot(edos_sf$geometry)
edos_sf$CVE_ENT<-as.numeric(edos_sf$CVE_ENT) #ventaja: los datos espaciales se pueden manipular como si fuese un dataframe
head(edos_sf)
edos_sf<-merge(edos_sf,tasa1,by.x="CVE_ENT",by.y="entidad")
head(edos_sf)


########## crear maps ############################

#limite de los estados
map1<-tm_shape(edos_sf)+
  tm_borders()
map1

#colorear en función de los valores una variable
map2<-tm_shape(edos_sf)+
  tm_fill(col="desocupacion")
map2

#limites+color
map3<-tm_shape(edos_sf)+
  tm_borders()+
  tm_fill(col="desocupacion")
map3

#diferente paleta de colores
map4<-tm_shape(edos_sf)+
  tm_borders()+ 
  tm_fill(col="desocupacion",palette = "YlGnBu")#brewer: https://r-graph-gallery.com/38-rcolorbrewers-palettes.html
map4

#diferente paleta de colores
map5<-tm_shape(edos_sf)+
  tm_borders()+ 
  tm_fill(col="desocupacion",palette = "magma")#viridis: https://cran.r-project.org/web/packages/viridis/vignettes/intro-to-viridis.html
map5

#revertir paletta de colores
map6<-tm_shape(edos_sf)+
  tm_borders()+ 
  tm_fill(col="desocupacion",palette = "seq")+
  tm_layout(aes.palette = list(seq = "-magma"))
map6

#cambiar rangos de color
map6<-tm_shape(edos_sf)+
  tm_borders()+ 
  tm_fill(col="desocupacion",palette = "seq", breaks = c(0,3,6))+
  tm_layout(aes.palette = list(seq = "-magma"))
map6

#mayor grosor de borders
map7<-tm_shape(edos_sf)+
  tm_borders(lwd=3)+ 
  tm_fill(col="desocupacion")
map7

#mayor transparencia
map8<-tm_shape(edos_sf)+
  tm_borders()+ 
  tm_fill(col="desocupacion",alpha=0.5)
map8

#resaltar algunos estados (sobreponer capas)
map9<-tm_shape(edos_sf)+
  tm_borders()+ 
  tm_fill(col="desocupacion")+
  tm_shape(edos_sf[edos_sf$CVE_ENT %in% c(2,5,8,19,26,28),])+
  tm_borders(lwd=3)
map9

#posicion de leyenda
map10<-tm_shape(edos_sf)+
  tm_borders()+ 
  tm_fill(col="desocupacion")+
  tm_shape(edos_sf[edos_sf$CVE_ENT %in% c(2,5,8,19,26,28),])+
  tm_borders(lwd=3)+
  tm_layout(legend.title.size = 1,
            legend.text.size = 0.6,
            legend.position = c("left","bottom"))
map10

#titulo, remover cuadro
map11<-tm_shape(edos_sf)+
  tm_borders()+ 
  tm_fill(col="desocupacion")+
  tm_layout(legend.position = c("left", "bottom"), 
            main.title= 'Tasa de desocupación por estado',
            frame = FALSE)
map11

#guardar mapa
tmap_save(filename=paste0(figures, "tasa de desocupacion.png"))

