# V.1 - Analyse et correction de la base de données
# 1-Chargement de la base…
CREATE TABLE livres (NL integer primary key auto_increment, editeur varchar(50),
NO integer not null, foreign key(NO) references oeuvres(NO) ) ENGINE InnoDB
# Error Code: 1824. Failed to open the referenced table 'oeuvres'
# 2-Correction de la base et explication :
/*- Comme la table livre contient une clé étrangère qui est NO alors j'ai inversé l'ordre
de création des tables (création de la table œuvres puis création de la table livre) ;
- Tout comme la table livre, la table emprunter contient une clé étrangère qui est NA
alors j'ai aussi inversé l'ordre de création des tables (création de la table adhérents
puis création de la table emprunter après)
3-Nombre de tuples de la table œuvres après le script de création des tables et des tuples :*/
SELECT (SELECT COUNT(*) FROM biblio.oeuvres)+
 (SELECT COUNT(*) FROM biblio.livres)+
 (SELECT COUNT(*) FROM biblio.adherents)+
 (SELECT COUNT(*) FROM biblio.emprunter)
AS 'Nb Total de Tuples';

# V.2 - Interactions avec la base de données
# 9. Livres actuellement empruntés :
SELECT emprunter.NL, editeur, livres.NO
FROM biblio.emprunter, biblio.adherents, biblio.livres
WHERE dateRet IS NULL AND emprunter.NA = adherents.NA AND emprunter.NL=livres.NL;
# 10. Livres empruntés par Jeannette Lecoeur :
SELECT NL FROM biblio.emprunter, biblio.adherents
WHERE emprunter.NA = adherents.NA
AND adherents.prenom='Jeannette' AND adherents.nom='Lecoeur';
# 0 row(s) returned
/* Par contre, il y a un homonyme qui s’appelle ‘Jeanette Lecoeur’ qui affiche 4 emprunts
11. Tous les livres empruntés en septembre 2009 :*/
SELECT dateEmp FROM biblio.emprunter
WHERE year(dateEmp) =2009 AND month(dateEmp) = 9;
# 0 row(s) returned
# 12. Tous les adhérents qui ont emprunté un livre de Fedor Dostoievski :
SELECT adherents.NA, nom, prenom FROM biblio.adherents, biblio.emprunter
WHERE adherents.NA=emprunter.NA AND emprunter.NL IN (SELECT NL FROM oeuvres,
livres WHERE auteur='Fedor Dostoievski' AND oeuvres.NO=livres.NO);
# 13. Enregistrement du nouvel adhérent (Olivier DUPOND, 76, quai de la Loire, 75019 Paris, téléphone : 0102030405) :
INSERT INTO adherents VALUES
(31, 'Olivier','DUPOND','76, quai de la Loire, 75019 Paris','0102030405');
/* 14. Martine CROZIER vient d’emprunter « Au cœur des ténèbres » que vous venez d’ajouter et « Le
rouge et le noir » chez Hachette, livre n°23 ;
Mises à jour de la BD :
Trouver le NA de Martine CROZIER dans la base de données :*/
SELECT NA FROM adherents WHERE nom='CROZIER' AND prenom='Martine';
# Trouver le NL de “Au Coeur des Ténèbres” :
SELECT livres.NL, titre FROM livres, oeuvres WHERE titre='Au coeur des ténèbres'
AND livres.NO=oeuvres.NO;
# Insérer les données dans la table emprunter:
INSERT INTO emprunter VALUES
(31, '2022-06-28', 14, NULL, 7),
(23, '2022-06-28', 14, NULL, 7);
# 15. M. Cyril FREDERIC ramène les livres qu’il a empruntés. Mise à jour de la BD :
 UPDATE emprunter SET DateRet='2022-06-28' WHERE NA=28;
