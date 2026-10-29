# my-nkap — ce qu'il reste à faire avant la production

État au 29 octobre 2026, version **1.4.0 (build 9)**. Aujourd'hui, l'app est distribuée en APK de la main
à la main et via les Releases GitHub, signée avec la clé de développement du PC.
« Production » veut dire ici : **Google Play Store**, connexion Google ouverte à tout le monde.

Légende : 🔴 bloquant pour publier · 🟠 fortement conseillé · 🟢 confort

---

## 1. Décisions à prendre d'abord

- [ ] 🔴 **Identifiant Android définitif.** `com.ndi.carnet237` ne pourra plus jamais changer une fois
  l'app publiée sur le Play Store. Le garder (conseillé : les mises à jour restent simples) ou passer
  à `com.ndi.mynkap` maintenant, avant toute publication.
- [ ] 🔴 **Nom sur le Play Store.** Vérifier que « my-nkap » n'est pas déjà pris sur le Play Store,
  et faire une recherche de marque (OAPI pour l'Afrique centrale et de l'Ouest, et INPI si besoin).
- [ ] 🟠 **Niveau de sécurité.** Pour la distribution entre proches, tu avais choisi « rien de plus ».
  Pour un public large, décider si on ajoute :
  - le chiffrement de la base sur le téléphone (SQLCipher). Aujourd'hui, la base est protégée
    uniquement par le bac à sable Android et le chiffrement du téléphone ;
  - l'interdiction des captures d'écran (`FLAG_SECURE`).

## 2. Signature et migration des utilisateurs actuels

- [ ] 🔴 **Créer la clé de publication** (« upload key ») : voir [play-store.md](play-store.md) §1.
  Faire deux sauvegardes hors du PC, de `debug.keystore` et de la nouvelle clé.
- [ ] 🔴 **Prévoir la migration des proches.** Les APK actuels sont signés avec la clé du PC, et la
  version Play Store sera signée par Google. Android refusera donc la mise à jour, et il faudra
  désinstaller l'ancienne version, ce qui **efface les données**. Procédure à leur donner :
  1. Plus › **Sauvegarde complète (fichier)** › Créer le fichier, avec un mot de passe noté.
  2. Garder le fichier `.nkap` hors du téléphone (WhatsApp à soi-même, e-mail, clé USB).
  3. Désinstaller l'ancienne app, installer celle du Play Store.
  4. Plus › Sauvegarde complète (fichier) › **Restaurer depuis un fichier**.
- [ ] 🟠 **Numéros de version.** Les APK actuels ont un code de version de 2000 et plus
  (1000 × architecture + build), alors qu'un AAB utilise le numéro de build seul (9). Sur le Play Store,
  le code doit seulement augmenter d'une version à l'autre, donc ce n'est pas bloquant. Mais pour
  éviter toute confusion, repartir par exemple de `2.0.0+3000` pour la première version Play Store.

## 3. Google Cloud (connexion Google et Drive)

- [ ] 🔴 **Passer l'écran de consentement en production** : Google Auth Platform › Audience ›
  *Publier l'application*. Tant qu'il reste en « Test », seuls les utilisateurs test peuvent se connecter.
- [ ] 🔴 **Branding** : nom **my-nkap**, logo 120 × 120 (`assets/icon/logo-512.png` réduit), e-mail
  d'assistance, **page d'accueil** et **URL des règles de confidentialité** (voir §4).
  Avec un logo, Google demande une vérification de la marque, qui prend quelques jours.
- [ ] 🔴 **Empreintes SHA-1** : ajouter un ID client Android pour la clé de publication **et** pour
  la clé de signature Google Play (voir [play-store.md](play-store.md) §3). Sans la seconde, la
  connexion Google échoue pour toute installation depuis le Play Store (erreur 10 / 28444).
- [ ] 🟠 **Vérification des accès** : l'app ne demande que `drive.appdata`, un dossier caché propre
  à l'app. Prévoir quand même une courte vidéo de démonstration si Google la réclame.

## 4. Documents publics

- [ ] 🔴 **Règles de confidentialité** à une adresse publique (GitHub Pages du dépôt, par exemple).
  Contenu minimal :
  - les données (opérations, photos de justificatifs) restent sur le téléphone ;
  - aucune donnée n'est envoyée au développeur, et il n'y a ni publicité ni statistiques d'usage ;
  - la sauvegarde Google Drive est chiffrée, va dans le Drive de l'utilisateur et n'a lieu que
    s'il la lance ;
  - le fichier `.nkap` est chiffré avec le mot de passe de l'utilisateur ;
  - comment tout effacer : Paramètres › Données, ou désinstaller l'app ;
  - un contact.
