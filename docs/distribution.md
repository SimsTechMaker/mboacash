# Donner my-nkap à tes proches (APK, hors Play Store)

## Avant la première distribution : une étape côté Google Cloud

Ton écran de consentement OAuth est en mode **Test**. Dans ce mode, seules les adresses listées comme
« utilisateurs test » peuvent se connecter, et l'autorisation expire au bout de 7 jours.

Pour que n'importe qui puisse synchroniser avec **son propre** compte Google :

1. <https://console.cloud.google.com/> › ton projet `carnet237` › **Écran de consentement OAuth**
   (ou *Google Auth Platform › Audience*).
2. **Publier l'application** : l'état passe de « Test » à **« En production »**.
3. Vérifie que l'adresse e-mail d'assistance est celle que tu veux montrer : elle s'affiche sur
   l'écran de connexion Google. Tu peux utiliser une adresse dédiée.

L'app ne demande qu'un accès : `drive.appdata`, un dossier caché du Drive que seule my-nkap peut lire.
D'après la documentation de Google, ce type d'accès n'exige pas de vérification. Si la console
te demande quand même une vérification au moment de publier, suis ses indications.

## Ce que tes proches reçoivent

- `build\distribution\my-nkap-arm64.apk` : pour presque tous les téléphones de moins de 8 ans.
- `build\distribution\my-nkap-arm32.apk` : pour les modèles anciens ou d'entrée de gamme, si le premier ne s'installe pas.
- À envoyer par WhatsApp, câble USB, Bluetooth ou clé USB.
- Le guide [guide-utilisateur.md](guide-utilisateur.md), à leur transmettre si besoin.

## Ce qui ne te concerne plus après l'installation

- Les données de chacun restent **sur son téléphone**. Tu n'y as aucun accès.
- La synchronisation va dans **le Google Drive de l'utilisateur**, chiffrée avec **son** code.
- Le seul lien technique : le projet Google Cloud qui autorise la connexion est à ton nom. Il ne voit
  aucune donnée, mais **ne le supprime pas**, sinon la synchronisation s'arrêtera pour tout le monde.

## Mises à jour

- L'APK est signé avec la **clé de développement de ce PC** (`%USERPROFILE%\.android\debug.keystore`).
- Une nouvelle version s'installe par-dessus l'ancienne, sans perte de données, **uniquement si elle
  est signée avec la même clé**. Sauvegarde donc ce fichier `debug.keystore` sur une clé USB : si tu
  changes de PC, recopie-le au même endroit avant de compiler.
- Si tu passes un jour à la clé de publication (Play Store), tes proches devront désinstaller l'app,
  après avoir synchronisé, puis réinstaller et restaurer leur sauvegarde Drive.
- À chaque nouvelle version, augmente `version:` dans `pubspec.yaml` (par exemple `1.0.0+1` → `1.1.0+2`).

## Compiler une nouvelle version

```powershell
flutter build apk --release
Copy-Item build\app\outputs\flutter-apk\app-release.apk build\my-nkap.apk
```

## Accès à internet

L'app n'utilise internet **que** lorsque l'utilisateur touche un bouton de l'écran
*Plus › Synchronisation Google Drive* (se connecter, synchroniser, afficher ou restaurer
les sauvegardes, se déconnecter). Rien d'autre ne passe par le réseau : ni au démarrage,
ni en arrière-plan, ni pour les notifications, qui sont préparées sur le téléphone.
