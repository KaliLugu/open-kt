# Modèles 3D : `.P3D`, `.PSI`, `.PMA`

Les modèles 3D du jeu sont dans les PKG, sous `WIN32\GRAPH\`. Trois fichiers vont
ensemble :

| Fichier | Rôle |
|---|---|
| `.P3D` | la géométrie : nœuds, maillages, niveaux de détail |
| `.PMA` | un matériau : effet (`.PFX`), paramètres, textures (`.PTX`) |
| `.PSI` | l'objet « prêt à poser » : un `.P3D` + les `.PMA` à lui appliquer |

Les scènes `.PLM` ne référencent que des `.PSI` (propriété `ResourceID` du composant
`Mesh`).

**État** : la géométrie des `.P3D` (positions, UV, triangles) est lue et exportée en
OBJ par `tools/p3d2obj.pl`, vérifié sur 148 modèles avec des dimensions cohérentes.
Normales, tangentes, couleurs, squelette et physique ne sont pas décodés. Écrire un
P3D n'a pas été tenté.

## Conteneur RIFF

`.P3D` et `.PSI` sont des fichiers RIFF classiques : `RIFF`, taille, type `PA__`,
puis des blocs `identifiant (4 caractères) + taille (u32) + données`, et des blocs
`LIST` qui en contiennent d'autres. Les données de beaucoup de blocs se terminent par
le marqueur `cd ab`.

Le premier bloc, `Head`, indique le type de contenu : `SCENE___` pour un P3D,
`SCENINST` pour un PSI.

## Structure d'un P3D

```
RIFF 'PA__'
  Head                      "SCENE___ENDI"...
  LIST 'Nods'               un nœud de l'arbre
    NoHe                    en-tête du nœud : nom + matrice
    Node
    LIST 'Nods'             nœuds enfants...
      NoHe
      LIST 'MeLi'           liste de maillages
        Mesh
        LIST 'GeLi'         liste de géométries
          Geom
          LIST 'SGLi'       liste de sous-géométries
            SuGe            nombre de sommets et de triangles
            vpos            positions
            vnor            normales
            vtan            tangentes
            vuvs            coordonnées de texture
            vcol            couleurs (optionnel)
            indx            indices des triangles
            EndG
      PhHe / PhAc           physique (optionnel)
  Skin
  LODs
  Shad
```

### `NoHe` — en-tête de nœud

| Type | Contenu |
|---|---|
| u16 | 1 |
| u32 | longueur du nom |
| char[n] | nom du nœud |
| 2 octets | `01 00` |
| float[16] | matrice 4×4 locale, translation dans la dernière ligne |
| … | fin non décodée |

La transformation d'un sommet est le produit des matrices du nœud jusqu'à la racine.
Les niveaux de détail sont des nœuds frères nommés `…_LOD1`, `…_LOD2`, etc.

### `SuGe` — sous-géométrie

| Type | Contenu |
|---|---|
| u16 | 6 |
| u32 | nombre de sommets |
| u32 | nombre de triangles |

### Flux de sommets

| Bloc | Octets par sommet | Contenu |
|---|---|---|
| `vpos` | 12 | 3 flottants x, y, z |
| `vuvs` | 4 ou 8 | UV en entiers 16 bits, à diviser par 4096 ; 8 octets = probablement deux jeux d'UV |
| `vnor` | 8 | normale compressée (non décodée) |
| `vtan` | 4 | tangente compressée (non décodée) |
| `vcol` | 4 | couleur |

`indx` : trois indices par triangle, en 16 bits (cas courant) ou 32 bits pour les gros
maillages. On distingue les deux par la taille du bloc (6 ou 12 octets par triangle).

Repère : **Z vers le haut**, 1 unité = 1 mètre.

### `Mesh` — en-tête de maillage

60 octets. Contient les volumes englobants, en coordonnées locales :

| Offset | Type | Contenu |
|---|---|---|
| +5 | float[3] | coin minimum de la boîte englobante |
| +17 | float[3] | coin maximum |
| +33 | float[3] | centre de la sphère englobante |
| +45 | float | rayon |

Vérifié : ces valeurs correspondent exactement aux positions des sommets.

## Retoucher un P3D

`tools/p3dpatch.pl` réécrit le bloc `vpos` et les volumes englobants en laissant le
reste intact. Testé en jeu : un `BANNER_FULL.P3D` agrandi deux fois
s'affiche correctement, animation de vent comprise.

## Structure d'un PSI

Petit fichier (environ 200 octets) : le chemin du `.P3D`, puis pour chaque maillage
son nom et le chemin du `.PMA` à utiliser. Exemple `HEIGHTMAP_00_00.PSI` :

```
DATA:/GRAPH/PROPS/TERRAIN/MESH/HEIGHTMAP_00_00.P3D
  HEIGHTMAP_00_00  ->  DATA:/GRAPH/PROPS/TERRAIN/PMA/HEIGHTMAP_00_00_COLORMAP.PMA
