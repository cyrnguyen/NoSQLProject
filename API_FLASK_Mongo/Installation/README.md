# __API Flask_Mongo on AWS EB__



## Déploiement d'une API Flask Mongo sur AWS Elastic Beanstalk

AWS Elastic Beanstalk est un service facile à utiliser pour déployer et dimensionner des applications et des services web développés avec Java, .NET, PHP, Node.js, Python, Ruby, Go et Docker sur des serveurs familiers comme Apache, Nginx, Passenger et IIS.

Il vous suffit de charger votre code, et Elastic Beanstalk effectue automatiquement les étapes du déploiement que sont le dimensionnement des capacités, l'équilibrage de la charge, le dimensionnement automatique et la surveillance de l'état de l'application.


### Installation :

#### En local :
Installation d'un environnement virtuel Python comprenant Flask et tous les packages nécessairesau code de l'API.

1. Créer un environnement virtuel :  
`~$ virtualenv eb-virt`

2. activer l'environnement :  
`~$ source activate eb-virt`  
`(eb-virt) ~$`

3. installer Flask, Flask_pymongo, et tout package nécessaire à l'API. Pour nous :  
`pip install flask`  
`pip install flask_pymongo`  
`pip install pandas`  
`pip install pycountry_convert`


4. ajouter le code de l'application Flask dans un dossier de projet:  
`mkdir eb-flask`  
`cd eb-flask`  
<Créé votre fichier d'application python ou le transférer dans ce dossier. Attention de bien nommer le fichier application.py>

5. exporter les variable d'environnement:  
`pip freeze > requirements.txt`  
`source deactivate`  


A présent dans le dossier eb-flask nous avons le fichier python de l'application flask et le fichier requirements.

#### Déploiement de l'Api dans Elastic Beanstlak (il faut avoir installer awsebcli pour gérer le déploiement d'EB en ligne de commande.

1. Initialiser le repository EB avec la version de python désirée :  
`eb init -p python2.7 flask-gdelt`

2. création de l'environnement et deploiement de l'application :  
`eb create flask-env`

3. Acceder à l'url de l'API Flask EB:  
`eb open`

4. Si besoin de modifier le code de l'api, redéployer l'application avec :  
`eb deploy`
