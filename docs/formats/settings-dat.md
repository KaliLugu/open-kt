# Configs chiffrées `DUMMY*.DAT`

Trois fichiers dans `TT3/Common/Settings/` sont des scripts Lua chiffrés :

| Fichier | Taille | Contenu |
|---|---|---|
| `DUMMYS.DAT` | 22 881 | config moteur : table `Engine` et ses sous-tables |
| `DUMMYCM.DAT` | 650 | table `CHUNKS` : répartition des PACLOG dans les PKG |
| `DUMMYCL.DAT` | 322 | table `ContentLocks` |

Le moteur ouvre `COMMON:/SETTINGS/DUMMYS.DAT` explicitement.

## Chiffrement

XOR octet à octet avec une clé de 32 caractères qui se répète, en partant du début du
fichier :

```
14F5FsyDFFUC4NVANPpYggyakreWkJfy
```

La clé est en clair dans l'exe et utilisée par
`PlayAll::Core::VirtualFile::EncryptDecrypt`. L'opération est symétrique : la même
fonction chiffre et déchiffre. Aucune somme de contrôle n'a été vue dans cette fonction.

Vérifié : déchiffrer puis rechiffrer `DUMMYS.DAT` redonne le fichier d'origine à
l'octet près. Outil : `tools/settings_crypt.pl`.

**Testé en jeu** : un `DUMMYS.DAT` déchiffré, modifié puis rechiffré est accepté par
le jeu et les changements sont pris en compte. Il n'y a donc pas de contrôle
d'intégrité sur ce fichier, et sa taille peut changer.

Les trois fichiers utilisent la même clé. Les autres `DUMMY.DAT` de l'installation
(2 octets, `6e 74`) ne sont pas des fichiers chiffrés mais de simples marqueurs de
dossier.

## DUMMYS.DAT — table `Engine`

Extraits utiles (numéros de ligne du fichier déchiffré) :

```lua
Engine =
{
	ShowGameVersion = false,
	ShowCameraPos = true,
	GameVersion = "MS0",
	UnitScale = 1,              -- 1 unité = 1 mètre
	UseHeightmap = false,
	UseStreaming = true,
	UseContentLocks = true,
	AllowRenderDocCapture = false,
	...
}
Engine.Editor = { NearClip = 0.1, FarClip = 25000.0, SkipRoadBuild = false }
Engine.Device = { ... PC = { DirectXVersion = 11, ScreenMode = "Borderless", ... } }
Engine.UsePkg = true;                    -- ligne 699
Engine.MenuDebugTheme = "Dark";          -- ligne 1013
Engine.AllowMenuDebug = false;           -- ligne 1014
Engine.AllowLoadingInfoDebug = false;    -- ligne 1015
```

Le fichier définit aussi une table `Game` (ligne 1057) :

```lua
Game =
{
	IsDemo = false,
	IsTrialFullSwitchable = false,
	MainLevel = "DATA:/LEVELS/MAIN/MAIN.PLM",
	--MainLevels = { ".../MAIN/MAIN.PLM", ".../MAIN_SNOW/MAIN_SNOW.PLM", ".../MAIN_GRAVEL/MAIN_GRAVEL.PLM" },
	LiveryManager = true,
	...
}
```

`DATA:/LEVELS/MAIN/MAIN.PLM` n'existe pas dans les PKG (reste d'un autre jeu du
studio, comme la ligne commentée) ; le monde réel est `IOM_SNAEFELL`.

Autres sous-tables présentes : `Engine.BugReporter`, `Engine.QAVersion`,
`Engine.Script`, `Engine.Pathfind`, réglages par plateforme (PS4, PS5, XBoxOne,
Scarlett, Switch, PC), options de debug (`DisplayUXEditor`, `ShowChunkLoaderDebug`,
`DrawActivityManagerDebugWindow`, toutes à `false`).

Options à explorer pour le modding :
- `Engine.UsePkg` : à `false`, les PKG ne sont pas montés (voir [../moteur/vfs.md](../moteur/vfs.md)).
- `Engine.AllowMenuDebug` : active probablement le menu de debug du moteur
  (`Core::MenuDebug`, très présent dans le code). Non testé.

## DUMMYCM.DAT — table `CHUNKS`

```lua
CHUNKS =
{
	CHUNK_0 =
	{
		ChunkId = 0,
		Paclogs =
		{
			"DATA:/PACLOG/LEVELS/ENTRY/ENTRY.PACLOG",
			"DATA:/PACLOG/CUSTOMPAC/VEHICLES/*.PACLOG",
			"DATA:/PACLOG/CUSTOMPAC/VEHICLES/COMPONENTS/*.PACLOG",
			"DATA:/PACLOG/CUSTOMPAC/RIDERS/*.PACLOG",
			"DATA:/PACLOG/ENGINE.PACLOG",
			"DATA:/PACLOG/LEVELS/IOM_SNAEFELL/IOM_SNAEFELL.PACLOG",
		},
		SeparatePkgs = false,
	},
}
```

Un seul chunk : tout le jeu est dans `CHUNK_0`.

## DUMMYCL.DAT — table `ContentLocks`

```lua
ContentLocks =
{
	AvailableMenu = { },
	AvailableRaces = { },
	AvailableBikes = { },
	FirstSectionAvailable  = 0,
	LastSectionAvailable   = 11,
	LeaderboardPostEnabled = true,
	AllowTutorialPrompt    = true,
}
```

Sert au verrouillage de contenu (démo, téléchargement partiel), activé par
`Engine.UseContentLocks`.
