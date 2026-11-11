# Structure de la map

Le jeu n'a qu'un seul monde : **`IOM_SNAEFELL`** (l'île de Man). Les « circuits » sont
des portions de ce monde. Il existe aussi deux niveaux annexes : `ENTRY` (démarrage,
ne contient qu'une machine à états `COMMON:/StateMachines/EntryStateMachine.xml`) et
`TestSpline`.

## Les couches, de la plus haute à la plus basse

```
TRACKS.LUA                      liste des circuits
   └─ LevelAsset ─▶ TRACK_x.PLM        règles et décor d'un circuit
IOM_SNAEFELL.PLM                scène principale du monde
   ├─ référence 148 autres PLM (tuiles, circuits, météos)
   ├─ TILE_Xnn_Ynn.PLM  ×104           routes, murs, objets d'une tuile
   │     └─ ROADS\*.PRO                géométrie de route précalculée
   ├─ IOM_SNAEFELL.PWS  ×104           terrain streamé d'une tuile
   └─ WTn_xxx_yyy.PLM   ×12            ambiances heure / météo
```

## 1. `COMMON\DATABASE\TRACKS.LUA`

Table `Tracks`, une entrée par circuit ou variante. Champs vus sur la première entrée :

```lua
{
	Name = "Track St John",
	TrackGroupId = 3,
	MapSectors = "MsStJohnCourseFull",
	UI_Name = LocalesId.EDITOR_TRACK_NAME_ST_JOHN_FULL,
	UI_HUD_MapScale = 1.65,  UI_HUD_MapZoom = 0.4,
	UI_HUD_MapOffsetX = 0,   UI_HUD_MapOffsetY = -285,  UI_HUD_MapRotation = 0,
	UI_HUD_MapSource = "DATA:/GUI/TEXTURES/HUD/MINIMAPS/MINIMAP_ZOLDER.PTX",
	IsCircuit = true,
	LengthKm = 25.5,
	LevelAsset = "DATA:/LEVELS/IOM_SNAEFELL/TRACK_STJOHN/TRACK_STJOHN.PLM",
	LevelAssetLQ = nil,
	Order = 22,  Locked = false,  Available = true,  UI_Hidden = false,
	LoadingTag = "Zolder",
	PrivateTestLeaderboard = "times_john_full",
	ObjectiveLapTime = 90,
	AIDifficultyLevelLowest = 20, AIDifficultyLevelMedium = 60, AIDifficultyLevelHighest = 100,
	...
}
```

Plusieurs valeurs portent encore le nom `Zolder` : restes d'un autre projet du studio.

Fichiers associés : `TRACKGROUPS.LUA`, `WEATHERTRACKBINDS.LUA`,
`TRACKASPHALTCONSUMPTIONS.LUA`, et un réglage d'IA par circuit dans
`COMMON\TUNING\FACTORIES\AI\AIMAINSETTINGS\TRACK *.CFG`.

## 2. Les circuits — `TRACK_*.PLM`

8 circuits de base, chacun avec des variantes numérotées (secteurs) :

| Circuit | Variantes |
|---|---|
| `TRACK_SNAEFELL` | `_1` à `_6` |
| `TRACK_CLYPSE` | `_1`, `_2` |
| `TRACK_LAXEY` | `_1` à `_3` |
| `TRACK_NORTH_EAST` | `_1` à `_3` |
| `TRACK_NORTH_WEST` | `_1` à `_3` |
| `TRACK_SOUTH_EAST` | `_1`, `_2` |
| `TRACK_SOUTH_WEST` | `_1` à `_3` |
| `TRACK_STJOHN` | `_1`, `_2` |

Un PLM de circuit ne contient pas la route. Il contient ce qui est propre à la course :
mode de jeu, initialisation (`NbLaps`, grille par défaut, ligne d'arrivée, respawn),
positions de départ `StartPos_01`…`_10`, file d'attente `StartQueue_WaitPos_*`,
triggers, décalques de grille, arche de départ, bannières et panneaux.

## 3. La scène principale — `IOM_SNAEFELL.PLM`

4,9 Mo. Dimensions dans l'en-tête : origine `-16384, -16384`, puis `2048` répété, ce
qui suggère un monde de 32 768 unités de côté découpé en cases de 2 048 (1 unité =
1 mètre d'après `Engine.UnitScale`). **Interprétation à confirmer.**

Contient le terrain (composant `HeightmapComponent` avec `Resolution = 4096`,
distances de fondu, et la liste des couches `TerrainLayerComponent`), le `TileSpawner`,
les routes procédurales, le ciel, l'éclairage, la végétation, les réglages physiques
et par plateforme. Liste complète dans [formats/plm.md](formats/plm.md).

Types d'instances : `COMMON\LEVELS\IOM_SNAEFELL\INSTANCETYPES.GIS`.

## 4. Les tuiles — `TILE_Xnn_Ynn`

104 tuiles, X de 02 à 28, Y de 02 à 24, disposées **en quinconce** : les X pairs ont
des Y de la forme 4k (04, 08, 12…), les X impairs des Y de la forme 4k+2 (02, 06, 10…).

Chaque tuile a trois jeux de fichiers :

| Fichier | Emplacement | Contenu |
|---|---|---|
| `IOM_SNAEFELL_TILE_Xnn_Ynn.PLM` | PKG, `WIN32\LEVELS\IOM_SNAEFELL\TILE_Xnn\TILE_Xnn_Ynn\` | routes, splines, murs, bordures, rivières |
| `ROADS\*.PRO` | PKG, `COMMON\LEVELS\IOM_SNAEFELL\TILE_Xnn\TILE_Xnn_Ynn\` | géométrie générée le long des splines |
| `IOM_SNAEFELL.PWS` | disque, `WIN32/LEVELS/IOM_SNAEFELL/TILE_Xnn/TILE_Xnn_Ynn/` | terrain — voir [formats/pws.md](formats/pws.md) |

Les `.PRO` sont nommés `<entité>.<identifiant>.PRO`, par exemple
`02_ROAD_02.2334326292.PRO`, `SPAWNER_STONEWALL_X07_Y10_01.167550082.PRO`,
`SPAWNER_SIDEWALK_…`, `SPAWNER_TALUS_…`, `SPAWNER_RIVER_…`. Ce sont les résultats
précalculés des `SplineSpawner` / `ProceduralRoadComponent` du PLM de la tuile. Une
modification du tracé dans le PLM demandera donc probablement de régénérer ou
remplacer les `.PRO` correspondants (`Engine.Editor.SkipRoadBuild` existe dans la config).

## 5. Les ambiances — `WTn_xxx_yyy.PLM`

12 fichiers d'environ 5,5 Ko : 3 moments × 4 météos.

| Moment | Météos |
|---|---|
| `WT1_MRN` (matin), `WT2_AFT` (après-midi), `WT3_DSK` (crépuscule) | `CLEAR`, `CLOUDY`, `OVERCAST`, `RAINY` |

Contenu : un `DayTimeSet` (heure, minute, couleur d'environnement) et une
`DirectionalLight` (couleur, intensité, ombres, god rays). Petits et simples : de bons
candidats pour un premier essai de modification de PLM.

## Selon ce qu'on veut changer

| Objectif | Fichiers |
|---|---|
| Nom, longueur, minimap, disponibilité d'un circuit | `TRACKS.LUA` |
| Grille de départ, nombre de tours, décor de départ | `TRACK_*.PLM` |
| Lumière, heure, météo | `WT*.PLM` |
| Ajouter / déplacer un objet, un mur | PLM de tuile ou principal |
| Tracé d'une route | PLM de tuile + `.PRO` |
| Relief, textures du sol, végétation | `.PWS` + couches dans `IOM_SNAEFELL.PLM` |
