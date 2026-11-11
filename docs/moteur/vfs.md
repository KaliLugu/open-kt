# Système de fichiers virtuel

Classe centrale : `PlayAll::Core::FileSystemController` (singleton), source d'origine
`S:\TT3\PlayAll\Code\Runtime\Common\PlayAll\Common\Core\VirtualFileSystem.cpp`.

## Lecteurs virtuels

Le jeu n'utilise que des chemins virtuels de la forme `LECTEUR:/chemin` :

| Lecteur | Dossier disque / préfixe dans les PKG |
|---|---|
| `DATA:/` | `WIN32/` |
| `COMMON:/` | `Common/` |
| `ARCHETYPES:/` | vu dans les PACLOG ; les fichiers sont sous `COMMON\ARCHETYPES\` dans les PKG |
| `TUNING:/` | vu dans les PACLOG ; les fichiers sont sous `COMMON\TUNING\` dans les PKG |

La correspondance `DATA:` → `WIN32` et `COMMON:` → `Common` est déduite des chemins
(les `.PWS` sont chargés depuis `WIN32/LEVELS/...`, `DUMMYS.DAT` via
`COMMON:/SETTINGS/DUMMYS.DAT`). Les alias sont enregistrés par
`FileSystemController::AddAlias` ; un lecteur peut avoir plusieurs dossiers physiques.

## Plugins de chemin

Chaque source de fichiers est un `PathPlugin` enregistré dans le contrôleur :

- un plugin « physique » pour les dossiers du disque (`PhysicalFileSystem`, `PhysicalFile`) ;
- `PathPluginPkg` pour chaque archive `.PKG` ;
- `PathPluginInspector` (rôle non étudié).

`FileSystemController::Mount(chemin, device)` :
- si le chemin est un fichier d'extension `.PKG`, crée un `PathPluginPkg` et lui fait
  lire l'index (`PathPluginPkg::Parse`, qui vérifie le magic `PPKG`) ;
- sinon crée un plugin physique sur le dossier ;
- refuse un double montage (code `0x10015`) ;
- appelle `PathPlugin::Register`.

**`PathPlugin::Register` insère le nouveau plugin en tête de liste.** Le dernier monté
est donc consulté en premier.

## Ouverture d'un fichier

`FileSystemController::OpenFile` → `AccessFile` :

1. extrait le lecteur du chemin virtuel et retrouve ses alias physiques ;
2. pour chaque alias, parcourt les plugins dans l'ordre de la liste ;
3. appelle `Access` sur chaque plugin ; le premier qui répond « trouvé » gagne ;
4. si aucun ne répond : erreur `0x1000c` et le message
   `File %s not accessible. Please check file existence with Exist() before opening…`.

`PathPluginPkg::Access` renvoie `0x10017` (introuvable) quand le nom n'est pas dans sa
table, ce qui laisse la main au plugin suivant.

### Conséquence

Les PKG étant montés après les dossiers physiques, ils passent **devant**. Pour un
chemin donné :

- présent dans un PKG → version du PKG, même s'il existe un fichier en vrac ;
- absent des PKG → fichier en vrac (c'est le cas normal des `.PWS`).

C'est la base des deux méthodes de [../modding.md](../modding.md). Cet ordre est lu
dans le code décompilé, pas observé en jeu.

## Montage des PKG et option `UsePkg`

Trois endroits lisent `Engine.UsePkg` dans la table Lua `Engine`
(définie dans `DUMMYS.DAT`, voir [../formats/settings-dat.md](../formats/settings-dat.md)) :

- `PlayAll::Game::GameEngine::MountPkgs` : si `UsePkg` est vrai, liste
  `DATA:/PKG/CHUNK_0` et monte chaque fichier trouvé avec `MountAsync` ;
- `PlayAll::Game::InstallationManagerBase::Create` : liste `DATA:/PKG`, cherche les
  dossiers `CHUNK_*` et les monte ;
- `PlayAll::Game::DLCManagerBase`.

Si la clé `UsePkg` n'existe pas ou n'est pas un booléen, la valeur retenue est `false`.
Avec `UsePkg = false`, aucun PKG n'est monté et tout doit exister en vrac.

## Autres éléments repérés

- `MountAsync` : montage en tâche de fond via `TaskManager`.
- Cache de fichiers ouverts : `AddCachedFileEntry`, `RemoveCachedFileEntry`,
  `CachedFilePurge`.
- Avertissement `**/!\** OPENING FILE OUTSIDE ASYNCLOADING : %s` quand un fichier est
  ouvert hors du chargement asynchrone.
- `SetPacLogGen` : génération de PACLOG à l'exécution (`Data:/RUNTIME_PACLOG`).
