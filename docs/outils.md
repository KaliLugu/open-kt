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
[modding.md](modding.md). Testé en jeu ; restauration
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

## `p3d2obj.pl` — exporter un modèle 3D en OBJ

```
perl tools/p3d2obj.pl MODELE.P3D               # liste les parties, sommets et triangles
perl tools/p3d2obj.pl MODELE.P3D SORTIE.OBJ    # exporte positions, UV et triangles
perl tools/p3d2obj.pl --terrain DOSSIER ILE.OBJ   # assemble le relief de toute l'île
```

Chaque sous-maillage devient un objet OBJ nommé d'après son nœud ; les niveaux de
détail (`_LOD1`, `_LOD2`…) sont exportés comme des objets séparés. Repère du jeu :
Z vers le haut, en mètres. Normales et matériaux ne sont pas exportés.

Le mode `--terrain` prend le dossier des `HEIGHTMAP_xx_yy.P3D` extraits et place
chaque morceau à sa position dans le monde. Voir [formats/p3d.md](formats/p3d.md).

## `p3dpatch.pl` — retoucher un modèle 3D

Modifie uniquement la position des sommets d'un P3D ; tout le reste du fichier est
conservé à l'identique.

```
perl tools/p3dpatch.pl ENTREE.P3D SORTIE.P3D --scale 1,1,2.5          # étirer (ici 2,5× en hauteur)
perl tools/p3dpatch.pl ENTREE.P3D SORTIE.P3D --move 0,0,1             # déplacer
perl tools/p3dpatch.pl ENTREE.P3D SORTIE.P3D --scale 1,1,3 --part LOD0   # une seule partie
perl tools/p3dpatch.pl ENTREE.P3D SORTIE.P3D --obj MODIFIE.OBJ        # depuis un logiciel 3D
```

Avec `--obj`, le fichier doit venir de `p3d2obj.pl` et avoir été modifié sans ajouter
ni supprimer de sommet, ni changer leur ordre : on déplace des points, c'est tout.
Dans Blender, garder les mêmes réglages d'axes à l'import et à l'export. Les parties
sont retrouvées par leur nom d'objet. Un aller-retour P3D → OBJ → P3D sans modification
redonne exactement les mêmes positions.

L'outil recalcule la boîte et la sphère englobantes de chaque maillage. Il ne met pas
à jour les normales (l'éclairage reste celui de l'ancienne forme) ni la collision.

## `ptxfill.pl` — colorer une texture pour un test

```
perl tools/ptxfill.pl ENTREE.PTX SORTIE.PTX ff00ff
```

Remplit une texture DXT1 d'une couleur unie (magenta par défaut), mipmaps compris.
Sert à rendre un objet immédiatement reconnaissable en jeu. Les `.PTX` sont des RIFF
`PATX` : un bloc `Pixl` par niveau de mipmap, en DXT1 ou DXT5.

## `prmpatch.pl` — déplacer une route

```
perl tools/prmpatch.pl ROUTE.PRM                              # maillages, niveaux de détail, collision
perl tools/prmpatch.pl ROUTE.PRM SORTIE.PRM --move 0,0,0.5    # relever de 50 cm
```

Les `.PRM` de `ROADBUILDSTEP` sont des RIFF `PA__` de type `PROAD` : sommets en
coordonnées du monde, trois niveaux de détail, et un bloc `Phys` (collision PhysX).
L'outil déplace les deux ensemble ; `--visual` laisse la collision en place.

Bloc `Phys` : u32 nombre de maillages, puis pour chacun un u32 « présent » suivi, s'il
vaut 1, d'un u32 taille, d'un maillage PhysX cuit (`NXS MESH` version 14, arbre `RTRE`
en gros-boutiste) et du chemin du matériau physique (`.PMC`). Décodage vérifié sur les
461 routes, carrefours et ronds-points.

## `modsync.pl` — reporter les modifications vers l'instance lancée

```
perl tools/modsync.pl TT3 /chemin/instance --dry    # montre ce qui serait fait
perl tools/modsync.pl TT3 /chemin/instance
```

Pour chaque entrée masquée dans les PKG de la copie source : copie le fichier en vrac
vers l'instance et masque la même entrée dans ses PKG (sans recopier les archives).
Une entrée masquée seulement dans l'instance est restaurée. Une entrée n'est jamais
masquée si son fichier en vrac manque, car le jeu plante dans ce cas.

## `plmstr.pl` — chaînes brutes d'un PLM

```
perl tools/plmstr.pl FICHIER.PLM
```

Affiche l'en-tête et toutes les chaînes de la table, sans structure. Remplacé par
`plm.pl` pour l'usage courant.

## Outils qui manquent

- ajout d'entités et édition des tableaux dans les PLM ;
- décodeur de PWS ;
- modification libre de la forme des routes (reconstruction de l'arbre de collision), lecteur des `.PRO` ;
- réécriture de PKG.
