# Format PLM (`.PLM`, magic `PLMB`)

Fichier de scène : un arbre d'entités, chacune avec une position et des composants
dont les propriétés sont stockées en texte. C'est le format des niveaux, des circuits,
des tuiles et des ambiances météo. Tous sont dans les PKG.

**État : structure entièrement décodée.** Les 150 PLM du jeu se lisent jusqu'au
dernier octet sans anomalie avec `tools/plm.pl`. Le format a été déduit des fichiers
eux-mêmes, pas du code du moteur : le sens de quelques champs reste inconnu, et la
réécriture n'a **pas encore été testée en jeu**.

Tout est en little-endian.

## Vue d'ensemble

```
en-tête                      0x80 octets
table de chaînes             taille donnée par l'en-tête
table des sous-niveaux       24 octets × nombre de sous-niveaux
table des entités            69 octets × nombre d'entités
groupes de composants        nombre donné par l'en-tête
8 octets à zéro              fin de fichier
```

## En-tête

| Offset | Type | Contenu |
|---|---|---|
| 0x00 | char[4] | `PLMB` |
| 0x04 | u32 | version = 12 |
| 0x08 | u32 | drapeau (1 pour le niveau principal et `ENTRY`, 0 sinon) |
| 0x0C | float[9] | bornes du monde (remplies seulement quand le drapeau vaut 1) |
| 0x30 | u32 | taille de la table de chaînes |
| 0x34 | u32 | nombre d'entités |
| 0x38 | u32 | taille de la table des entités (= 69 × nombre) |
| 0x3C | u32 | nombre de groupes de composants |
| 0x40 | u32 | plus grand nombre de propriétés d'une classe (probable) |
| 0x44 | u32 | toujours 0 |
| 0x48 | u32 | nombre de sous-niveaux |
| 0x4C | u32 | profondeur maximale de l'arbre (probable) |
| 0x50 | | zéros jusqu'à 0x80 |

Bornes du niveau principal : `-16384, -16384, 0, 2048, 2048, 0, 2048, 2048, 0`.

## Table de chaînes

Chaînes ASCII terminées par un zéro, sans doublon. Tout le reste du fichier y renvoie
par **offset depuis le début de la table** : noms d'entités, noms de classes, noms de
propriétés et valeurs.

Les valeurs sont toujours du texte :

- nombres : `150`, `1.5708`
- vecteurs et couleurs séparés par `;` : `0.5;1;0.5;1`
- chemins virtuels : `DATA:/GRAPH/TRACKS/COMMON/DECALS/STARTINGGRID01A.PSI`
- référence à une autre entité : son identifiant en décimal (`3745082722`),
  ou une liste `{2831935820}`
- listes de ressources : `{DATA:/.../A.PSI},{DATA:/.../B.PSI}`

