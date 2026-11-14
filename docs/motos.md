# Configuration des motos

Où sont les réglages des motos et comment ils s'enchaînent.

> **État** : tout ce qui suit vient de la lecture des fichiers extraits des PKG.
> **Rien n'a encore été testé en jeu.** Les points marqués « hypothèse » ne sont pas
> confirmés, même par les fichiers.

Tous ces fichiers sont dans `CHUNK_0_PART0000.PKG` et sont en **texte clair** (XML ou
Lua). Pour les extraire :

```sh
PKG=TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG
perl tools/pkgextract.pl $PKG out '^COMMON\\(TUNING|DATABASE)\\'
perl tools/pkgextract.pl $PKG out '^COMMON\\ARCHETYPES\\GAMEPLAY\\VEHICLES\\'
```

## Les couches

```
BIKES.LUA                           liste des motos
   └─ BikeArchetype ─▶ <CODE>_BIKE.PPF        archétype d'une moto
         ├─ instanceof ─▶ TEMPLATE\TT3_SUPERBIKE.PPF ou TT3_SUPERSPORT.PPF
         │                    └─▶ TEMPLATE\MOTOTT3_TEMPLATE.PPF
         └─ "Physic settings path" ─▶ BIKES\1000\<MODELE>.DYN     physique du modèle
               └─ InstanceOf ─▶ BIKES\BASE\BASE1000.DYN           base de la catégorie
                     └─ InstanceOf ─▶ BIKES\BASE\BASE.DYN         base commune
FACTORIES\TYRES.CFG                 liste des pneus
   └─ DynaPathFront / DynaPathRear ─▶ BIKES\TYRES\*.TYR
         └─ InstanceOf ─▶ FRONTTYREBASE.DYN / REARTYREBASE.DYN
BIKECONFIGS.LUA, COMPONENTS.LUA…    pièces montées et leurs niveaux
```

## Où trouver quoi

Chemins relatifs à `COMMON\` dans le PKG.

| Sujet | Fichier | Contenu |
|---|---|---|
| Physique d'un modèle | `TUNING\BIKES\1000\*.DYN`, `TUNING\BIKES\600\*.DYN` | couple max, régime max, courbe de couple, boîte, centre de masse, débattement |
| Base par catégorie | `TUNING\BIKES\BASE\BASE1000.DYN`, `BASE600.DYN` | masse, aéro, embrayage, ressorts, amortisseurs, vitesse max de simulation |
| Base commune | `TUNING\BIKES\BASE\BASE.DYN` | 547 propriétés, tout ce qui n'est pas redéfini plus haut |
| Pneus | `TUNING\BIKES\TYRES\*.TYR` | grip par surface, chauffe, usure |
| Liste des pneus | `TUNING\FACTORIES\TYRES.CFG` | type, gomme, `.TYR` avant et arrière |
| Archétype | `ARCHETYPES\GAMEPLAY\VEHICLES\<CODE>_BIKE.PPF` | `.DYN` utilisé, aides (ABS, antipatinage), pression des pneus, angle max, caméras, IA, son |
| Liste des motos | `DATABASE\BIKES.LUA` | archétype, modèle 3D, catégorie, marque, fiche technique affichée |
| Pièces | `DATABASE\BIKECONFIGS.LUA`, `BIKETEMPLATES.LUA`, `COMPONENTS.LUA`, `COMPONENTPROPERTIES.LUA`, `COMPONENTPROPERTIESTEMPLATE.LUA` | pièces montées par défaut, emplacements, niveaux, prix |
| Écran de réglages | `TUNING\MBT\MOTORBIKETUNING.CFG`, `TUNING\MBM\TUNINGS\*.CFG` | groupes du menu : suspensions, boîte, pneus, ECU |
| Indice de performance | `TUNING\PERFORMANCEPOINT.CFG` | conversion poids / couple / régime en points |

## Fichiers `.DYN`

XML sans élément racine. La première ligne désigne le parent ; le fichier ne contient
que les propriétés qui changent par rapport à lui.

```xml
<InstanceOf value="DATA:/TUNING/BIKES/BASE/BASE1000.DYN" />
<PlayAll::GameServices::RigidBody>
	<props>
	</props>
</PlayAll::GameServices::RigidBody>
<GamePlay::GPVehicleSDK>
	<props>
		<prop name="Engine Max Omega (rad/s)" value="1560" />
		<prop name="Engine Peak torque" value="117.6" />
		<prop name="Engine torque curve P1" value="0.0000;0.4000" />
		...
		<prop name="Gearbox final ratio" value="4.373" />
		<prop name="Gearbox ratios" value="2.562,2.052,1.714,1.500,1.360,1.269" />
	</props>
