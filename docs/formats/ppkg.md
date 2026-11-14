# Format PPKG (`.PKG`)

Archives du jeu : `TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG` à `PART0002.PKG`.

| Archive | Entrées | Taille de l'index |
|---|---|---|
| `CHUNK_0_PART0000.PKG` | 3 254 | 457 021 |
| `CHUNK_0_PART0001.PKG` | 14 541 | 2 259 842 |
| `CHUNK_0_PART0002.PKG` | 3 963 | 720 680 |

Tout est en little-endian. Format vérifié : l'index se parcourt jusqu'à sa fin exacte
sur les trois archives et 821 fichiers extraits ont la taille annoncée.

## En-tête (0x30 octets)

| Offset | Type | Contenu |
|---|---|---|
| 0x00 | char[4] | `PPKG` |
| 0x04 | u32 | version = 2 |
| 0x08 | u32 | nombre d'entrées |
| 0x0C | u32 | taille de l'index en octets |
| 0x10 | 32 octets | zéros |

L'index commence à 0x30. Les données commencent à `0x30 + taille de l'index`.

## Entrée d'index (taille variable)

| Type | Contenu |
|---|---|
| u32 | longueur du nom |
| char[n] | nom, majuscules, séparateur `\`, sans zéro final (ex. `COMMON\TUNING\PHYSIC.LUA`) |
| u32 | valeur de hachage, rôle non déterminé (probablement liée au nom) |
| u64 | offset absolu des données dans l'archive |
| u64 | date au format FILETIME Windows |
| u64 | taille compressée |
| u64 | taille décompressée |
| u32 | mode de compression : `2` = LZ4, `0` = brut |
| u32 | CRC32 des données stockées (entre `PKGB` et `PKGE`) |
| u32 | CRC32 des données décompressées |
| 32 octets | zéros |

Soit `4 + n + 80` octets par entrée.

Sur les 21 758 entrées, 21 693 sont en mode 2 et 65 en mode 0.

## Données d'un fichier

```
"PKGB"                     4 octets
données stockées           `taille compressée` octets
"PKGE"                     4 octets
```

Les données stockées sont une frame LZ4 standard (magic `04 22 4D 18`) en mode 2, ou
le fichier tel quel en mode 0. Les 8 octets des deux marqueurs ne sont pas comptés
dans la taille compressée.

Les deux CRC32 sont le CRC standard (celui de zlib). Vérifié : le CRC des données
stockées correspond sur 300 entrées, et `pkgextract.pl` contrôle celui des données
décompressées à chaque extraction.

Le mode 0 sert pour 65 petits fichiers (`.PMC`, `.PMA`, `.LUA`, `.CFG`…).

## Recherche d'un fichier par le moteur

`PathPluginPkg::GetLookupTableEntry` met le chemin demandé en majuscules, calcule
`crnlib::fast_hash` dessus et cherche dans une table de hachage construite au
chargement, avec comparaison finale par `StrCmp` sur le nom. La recherche se fait donc
**par nom**, pas par le CRC stocké dans l'index. Conséquence : changer un caractère
d'un nom dans l'index rend l'entrée introuvable (voir [../modding.md](../modding.md)).

## Points ouverts

- Rôle du premier u32 de l'entrée. Ce n'est ni un CRC32, ni un Adler32, ni un FNV du nom
  ou des données sous les formes essayées.
- Le moteur vérifie-t-il les CRC à la lecture ? (Modifier l'index pour masquer une entrée
  ne déclenche en tout cas aucun contrôle : testé en jeu.)
- Le code référence `DATA:/PKG/CHUNK_%d/CHUNK_%d.PKG`, alors que les fichiers
  s'appellent `CHUNK_0_PART000n.PKG` : le montage liste en fait le dossier
  `DATA:/PKG/CHUNK_0` et monte tout ce qu'il y trouve (`GameEngine::MountPkgs`).

## Outils

`tools/pkglist.pl`, `tools/pkgextract.pl`, `tools/pkghide.pl` — voir [../outils.md](../outils.md).
