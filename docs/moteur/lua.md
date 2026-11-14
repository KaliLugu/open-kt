# Lua dans le moteur

Le moteur embarque Lua via **LuaPlus** (`LuaPlus::LuaObject`, helpers `LPCD::Get`),
encapsulé par le singleton `PlayAll::Core::LuaScript`. Le code appelle directement
l'API C (`lua_getfield`, `lua_type`, `lua_settop`, `lua_gettop`).

## À quoi sert Lua ici

D'après les 74 fichiers `.LUA` des PKG, Lua sert surtout de **format de données** :
des tables déclarées en clair, lues par le C++. Peu ou pas de logique de jeu.

Lecture type côté C++ :

```
LuaScript::OpenMultiTable("Engine")
lua_getfield(L, top, "UsePkg")
lua_type(...) == 1 (booléen) ? LPCD::Get(...) : valeur par défaut
LuaScript::CloseTable()
```

Tous les `.LUA` des PKG sont en **texte source**, pas en bytecode.

## Fichiers

### Config moteur (hors PKG, chiffrée)

`Common/Settings/DUMMYS.DAT`, `DUMMYCM.DAT`, `DUMMYCL.DAT` — voir
[../formats/settings-dat.md](../formats/settings-dat.md).

### Bases de données — `COMMON\DATABASE\*.LUA`

55 fichiers, une table par fichier. Les plus gros :

| Fichier | Taille | Sujet |
|---|---|---|
| `CAREEREVENTREWARDS.LUA` | 428 Ko | carrière |
| `BIKETEMPLATES.LUA` | 392 Ko | motos |
| `CAREEREVENTS.LUA` | 293 Ko | carrière |
| `CAREERDAYS.LUA` | 191 Ko | carrière |
| `QUICKRACES.LUA`, `RIDERS.LUA` | 181 Ko | courses rapides, pilotes |
| `BIKECONFIGS.LUA`, `COMPONENTS.LUA`, `BIKES.LUA` | ~100 Ko | motos et pièces |
| `POIS.LUA` | 97 Ko | points d'intérêt de la carte |
| `TRACKS.LUA` | 55 Ko | circuits |

Liés aux motos : `BIKES.LUA`, `BIKECONFIGS.LUA`, `BIKETEMPLATES.LUA`, `COMPONENTS.LUA`,
`COMPONENTPROPERTIES.LUA`. Détail dans [../motos.md](../motos.md).

Liés à la map : `TRACKS.LUA`, `TRACKGROUPS.LUA`, `TRACKASPHALTCONSUMPTIONS.LUA`,
`WEATHERTRACKBINDS.LUA`, `WEATHERCONDITIONS.LUA`, `ASPHALTCONDITIONS.LUA`,
`POIS.LUA`, `POITYPES.LUA`. Détail de `TRACKS.LUA` dans [../map.md](../map.md).

### Scripts moteur — `COMMON\ENGINE\SCRIPTS\`

`EDITOR.LUA`, `HUD.LUA`, `INPUTDEBUGACTIONS.LUA`, `PHYSIC.LUA`, `SCREENMANAGER.LUA`,
`THREAD.LUA`, `TRIGGER.LUA`, `VECTOR2.LUA`, `VECTOR3.LUA`, `VECTOR4.LUA`.

### Scripts jeu — `COMMON\SCRIPTS\`

`INPUTACTIONS.LUA`, `INPUTKEYBINDINGS.LUA`, `INPUTPRESETS.LUA`, `LOCALISATION.LUA`
(514 Ko, identifiants `LocalesId.*`), `MASKS.LUA`.

### Divers

`COMMON\TUNING\PHYSIC.LUA` (commence par `Physic.CollisionGroup = { Default = 0, …`),
`COMMON\TUNING\LIVERIES.LUA`, `COMMON\SETTINGS\DLC.LUA`,
`COMMON\POSTPROCESS\COLLISIONEFFECT.LUA`.

## Ce que Lua ne contient pas

La géométrie du monde n'est pas en Lua : elle est dans les `.PLM`, `.PWS`, `.PRO`.
Lua ne fait que pointer dessus (champ `LevelAsset` de `TRACKS.LUA`).