# 16. M. Cyril FREDERIC essaye d’emprunter le livre n°23. La Requête est :
INSERT INTO emprunter VALUES (23, '2022-06-28', 14, NULL, 28);
# Error Code: 1062. Duplicata du champ '23-2022-06-28' pour la clef 'emprunter.PRIMARY'
# 17. M. Cyril FREDERIC essaye d’emprunter le livre n°29. La Requête est :
INSERT INTO emprunter VALUES
(29, '2022-06-28', 14, NULL, 28);
# Requête effectuée avec succès.
# 18. Auteurs du titre « Voyage au bout de la nuit » :
SELECT titre, auteur FROM biblio.oeuvres WHERE titre = 'Voyage au bout de la nuit';
# 19. Les éditeurs du titre « Narcisse et Goldmund » :
SELECT DISTINCT editeur, titre FROM biblio.livres, biblio.oeuvres
WHERE titre = 'Narcisse et Goldmund' AND livres.NO = oeuvres.NO;
# 20. Les adhérents actuellement en retard :
SELECT emprunter.NA, prenom, nom, count(NL) AS 'Nombre de livre(s) en retard', 
AVG((CASE WHEN (dateRet IS NULL OR dateRet='0000-00-00') THEN DATEDIFF(NOW(), DATE_ADD(dateEmp, INTERVAL dureeMax day))-dureeMax
ELSE datediff(DateRet, DateEmp)-dureeMax END)) AS 'Moyenne du nombre de jour(s) de retard'
FROM biblio.emprunter, biblio.adherents
WHERE (CASE WHEN (dateRet IS NULL OR dateRet='0000-00-00') THEN DATEDIFF(NOW(), DATE_ADD(dateEmp, INTERVAL dureeMax day)) > dureeMax
ELSE datediff(DateRet, DateEmp) > dureeMax END) AND emprunter.NA = adherents.NA GROUP BY NA;
# 21. Les livres actuellement en retard :
SELECT emprunter.NL, editeur, livres.NO
FROM biblio.emprunter, biblio.adherents, biblio.livres
WHERE (dateRet IS NULL OR dateRet='0000-00-00') AND emprunter.NA = adherents.NA
AND DATEDIFF(NOW(), DATE_ADD(dateEmp, INTERVAL dureeMax day)) > dureeMax
AND emprunter.NL=livres.NL;
# 22. Les adhérents en retard avec le nombre de livre en retard et la moyenne du nombre de jour de retard :
SELECT emprunter.NA, prenom, nom, count(NL) AS 'Nombre de livre(s) en retard',
AVG(DATEDIFF(NOW(), DATE_ADD(dateEmp, INTERVAL dureeMax day))-dureeMax) AS
'Moyenne du nombre de jour(s) de retard' FROM biblio.emprunter, biblio.adherents
WHERE (dateRet IS NULL OR dateRet='0000-00-00') AND emprunter.NA = adherents.NA
AND DATEDIFF(NOW(), DATE_ADD(dateEmp, INTERVAL dureeMax day)) > dureeMax GROUP BY NA;
# 23. Nombre de livres empruntées par auteur :
SELECT auteur AS AUTEUR, count(livres.NL) AS 'Nb de livres empruntés' FROM biblio.livres,
biblio.oeuvres, biblio.emprunter WHERE livres.NO=oeuvres.NO AND livres.NL=emprunter.NL GROUP BY auteur;
# 24. Nombre de livres empruntés par éditeur :
SELECT count(livres.NL) AS 'Nb de livres empruntés', editeur FROM biblio.livres,
biblio.oeuvres, biblio.emprunter WHERE livres.NO=oeuvres.NO AND livres.NL=emprunter.NL GROUP BY editeur;
# 25. Durée moyenne des emprunts rendus :
/* La base de donnée comporte des erreurs de saisies dans la table emprunter pour ces 2 insertions :
INSERT INTO emprunter VALUES
(26,from_days(to_days(current_date)-315),21,from_days(to_days(current_date)-318),9),
(12,from_days(to_days(current_date)-300),21,from_days(to_days(current_date)-1290),7),
En effet, la date de retour des livres est antérieure à la date d’emprunt, ce qui n’est pas logique !!!.
Ce qui a pour effet de fausser le calcul de la valeur de la durée moyenne des emprunts rendus (elle est négative).
Alors pour y remédier, j’ai fait un update à NULL pour la valeur dateRet de ces 2 tuples */
UPDATE emprunter SET `dateRet` = '' WHERE (`NL` = '26') and (`dateEmp` = '2021-08-16');
UPDATE emprunter SET `dateRet` = '' WHERE (`NL` = '12') and (`dateEmp` = '2021-08-31');
# Pour calculer la moyenne :
SELECT AVG(datediff(dateRet, dateEmp)) AS 'Durée moyenne des emprunts rendus (jours)'
FROM biblio.emprunter WHERE dateRet IS NOT NULL;
# 26. Durée moyenne des retards pour l’ensemble des emprunts :
SELECT AVG(CASE WHEN dateRet='0000-00-00' OR dateRet IS NULL THEN DATEDIFF(NOW(),
DATE_ADD(dateEmp, INTERVAL dureeMax day))-dureeMax
ELSE datediff(DateRet, DateEmp)-dureeMax END) AS 'Duree moyenne des retards (jours)'
FROM emprunter WHERE ((CASE WHEN dateRet='0000-00-00' OR dateRet IS NULL THEN DATEDIFF(NOW(), DATE_ADD(dateEmp, INTERVAL dureeMax day))
ELSE datediff(DateRet, DateEmp) END));
# 27. Durée moyenne des retards parmi les seuls retardataires :
SELECT AVG(CASE WHEN dateRet='0000-00-00' OR dateRet IS NULL THEN DATEDIFF(NOW(),
DATE_ADD(dateEmp, INTERVAL dureeMax day))-dureeMax
ELSE datediff(DateRet, DateEmp)-dureeMax END) AS 'Duree moyenne des retards (jours)'
FROM emprunter WHERE ((CASE WHEN dateRet='0000-00-00' OR dateRet IS NULL THEN DATEDIFF(NOW(), DATE_ADD(dateEmp, INTERVAL dureeMax day))
ELSE datediff(DateRet, DateEmp) END) > dureeMax);








