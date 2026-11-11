# open-kt

Rétro-ingénierie de **TT Isle of Man – Ride on the Edge 3**, 

Le jeu tourne sur le KT Engine de Kylotonn (appelé `PlayAll` dans le code). Ce dépôt
rassemble ce qu'on a compris de ses formats de fichiers et de son fonctionnement,
ainsi que quelques scripts pour extraire et inspecter les données.

> Projet amateur, sans lien avec Kylotonn ni Nacon. Le dépôt ne contient aucun fichier
> du jeu : il faut posséder sa propre copie pour utiliser les outils.

## Où en est le projet

C'est un travail en cours. Pour l'instant, tout repose sur de l'analyse statique
(fichiers du jeu et décompilation Ghidra). Seule la modification de la config
chiffrée a été **testée en jeu** pour l'instant.

| Sujet | État |
|---|---|
| Archives `.PKG` | format compris, extraction fonctionnelle |
| Configs chiffrées `DUMMY*.DAT` | déchiffrement et rechiffrement fonctionnels, modification testée en jeu |
| Chargement d'un fichier modifié | méthode trouvée dans le code, à valider en jeu |
| Scènes `.PLM` | format décodé, lecture et modification de valeurs possibles, à valider en jeu |
| Terrain `.PWS` | on sait que ce sont des flux zlib, pas plus |
| Modèles, textures, routes (`.P3D`, `.PTX`, `.PRO`…) | pas encore regardés |

Chaque page de la doc précise ce qui est vérifié et ce qui n'est qu'une hypothèse.

## Par où commencer

- Pour comprendre comment la map est organisée : [map.md](map.md)
- Pour essayer de modifier quelque chose : [modding.md](modding.md)
- Pour extraire les fichiers du jeu : [outils.md](outils.md)

## Démarrage rapide

Il faut Perl (aucun module à installer) et une copie du jeu dans un dossier `TT3/` à
la racine du dépôt.

```sh
# lister le contenu d'une archive
perl tools/pkglist.pl TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG

# extraire tous les scripts Lua
perl tools/pkgextract.pl TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG out '\.LUA$'

# déchiffrer la config du moteur
perl tools/settings_crypt.pl TT3/Common/Settings/DUMMYS.DAT DUMMYS.lua
```

## Documentation

**Le jeu**
- [arborescence.md](arborescence.md) — ce qu'on trouve dans le dossier d'installation
- [map.md](map.md) — circuits, tuiles, terrain, météo : qui contient quoi
- [modding.md](modding.md) — faire charger un fichier modifié par le jeu

**Les formats**
- [formats/ppkg.md](formats/ppkg.md) — archives `.PKG`
- [formats/paclog.md](formats/paclog.md) — listes de ressources `.PACLOG`
- [formats/plm.md](formats/plm.md) — scènes et niveaux `.PLM`
- [formats/pws.md](formats/pws.md) — terrain streamé `.PWS`
- [formats/settings-dat.md](formats/settings-dat.md) — configs chiffrées `DUMMY*.DAT`
- [formats/extensions.md](formats/extensions.md) — toutes les extensions rencontrées

**Le moteur**
- [moteur/vfs.md](moteur/vfs.md) — système de fichiers virtuel (`DATA:/`, `COMMON:/`, PKG)
- [moteur/lua.md](moteur/lua.md) — Lua (LuaPlus) et les bases de données du jeu
- [moteur/code-decompile.md](moteur/code-decompile.md) — se repérer dans le code décompilé

**Les outils**
- [outils.md](outils.md) — mode d'emploi des scripts de `tools/`

## Travailler sur le code du moteur

L'analyse du binaire se fait avec [Ghidra](https://ghidra-sre.org/). `TT3.exe` exporte
ses symboles C++, ce qui donne les vrais noms de la plupart des classes et méthodes
du moteur dès l'import : la doc désigne donc les fonctions par leur nom et leur
adresse, qu'on retrouve directement dans Ghidra.

## Contribuer

Les corrections et les découvertes sont les bienvenues, en particulier :

- un retour de test en jeu sur les méthodes de [modding.md](modding.md) ;
- un retour de test en jeu sur un `.PLM` modifié avec `tools/plm.pl` ;
- le décodage des `.PWS`.

Merci d'indiquer comment une information a été obtenue (lue dans le code, observée
dans un fichier, testée en jeu), pour que la doc reste fiable.
