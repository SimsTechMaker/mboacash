# my-nkap

« Où va mon argent ? » — carnet de dépenses personnel pour Android, en Flutter (anciennement carnet237 ;
l'identifiant Android reste `com.ndi.carnet237` pour que les mises à jour gardent les données). Les données restent sur le téléphone ;
internet n'est utilisé que lorsque l'utilisateur lance une synchronisation Google Drive.

## Fonctions

- Dépenses, revenus et transferts entre comptes (Espèces, Banque, Mobile Money…), avec ajustement de solde
- Catégories personnalisables (icônes Lucide, couleurs, plafonds mensuels), budget mensuel
- Statistiques : répartition par catégorie, six derniers mois, plus grosses dépenses
- Objectifs d'épargne et suivi des dettes (« je dois » / « on me doit ») ; l'épargne et les dettes
  comptent comme revenus ou dépenses selon le sens, hors budget
- Assistant local : catégorie devinée d'après la note, opérations récurrentes, conseils mensuels,
  prévision de fin de mois, assistant budget (50/30/20, 70/20/10 ou d'après l'historique)
- Justificatif photo (reçu, facture) sur une opération, pris à l'appareil photo ou dans la galerie
- Relevé PDF imprimable, export CSV et réimport (sans doublons)
- Sauvegarde complète dans un fichier chiffré par mot de passe (justificatifs compris), à garder où l'on veut,
  sans compte Google
- Verrouillage par code (PBKDF2) et biométrie
- Sauvegarde chiffrée (AES-256-GCM) dans le dossier privé `appDataFolder` du Google Drive de l'utilisateur,
  justificatifs compris
- Notifications locales : rappel quotidien, budget, échéances de dettes, rappel de synchronisation
- Thèmes clair, sombre et automatique ; interface en français et en anglais (suit la langue du téléphone, modifiable dans Paramètres › Apparence) ; devise par défaut FCFA (XAF)

## Développer

Prérequis : Flutter 3.47 ou plus récent, Android SDK, JDK 17.

```powershell
flutter pub get
flutter run                 # sur un émulateur ou un téléphone branché
flutter analyze
flutter test
```

Compiler l'APK : `flutter build apk --release --split-per-abi` → un APK par type de processeur
dans `build/app/outputs/flutter-apk/` (`arm64-v8a` pour la plupart des téléphones récents).

Projet sur un autre disque que le cache pub (par exemple `D:` et `C:`) : la compilation incrémentale
de Kotlin est désactivée dans `android/gradle.properties`, car elle échoue dans ce cas.

## Organisation du code

| Fichier | Rôle |
|---|---|
| `lib/models.dart` | Modèles (opérations, comptes, catégories, objectifs, dettes, réglages) |
| `lib/db.dart` | Stockage SQLite |
| `lib/state.dart` | État de l'app, calculs (soldes, cumuls), données d'exemple |
| `lib/security.dart` | Code de verrouillage, biométrie, verrouillage automatique |
| `lib/backup.dart` | Sauvegarde chiffrée Google Drive (à la demande uniquement) |
| `lib/notify.dart` | Notifications locales programmées |
| `lib/export.dart` | Export CSV et relevé PDF |
| `lib/csv_import.dart` | Lecture et import d'un CSV exporté |
| `lib/insights.dart` | Suggestions, récurrences, conseils, prévision, préréglages de budget |
| `lib/screens/`, `lib/widgets/` | Interface |
| `lib/icons.dart` | Table des icônes Lucide utilisées (générée) |

## Configuration

- `lib/config.dart` : identifiant client OAuth **Web** du projet Google Cloud. Ce n'est pas un secret :
  la connexion n'est acceptée que pour une app signée avec une clé dont l'empreinte SHA-1 est
  enregistrée dans ce projet. Voir [docs/google-drive-setup.md](docs/google-drive-setup.md).
- Signature : sans `android/key.properties`, les versions publiées sont signées avec la clé de
  développement du PC. Voir [docs/distribution.md](docs/distribution.md) et
  [docs/play-store.md](docs/play-store.md). Les clés et mots de passe ne doivent jamais être commités.

## Documentation

- [docs/guide-utilisateur.md](docs/guide-utilisateur.md) : guide pour les utilisateurs
- [docs/distribution.md](docs/distribution.md) : distribuer l'APK à la main, mettre à jour
- [docs/google-drive-setup.md](docs/google-drive-setup.md) : créer le projet Google Cloud
- [docs/play-store.md](docs/play-store.md) : publier sur le Play Store
- `docs/logo/make_logo.py` : génère le logo (`python docs/logo/make_logo.py .`), puis `dart run flutter_launcher_icons`
- `prototype_web/` : le prototype web d'origine
