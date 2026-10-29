# Configurer la synchronisation Google Drive de carnet237 (de A à Z)

Le projet Google Cloud est la « carte d'identité » de l'app auprès de Google. Il ne voit aucune
donnée : chaque utilisateur se connecte avec son propre compte, et ses sauvegardes vont dans son
propre Drive, chiffrées avec son code. Tout est gratuit.

## Les valeurs à avoir sous la main

| Élément | Valeur |
|---|---|
| Nom du package Android | `com.ndi.carnet237` |
| Empreinte SHA-1 de la clé qui signe l'APK (ce PC) | `C4:37:A1:1B:DD:BC:5C:51:FE:2E:08:00:61:DF:27:54:45:2E:92:5F` |
| Accès demandé (scope) | `https://www.googleapis.com/auth/drive.appdata` |

Pour retrouver l'empreinte SHA-1 d'un APK :

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\<version>\apksigner.bat" verify --print-certs build\app\outputs\flutter-apk\app-release.apk
```

## Étape 1 — Le projet

1. Ouvre <https://console.cloud.google.com/> avec le compte Google qui « possède » l'app.
2. En haut, à côté du logo, ouvre le sélecteur de projet › **Nouveau projet**.
3. Nom : `carnet237`. Organisation : « Aucune organisation ». Touche **Créer**.
4. Sélectionne ce projet. Dans *Paramètres du projet*, note le **numéro du projet** (par exemple
   `1050417282744`) : tous tes ID clients commenceront par ce nombre.

## Étape 2 — L'API Google Drive

1. Menu ☰ › **API et services › Bibliothèque**.
2. Cherche **Google Drive API** › **Activer**.

## Étape 3 — Google Auth Platform (écran de consentement)

Menu ☰ › **Google Auth Platform** (anciennement « Écran de consentement OAuth ») › **Commencer**.

1. **Informations sur l'application** : nom `carnet237`, adresse e-mail d'assistance (elle sera
   visible des utilisateurs : une adresse dédiée est possible).
2. **Audience** : **Externe**.
3. **Coordonnées** : ton adresse e-mail (Google t'écrira ici, elle n'est pas montrée aux utilisateurs).
4. Accepte la politique, puis **Créer**.

Ensuite, dans le menu de gauche de Google Auth Platform :

- **Accès aux données** › *Ajouter ou supprimer des champs d'application* › coche ou colle
  `https://www.googleapis.com/auth/drive.appdata` › *Mettre à jour* › **Enregistrer**.
- **Audience** › *Utilisateurs test* › **Ajouter des utilisateurs** › ton adresse Gmail (celle que tu
  choisis sur le téléphone) › *Enregistrer*.

## Étape 4 — Les deux ID clients

Google Auth Platform › **Clients** › **Créer un client**, deux fois :

1. **Type : Android**
   - Nom : `carnet237 Android`
   - Nom du package : `com.ndi.carnet237`
   - Empreinte SHA-1 : `C4:37:A1:1B:DD:BC:5C:51:FE:2E:08:00:61:DF:27:54:45:2E:92:5F`
   - **Créer**. Il n'y a rien à copier pour ce client.
2. **Type : Application Web**
   - Nom : `carnet237 Web`
   - Ne remplis ni « Origines JavaScript » ni « URI de redirection ».
   - **Créer**, puis **copie l'ID client** (`<numéro du projet>-xxxx.apps.googleusercontent.com`).
     Ignore le « code secret du client » : l'app n'en a pas besoin, ne le partage pas.

Vérifie que les **deux** ID clients commencent par le **même numéro de projet**.

## Étape 5 — Mettre l'ID dans l'app

1. Dans `lib/config.dart`, colle l'ID client **Web** :
   ```dart
   const googleServerClientId = '<numéro>-xxxx.apps.googleusercontent.com';
   ```
2. Recompile : `flutter build apk --release --split-per-abi`, et installe l'APK.

## Étape 6 — Tester

1. Attends **5 à 10 minutes** après les modifications dans la console.
2. Dans l'app : **Plus › Sécurité** › active un code, puis **Plus › Synchronisation Google Drive ›
   Se connecter avec Google**, avec l'adresse ajoutée comme utilisateur test.
3. Touche **Synchroniser maintenant**, puis **Afficher** : la sauvegarde doit apparaître.

## Étape 7 — Ouvrir à tes proches

Google Auth Platform › **Audience** › **Publier l'application** › confirmer : l'état passe à
**« En production »**. N'importe quel compte Google peut alors se connecter, sans que tu connaisses
les adresses, et l'autorisation n'expire plus au bout de 7 jours. Le scope `drive.appdata` ne donne
accès qu'au dossier caché de l'app ; si la console te demande malgré tout une vérification, suis ses
indications.

## En cas d'erreur

| Message | Cause probable |
|---|---|
| `[28444] Developer console is not set up correctly` | ID client Android absent, dans un autre projet, ou package/SHA-1 différent ; ou Branding non enregistré |
| `[10]` ou `DEVELOPER_ERROR` | Empreinte SHA-1 différente de celle de la clé qui signe l'APK |
| « Accès bloqué : l'app n'a pas terminé la procédure de validation » | Mode Test et adresse absente des utilisateurs test |
| `Google Drive a refusé la demande (403)` | API Google Drive non activée |

Si tu changes de PC ou de clé de signature, ajoute un **nouvel ID client Android** avec la nouvelle
empreinte SHA-1 (on peut en avoir plusieurs), sans toucher à l'ID Web.
