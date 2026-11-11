# Format PWS (`.PWS`)

Données de terrain streamées, une par tuile :
`TT3/WIN32/LEVELS/IOM_SNAEFELL/TILE_Xnn/TILE_Xnn_Ynn/IOM_SNAEFELL.PWS`.

104 fichiers, de 26 Mo à 96 Mo. Ils sont **en vrac sur le disque**, pas dans les PKG.

**État : très partiel.** On sait que c'est un conteneur de flux zlib ; le contenu des
flux n'est pas décodé.

## Ce qui est observé

En-tête de 0x20 octets, puis un premier flux zlib (octets `78 01`) à l'offset 0x20.

Exemple `TILE_X02_Y08` (26 420 687 octets) :

```
12 00 01 00 00 00 cb e5 92 01 77 7f d2 00 7f bf
52 01 c3 d4 d1 00 20 00 00 00 83 df 92 01 cd ab
```

| Offset | Lecture proposée |
|---|---|
| 0x00 | u16 = 0x12 (version ?), u16 = 1 |
| 0x06… | plusieurs u32 non alignés, de l'ordre de la taille du fichier (tailles ou offsets de sections) |
| 0x16 | u32 = 0x20 = offset du premier flux |
| 0x1E | `cd ab` (marqueur ?) |

- Le premier flux fait 18 228 octets compressés et 80 573 décompressés ; il commence
  par des flottants (`00 00 80 3f` = 1.0).
- Les flux ne sont pas collés : il y a des octets entre deux flux (en-têtes de bloc
  probables). Le flux suivant commence à 0x4754 dans cet exemple.
- Le motif `78 01` apparaît 516 fois dans ce fichier (borne haute du nombre de flux,
  le motif pouvant apparaître par hasard dans des données compressées).

## Côté moteur

La classe qui les lit est `PlayAll::Game::WorldStreamer`. Ses méthodes indiquent ce
qu'une tuile contient :

- `GetHeightmap`, `GetHeightmapReferent` — relief
- `GetMaskMap` — masque des couches de terrain (herbe, gravier, bitume…)
- `GetNormalMap`
- `GetBiomeMap`, `GetBiomeIDHash` — répartition de la végétation
- `GetChunkPerTile` — une tuile est subdivisée en chunks

Les couches de terrain elles-mêmes (textures, matériau physique) sont déclarées dans
le niveau principal par des `TerrainLayerComponent`, voir [plm.md](plm.md).

À noter : `Engine.UseHeightmap = false` et `Engine.UseStreaming = true` dans la config
moteur ([settings-dat.md](settings-dat.md)). Le niveau principal référence aussi des
maillages `DATA:/GRAPH/PROPS/TERRAIN/HEIGHTMAP_xx_yy.PSI`. Le lien entre ces maillages
et les PWS reste à établir.

## À faire

1. Décoder l'en-tête et la table des blocs (ce qu'il y a entre les flux).
2. Identifier quel flux est la heightmap, le masque, la normal map, la biome map.
3. Lire `WorldStreamer` dans le code décompilé pour confirmer les tailles et formats.
