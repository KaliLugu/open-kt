# Outils (`tools/`)

Scripts Perl sans dépendance externe (Perl de base suffit). Lancer depuis la racine
du repo.

## `pkglist.pl` — lister un PKG

```
perl tools/pkglist.pl TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG
```

Sortie tabulée, une ligne par fichier :
`nom  offset  taille_compressée  taille_décompressée  mode  crc`.
Les informations générales (version, nombre d'entrées) sortent sur stderr.

## `pkgextract.pl` — extraire

```
perl tools/pkgextract.pl FICHIER.PKG DOSSIER_SORTIE [regex]
```

- `regex` (optionnelle, insensible à la casse) filtre sur le nom interne.
- Les `\` des noms deviennent des `/` ; l'arborescence est recréée.
- Avertit si la taille obtenue diffère de celle de l'index.

Exemples :

```
# tous les scripts et configs texte
perl tools/pkgextract.pl TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG out '\.(LUA|CFG|XML)$'
# tous les PLM
perl tools/pkgextract.pl TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG out '\.PLM$'
```

Le décodeur LZ4 est en Perl pur : correct mais lent sur les gros fichiers (textures).
Vérifié sur 821 fichiers.

## `pkghide.pl` — masquer / restaurer une entrée

```
perl tools/pkghide.pl FICHIER.PKG 'COMMON\DATABASE\TRACKS.LUA'
perl tools/pkghide.pl FICHIER.PKG 'COMMON\DATABASE\TRACKS.LUA' --restore
```

Remplace le premier caractère du nom par `#` dans l'index (un octet écrit sur place).
Accepte `/` ou `\` et n'importe quelle casse. **Modifie le PKG** : voir
[modding.md](modding.md). Testé sur une copie de l'index seulement, restauration
identique à l'octet.

## `settings_crypt.pl` — chiffrer / déchiffrer les `DUMMY*.DAT`

```
perl tools/settings_crypt.pl TT3/Common/Settings/DUMMYS.DAT DUMMYS.lua   # déchiffre
perl tools/settings_crypt.pl DUMMYS.lua DUMMYS.DAT                       # rechiffre
```

Opération symétrique. Voir [formats/settings-dat.md](formats/settings-dat.md).

## `plmstr.pl` — inspecter un PLM

```
perl tools/plmstr.pl chemin/vers/FICHIER.PLM
```

Affiche l'en-tête (magic, version, drapeau, 9 flottants, 16 entiers) puis toutes les
chaînes de la table. Pratique avec `grep` :

```
perl tools/plmstr.pl X.PLM | grep '::'        # classes de composants
perl tools/plmstr.pl X.PLM | grep ':/'        # ressources référencées
```

Voir [formats/plm.md](formats/plm.md).

## Outils qui manquent

- lecteur / éditeur complet de PLM ;
- décodeur de PWS ;
- réécriture de PKG.
