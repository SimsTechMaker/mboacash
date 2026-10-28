# Publier carnet237 sur le Google Play Store

## 1. Clé de publication (une seule fois)

Google Play demande que chaque version soit signée avec **ta** clé de publication (« upload key »),
pas avec la clé de développement du PC.

Dans PowerShell :

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\cles" | Out-Null
& "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin\keytool.exe" -genkeypair -v `
  -keystore "$env:USERPROFILE\cles\carnet237-upload.jks" -storetype JKS `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

keytool demande un mot de passe (deux fois), puis ton nom, ton organisation, ta ville, ton pays (`CM`)…

Ensuite :

1. Copie `android/key.properties.example` vers `android/key.properties`.
2. Remplace les deux `CHANGE_ME` par ton mot de passe. Avec un keystore JKS, utilise le même pour les deux.
3. **Sauvegarde** `carnet237-upload.jks` et le mot de passe hors de ce PC (clé USB, gestionnaire de
   mots de passe). Ne les mets jamais dans Git, sur GitHub ou en pièce jointe d'un e-mail.

`android/key.properties` et les fichiers `*.jks` sont déjà exclus par `android/.gitignore`.

## 2. Compiler pour le Play Store

```powershell
flutter build appbundle --release
```

Le fichier à envoyer : `build\app\outputs\bundle\release\app-release.aab`.

À chaque nouvelle version, augmente `version:` dans `pubspec.yaml`, par exemple de `1.0.0+1` à `1.0.1+2`.
Le nombre après `+` doit toujours augmenter.

## 3. Google Cloud : ajouter les nouvelles empreintes

La connexion Google vérifie l'empreinte SHA-1 de la clé qui signe l'app. Il faut donc en ajouter
de nouvelles dans **Google Cloud › Identifiants**, une par **ID client Android**, toutes avec le
package `com.ndi.carnet237` :

| Clé | Où trouver la SHA-1 |
|---|---|
| Clé de développement de ce PC | déjà ajoutée (`C4:37:A1:…:92:5F`) |
| Ta clé de publication | `keytool -list -v -keystore "%USERPROFILE%\cles\carnet237-upload.jks" -alias upload` |
| **Clé de signature Google Play** | Play Console › ton app › *Test et publication › Intégrité de l'application › Signature d'application* |

La dernière est la plus importante : Google Play re-signe l'app avec sa propre clé avant de
l'installer chez les utilisateurs. Sans cette empreinte, la connexion Google échoue pour les
versions installées depuis le Play Store.

## 4. Play Console : ce qu'il faut préparer

- **Compte développeur** : 25 $, payés une seule fois, sur <https://play.google.com/console>.
  Pour un compte personnel créé récemment, Google exige un **test fermé avec au moins 12 testeurs
  pendant 14 jours** avant la mise en production.
- **Fiche de l'app** : nom (30 caractères), description courte (80), description complète, **icône
  512 × 512**, **bannière 1024 × 500**, au moins **2 captures d'écran** de téléphone.
- **Règles de confidentialité** : une URL publique est obligatoire, car l'app se connecte à un compte
  Google. Elle doit expliquer que les données restent sur le téléphone et que la sauvegarde va dans
  le Drive de l'utilisateur, chiffrée.
- **Section « Sécurité des données »** : aucune donnée collectée par le développeur, aucune donnée
  partagée, données chiffrées en transit, l'utilisateur peut effacer ses données.
- **Classification du contenu** (questionnaire), **public cible** (adultes, 18 ans et plus), **pays**.
- **Écran de consentement OAuth** dans Google Cloud : passe-le de « Test » à **« En production »**.
  Sinon, seuls les utilisateurs test peuvent se connecter. Google peut demander une vérification
  selon les accès (scopes) utilisés.
