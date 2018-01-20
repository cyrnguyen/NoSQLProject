## Objectif général

* Proposer un système de stockage distribué et tolérant aux pannes fonctionnant sur AWS pour les données GDELT v2.0 (*Global Database of Events, Language, and Tone*).

* Analyser ces données pour répondre à une problématique.

## Problématique

**Comment l’action du gouvernement américain est-elle perçue dans le monde en 2017 ?**

On se propose de répondre aux questions suivantes :

1.	Afficher la perception de l’action du gouvernement américain moyennée entre deux dates à l’échelle du monde

2.	Afficher l’évolution de la perception de l’action du gouvernement américain entre deux dates à l’échelle d’un pays

3.	Optionnel : afficher l’évolution de la localisation des mentions relatives à l’action du gouvernement américain à l’échelle du monde.

## Données

3 jeux de fichiers au format csv : [*Events*](http://data.gdeltproject.org/documentation/GDELT-Event_Codebook-V2.0.pdf), [*Mentions*](http://data.gdeltproject.org/documentation/GDELT-Event_Codebook-V2.0.pdf), [*Global Knowledge Graph*](http://data.gdeltproject.org/documentation/GDELT-Global_Knowledge_Graph_Codebook-V2.1.pdf). Les fichiers sont disponibles toutes les 15 minutes, du 1er janvier 2017 au 15 décembre 2017, soit environ 3.5 TB de données.

### Événements
La table *Events* contient les (nouveaux) événements détectés au cours du quart d'heure. Pour notre application, on conserve les champs suivants :
* **GlobalEventID** (entier).
* **Day** (entier/YYYYMMDD), date de l’événement.
* **Actor1Code** (string), e.g. "USAGOV", "GOV".
* **Actor1Name** (string), e.g. "PRESIDENT", "OBAMA", "ADMINISTRATION", "AUTHORITIES", "THE WHITE HOUSE".
* **Actor1Geo_CountryCode** (string), 2-character FIPS10-4 country code, e.g. "US".
* **Actor2Code** (string).
* **Actor2CountryCode** (string), 3-character CAMEO code, e.g. "USA".

### Mentions
La table *Mentions* contient les mentions aux événements dans les médias du monde. Pour notre application, on conserve les champs suivants :
* **GlobalEventID** (entier).
* **MentionTimeDate** (entier/YYYYMMDDHHMMSS), date de la mention (granularité 15 min).
* **MentionType** (string), 1 = WEB.
* **MentionSourceName** (string), nom du domaine émettant la mention si MentionType = 1.
* **MentionIdentifier** (string), URL si MentionType = 1.
* **MentionDocTone** (numeric), ton de l’article entre -100 (extrêmement négatif) et +100 (extrêmement positif).

### Domaines
On utilise une table annexe (non-GDELT), *Domains*, pour les informations relatives aux domaines. Elle contient les champs suivants :
* **DomainName** (string).
* **DomainCountryCode** (string), FIPS country code.

## Fonctions

### Opinion moyenne dans le monde

```
GetWorldWideAverageOpinion(DateStart, DateEnd)  
Returns: dict {DomainCountryCode: [NumberOfMentions, AvgDocTone]}  
Example: {"US": [510, 0.284], "FR": [20, 1.265], ...}
```

-	Filtrer les mentions (**MentionTimeDate** > DateStart & < DateEnd)
-	Filtrer les mentions qui correspondent à une action du gouvernement américain, i.e. les mentions d'événements tels que **Actor1Code** = USAGOV (nécessite jointure Events.**GlobalEventID** = Mentions.**GlobalEventID**)  
Autres possibilités de filtres :  
    - **Actor1Code** = GOV & **Actor1Geo_CountryCode** = US
    - **Actor1Code** = GOV & **Actor1Name** = PRESIDENT & **Actor1Geo_CountryCode** = US
-	Ajouter **DomainCountryCode** (nécessite jointure Mentions.**MentionSourceName** = Domains.**DomainName**)
-	Grouper les mentions par **DomainCountryCode**
-	Compter les mentions, moyenner leur **MentionDocTone** pour chaque **DomainCountryCode**.

### Évolution de la perception d'un pays
```
GetCountryMovingOpinion(CountryCode, DateStart, DateEnd)  
Returns: 3-column array [Date, NumberOfMentions, AvgDocTone]
```

-	Filtrer les mentions (**MentionTimeDate** > DateStart & < DateEnd)
-	Filtrer les mentions qui correspondent à une action du gouvernement américain, i.e. les mentions d'événements tels que **Actor1Code** = USAGOV (nécessite jointure Events.**GlobalEventID** = Mentions.**GlobalEventID**)
-	Ajouter **DomainCountryCode** (nécessite jointure Mentions.**MentionSourceName** = Domains.**DomainName**)
-	Filtrer les mentions (**DomainCountryCode** = CountryCode)
-	Faire glisser une fenêtre de 24 heures avec un pas de 12 heures : compter les mentions, moyenner leur **MentionDocTone**.

 
