# Outils (`tools/`)

Scripts Perl sans dépendance externe (Perl de base suffit). Lancer depuis la racine
du repo.

## `pkglist.pl` — lister un PKG

```
perl tools/pkglist.pl TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG
```

Sortie tabulée, une ligne par fichier :
`nom  offset  taille_compressée  taille_décompressée  mode  crc`.
Les informations générales (version, nombre d'entrées) sortent sur stderr.

## `pkgextract.pl` — extraire

```
perl tools/pkgextract.pl FICHIER.PKG DOSSIER_SORTIE [regex]
```

- `regex` (optionnelle, insensible à la casse) filtre sur le nom interne.
- Les `\` des noms deviennent des `/` ; l'arborescence est recréée.
- Avertit si la taille obtenue diffère de celle de l'index.

Exemples :

```
# tous les scripts et configs texte
perl tools/pkgextract.pl TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG out '\.(LUA|CFG|XML)$'
# tous les PLM
perl tools/pkgextract.pl TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG out '\.PLM$'
```

Le décodeur LZ4 est en Perl pur : correct mais lent sur les gros fichiers (textures).
Vérifié sur 821 fichiers.

## `pkghide.pl` — masquer / restaurer une entrée

```
perl tools/pkghide.pl FICHIER.PKG 'COMMON\DATABASE\TRACKS.LUA'
perl tools/pkghide.pl FICHIER.PKG 'COMMON\DATABASE\TRACKS.LUA' --restore
```

Remplace le premier caractère du nom par `#` dans l'index (un octet écrit sur place).
Accepte `/` ou `\` et n'importe quelle casse. **Modifie le PKG** : voir
[modding.md](modding.md). Testé sur une copie de l'index seulement, restauration
identique à l'octet.

## `settings_crypt.pl` — chiffrer / déchiffrer les `DUMMY*.DAT`

```
perl tools/settings_crypt.pl TT3/Common/Settings/DUMMYS.DAT DUMMYS.lua   # déchiffre
perl tools/settings_crypt.pl DUMMYS.lua DUMMYS.DAT                       # rechiffre
```

Opération symétrique. Voir [formats/settings-dat.md](formats/settings-dat.md).

## `plm.pl` — lire et modifier un PLM

Afficher une scène :

```
perl tools/plm.pl tree FICHIER.PLM            # arbre des entités et leurs composants
perl tools/plm.pl dump FICHIER.PLM            # idem avec toutes les propriétés
perl tools/plm.pl dump FICHIER.PLM StartPos   # seulement les entités qui correspondent
perl tools/plm.pl subs FICHIER.PLM            # sous-niveaux (tuiles, circuits, météos)
```

Le filtre est une expression régulière, insensible à la casse, appliquée au chemin de
l'entité et à tout son contenu (classes, propriétés, valeurs). Chaque entité est
affichée avec son identifiant `[#xxxxxxxx]`.

Modifier (écrit toujours dans un nouveau fichier) :

```
perl tools/plm.pl set ENTREE.PLM SORTIE.PLM \
    'RaceInitializer:NbLaps=3' \
    'StartingGrid01a_1:Mesh.MaxVisibleDistance=275' \
    'StartingGrid:pos=9775.84,4472.44,165'
```

- `ENTITE:Propriete=valeur` change une propriété ; ajouter `Classe.` devant la
  propriété si plusieurs composants de l'entité ont une propriété du même nom.
- `ENTITE:pos=x,y,z`, `rot=x,y,z`, `scale=x,y,z` changent la transformation.
- `ENTITE` est le nom de l'entité, ou `#identifiant` quand le nom n'est pas unique
  (l'outil le signale et liste les identifiants possibles).

L'outil affiche l'ancienne et la nouvelle valeur de chaque modification. Limites :
pas d'ajout ni de suppression d'entité, pas de modification des tableaux (points de
spline). Voir [formats/plm.md](formats/plm.md).

## `plmstr.pl` — chaînes brutes d'un PLM

```
perl tools/plmstr.pl FICHIER.PLM
```

Affiche l'en-tête et toutes les chaînes de la table, sans structure. Remplacé par
`plm.pl` pour l'usage courant.

## Outils qui manquent

- ajout d'entités et édition des tableaux dans les PLM ;
- décodeur de PWS ;
- réécriture de PKG.
