# Arborescence de l'installation

Chemins relatifs au dossier `TT3/` (16 Go, 714 fichiers).

```
TT3/
├── TT3.exe                  exécutable principal (exporte ses symboles C++)
├── *.dll                    fmod, PhysX, Steam, EOS, sentry, CrashRpt, Ansel…
├── imgui.ini                le jeu embarque Dear ImGui (fenêtre [Debug])
├── Common/                  racine du lecteur virtuel COMMON:/
│   ├── Settings/
│   │   ├── DUMMYS.DAT       config moteur Lua chiffrée (table Engine)
│   │   ├── DUMMYCM.DAT      mapping des chunks PKG, chiffré
│   │   └── DUMMYCL.DAT      ContentLocks, chiffré
│   └── Archetypes/, Engine/, FX/, Tuning/   vides (un DUMMY.DAT de 2 octets)
├── Settings/DUMMY.DAT       2 octets ("nt"), simple marqueur de dossier
└── WIN32/                   racine du lecteur virtuel DATA:/
    ├── PKG/CHUNK_0/         3 archives PPKG, 10,3 Go (17,3 Go décompressés)
    ├── PACLOG/              375 listes de fichiers en texte
    ├── LEVELS/IOM_SNAEFELL/ 104 fichiers .PWS (terrain streamé, un par tuile)
    ├── Sounds/              banques FMOD (.bank) + GUIDs.txt
    ├── Movies/              vidéos .mp4 (logos, intro)
    └── Engine/, Save/       vides
```

## Ce qui est en vrac et ce qui est dans les PKG

En vrac sur le disque :
- les `.PWS` (terrain), les `.bank` (son), les `.mp4`, les `.PACLOG`, les `DUMMY*.DAT`.

Dans les PKG : tout le reste (21 758 fichiers), dont les scripts Lua, les `.PLM`,
les modèles, textures, configs. Les noms dans les PKG commencent par `COMMON\` ou
`WIN32\`, c'est-à-dire exactement les deux dossiers ci-dessus : un fichier extrait
à la racine de `TT3/` se retrouve au chemin que le moteur attend.

Voir [moteur/vfs.md](moteur/vfs.md) pour la correspondance lecteurs virtuels / disque
et [formats/ppkg.md](formats/ppkg.md) pour les archives.

## Les fichiers DUMMY.DAT

Deux sortes à ne pas confondre :
- `DUMMY.DAT` de 2 octets : sans contenu utile, ils servent à ce que le dossier existe.
- `Common/Settings/DUMMYS.DAT`, `DUMMYCM.DAT`, `DUMMYCL.DAT` : de vrais fichiers Lua
  chiffrés, voir [formats/settings-dat.md](formats/settings-dat.md).