- [ ] 🟠 **Conformité au Cameroun** : vérifier les obligations de la loi de 2024 sur la protection des
  données personnelles. L'app ne collecte rien côté serveur, mais la page doit le dire clairement.
- [ ] 🟢 Page d'accueil simple : présentation, captures, lien Play Store, contact.

## 5. Play Console

- [ ] 🔴 **Compte développeur** (25 $, une fois). Un compte personnel récent doit faire un
  **test fermé avec au moins 12 testeurs pendant 14 jours** avant la production : les proches
  actuels sont les testeurs tout trouvés.
- [ ] 🔴 **Construire l'AAB** : `flutter build appbundle --release` (et non plus les APK séparés).
- [ ] 🔴 **Fiche** en français **et** en anglais : nom, description courte (80 caractères) et longue,
  icône 512 × 512 (`assets/icon/logo-512.png`), bannière 1024 × 500 (à créer), au moins
  2 captures d'écran de téléphone (accueil, statistiques, saisie avec justificatif, épargne).
- [ ] 🔴 **Contenu de l'app** :
  - Sécurité des données : aucune donnée collectée ni partagée par le développeur, et suppression possible ;
  - **Fonctionnalités financières** : déclarer « gestion de budget personnel », sans prêt, paiement
    ni placement ;
  - classification du contenu, public cible (18 ans et plus), publicité : aucune ;
  - autorisations : notifications, biométrie, démarrage (rappels). Aucune autorisation photo n'est
    demandée : Android fournit lui-même le sélecteur de photos.
- [ ] 🟠 **API cible** : le Play Store exige chaque année une `targetSdk` récente. Elle suit Flutter :
  le vérifier à chaque mise à jour de Flutter.

## 6. Tests restants avant la mise en production

Déjà vérifié sur un Pixel 7 Pro (Android 17) : français et anglais, justificatif depuis la galerie,
création du fichier de sauvegarde, connexion Google (en mode test), pages, notifications, verrouillage.
Les 15 tests automatiques passent.

- [ ] 🔴 **Restaurer un fichier `.nkap` sur un deuxième téléphone** (avec justificatifs), et vérifier
  le refus d'un mauvais mot de passe.
- [ ] 🔴 **Restaurer une sauvegarde Google Drive** contenant des justificatifs.
- [ ] 🔴 **Justificatif pris à l'appareil photo** : seule la galerie a été essayée sur le téléphone.
- [ ] 🟠 **Téléphone ancien ou d'entrée de gamme** (APK arm32, Android 7 à 9, 2 Go de RAM) :
  démarrage, fluidité, sélecteur de photos.
- [ ] 🟠 **Gros volume** : 3 000 opérations et 200 justificatifs. Mesurer la taille et la durée de la
  sauvegarde. Aujourd'hui, toute la sauvegarde est construite en mémoire : au-delà de ~100 Mo
  de photos, prévoir un avertissement ou une sauvegarde en flux.
- [ ] 🟠 **Mise à jour depuis la v1.2.0** avec des données réelles (migration de la base v1 → v2).
- [ ] 🟠 **Relecture de l'anglais** par une personne anglophone (608 textes).
- [ ] 🟢 **Accessibilité** : TalkBack, très grande taille de police, contraste en mode clair.

## 7. Après la publication

- [ ] 🟠 **Retour des utilisateurs** : l'app n'envoie aucun rapport de plantage, et c'est voulu.
  Prévoir un canal (e-mail d'assistance dans la fiche et dans Plus › À propos) et suivre la section
  *Android vitals* de la Play Console.
- [ ] 🟢 Mettre à jour [distribution.md](distribution.md) et [guide-utilisateur.md](guide-utilisateur.md)
  pour l'installation depuis le Play Store.
- [ ] 🟢 Renommer le dépôt GitHub `mboacash` en `my-nkap` (les anciens liens restent redirigés).

---

**Ordre conseillé :** §1 → §2 (clé) → §4 (confidentialité) → §3 (Google Cloud) → §6 (tests) →
§5 (test fermé de 14 jours) → production.
