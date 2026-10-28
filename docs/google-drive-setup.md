# Activer la sauvegarde Google Drive de carnet237

La sauvegarde utilise ton propre projet Google Cloud. Il faut le créer une seule fois, en 10 minutes environ.
Tout est gratuit : l'app n'utilise que l'API Google Drive, sur un dossier privé.

## Valeurs dont tu auras besoin

| Élément | Valeur |
|---|---|
| Nom du package Android | `com.ndi.carnet237` |
| Empreinte SHA-1 (clé de ce PC) | `C4:37:A1:1B:DD:BC:5C:51:FE:2E:08:00:61:DF:27:54:45:2E:92:5F` |
| Accès demandé (scope) | `https://www.googleapis.com/auth/drive.appdata` |

L'empreinte vient de la clé de développement de ce PC (`%USERPROFILE%\.android\debug.keystore`),
celle qui signe l'APK aujourd'hui. Pour compiler sur un autre PC, ou avec une clé de publication pour
le Play Store, ajoute l'empreinte SHA-1 de cette autre clé dans un second identifiant Android (étape 4).

## Étapes

1. Va sur <https://console.cloud.google.com/> et connecte-toi avec ton compte Google.
2. **Crée un projet** : menu en haut › *Nouveau projet* › nom `carnet237` › *Créer*.
3. **Active l'API Drive** : *API et services › Bibliothèque* › cherche **Google Drive API** › *Activer*.
4. **Écran de consentement OAuth** (*API et services › Écran de consentement OAuth*, ou *Google Auth Platform*) :
   - Type d'utilisateur : **Externe** ;
   - Nom de l'application : `carnet237`, puis ton e-mail comme adresse d'assistance et de contact ;
   - Accès aux données : ajoute le scope `.../auth/drive.appdata` ;
   - **Utilisateurs test** : ajoute ton adresse Gmail, et celles des personnes qui testeront l'app.
     Tant que l'app est « en test », seules ces adresses peuvent se connecter.
5. **Identifiants** (*API et services › Identifiants › Créer des identifiants › ID client OAuth*) :
   - **ID client « Android »** : nom du package `com.ndi.carnet237`, empreinte SHA-1 ci-dessus ;
   - **ID client « Application Web »** : un nom comme `carnet237 web`, sans URL à remplir.
     Copie l'**ID client** affiché, qui ressemble à `1234567890-abc…apps.googleusercontent.com`.
6. Colle cet ID client **Web** dans `lib/config.dart` :

   ```dart
   const googleServerClientId = '1234567890-abc...apps.googleusercontent.com';
   ```

7. Recompile l'APK (`flutter build apk --release`) et installe-le.

## Dans l'app

1. **Plus › Sécurité** : active un code. Il chiffre tes sauvegardes, donc il est obligatoire.
2. **Plus › Synchronisation Google Drive** › *Se connecter avec Google* › *Synchroniser maintenant*.
3. Il n'y a pas de synchronisation automatique : l'app ne va sur internet que quand on touche un bouton.
   Une notification rappelle de synchroniser si la dernière sauvegarde date de plus de 7 jours.

Pour **restaurer sur un autre téléphone** : installe l'app, connecte le même compte Google, puis
touche une sauvegarde › *Restaurer*. Il faut le code qui était actif au moment de cette sauvegarde.

## En cas d'erreur

- **« Connexion Google impossible (…) »** : l'empreinte SHA-1, le nom du package ou l'ID client Web
  ne correspondent pas, ou ton adresse n'est pas dans les utilisateurs test.
- **« Google Drive a refusé la demande (403) »** : l'API Google Drive n'est pas activée dans le projet.
- Après une modification dans la console Google, attends quelques minutes avant de réessayer.
