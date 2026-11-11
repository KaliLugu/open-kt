# Format PLM (`.PLM`, magic `PLMB`)

Fichier de scène : une liste d'entités, chacune avec des composants et leurs
propriétés. C'est le format des niveaux, des circuits, des tuiles et des ambiances
météo. Tous sont dans les PKG.

**État : seuls l'en-tête et la table de chaînes sont compris.** La partie binaire qui
relie entités, composants et valeurs n'est pas décodée.

## En-tête

| Offset | Type | Contenu |
|---|---|---|
| 0x00 | char[4] | `PLMB` |
| 0x04 | u32 | version = 12 |
| 0x08 | u32 | drapeau (1 pour le niveau principal et `ENTRY`, 0 pour circuits, tuiles, météo) |
| 0x0C | float[9] | bornes / dimensions (voir exemples) |
| 0x30 | u32 | taille en octets de la table de chaînes |
| 0x34 | u32 | compteur (sens inconnu, voir plus bas) |
| 0x38 | u32 | taille d'une section suivante (supposé) |
| 0x3C… | u32 × n | petits compteurs, sens inconnu |
| 0x80 | | début de la table de chaînes |

Exemples de valeurs :

| Fichier | float[9] | 0x30 | 0x34 | 0x38 | taille fichier |
|---|---|---|---|---|---|
| `IOM_SNAEFELL.PLM` | -16384, -16384, 0, 2048, 2048, 0, 2048, 2048, 0 | 727 256 | 24 581 | 1 696 089 | 4 903 045 |
| `ENTRY.PLM` | -512, -512, 0, 0, 0, 0, 1024, 1024, 0 | 103 | 2 | 138 | 427 |
| `TRACK_LAXEY_1.PLM` | tout à 0 | 15 914 | 356 | 24 564 | 58 974 |
| tuile `X07_Y10` | tout à 0 | 134 217 | 2 962 | 204 378 | 652 101 |

Le compteur en 0x34 ne correspond **pas** au nombre de chaînes séparées par des zéros
(356 annoncé contre 934 trouvées pour `TRACK_LAXEY_1`). C'est peut-être le nombre
d'entités ou de composants.

## Table de chaînes

À partir de 0x80, des chaînes ASCII terminées par un zéro, sans doublon apparent.
On y trouve mélangés :

- noms d'entités : `RaceGameMode`, `StartPos_01`, `StartingGrid01a_1`, `Arch`…
- classes de composants : `PlayAll::GameServices::Mesh`, `GamePlay::GPRaceInitializerComponent`…
- noms de propriétés : `ResourceID`, `MaxVisibleDistance`, `NbLaps`, `CastShadows`…
- valeurs, toujours en texte :
  - nombres : `150`, `1.5708`, `0.013587`
  - vecteurs et couleurs séparés par `;` : `0.5;1;0.5;1`
  - chemins virtuels : `DATA:/GRAPH/TRACKS/COMMON/DECALS/STARTINGGRID01A.PSI`
  - références à d'autres entités par identifiant numérique : `3745082722`, `{2831935820}`
  - listes : `{DATA:/.../A.PSI},{DATA:/.../B.PSI}`

Une valeur partagée par plusieurs propriétés n'apparaît qu'une fois : modifier une
chaîne sur place peut donc toucher plusieurs propriétés à la fois.

## Composants rencontrés

Niveau principal `IOM_SNAEFELL.PLM` :
- terrain : `HeightmapComponent`, `TerrainLayerComponent` (diffuse, normal, matériau
  physique, couleur par couche : `Wild_Grass`, `Grass_Cut`, `Bush_Leaves`…), `TileSpawner`
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

Tuile : `RoadComponent`, `RoadControlPointInterp`, `ProceduralRoadComponent`,
`SplineSpawner`, `SplineMeshSkinnerComponent`, `SplineMeshSkinnerCollider`,
`SnapToGround`, `PublicComponent`.

Circuit : `GamePlay::GPGameModeComponent`, `GPRaceInitializerComponent`,
`GPRaceLineController`, `GPLineSwitchComponent`, `Rc2RaceStartingGrid`,
`Rc2RaceStartPosition`, `PlayAll::GameServices::TriggerBase`, `AnimatorController`.

Météo (`WT1_MRN_CLEAR`…) : `DayTimeSet`, `DirectionalLight` et réglages de lumière.

Le niveau principal référence 148 autres `.PLM` (tuiles, circuits, météos).

## Ce qu'on peut déjà faire

- Lister le contenu d'une scène : `tools/plmstr.pl fichier.plm`.
- Remplacer une valeur par une autre **de même longueur** directement dans le fichier
  (par exemple un chemin de `.PSI` par un autre de même taille), sans toucher à la
  structure. Non testé en jeu.

## À faire

Décoder la partie binaire après la table de chaînes (arbre des entités, index vers les
chaînes, transformations). Le chargeur est à chercher dans le code autour de la
constante `PLMB` et des classes citées ci-dessus.
