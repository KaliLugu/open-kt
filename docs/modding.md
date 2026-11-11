# Faire charger un fichier modifié

**Aucune de ces méthodes n'a été testée en jeu.** Elles découlent de la lecture du
code (voir [moteur/vfs.md](moteur/vfs.md)). Faire une sauvegarde avant toute écriture
dans `TT3/`.

Rappel du principe : le moteur cherche un fichier d'abord dans les PKG (par nom), puis
dans les dossiers du disque. `DATA:/x` correspond à `TT3/WIN32/x`, `COMMON:/x` à
`TT3/Common/x`.

## Méthode 1 — masquer l'entrée dans le PKG (recommandée)

On change un caractère du nom dans l'index du PKG. Le moteur ne trouve plus le fichier
dans l'archive et prend la version en vrac.

1. Trouver dans quel PKG est le fichier :
   ```
   perl tools/pkglist.pl TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG | grep TRACKS.LUA
   ```
2. L'extraire à la racine de `TT3/` (le chemin interne `COMMON\DATABASE\TRACKS.LUA`
   donne `TT3/COMMON/DATABASE/TRACKS.LUA`) :
   ```
   perl tools/pkgextract.pl TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG TT3 'DATABASE\\TRACKS\.LUA$'
   ```
3. Modifier le fichier extrait.
4. Masquer l'entrée :
   ```
   perl tools/pkghide.pl TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG 'COMMON\DATABASE\TRACKS.LUA'
   ```
5. Pour revenir en arrière : même commande avec `--restore`, et supprimer le fichier en vrac.

Avantages : un seul octet modifié dans le PKG, réversible, on n'extrait que ce qu'on change.

Points à surveiller :
- Casse des dossiers : les noms des PKG sont en majuscules (`COMMON`), le dossier
  existant s'appelle `Common`. Sans importance sous Windows ; sous Linux/Proton,
  fusionner dans le dossier existant.
- Si le jeu refuse de démarrer, soupçonner un contrôle d'intégrité des PKG (champs
  CRC/hash de l'index dont le rôle n'est pas établi) ou Steam qui répare les fichiers.

## Méthode 2 — désactiver les PKG

1. Déchiffrer la config :
   ```
   perl tools/settings_crypt.pl TT3/Common/Settings/DUMMYS.DAT DUMMYS.lua
   ```
2. Passer `Engine.UsePkg = true;` à `false`.
3. Rechiffrer vers `DUMMYS.DAT` (même commande, sens inverse).
4. Extraire **les trois PKG en entier** dans `TT3/` (17,3 Go).

Inconvénients : volume, et l'extracteur Perl est lent sur une telle quantité. Le jeu
n'a peut-être jamais été lancé ainsi en version commerciale : des fichiers peuvent
manquer ou d'autres options peuvent être nécessaires.

Intérêt : c'est le mode de travail des développeurs ; tout devient modifiable
librement. La même manipulation permet d'essayer `Engine.AllowMenuDebug = true`.

## Méthode 3 — réécrire le PKG (pas outillée)

Remplacer les données dans l'archive et corriger l'index (offsets, tailles). Le mode de
compression `0` (brut) éviterait d'avoir à compresser en LZ4. Non réalisé : la
méthode 1 donne le même résultat sans risque sur les offsets, et le rôle des champs
CRC/hash n'est pas connu.

## Premier essai conseillé

Valider la chaîne avec le changement le plus simple et le plus visible :

1. méthode 1 sur `COMMON\DATABASE\TRACKS.LUA` ;
2. changer `LengthKm` ou `Order` d'un circuit ;
3. lancer le jeu et regarder l'écran de sélection des circuits.

Si la valeur change, la méthode fonctionne pour tous les fichiers des PKG. Ensuite
seulement, passer aux PLM (voir [formats/plm.md](formats/plm.md)).

## Cas des `.PWS`

Ils sont déjà en vrac : aucun contournement n'est nécessaire, il suffit de remplacer
le fichier. Le blocage est le format, pas le chargement
(voir [formats/pws.md](formats/pws.md)).

## Précautions

- Sauvegarder `DUMMYS.DAT` et noter chaque entrée masquée.
- Une vérification des fichiers par Steam annulera les modifications des PKG et de
  `DUMMYS.DAT`.
- Rester hors ligne pour les essais : le jeu a des classements en ligne
  (`LeaderboardPostEnabled`, services KtOS / Nacon).