</GamePlay::GPVehicleSDK>
<front_left_wheel>
	<GamePlay::GPPhysicWheel>
		<props>
			<prop name="Suspension MaxCompression" value="0.150" />
		</props>
	</GamePlay::GPPhysicWheel>
	<GamePlay::GPTyreGrip>
		<props>
		</props>
	</GamePlay::GPTyreGrip>
</front_left_wheel>
<front_right_wheel> … <rear_left_wheel> … <rear_right_wheel> …
```

Les sections portent le nom d'un composant du moteur (`RigidBody`, `GPVehicleSDK`) ou
d'un acteur enfant de l'archétype (`front_left_wheel`…) contenant ses composants. Les
quatre roues existent bien pour une moto : gauche et droite ont les mêmes valeurs.

### Propriétés principales

| Section | Propriété | Remarque |
|---|---|---|
| `RigidBody` | `Mass` | 280 dans `BASE1000.DYN` |
| `RigidBody` | `CenterOfMassOffset` | |
| `GPVehicleSDK` | `Engine Peak torque` | |
| `GPVehicleSDK` | `Engine Max Omega (rad/s)` | 1560 rad/s ≈ 14 900 tr/min |
| `GPVehicleSDK` | `Engine torque curve P1`…`P12`, `Engine torque curve length` | points `régime;couple`, les deux entre 0 et 1 |
| `GPVehicleSDK` | `Gearbox ratios`, `Gearbox final ratio` | |
| `GPVehicleSDK` | `Gearbox switch time`, `Gearbox down switch time` | |
| `GPVehicleSDK` | `Aero Front Surface`, `Front Aero Downforce(kg) at saturation speed` | |
| `GPVehicleSDK` | `Simulation Max Speed KMH` | 335 dans `BASE1000.DYN` |
| `GPVehicleSDK` | `Default Center Of Mass`, `Rider Center Of Mass` | |
| `GPVehicleSDK` | `Category`, `Vehicle class` | `Superbike`, `CLASS_BIKE` |
| `GPPhysicWheel` | `Suspension Spring Strength`, `Suspension compression Damping`, `Suspension extension Damping` | |
| `GPPhysicWheel` | `Suspension MaxCompression`, `Suspension Preload`, `Wheel Radius` | |

Format des valeurs :
- vecteur : `x;y;z` ;
- liste : `a,b,c` ;
- courbe : `-3.40282e+38,-3.40282e+38,N,x1;y1,x2;y2,…` avec `N` le nombre de points
  (le rôle des deux premiers nombres n'est pas connu).

### Quel `.DYN` pour quelle moto

Relevé dans la propriété `Physic settings path` des `.PPF`. Un `.DYN` est partagé par
toutes les déclinaisons d'un modèle.

| `.DYN` | Archétypes (`<CODE>_BIKE.PPF`) |
|---|---|
| `1000\CBR1000RRRSP` | HDA001 à 005, HDA010 à 020 |
| `1000\S1000RR` | BMW003, 005, 007, 008, 011 à 016 |
| `1000\M1000RR` | BMW001, 002, 004, 006 |
| `1000\M1000RR23` | BMW009, 010 |
| `1000\YZFR1` | YAM001, 002, 010 à 012 |
| `1000\GSXR1000R` | SZK001 à 005 |
| `1000\ZX10RR21` | KAW001, 002 |
| `1000\ZX10RR19` | KAW003, 007 |
| `600\YZFR6` | YAM003 à 009, YAM013 à 023 |
| `600\CBR600RR` | HDA006 à 009, HDA021 à 023 |
| `600\DAYTONA765` | TRI002 à 007 |
| `600\DAYTONA675R` | TRI001 |
| `600\ZX6R` | KAW004 à 006, KAW009 |

Les 24 autres `.DYN` de modèles (`APL001`, `DUC001`, `EBR001`, `MVA001`, `NRT001`…) ne
sont référencés par aucun `.PPF`. Hypothèse : restes d'un jeu précédent, sans effet.

## Fichiers `.TYR`

Même syntaxe que les `.DYN`, avec une seule section `GamePlay::GPTyreGrip`. Ils héritent
de `FRONTTYREBASE.DYN` ou `REARTYREBASE.DYN`.

Pour chaque surface (`Tarmac`, `WetTarmac`, `Grass`, `WetGrass`, `Sand`, `WetSand`) :
`<Surface> Friction`, `LatStiffX`, `LatStiffY`, `LongitudinalStiffnessPerUnitGravity`,
`CamberStiffnessPerUnitGravity`, et pour le bitume les `Dynamic … Friction Ratio`.

Autres propriétés : `Heat Performance Curve` (grip selon la température),
`Wear Over Heat Curve`, `Tire Thermal Capacity`, `Tire Spring Strength`,
`Tyre Type` (`TYPE_SLICK`…), `Tyre Compound` (`COMPOUND_SOFT`…).

`TUNING\FACTORIES\TYRES.CFG` (Lua) associe chaque pneu (`ID`, `Type`, `Compound`) à ses
deux fichiers `DynaPathFront` et `DynaPathRear`.

## Archétypes `.PPF`

XML (`<actor>` contenant des `<component class="…">` avec leurs `<prop>`). Chaque moto
hérite de `TEMPLATE\TT3_SUPERBIKE.PPF` ou `TT3_SUPERSPORT.PPF` par l'attribut
`instanceof`.

Le composant `GamePlay::GPVehicleSDK` du `.PPF` porte, en plus du chemin du `.DYN`, des
réglages qu'on ne trouve pas dans les `.DYN` de modèles :

- aides : `ABS Front Bias`, `ABS Rear Bias`, `ABS AntiStoppie Bias`,
  `Traction Control Bias`, `Traction Control AntiWheeling Bias`, et leurs `PID Gains` ;
- équilibre et direction : `Balance PID Gains`, `Steering PID Gains`,
  `Max Lean Low Speed`, `Maximum Lean For Low Speed Curve (KPH/DEG)` ;
- `Front Tire Pressure`, `Rear Tire Pressure`.

Autres composants : `GPGameCameraViews` (pointe vers
`DATA:/TUNING/Camera/GameViewCameras<CODE>_BIKE.cfg`), `GPAISettings`, `GPVehicleSound`,
`RWCockpitHUDComponent`.

Si une même propriété figure dans le `.PPF` et dans le `.DYN`, on ne sait pas laquelle
l'emporte.

## Bases de données Lua

- `BIKES.LUA` (table `Bikes`) : `Name` (ex. `TT_SZK001`), `BikeArchetype`,
  `BikeAssetPSI`, `BikePacLog`, `BikeCategoryId`, `BikeBrandId`, `SaddleHeight`,
  `BikeConfigTemplateId`, et les champs `UI_*` de la fiche technique. Ces derniers sont
  du texte affiché (`"##999.8[cc]##"`), pas des valeurs physiques.
- `BIKECATEGORIES.LUA` : 1 = Superbike, 2 = Supersport, 3 = Superbike_2023…
- `BIKECONFIGS.LUA` : pour chaque moto, les pièces montées par défaut
  (`ComponentId` + `BikeConfigTemplateElementId`).
- `BIKETEMPLATES.LUA` : les emplacements de pièces d'une moto (catégorie, point
  d'ancrage, obligatoire ou non).
- `COMPONENTS.LUA` : les pièces (`Code`, `Price`, `PerformanceIndex`,
  `ComponentPropertiesMinId` / `MaxId`, `ComponentPropertiesTemplateId`).
- `COMPONENTPROPERTIES.LUA` : valeurs `Prop1`…`Prop14` d'une pièce à un niveau donné
  (ex. `TT_M1000RR Shock Absorber Lv1` et `Lv5`). Le sens de chaque `PropN` dépend de
  `LayoutType` et n'est pas décodé.

Hypothèse : les pièces montées modifient le couple, le poids ou les suspensions
par-dessus le `.DYN`. Une valeur changée dans un `.DYN` pourrait donc être en partie
écrasée en jeu.

## Modifier une moto

Méthode 1 de [modding.md](modding.md), ici sur la GSX-R1000 :

```sh
PKG=TT3/WIN32/PKG/CHUNK_0/CHUNK_0_PART0000.PKG
perl tools/pkgextract.pl $PKG TT3 'BIKES\\1000\\GSXR1000R\.DYN$'
# éditer le fichier extrait
perl tools/pkghide.pl $PKG 'COMMON\TUNING\BIKES\1000\GSXR1000R.DYN'
```

- Pour changer sur un seul modèle une valeur définie dans une base (la masse, par
  exemple), ajouter la ligne `<prop … />` dans le `.DYN` du modèle plutôt que de
  modifier `BASE1000.DYN`, qui touche toutes les 1000.
- Les `.PPF` désignent les `.DYN` par `DATA:/TUNING/BIKES/…` alors que le PKG les range
  sous `COMMON\TUNING\…`. On ne sait pas dans quel dossier la version en vrac est
  cherchée : essayer `TT3/Common/Tuning/BIKES/1000/`, puis
  `TT3/WIN32/TUNING/BIKES/1000/`.
- Pour vérifier que le fichier est chargé, commencer par une valeur extrême
  (`Engine Peak torque`, ou `Tarmac Friction` d'un `.TYR`).

## À faire

- tester en jeu un `.DYN` modifié et noter le dossier qui fonctionne ;
- comprendre comment les pièces (`COMPONENTPROPERTIES.LUA`) s'appliquent sur le `.DYN` ;
- décoder les `PropN` par `LayoutType` ;
- établir la priorité entre `.PPF` et `.DYN`.
