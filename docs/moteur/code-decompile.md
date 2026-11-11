# Repères dans le code décompilé

Le code décompilé vient de Ghidra (File → Export Program, format C/C++). L'export
complet fait environ 120 Mo et n'est pas inclus dans le dépôt.

`TT3.exe` **exporte ses symboles C++** (noms décorés + ordinaux), ce qui donne les
vrais noms de classes et de méthodes pour une grande partie du moteur. Chaque fonction
exportée porte un commentaire du type :

```
// 0xa7e4a0  16666
// ?Mount@FileSystemController@Core@PlayAll@@QEAAHAEBVPath@23@W4StorageDevice@23@@Z
```

Le premier nombre est l'adresse relative (base image `0x140000000`, donc
`0x140a7e4a0` dans Ghidra), le second l'ordinal d'export.

Chercher les fonctions par nom ou par adresse, dans Ghidra ou dans un export.

## Espaces de noms

| Espace | Rôle |
|---|---|
| `PlayAll::Core` | bas niveau : fichiers, chaînes, mémoire, tâches, Lua, menu debug |
| `PlayAll::Game` | moteur de jeu : `GameEngine`, `WorldStreamer`, installation, DLC |
| `PlayAll::GameServices` | composants de scène (ceux qu'on retrouve dans les PLM) |
| `GamePlay` | logique de course (`GPRaceInitializerComponent`…) |
| `RWLib` | couche jeu au-dessus du moteur (`RWPacLogSingleResourceLoader`…) |
| `LuaPlus`, `LPCD` | liaison Lua |
| `crnlib` | bibliothèque Crunch (son `fast_hash` sert pour la table des PKG) |

Chemins sources d'origine visibles dans les messages de log : `S:\TT3\PlayAll\Code\...`
et `S:\TT3\RWLib\Code\Sources\RWLib\...`.

## Fonctions utiles

### Fichiers

| Fonction | Adresse | Rôle |
|---|---|---|
| `Core::FileSystemController::Mount` | `0xa7e4a0` | monte un dossier ou un `.PKG` |
| `Core::FileSystemController::MountAsync` | `0xa7e8b0` | idem en tâche de fond |
| `Core::FileSystemController::AccessFile` | `0xa7a550` | résolution chemin virtuel → plugin |
| `Core::FileSystemController::OpenFile` | `0xa7ed80` | ouverture |
| `Core::PathPlugin::Register` | `0xa59e90` | insertion en tête de liste |
| `Core::PathPluginPkg::Access` | `0xa5ba60` | présence d'un fichier dans un PKG |
| `Core::PathPluginPkg::GetLookupTableEntry` | `0xa5bff0` | recherche par nom |
| `Core::PathPluginPkg::Parse` | — | lecture de l'index, test du magic `0x474b5050` |
| `Core::PathPluginPkg::ReadAtPos`, `OpenFile` | — | lecture des données |
| `Core::VirtualFile::EncryptDecrypt` | `0xa78230` | XOR des `DUMMY*.DAT` |
| `Core::FileSystemController::SetPacLogGen` | `0xa7f5d0` | génération de PACLOG |

### Démarrage / contenu

| Fonction | Adresse | Rôle |
|---|---|---|
| `Game::GameEngine::MountPkgs` | `0x74d030` | lit `Engine.UsePkg`, monte `DATA:/PKG/CHUNK_0` |
| `Game::InstallationManagerBase::Create` | `0x7a2a90` | chunks, `LoadMappingFile`, menu debug « InstallationManager » |
| `Game::DLCManagerBase` | — | lit aussi `Engine.UsePkg` |

### Monde

`Game::WorldStreamer` : `GetHeightmap`, `GetMaskMap`, `GetNormalMap`, `GetBiomeMap`,
`GetBiomeIDHash`, `GetChunkPerTile`, `AddTotalShifted`, `GetInstance`.

## Chaînes pratiques pour se repérer

- `"DATA:/PKG/CHUNK_%d"`, `"DATA:/PKG/CHUNK_0/CHUNK_0.PKG"`, `".PKG"`
- `"COMMON:/SETTINGS/DUMMYS.DAT"`
- `"14F5FsyDFFUC4NVANPpYggyakreWkJfy"` (clé XOR)
- `"UsePkg"`, `"Engine"`
- `"Data:/RUNTIME_PACLOG"`
- `"DATA:/LEVELS/MAIN/MAIN.PLM"`

## Options de ligne de commande vues

`-windowed`, `-shortenfilename`, `-silent`, `-internal`, `-PathCamera`,
`-trainerchallengeid`, `-epicapp`, `-epicenv`, `-epicusername`, `-epicuserid`,
`-epiclocale`. Leur effet n'a pas été étudié.

## Menu de debug

`Core::MenuDebug` (`OpenDirectory`, `AddBool`, `CloseDirectory`) est appelé partout :
le moteur construit un menu de debug hiérarchique (« InstallationManager »,
« Engine »…). Il est conditionné par `Engine.AllowMenuDebug` dans `DUMMYS.DAT`
(à `false` en version commerciale). Le jeu embarque aussi Dear ImGui (`imgui.ini`).
