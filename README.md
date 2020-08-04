# Requete_OSM_via_R
Script qui permet d'automatiser l'extraction des données OSM via trubopass pour les analyser, comparer, enregistrer via les données géographiques dans le logiciel R 

## Structuration des fichiers 
Vous pouvez directement télécharger le dossier REQUETE_OSM
à l'intérieur se situe :

* Dossier Resultat : où seront enregistrer si souhaitez le fichier SHP des données OSM extrait
* Dossier SHP_REG : fichier SHP, contenant les différentes zones à extraire les données
* le script R : qui permet de lancer les requêtes sur OSM

## Structuration du script
Le fonctionnement script est fragmenté en plusieurs parties :

* 0 - Chargement des librairies 
* 1 - Chargement des fonctions
* 2 - Lancer la requête
* 3 - Visualiser les données 
* 4 - Enregistrer les données 

***

### /!\ Attention /!\

Certaine variable son a changer, tel que : 
* *chemin_dossier* : qui doit indiquer l'emplacement du dossier REQUETE_OSM
* *requete* : la requete turbopass pour extraire OSM.

***

Enfin vous pouvez lancer une requête de deux façons : 
#### 2.1 - ensemble de la région 

Cette méthode permet de lancer une requête sur chaque géométrie du fichier SHP et d'assembler le resultat sous un seule fichier,
ainsi si seras plus facile d'extaire un ensemble de donnée sur une zone géographique importantes.
De base le fichier inclue permet d'obtenir l'ensemble de la région Pays de la Loire.

#### 2.2 - Emprise ciblé 

Cette méthodes, souvent plus rapide vous permet en indiquant latitudes et longitudes (min et max) de selectionner votre zone, de cette façon une seule requête est envoyé.
cependant attention si la zone est trop importante il est possible que la requête ne puisse pas aboutir dans ce cas, il faudras découper votre zone en plusieurs partie et se référer à la méthodes 1



*******

Good luck et je reste disponible en cas de question ;)


