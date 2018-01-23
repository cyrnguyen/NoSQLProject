# Visualisation des données (D3js)
Source : http://bl.ocks.org/tomschulze/961d57bd1bbd2a9ef993f2e8645cb8d2#index.html

## Inventaire :  
`index_form.html` : formulaire de sélection des dates de début et de fin de période d'analyse.  
`index.html` : graphique _D3js_.  
`functions.js` : librairie de fonctions _javascript_.  
`world.json` : référentiel de coordonnées des pays du monde.  

## Mode d'emploi :  
`WARNING` : Installer et **activer** dans le navigateur web un module complémentaire permettant d'outrepasser les restrictions CORS de type "*L’en-tête CORS « Access-Control-Allow-Origin » est manquant*".  
  > Mozilla Firefox :
    > Outils  
      > Modules complémentaires  
        > Extensions
          > Rechercher : **CORS Everywhere**  
1. Ouvrir le fichier `index_form.html` dans un navigateur web.
2. Renseigner les champs du formulaire par des dates au format `YYYYMMDD`.
3. Curseur dynamique de l'axe temporel.  

/!\ Désactiver le module en fin de traitement.