```

## Structure d'un PMA

Pas un RIFF. Commence par `UNDEFINDENDI`, puis le nom du matériau, le chemin de
l'effet et une liste de paramètres nommés (`Smoothness`, `Specular`, `DiffuseMap`…)
avec leur valeur ou un chemin de texture. Lisible à l'œil, pas d'outil pour l'instant.

## Où sont les modèles

1 277 fichiers `.P3D`, 1,1 Go décompressés.

| Dossier (`WIN32\GRAPH\…`) | Nombre | Contenu |
|---|---|---|
| `TRACKS\COMMON` | 569 | décor de bord de route : murs, bordures, arches, sponsors |
| `PROPS\SIGNS` | 155 | panneaux |
| `PROPS\TERRAIN` | 144 | relief de l'île, voir ci-dessous |
| `TRACKS\TTMAP` | 68 | probablement la carte de l'île (textures `TTMAPCOMPLETE`, `MAPSPLINES`, `POI`) |
| `CHARACTERS\RIDER` | 65 | pilotes |
| `TRACKS\ROADS` | 48 | éléments de route |
| `VEHICLES\MODELS` | 37 | motos |
| `PROPS\BUILDING`, `RAILCLONES`, `MISC`, `COMMON` | ~100 | bâtiments et objets divers |

## Le relief de l'île

`PROPS\TERRAIN\MESH\HEIGHTMAP_xx_yy.P3D` : 144 maillages d'environ 2 300 sommets,
chacun couvrant un carré de 2 048 m. Ce sont des versions basse résolution du terrain,
posées par les entités `TILE_SPAWNER_x_y` de la scène principale à la position
`(-16384 + 1024 × xx, -16384 + 1024 × yy)`. La numérotation est la même que celle des
tuiles `TILE_Xnn_Ymm`, mais il y en a 144 contre 104 tuiles streamées : elles couvrent
aussi les zones où l'on ne roule pas.

Assemblées, elles donnent l'île entière : environ 30 km × 30,7 km, 384 516 sommets,
altitude maximale 618 m (le Snaefell réel culmine à 621 m).

```sh
perl tools/pkgextract.pl TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0001.PKG out 'PROPS\\TERRAIN\\MESH\\HEIGHTMAP_.*\.P3D$'
perl tools/p3d2obj.pl --terrain out/WIN32/GRAPH/PROPS/TERRAIN/MESH out/terrain_ile.obj
```

Le terrain détaillé sur lequel on roule est ailleurs, dans les `.PWS`
(voir [pws.md](pws.md)).

## Les routes et le décor généré

La géométrie des routes n'est pas dans des `.P3D`. Elle est précalculée par tuile dans
`COMMON\LEVELS\IOM_SNAEFELL\TILE_*\` :

| Dossier | Extension | Nombre | Taille | Contenu |
|---|---|---|---|---|
| `SPLINEMESHSKINNERS\` | `.PRM` | 6 385 | 4,1 Go | objets déformés le long des splines (murs, haies, barrières) |
| `ROADBUILDSTEP\` | `.PRM` | 371 | 269 Mo | chaussée |
| `CROSSROADBUILDSTEP\` | `.PRM` | 88 | 9 Mo | carrefours |
| `ROUNDABOUTBUILDSTEP\` | `.PRM` | 4 | 1 Mo | ronds-points |
| `ROADS\` | `.PRO` | 1 375 | 479 Mo | résultats des générateurs le long des routes |

Ces formats n'ont pas encore été regardés. C'est là que se trouve la plus grosse part
de la géométrie de la map.
