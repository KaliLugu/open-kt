# Format PACLOG (`.PACLOG`)

Fichiers texte dans `TT3/WIN32/PACLOG/` (375 fichiers). Un chemin virtuel par ligne,
fins de ligne `CRLF`, sans en-tête :

```
DATA:/GRAPH/TEXTURES/TERRAIN/GRASS/WILD_GRASS_01_DIFF.PTX
DATA:/PHYSICALMATERIAL/CCAMCBLOCKGRASS.PMC
ARCHETYPES:/LEVELS/CAMERA_MANAGER.PPF
COMMON:/SETTINGS/DLC.LUA
TUNING:/LIVERIES.LUA
```

Un PACLOG est la liste des ressources d'un « pac » (un niveau, une moto, un pilote,
un paquet d'interface). On y voit les lecteurs virtuels utilisés par le jeu :
`DATA:`, `COMMON:`, `ARCHETYPES:`, `TUNING:`.

## Organisation

| Dossier | Contenu |
|---|---|
| `PACLOG/CustomPac/` | paquets généraux : `PAC_LUA`, `PAC_CFG`, `PAC_UI*`, `PAC_MINIMAP`, `PAC_PREFAB`, `GAME`, `GAME_<langue>`, `DYNA`, `LoadingScreens`… |
| `PACLOG/CustomPac/VEHICLES/` | un PACLOG par moto (+ `COMPONENTS/Tyres`) |
| `PACLOG/CustomPac/RIDERS/` | un PACLOG par pilote |
| `PACLOG/CustomPac/UI/` | interface |
| `PACLOG/Engine/` | ressources moteur |
| `PACLOG/Levels/Entry/`, `INTROMOVIE.PACLOG`, `TestSpline/` | niveaux annexes |
| `PACLOG/Levels/IOM_SNAEFELL/` | le monde : un PACLOG global, un par tuile, un par circuit, un par météo |

`Levels/IOM_SNAEFELL/IOM_SNAEFELL.PACLOG` référence par exemple 708 `.PTX`,
420 `.PSI`, 420 `.PMA`, 391 `.P3D`, 79 `.PAN`, 26 `.PST`.

## Rôle (supposé)

- Liste de préchargement : le moteur a une classe `RWLib::PacLogSingleResourceLoader`.
- Liste de fabrication des PKG : `DUMMYCM.DAT` décrit quels PACLOG vont dans quel
  chunk (voir [settings-dat.md](settings-dat.md)).
- Le moteur sait aussi les générer : `FileSystemController::SetPacLogGen` et le chemin
  `Data:/RUNTIME_PACLOG` existent dans le code.

Non vérifié : ce qui se passe si un fichier chargé n'est pas listé dans le PACLOG de
son niveau.
