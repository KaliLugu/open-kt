# Inventaire des extensions

## Dans les PKG (21 758 fichiers)

Le nombre est exact. La colonne « nature » est une **supposition** tirée du nom, de
l'emplacement et des références dans les PLM, sauf mention « vérifié ».

| Ext. | Nombre | Nature |
|---|---|---|
| `PTX` | 7 217 | texture |
| `PRM` | 6 848 | géométrie générée par tuile : routes, carrefours, objets le long des splines (4,4 Go) |
| `PMA` | 2 035 | matériau (effet, paramètres, textures) — vérifié |
| `PSI` | 1 545 | objet posable : un `.P3D` + ses matériaux — vérifié, voir [p3d.md](p3d.md) |
| `PRO` | 1 375 | géométrie procédurale précalculée (routes, murs, talus, trottoirs par tuile) |
| `P3D` | 1 277 | maillage 3D (RIFF) — vérifié, voir [p3d.md](p3d.md) |
| `CFG` | 262 | config de tuning |
| `PAN` | 204 | animation |
| `PFX` | 169 | effet / shader |
| `PLM` | 150 | scène — vérifié, voir [plm.md](plm.md) |
| `PPF` | 107 | archétype / prefab (`ARCHETYPES:/...`), XML — vérifié pour les motos, voir [../motos.md](../motos.md) |
| `SSB` | 96 | non identifié |
| `LUA` | 74 | script Lua en texte clair — vérifié |
| `UIML` | 54 | page d'interface |
| `TYR` | 52 | réglage de pneu, XML — vérifié, voir [../motos.md](../motos.md) |
| `PSK` | 49 | atlas de textures d'interface |
| `XML` | 47 | machines à états, post-process, animations d'UI |
| `DYN` | 42 | dynamique de moto et base des pneus, XML — vérifié, voir [../motos.md](../motos.md) |
| `PST` | 26 | végétation (SpeedTree) |
| `PMC` | 26 | matériau physique |
| `PKFX` | 24 | effet de particules (PopcornFX) |
| `UIBK`, `PKAT` | 16 chacun | interface / particules |
| `PLOC` | 14 | localisation (une par langue) |
| `PAR` | 10 | contrôleur d'animation |
| `BIN` | 8 | non identifié |
| `PFT` | 4 | police |
| `KSS`, `PLA` | 2 chacun | styles d'interface / non identifié |
| `DDS`, `TTF`, `FNT`, `FLS`, `GIS`, `VSB`, `VIB` | 1 chacun | divers (`GIS` = `INSTANCETYPES.GIS` du niveau) |

## En vrac sur le disque

| Ext. | Nombre | Nature |
|---|---|---|
| `PACLOG` | 375 | liste de fichiers — voir [paclog.md](paclog.md) |
| `PWS` | 104 | terrain streamé — voir [pws.md](pws.md) |
| `bank` | 25 | banque FMOD |
| `DAT` | 11 | marqueurs de dossier et configs chiffrées — voir [settings-dat.md](settings-dat.md) |
| `mp4` | 5 | vidéo |
| `PKG` | 3 | archive — voir [ppkg.md](ppkg.md) |
