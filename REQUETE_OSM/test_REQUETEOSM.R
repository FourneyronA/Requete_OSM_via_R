
### 0 - Librairies utiles ====
# install.packages("rjson")

library(rjson)
library(tidyverse)
library(sp) # classes et methodes pour donnees spatiales pe dlasspar SF
library(rgdal) #gdal pour projection, crud et surtout export
library(sf) # nouveau package de classes et methodes spatiales doit "remplacer" rgdal et rgeos (et ofc sp)
library(tmap) # carto

### 1 - fonctions requetage ====
#### gestion des points nodes
OverpassJsonToDataframe <- function(jsonstring) {
  myDF <- data.frame(type = "", id = "", lat = "", lon = "", stringsAsFactors = FALSE)
  myDF <- myDF[-1, ]
  for (node in jsonstring$elements) {
    if (node$type == 'node'){
      myDF[nrow(myDF) + 1, ] <- c(node$type, node$id, node$lat, node$lon)
    }
  }
  myDF$lat <- as.numeric(myDF$lat)
  myDF$lon <- as.numeric(myDF$lon)
  return(myDF)
}

#### gestion des lignes way
OverpassJsonLineToDataframe <- function(jsonstring) {

  myDF <- data.frame(type = "", id_route = "", nodes = "", maxspeed = "", highway = "", stringsAsFactors = FALSE)
  myDF <- myDF[-1, ]

  for (way in jsonstring$elements) {

    if (way$type == 'way'){

      type <- way$type
      id <- way$id
      noeux <- way$nodes
      vitesse <- way$tags$maxspeed
      nature <- way$tags$highway

      print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")


      if(is.null(vitesse) | is.null(id) | is.null(nature) | is.null(noeux)){

        print(paste("Type = ",type))
        print(paste("id = ",id))
        print(paste("nodes = ",noeux))
        print(paste("vitesse = ",vitesse))
        print(paste("nature = ",nature))
        if(is.null(vitesse)){
          vitesse <- "Unknow"
        }

      }

      DF.tempo <- data.frame(type = type,
                             id_route = id,
                             nodes = noeux,
                             maxspeed = vitesse,
                             highway = nature, stringsAsFactors = FALSE)


      myDF <- myDF %>%
        rbind(DF.tempo)

      #print(DF.tempo)



    }

  }

  myDF$nodes <- as.character(myDF$nodes)


  return(myDF)

}

#### assemblage aux formats SF
donnee_overpass <- function(requete, emprise){

  # supression des connexions/requetes en memoire
  lapply(dbListConnections(drv = dbDriver("PostgreSQL")),
         function(x) {dbDisconnect(conn = x)})

  #preparation de la requete
  myQuery <- paste("way",requete,emprise,";  out body;  >;out skel qt;", sep="")
  myJSONQuery <- paste("[out:json];", myQuery, sep = "")
  myURL <- paste("http://overpass-api.de/api/interpreter?data=", myJSONQuery,
                 sep = "")
  # envoie de la requete et récuperation du resultat
  myJSON <- fromJSON(file = myURL)

  # extraction des routes "way"
  dfRoute <-  OverpassJsonLineToDataframe(myJSON)
  # extraction des points de coordonnees des "nodes" qui composes les "way"
  NODES <- OverpassJsonToDataframe(myJSON)

  # création du fichier des géométry final
  dfRoute_GEOM <- dfRoute %>%
    inner_join(NODES, by = c("nodes" = "id"))%>% # jointures des coordonner LAT et LON des nodes
    st_as_sf(coords = c("lon", "lat"), crs = CRS("+init=epsg:4326")) %>% # mise sous forme d'objet geometry
    group_by(id_route,maxspeed,highway ) %>% #groupement par id de la route
    summarise(nb_point = n(), # somme du nombre de nodes
              #geometry = st_union(geometry),
              do_union = FALSE)%>% # unions des points
    st_cast("LINESTRING")

  # renvoie du resultat
  return(dfRoute_GEOM)
}

### 2 - Lancer une requete ====

#### preparation des fichiers
chemin_dossier = "C:/Users/afn/Desktop/"
setwd(dir =paste(chemin_dossier,"REQUETE_OSM", sep = ""))

requete <- "[highway~\"(motorway_link|trunk_link|primary_link|secondary_link|tertiary_link)\"]"

# Requete route :  "[highway~\"(motorway|trunk|primary|secondary)\"]"
# Requete route liaison : [highway~\"(motorway_link|trunk_link|primary_link|secondary_link|tertiary_link)\"]


## 2.1 - Ensemble de la région ====

TAB_SF <- NULL
quadri <- st_read("SHP_REG/quadri_region2.shp")
for (i in 1:nrow(quadri)) {
#   print(i)
#   st_bbox(quadri[1,])
# as.numeric(st_bbox(quadri[1,])[1])
emprise <- paste("(",as.numeric(st_bbox(quadri[i,])[2]),",",
                 as.numeric(st_bbox(quadri[i,])[1]),",",
                 as.numeric(st_bbox(quadri[i,])[4]),",",
                 as.numeric(st_bbox(quadri[i,])[3]),")", sep = "" )


TAB_SF <- TAB_SF %>%
  rbind(donnee_overpass(requete, emprise))
}

### 2.2 - Emprise ciblé ====

# selection d'une emprise à la main /!\ ATTENTION /!\ la zone choisie ne doit pas être trop importante
emprise <- "(47.207248190922016,-1.5891551971435547,47.23967621202853,-1.5500679016113281)"

# Selection d'un carrée en particulier
# quadri_select <- filter(quadri, id == 855 )
# emprise_select <- paste("(",as.numeric(st_bbox(quadri_select)[2]),",",
#                  as.numeric(st_bbox(quadri_select)[1]),",",
#                  as.numeric(st_bbox(quadri_select)[4]),",",
#                  as.numeric(st_bbox(quadri_select)[3]),")", sep = "" )

TAB_SF_SELECT <- donnee_overpass(requete, emprise)

#### 3 - Affichage ====
 tmap_mode("view") +
  tm_basemap(server = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png') +
    tm_shape(TAB_SF_SELECT)+
    tm_lines( col = "highway")


#### 4 - Enregister le resultat au format SHP ====
 Nom_fichier <-"route_region"

TAB_SF %>%
 mutate(id_route = row_number()) %>% # remplacement de l'id OSM par news ID (plus court pour l'enregistrer aux format SHP)
 st_write( paste("RESULTAT/",Nom_fichier,".shp",sep="")) # enregistrement du fichier