Une même chaîne est partagée par toutes les propriétés qui ont cette valeur. Il ne
faut donc pas modifier une chaîne sur place : on ajoute la nouvelle valeur en fin de
table et on fait pointer la propriété dessus (c'est ce que fait `plm.pl set`).

## Table des sous-niveaux

Présente dans le niveau principal (148 entrées). 24 octets par entrée :

| Type | Contenu |
|---|---|
| u32 | type : 2 = tuile, 1 = autre (circuit, météo) |
| u32 | chemin du PLM (offset de chaîne) |
| float[3] | position du sous-niveau dans le monde |
| u32 | drapeau (0 ou 1) |

La position d'une tuile `TILE_Xnn_Ymm` est `((nn - 16) × 1024, (mm - 16) × 1024, 0)`.
Les circuits et météos sont en `(0, 0, 0)`.

## Table des entités

69 octets par entité, dans l'ordre de l'arbre (parent avant enfants) :

| Offset | Type | Contenu |
|---|---|---|
| +0 | u32 | nom (offset de chaîne) |
| +4 | u32 | identifiant unique |
| +8 | u32 | inconnu (5 le plus souvent) |
| +12 | u32 | identifiant du parent, 0 pour la racine |
| +16 | i32 | inconnu (un offset dans la table des entités, ou 0) |
| +20 | i32 | inconnu (-1 partout où on a regardé) |
| +24 | float[3] | position, relative au parent |
| +36 | float[3] | rotation, en degrés |
| +48 | float[3] | échelle |
| +60 | u32 | nombre d'enfants |
| +64 | u16 | nombre de composants |
| +66 | u16 | profondeur dans l'arbre |
| +68 | u8 | drapeaux (`0x90`, `0x10`, `0x08`…) |

Les noms d'entités ne sont pas forcément uniques ; l'identifiant l'est.

## Groupes de composants

Un groupe :

| Type | Contenu |
|---|---|
| i32 | identifiant du groupe |
| u32 | taille en octets de ce qui suit le champ suivant |
| u32 | nombre de classes |
| | les blocs de classe |

Identifiants rencontrés : `-1` (109 groupes), `0x80000000` (49 groupes, dans les
circuits et les tuiles, contient notamment les splines) et `1` (2 groupes). Leur
signification n'est pas connue.

### Bloc de classe

```
u32  nom de la classe (offset de chaîne)        absent pour un bloc imbriqué
u16  nombre de propriétés (np)
u16  nombre de propriétés simples (ns)
u16  0
u16  nombre de propriétés complexes (nc = np - ns)
u16  nombre d'instances
u32 × np   noms des propriétés, les simples d'abord
instances
```

Chaque classe déclare ses propriétés une seule fois ; les instances ne contiennent que
les valeurs, dans le même ordre.

### Instance

```
u32  identifiant de l'entité propriétaire (0 dans un bloc imbriqué)
u32  taille de l'instance, ces 8 octets compris
u32 × ns   valeurs des propriétés simples (offsets de chaîne)
pour chaque propriété complexe :  8 octets à zéro, puis un bloc imbriqué
```

Chaque instance est suivie de **8 octets à zéro** qui ne sont pas comptés dans sa taille.

### Propriétés complexes (tableaux)

Une propriété complexe est un tableau de structures. Elle est stockée comme un bloc
de classe sans nom : ses propres noms de champs, puis une instance par élément. Un
élément peut lui-même contenir des tableaux. Un tableau vide est un en-tête de
10 octets à zéro.

Tableaux rencontrés :

| Classe | Propriété | Champs d'un élément |
|---|---|---|
| `Spline` | `SplineCP` | 2 champs (points de contrôle) |
| `Spline` | `SplineData` | `Distances`, `_DatasTypeName`, et deux tableaux `Keys`, `Datas` |
| `ProceduralRoadComponent` | `Sub Offsets ##1` | `Offset Z`, `Subspline Alignment`, `Offset` |
| `ProceduralRoadCrossRoad` | `Inter-road settings`, `SubSplines` | 6 et 5 champs |
| `ProceduralRoundaboutComponent` | `Entrances`, `SubSplines` | 6 champs |

## Exemple

Sortie de `plm.pl dump` sur `TRACK_LAXEY_1.PLM` :

```
[#4c69a92a] GAMEPLAY
  [#0ea2073b] RaceInitializer
      <GamePlay::GPRaceInitializerComponent>
        Base Track Info = 3745082722
        Finish Line Trigger = 632430507
        NbLaps = 1
        ...
  [#d11474cb] StartingGrid  pos=(9775.84,4472.44,159.632)  rot=(0,0,-338.145)
      <Rc2RaceStartingGrid>
    [#6c47857f] StartigGrid_Decals
      [#3c4bb4aa] StartingGrid01a_1  pos=(4.002,12.1306,1.1262)  rot=(3.069,-0.054,-48.0559)
          <PlayAll::GameServices::Mesh>
            Visible = 1
            MaxVisibleDistance = 150
            ResourceID = DATA:/GRAPH/TRACKS/COMMON/DECALS/STARTINGGRID01A.PSI
```

## Composants rencontrés

Niveau principal `IOM_SNAEFELL.PLM` (24 581 entités, 98 classes) :
- terrain : `HeightmapComponent`, `TerrainLayerComponent`, `TileSpawner`
- routes : `ProceduralRoadComponent`, `ProceduralRoadCrossRoad`,
  `ProceduralRoundaboutComponent`, `ProRoadShapeCPData`, `ProRoadVisualCPData`,
  `RoadCollider`, `RoadFXCPData`
- splines : `Spline`, `SplineControlPoint`, `SplineAtom`, `MeshSplineAtom`
- objets : `Mesh`, `MeshCollider`, `BoxCollider`, `RigidBody`, `DecalComponent`,
  `TreeComponent`, `GenericInstanceSpawnerComponent`, `GenericInstanceComponent`
- rendu / ambiance : `Sky`, `DayTime`, `DayTimeSet`, `DirectionalLight`, `SpotLight`,
  `FogSettings`, `WeatherSettings`, `HDRSettings`, `Bloom`, `ColorGrading`, `Probe`,
  `CloudShadowComponent`, `WindComponent`
- réglages : `PhysicsSettings`, `CullerSettings`, `PlatformSettingsPC` (et PS4, XBoxOne, Switch)

Tuile : `Mesh`, `Spline`, `RoadComponent`, `RoadControlPointInterp`,
`ProceduralRoadComponent`, `SplineSpawner`, `SplineMeshSkinnerComponent`,
`SplineMeshSkinnerCollider`, `SnapToGround`, `Probe`, `ResourcePreloader`.

Circuit : `GamePlay::GPGameModeComponent`, `GPRaceInitializerComponent`,
`GPRaceLineController`, `GPLineSwitchComponent`, `Rc2RaceStartingGrid`,
`Rc2RaceStartPosition`, `PlayAll::GameServices::TriggerBase`, `AnimatorController`.

Météo (`WT1_MRN_CLEAR`…) : `DayTimeSet`, `DirectionalLight`, `LensFlareComponent`,
`Sky`, `Bloom`, `HDRSettings`, `ColorGrading`, brouillard et vent.

## Modifier un PLM

`tools/plm.pl set` sait :
- changer la valeur d'une propriété simple ;
- changer la position, la rotation ou l'échelle d'une entité.

Pour une propriété, la nouvelle valeur est ajoutée à la table de chaînes (ou réutilisée
si elle existe déjà), l'offset de la valeur est remplacé, et la taille de la table est
mise à jour dans l'en-tête. Rien d'autre ne bouge : tous les autres offsets du fichier
sont relatifs à leur propre section. Réécrire une valeur identique redonne le fichier
d'origine à l'octet près.

Pas encore possible : ajouter ou supprimer une entité ou un composant, modifier un
tableau (points de spline).

## Points ouverts

- Champs +8, +16 et +20 des entités, et sens exact des drapeaux.
- Signification des identifiants de groupe.
- Comment l'identifiant d'une entité est calculé (nécessaire pour en créer une).
- Le moteur accepte-t-il une table de chaînes agrandie ? À vérifier en jeu.
