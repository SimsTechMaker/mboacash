// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get accountsAdjust => 'Ajuster le solde';

  @override
  String get accountsDefault => 'par défaut';

  @override
  String get accountsIOwe => 'Je dois';

  @override
  String get accountsMine => 'Mes comptes';

  @override
  String get accountsNetWorth => 'Patrimoine net';

  @override
  String get accountsOnAccounts => 'Sur mes comptes';

  @override
  String get accountsOps => 'Opérations';

  @override
  String get accountsOwedToMe => 'On me doit';

  @override
  String accountsShare(int pct) {
    return '$pct % de ton argent disponible';
  }

  @override
  String get add => 'Ajouter';

  @override
  String get appTitle => 'my-nkap';

  @override
  String get assistantApplied => 'Budget et plafonds appliqués';

  @override
  String get assistantApply => 'Appliquer ce budget';

  @override
  String get assistantApplyNote =>
      'Remplace ton budget mensuel et les plafonds de tes catégories de dépenses. Tu pourras les modifier ensuite dans Paramètres.';

  @override
  String get assistantCapPerCat => 'Plafond par catégorie';

  @override
  String get assistantCreateGoal => 'Créer un objectif';

  @override
  String get assistantGoals => 'Objectifs d\'épargne';

  @override
  String get assistantGoalsReached => 'Tous tes objectifs sont atteints.';

  @override
  String get assistantIncomeLabel => 'Revenus mensuels';

  @override
  String get assistantIntro =>
      'Indique ce que tu gagnes par mois : l\'assistant propose un budget, un plafond par catégorie et ce qu\'il faut mettre de côté pour tes objectifs.';

  @override
  String get assistantMethod => 'Méthode';

  @override
  String get assistantMonthlyBudget => 'Budget mensuel (dépenses courantes)';

  @override
  String get assistantNeeds => 'Besoins';

  @override
  String get assistantNeedsSub =>
      'Logement, factures, alimentation, transport…';

  @override
  String assistantNoGoals(String amount) {
    return 'Aucun objectif pour l\'instant. Commence par un fonds d\'urgence d\'environ 3 mois de dépenses, soit à peu près $amount.';
  }

  @override
  String assistantPerMonth(String amount) {
    return '$amount / mois';
  }

  @override
  String get assistantPrefilled =>
      'Pré-rempli avec ta moyenne des 3 derniers mois.';

  @override
  String get assistantProposal => 'Proposition';

  @override
  String get assistantRule503020Desc =>
      'La règle classique : 50 % pour les besoins, 30 % pour les envies, 20 % pour l\'épargne.';

  @override
  String get assistantRule702010Desc =>
      'Plus réaliste quand le loyer et la nourriture pèsent lourd : 70 % besoins, 20 % envies, 10 % épargne.';

  @override
  String get assistantRuleHistory => 'Mes habitudes';

  @override
  String get assistantRuleHistoryDesc =>
      'Part de tes dépenses réelles des 3 derniers mois, et garde le reste pour l\'épargne.';

  @override
  String get assistantTitle => 'Assistant budget';

  @override
  String get assistantWants => 'Envies';

  @override
  String get assistantWantsSub => 'Restaurant, loisirs, shopping…';

  @override
  String get back => 'Retour';

  @override
  String get backupCodeSubtitle =>
      'Le code de verrouillage qui était actif quand cette sauvegarde a été faite';

  @override
  String get backupCodeTitle => 'Code de la sauvegarde';

  @override
  String get backupConnectIntro =>
      'Connecte ton compte Google pour enregistrer une copie chiffrée de tes données dans un espace privé de ton propre Drive. Tu pourras la restaurer sur un autre téléphone.';

  @override
  String get backupConnected => 'Compte Google connecté';

  @override
  String get backupDeleted => 'Sauvegarde supprimée';

  @override
  String get backupDisconnect => 'Déconnecter le compte Google';

  @override
  String get backupDisconnected => 'Compte Google déconnecté de l\'app';

  @override
  String backupDriveRefused(String status) {
    return 'Google Drive a refusé la demande ($status).';
  }

  @override
  String backupDriveRefusedDetail(String status, String detail) {
    return 'Google Drive a refusé la demande ($status : $detail).';
  }

  @override
  String get backupEnablePin => 'Activer un code';

  @override
  String backupInfo(int count) {
    return 'L\'app ne se connecte à internet que quand tu touches un de ces boutons. Les $count dernières sauvegardes sont gardées, chiffrées avec ton code, dans un dossier caché de ton Drive que seule my-nkap peut lire.';
  }

  @override
  String get backupInvalidFile =>
      'Ce fichier n\'est pas une sauvegarde my-nkap valide.';

  @override
  String backupLast(String date) {
    return 'Dernière synchronisation : $date';
  }

  @override
  String get backupListTitle => 'Sauvegardes sur Drive';

  @override
  String get backupNeedPin =>
      'Active un code de verrouillage : il sert à chiffrer tes sauvegardes.';

  @override
  String get backupNetworkError =>
      'Opération impossible. Vérifie ta connexion internet.';

  @override
  String get backupNever => 'Jamais synchronisé depuis ce téléphone';

  @override
  String get backupNone => 'Aucune sauvegarde pour ce compte.';

  @override
  String get backupNotConfigured =>
      'La synchronisation Google Drive n\'est pas configurée dans cette version de l\'app.';

  @override
  String get backupRefresh => 'Actualiser';

  @override
  String get backupRestore => 'Restaurer';

  @override
  String backupRestoreText(String date) {
    return 'Toutes les données actuelles de ce téléphone seront remplacées par celles du $date. Synchronise d\'abord si tu veux garder l\'état actuel.';
  }

  @override
  String get backupRestoreTitle => 'Restaurer cette sauvegarde ?';

  @override
  String get backupRestored => 'Sauvegarde restaurée';

  @override
  String get backupSent => 'Sauvegarde envoyée sur ton Google Drive';

  @override
  String get backupShow => 'Afficher';

  @override
  String get backupShowHint =>
      'Touche « Afficher » pour voir les sauvegardes de ce compte (connexion internet nécessaire).';

  @override
  String get backupSignIn => 'Se connecter avec Google';

  @override
  String get backupSignInCancelled => 'Connexion annulée.';

  @override
  String backupSignInFailed(String code) {
    return 'Connexion Google impossible ($code).';
  }

  @override
  String backupSignInFailedDetail(String code, String detail) {
    return 'Connexion Google impossible ($code : $detail).';
  }

  @override
  String backupSize(String size) {
    return '$size Ko';
  }

  @override
  String backupSizeLatest(String size) {
    return '$size Ko · la plus récente';
  }

  @override
  String get backupSyncNow => 'Synchroniser maintenant';

  @override
  String get backupTitle => 'Synchronisation';

  @override
  String get backupUnreadable =>
      'Cette sauvegarde est illisible ou vient d\'une autre application.';

  @override
  String backupWhen(String date, String time) {
    return '$date à $time';
  }

  @override
  String get backupWrongCode =>
      'Code incorrect pour cette sauvegarde. Il faut le code qui était actif au moment où elle a été faite.';

  @override
  String get cancel => 'Annuler';

  @override
  String get catsByCategory => 'Par catégorie';

  @override
  String catsCap(String amount) {
    return 'plafond $amount';
  }

  @override
  String catsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catégories',
      one: '$count catégorie',
    );
    return '$_temp0';
  }

  @override
  String get catsManage => 'Gérer';

  @override
  String get catsNoOps => 'Aucune opération ce mois-ci';

  @override
  String get catsOver => 'Dépassé';

  @override
  String catsOverCaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plafonds dépassés',
      one: '$count plafond dépassé',
    );
    return '$_temp0';
  }

  @override
  String catsReceivedIn(String month) {
    return 'Reçu en $month';
  }

  @override
  String catsShareOfTotal(int pct) {
    return '$pct % du total';
  }

  @override
  String catsSpentIn(String month) {
    return 'Dépensé en $month';
  }

  @override
  String catsTop(String name) {
    return 'la plus forte : $name';
  }

  @override
  String get catsUnused => 'Sans opération ce mois-ci';

  @override
  String get close => 'Fermer';

  @override
  String commonBorrowFrom(String who) {
    return 'Emprunt auprès de $who';
  }

  @override
  String get commonClear => 'Effacer';

  @override
  String get commonConfirmDelete => 'Confirmer la suppression';

  @override
  String get commonDebtDeleted => 'dette supprimée';

  @override
  String commonFromAccount(String account) {
    return 'Depuis $account';
  }

  @override
  String get commonGoalDeleted => 'objectif supprimé';

  @override
  String get commonLeaveAccounts => 'Ne pas toucher à mes comptes';

  @override
  String commonLendTo(String who) {
    return 'Prêt à $who';
  }

  @override
  String get commonNextMonth => 'Mois suivant';

  @override
  String get commonNoCategory => 'Sans catégorie';

  @override
  String get commonNone => 'Aucune';

  @override
  String get commonOffAccounts => 'Hors comptes';

  @override
  String get commonPrevMonth => 'Mois précédent';

  @override
  String commonRepayFrom(String who) {
    return 'Remboursement de $who';
  }

  @override
  String commonRepayTo(String who) {
    return 'Remboursement à $who';
  }

  @override
  String get commonSample => 'EXEMPLE';

  @override
  String commonSavingFrom(String name) {
    return 'Retrait d\'épargne : $name';
  }

  @override
  String commonSavingTo(String name) {
    return 'Épargne : $name';
  }

  @override
  String commonToAccount(String account) {
    return 'Vers $account';
  }

  @override
  String get commonTransfer => 'Transfert';

  @override
  String get confirm => 'Confirmer';

  @override
  String get curEUR => 'Euro (EUR)';

  @override
  String get curGHS => 'Cedi (GHS)';

  @override
  String get curGNF => 'Franc guinéen (GNF)';

  @override
  String get curMAD => 'Dirham marocain (MAD)';

  @override
  String get curNGN => 'Naira (NGN)';

  @override
  String get curUSD => 'Dollar US (USD)';

  @override
  String get curXAF => 'Franc CFA (XAF)';

  @override
  String get curXOF => 'Franc CFA (XOF)';

  @override
  String get debtsAddDebt => 'Ajouter une dette';

  @override
  String get debtsAddLoan => 'Ajouter un prêt';

  @override
  String get debtsBalance => 'Solde des dettes';

  @override
  String get debtsEmptyLent =>
      'Note l\'argent que tu as prêté et suis ce qu\'on te rembourse.';

  @override
  String get debtsEmptyOwe =>
      'Note l\'argent que tu as emprunté et suis tes remboursements.';

  @override
  String get debtsIOwe => 'Je dois';

  @override
  String get debtsIRepay => 'Je rembourse';

  @override
  String get debtsLate => 'En retard';

  @override
  String get debtsNoneOpen => 'Aucune dette en cours';

  @override
  String debtsOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dettes en cours',
      one: '$count dette en cours',
    );
    return '$_temp0';
  }

  @override
  String get debtsOwedToMe => 'On me doit';

  @override
  String debtsRepaidOf(String paid, String total) {
    return '$paid remboursés sur $total';
  }

  @override
  String get debtsSettled => 'Soldée';

  @override
  String debtsSince(String date) {
    return 'depuis le $date';
  }

  @override
  String get debtsTheyRepay => 'On me rembourse';

  @override
  String get debtsTitle => 'Dettes';

  @override
  String get defAccBank => 'Banque';

  @override
  String get defAccCash => 'Espèces';

  @override
  String get defAccMomo => 'Mobile Money';

  @override
  String get defCatActivite => 'Activité';

  @override
  String get defCatAlim => 'Alimentation';

  @override
  String get defCatAutre => 'Autre';

  @override
  String get defCatAutreIn => 'Autre revenu';

  @override
  String get defCatCadeau => 'Cadeau';

  @override
  String get defCatEducation => 'Éducation';

  @override
  String get defCatFactures => 'Factures';

  @override
  String get defCatFamille => 'Famille';

  @override
  String get defCatLogement => 'Logement';

  @override
  String get defCatLoisirs => 'Loisirs';

  @override
  String get defCatResto => 'Restaurant';

  @override
  String get defCatSalaire => 'Salaire';

  @override
  String get defCatSante => 'Santé';

  @override
  String get defCatShopping => 'Shopping';

  @override
  String get defCatTelephone => 'Téléphone et internet';

  @override
  String get defCatTransport => 'Transport';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get exportAllAccounts => 'Tous les comptes';

  @override
  String get exportByCategory => 'Dépenses par catégorie';

  @override
  String get exportClosing => 'Solde de clôture';

  @override
  String get exportColAccount => 'Compte';

  @override
  String get exportColAmount => 'Montant';

  @override
  String get exportColBalance => 'Solde';

  @override
  String get exportColCap => 'Plafond mensuel';

  @override
  String get exportColCategory => 'Catégorie';

  @override
  String get exportColCredit => 'Crédit';

  @override
  String get exportColDate => 'Date';

  @override
  String get exportColDebit => 'Débit';

  @override
  String get exportColDirection => 'Sens';

  @override
  String get exportColDue => 'Échéance';

  @override
  String get exportColGoal => 'Objectif';

  @override
  String get exportColLabel => 'Libellé';

  @override
  String get exportColLeft => 'Reste';

  @override
  String get exportColPerson => 'Personne';

  @override
  String get exportColProgress => 'Avancement';

  @override
  String get exportColRepaid => 'Remboursé';

  @override
  String get exportColSaved => 'Épargné';

  @override
  String get exportColShare => 'Part';

  @override
  String get exportColTarget => 'Cible';

  @override
  String get exportColTargetDate => 'Date visée';

  @override
  String get exportCredits => 'Total crédits';

  @override
  String get exportCsvSubject => 'Export my-nkap';

  @override
  String exportCurrency(String currency) {
    return 'Devise : $currency';
  }

  @override
  String get exportDebits => 'Total débits';

  @override
  String get exportDebtsLoans => 'Dettes et prêts';

  @override
  String get exportEmpty => 'Aucune opération sur cette période.';

  @override
  String exportFileName(String from, String to) {
    return 'releve-$from-au-$to';
  }

  @override
  String exportFooter(String from, String to) {
    return 'Relevé du $from au $to - document personnel, sans valeur bancaire officielle';
  }

  @override
  String get exportIOwe => 'Je dois';

  @override
  String exportIssued(String date) {
    return 'Édité le $date';
  }

  @override
  String get exportOpening => 'Solde d\'ouverture';

  @override
  String get exportOwedToMe => 'On me doit';

  @override
  String exportPage(String page, String pages) {
    return 'Page $page / $pages';
  }

  @override
  String get exportPdfDocTitle => 'Relevé my-nkap';

  @override
  String exportPercent(String value) {
    return '$value %';
  }

  @override
  String exportPeriod(String from, String to) {
    return 'Du $from au $to';
  }

  @override
  String exportPeriodSummary(String income, String expense, String ops) {
    return 'Revenus de la période : $income   ·   Dépenses de la période : $expense   ·   $ops';
  }

  @override
  String get exportSettled => 'Soldée';

  @override
  String get exportTitle => 'Relevé de compte';

  @override
  String get exportTotal => 'Total';

  @override
  String get exportTotals => 'Totaux';

  @override
  String get exportTransfer => 'Transfert';

  @override
  String get exportTransferInternal => 'Transfert interne';

  @override
  String get fileBackupExport => 'Créer le fichier de sauvegarde';

  @override
  String get fileBackupFailed => 'Opération impossible. Réessaie.';

  @override
  String get fileBackupImport => 'Restaurer depuis un fichier';

  @override
  String get fileBackupMoreSub =>
      'Tout dans un fichier protégé, sans compte Google';

  @override
  String get fileBackupPassword => 'Mot de passe';

  @override
  String get fileBackupPasswordAgain => 'Confirme le mot de passe';

  @override
  String get fileBackupPasswordEnter => 'Mot de passe du fichier';

  @override
  String get fileBackupPasswordHelp =>
      'Il sera demandé pour restaurer. Note-le bien : il ne peut pas être récupéré.';

  @override
  String get fileBackupPasswordMismatch =>
      'Les deux mots de passe ne sont pas identiques.';

  @override
  String get fileBackupPasswordNew => 'Protéger le fichier';

  @override
  String get fileBackupPasswordShort => 'Au moins 6 caractères.';

  @override
  String get fileBackupPointAll =>
      'Un seul fichier avec tout : opérations, comptes, catégories, épargne, dettes, réglages et justificatifs.';

  @override
  String get fileBackupPointOffline =>
      'Garde-le où tu veux (téléphone, clé USB, e-mail, WhatsApp…) et réimporte-le sur n\'importe quel téléphone.';

  @override
  String get fileBackupPointPassword =>
      'Chiffré avec un mot de passe que tu choisis : sans lui, personne ne peut l\'ouvrir.';

  @override
  String get fileBackupReplace => 'Remplacer';

  @override
  String get fileBackupReplaceText =>
      'Les opérations, comptes, catégories, épargne, dettes et justificatifs actuels seront remplacés par ceux du fichier.';

  @override
  String get fileBackupReplaceTitle => 'Remplacer toutes les données ?';

  @override
  String get fileBackupRestored => 'Sauvegarde restaurée';

  @override
  String get fileBackupSubject => 'Sauvegarde my-nkap';

  @override
  String get fileBackupTitle => 'Sauvegarde complète (fichier)';

  @override
  String get fileBackupWarning =>
      'Restaurer remplace toutes les données de ce téléphone par celles du fichier. Si tu oublies le mot de passe, le fichier ne peut plus être ouvert.';

  @override
  String get greetingDay => 'Bonjour';

  @override
  String get greetingEvening => 'Bonsoir';

  @override
  String importBadLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lignes illisibles',
      one: '$count ligne illisible',
    );
    return '$_temp0';
  }

  @override
  String importButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importer $count opérations',
      one: 'Importer $count opération',
    );
    return '$_temp0';
  }

  @override
  String get importCantRead => 'Impossible de lire ce fichier.';

  @override
  String importCurrencyWarn(String file, String app) {
    return 'Le fichier est en $file, l\'app en $app : les montants sont importés tels quels, sans conversion.';
  }

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opérations importées',
      one: '$count opération importée',
    );
    return '$_temp0';
  }

  @override
  String importDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doublons ignorés (déjà dans l\'app)',
      one: '$count doublon ignoré (déjà dans l\'app)',
    );
    return '$_temp0';
  }

  @override
  String importErrDebt(String line) {
    return 'ligne $line : dette sans personne ni sens';
  }

  @override
  String get importErrEmpty => 'Le fichier est vide.';

  @override
  String get importErrNotExport =>
      'Ce fichier n\'est pas un export my-nkap : il manque les colonnes date, type ou montant.';

  @override
  String importErrUnreadable(String line) {
    return 'ligne $line : date, type ou montant illisible';
  }

  @override
  String get importFailed => 'L\'import a échoué ; rien n\'a été modifié.';

  @override
  String get importIntro =>
      'Choisis un fichier exporté par my-nkap (Plus › Exporter en CSV), même modifié dans Excel. Les opérations déjà présentes sont ignorées, et les catégories, comptes, objectifs et dettes manquants sont créés.';

  @override
  String importMoreErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '… et $count autres',
      one: '… et $count autre',
    );
    return '$_temp0';
  }

  @override
  String importNewAccounts(String names) {
    return 'Comptes créés : $names';
  }

  @override
  String importNewCats(String names) {
    return 'Catégories créées : $names';
  }

  @override
  String importNewDebts(String names) {
    return 'Dettes créées : $names';
  }

  @override
  String importNewGoals(String names) {
    return 'Objectifs créés : $names';
  }

  @override
  String get importNothing => 'Rien à importer';

  @override
  String get importPick => 'Choisir un fichier';

  @override
  String get importPickOther => 'Choisir un autre fichier';

  @override
  String get importSavingsGoal => 'Épargne importée';

  @override
  String get importTitle => 'Importer un CSV';

  @override
  String importToImport(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opérations à importer',
      one: '$count opération à importer',
    );
    return '$_temp0';
  }

  @override
  String get importTooBig => 'Fichier trop volumineux (plus de 20 Mo).';

  @override
  String insGoodTextCurrent(String amount) {
    return 'Bien joué : $amount de moins que ta moyenne si tu gardes ce rythme.';
  }

  @override
  String insGoodTextPast(String amount) {
    return 'Bien joué : $amount de moins que ta moyenne.';
  }

  @override
  String insGoodTitle(int pct, String name) {
    return '$pct % en $name';
  }

  @override
  String insNoSavingText(String amount) {
    return 'D\'habitude tu mets $amount de côté par mois.';
  }

  @override
  String get insNoSavingTitle => 'Pas encore d\'épargne ce mois-ci';

  @override
  String insWarnTextCurrent(String spent, String projected, String avg) {
    return '$spent dépensés, à ce rythme, tu finirais le mois à $projected contre $avg en moyenne.';
  }

  @override
  String insWarnTextPast(String spent, String projected, String avg) {
    return '$spent dépensés, soit $projected contre $avg en moyenne.';
  }

  @override
  String insWarnTitle(int pct, String name) {
    return '+$pct % en $name';
  }

  @override
  String get language => 'Langue';

  @override
  String get languageAuto => 'Automatique';

  @override
  String get languageAutoDesc => 'Suit la langue du téléphone';

  @override
  String get languageEn => 'English';

  @override
  String get languageFr => 'Français';

  @override
  String get lockBiometricTooltip => 'Empreinte ou visage';

  @override
  String get lockChooseCode => 'Choisis un code';

  @override
  String get lockCode => 'Code';

  @override
  String get lockCodeTitle => 'Code de verrouillage';

  @override
  String get lockConfirmCode => 'Confirme le code';

  @override
  String get lockDigits => 'De 4 à 6 chiffres';

  @override
  String get lockEnterAgain => 'Saisis-le une deuxième fois';

  @override
  String get lockForgot => 'Code oublié ?';

  @override
  String get lockForgotBody =>
      'Le code ne peut pas être récupéré. La seule solution est d\'effacer toutes les données de l\'app sur ce téléphone et de retirer le code.\n\nSi tu as une sauvegarde Google Drive, tu pourras la restaurer ensuite, mais il faudra le code utilisé au moment de cette sauvegarde.';

  @override
  String get lockForgotTitle => 'Code oublié';

  @override
  String get lockMismatch => 'Les deux codes sont différents. Recommence.';

  @override
  String get lockSubmit => 'Valider';

  @override
  String get lockSubtitle => 'Saisis ton code pour continuer';

  @override
  String get lockTitle => 'my-nkap est verrouillé';

  @override
  String get lockTooManyLater => 'Trop d\'essais. Réessaie plus tard.';

  @override
  String lockTooManyWait(int seconds) {
    return 'Trop d\'essais. Réessaie dans $seconds s.';
  }

  @override
  String get lockWipeAll => 'Tout effacer';

  @override
  String get lockWiped => 'Données effacées et code retiré';

  @override
  String get lockWrongCode => 'Code incorrect.';

  @override
  String lockWrongCodeTries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Code incorrect. $count essais avant une pause.',
      one: 'Code incorrect. $count essai avant une pause.',
    );
    return '$_temp0';
  }

  @override
  String get moreAssistant => 'Assistant budget';

  @override
  String get moreAssistantSub =>
      'Budget et plafonds selon tes revenus et tes objectifs';

  @override
  String get moreBadgeDrive => 'Drive connecté';

  @override
  String get moreBadgeLocked => 'Protégée';

  @override
  String get moreBadgeNoCode => 'Sans code';

  @override
  String get moreBadgeOffline => 'Hors ligne';

  @override
  String get moreDebts => 'Dettes';

  @override
  String get moreDebtsEmpty => 'Suis ce que tu dois et ce qu\'on te doit';

  @override
  String moreDebtsSub(String owed, String lent) {
    return 'Je dois $owed · On me doit $lent';
  }

  @override
  String get moreDrive => 'Synchronisation Google Drive';

  @override
  String get moreDriveSub =>
      'Copie chiffrée dans ton Drive, à restaurer ailleurs';

  @override
  String get moreExportCsv => 'Exporter en CSV';

  @override
  String get moreExportCsvSub =>
      'Toutes tes opérations dans un fichier pour Excel';

  @override
  String get moreFooter => 'my-nkap · fait au Cameroun';

  @override
  String get moreGroupApp => 'Application';

  @override
  String get moreGroupData => 'Données';

  @override
  String get moreGroupMoney => 'Argent';

  @override
  String moreHeroSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opérations',
      one: '$count opération',
    );
    return '$_temp0 · données sur ce téléphone';
  }

  @override
  String get moreImportCsv => 'Importer un CSV';

  @override
  String get moreImportCsvSub => 'Récupérer un export my-nkap, sans doublons';

  @override
  String get moreNotifications => 'Notifications';

  @override
  String get moreNotificationsSub =>
      'Rappels, budget, échéances, synchronisation';

  @override
  String get moreSavings => 'Épargne';

  @override
  String get moreSavingsEmpty =>
      'Crée un objectif et mets de l\'argent de côté';

  @override
  String moreSavingsSub(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objectifs',
      one: '$count objectif',
    );
    return '$_temp0 · $amount mis de côté';
  }

  @override
  String get moreSecurity => 'Sécurité';

  @override
  String get moreSecurityOff => 'Protège l\'app par un code et ton empreinte';

  @override
  String get moreSecurityOn => 'Code activé';

  @override
  String get moreSecurityOnBio => 'Code activé · empreinte';

  @override
  String get moreSettings => 'Paramètres';

  @override
  String get moreSettingsSub =>
      'Langue, thème, devise, budget, catégories, comptes';

  @override
  String get moreStatement => 'Relevé PDF';

  @override
  String get moreStatementSub =>
      'Imprimable, par mois, par période ou par compte';

  @override
  String get newOperation => 'Nouvelle opération';

  @override
  String get next => 'Suivant';

  @override
  String get no => 'Non';

  @override
  String get notificationsAllow => 'Autoriser';

  @override
  String get notificationsBlocked =>
      'Les notifications sont bloquées pour my-nkap.';

  @override
  String get notificationsBlockedHelp =>
      'Autorise-les pour recevoir les rappels. Si rien ne s\'affiche, va dans Réglages Android › Applications › my-nkap › Notifications.';

  @override
  String get notificationsBudgetDesc =>
      'Alerte à 80 %, puis en cas de dépassement';

  @override
  String get notificationsDailyDesc =>
      '« As-tu noté tes dépenses ? », sauf si tu as déjà saisi quelque chose ce jour-là';

  @override
  String get notificationsDebtsDesc =>
      '3 jours avant et le jour de l\'échéance, à 9 h';

  @override
  String get notificationsFooter =>
      'Les notifications sont préparées sur le téléphone, sans internet. Sur un écran verrouillé, Android masque les montants.';

  @override
  String get notificationsSyncDesc =>
      'Si ta dernière sauvegarde Google Drive date de plus de 7 jours';

  @override
  String get notificationsTime => 'Heure du rappel';

  @override
  String notificationsTimeValue(String hour, String minute) {
    return '$hour h $minute';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notifyChBudget => 'Budget et plafonds';

  @override
  String get notifyChDaily => 'Rappel quotidien';

  @override
  String get notifyChDebts => 'Échéances de dettes';

  @override
  String get notifyChSync => 'Rappel de synchronisation';

  @override
  String get notifyDaily1 => 'As-tu noté tes dépenses aujourd\'hui ?';

  @override
  String get notifyDaily2 => 'Deux minutes pour mettre ton carnet à jour ?';

  @override
  String get notifyDaily3 =>
      'Un taxi, un repas, une recharge ? Note-les avant d\'oublier.';

  @override
  String get notifyDaily4 =>
      'Ton carnet t\'attend : note les opérations du jour.';

  @override
  String notifyDebtIOwe(String amount, String person, String when) {
    return 'Tu dois rembourser $amount à $person $when.';
  }

  @override
  String notifyDebtOwedToMe(String person, String amount, String when) {
    return '$person doit te rembourser $amount $when.';
  }

  @override
  String notifyDebtTitle(String person) {
    return 'Échéance : $person';
  }

  @override
  String get notifyIn3Days => 'dans 3 jours';

  @override
  String get notifyMonthBudget => 'Budget du mois';

  @override
  String notifyNearBody(String spent, String cap, String left) {
    return 'Déjà $spent sur $cap. Il reste $left pour le mois.';
  }

  @override
  String notifyNearTitle(String name) {
    return '$name : 80 % atteint';
  }

  @override
  String notifyOverBody(String spent, String cap) {
    return 'Tu as dépensé $spent ce mois-ci pour un plafond de $cap.';
  }

  @override
  String notifyOverTitle(String name) {
    return '$name : dépassé';
  }

  @override
  String get notifySyncNever =>
      'Tu n\'as pas encore sauvegardé tes données sur Google Drive.';

  @override
  String get notifySyncOld =>
      'Ta dernière sauvegarde Google Drive date de plus de 7 jours.';

  @override
  String get notifySyncTitle => 'Pense à synchroniser';

  @override
  String get notifyToday => 'aujourd\'hui';

  @override
  String get ok => 'OK';

  @override
  String get onboardingBudget => 'Préparer mon budget';

  @override
  String get onboardingSamples => 'Voir avec des exemples';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingText1 =>
      'Note tes dépenses et tes revenus en quelques secondes : marché, taxi, ENEO, Mobile Money… Tu vois où part ton argent, mois après mois.';

  @override
  String get onboardingText2 =>
      'Tout est enregistré sur ce téléphone, sans compte et sans internet. Tu peux protéger l\'app par un code ou ton empreinte, et la sauvegarder chiffrée sur ton propre Google Drive.';

  @override
  String get onboardingText3 =>
      'L\'app devine la catégorie à partir de la note, repère tes dépenses habituelles, te prévient avant de dépasser ton budget et propose un budget adapté à tes revenus.';

  @override
  String get onboardingTitle1 => 'Bienvenue dans my-nkap';

  @override
  String get onboardingTitle2 => 'Tes données restent chez toi';

  @override
  String get onboardingTitle3 => 'Un carnet qui t\'aide';

  @override
  String get opsAdvice => 'Conseils';

  @override
  String get opsBudget => 'Budget';

  @override
  String get opsBudgetAssistant => 'Préparer mon budget avec l\'assistant';

  @override
  String opsBudgetLeft(String amount) {
    return 'Reste $amount';
  }

  @override
  String get opsBudgetNote =>
      'L\'épargne et les dettes ne comptent pas dans le budget.';

  @override
  String opsBudgetOver(String amount) {
    return 'Dépassé de $amount';
  }

  @override
  String opsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opérations',
      one: '$count opération',
    );
    return '$_temp0';
  }

  @override
  String get opsDueTitle => 'Habituels pas encore saisis';

  @override
  String get opsEmptyFirst =>
      'Ton carnet est vide. Ajoute ta première dépense avec le bouton +, ou charge quelques exemples pour voir le carnet rempli.';

  @override
  String opsEmptyMonth(String month) {
    return 'Aucune opération en $month.';
  }

  @override
  String opsEmptyMonthAccount(String month) {
    return 'Aucune opération en $month sur ce compte.';
  }

  @override
  String get opsFilterAll => 'Tout';

  @override
  String get opsForecastBalance => ' · solde ≈ ';

  @override
  String opsForecastDay(int day, int days) {
    return 'Jour $day sur $days, d\'après ton rythme et tes habitudes.';
  }

  @override
  String get opsForecastExpenses => 'Dépenses ≈ ';

  @override
  String opsForecastOver(String amount) {
    return 'À ce rythme, le budget serait dépassé de $amount.';
  }

  @override
  String get opsForecastTitle => 'Prévision de fin de mois';

  @override
  String get opsHeroBalance => 'SOLDE DU MOIS';

  @override
  String get opsJournal => 'Journal';

  @override
  String get opsLoadSamples => 'Charger des exemples';

  @override
  String opsRecurringPlanned(String date) {
    return 'prévu le $date';
  }

  @override
  String opsRecurringUsual(int day) {
    return 'habituellement vers le $day';
  }

  @override
  String get opsSamplesLoaded =>
      'Exemples chargés. Tu pourras les retirer dans Paramètres › Données.';

  @override
  String get proofAdd => 'Ajouter un justificatif (photo, reçu)';

  @override
  String get proofCamera => 'Prendre une photo';

  @override
  String get proofGallery => 'Choisir dans la galerie';

  @override
  String get proofRemove => 'Retirer';

  @override
  String get proofReplace => 'Remplacer';

  @override
  String get proofTapToView => 'Touche l\'image pour l\'agrandir';

  @override
  String get proofTitle => 'Justificatif';

  @override
  String get save => 'Enregistrer';

  @override
  String savingsBefore(String date) {
    return 'avant le $date';
  }

  @override
  String get savingsEmpty =>
      'Crée un objectif (fonds d\'urgence, voyage, voiture…) puis mets de l\'argent de côté depuis tes comptes. L\'argent épargné quitte le compte et s\'ajoute à l\'objectif.';

  @override
  String get savingsMyGoals => 'Mes objectifs';

  @override
  String get savingsNewGoal => 'Nouvel objectif';

  @override
  String get savingsNoTarget =>
      'Fixe un montant à tes objectifs pour suivre tes progrès';

  @override
  String savingsOfTarget(String amount) {
    return 'sur $amount';
  }

  @override
  String savingsOfTargets(String amount) {
    return 'sur $amount d\'objectifs';
  }

  @override
  String savingsPerMonth(String amount) {
    return '$amount par mois pour y arriver';
  }

  @override
  String savingsPercent(String pct) {
    return '$pct %';
  }

  @override
  String get savingsPutAside => 'Mettre de côté';

  @override
  String get savingsReached => 'Atteint';

  @override
  String savingsReachedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objectifs atteints',
      one: '$count objectif atteint',
    );
    return '$_temp0';
  }

  @override
  String get savingsSampleTag => 'EXEMPLE';

  @override
  String get savingsTotalLabel => 'Total mis de côté';

  @override
  String get savingsWithdraw => 'Retirer';

  @override
  String get securityBioCancelled => 'Vérification biométrique annulée';

  @override
  String get securityBioEnableReason =>
      'Confirme pour activer le déverrouillage biométrique';

  @override
  String get securityBioNone =>
      'Aucune empreinte ou visage enregistré sur ce téléphone. Ajoute-en dans les réglages d\'Android.';

  @override
  String get securityBioOn =>
      'Déverrouille sans taper le code. Le code reste possible.';

  @override
  String get securityBioTitle => 'Empreinte ou reconnaissance faciale';

  @override
  String get securityBioUnlockReason => 'Déverrouille my-nkap';

  @override
  String get securityChange => 'Changer le code';

  @override
  String get securityCodeChanged =>
      'Code modifié. Les prochaines sauvegardes utiliseront le nouveau code.';

  @override
  String get securityCodeOn => 'Code activé';

  @override
  String get securityCodeRemoved => 'Code retiré';

  @override
  String get securityCurrentCode => 'Code actuel';

  @override
  String securityDelayMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Après $count minutes',
      one: 'Après $count minute',
    );
    return '$_temp0';
  }

  @override
  String get securityDelayNow => 'Immédiatement';

  @override
  String securityDelaySeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Après $count secondes',
      one: 'Après $count seconde',
    );
    return '$_temp0';
  }

  @override
  String securityDelayShort(int seconds) {
    return 'Après $seconds s';
  }

  @override
  String get securityEnable => 'Activer un code';

  @override
  String get securityEnterCurrent => 'Saisis ton code actuel';

  @override
  String get securityEnterToRemove => 'Saisis ton code pour le retirer';

  @override
  String get securityFootnote =>
      'Le code n\'est jamais enregistré en clair : seule une empreinte chiffrée est gardée dans le coffre sécurisé d\'Android. Après 5 erreurs, la saisie est bloquée un moment, et ce délai double à chaque nouvelle erreur. Le code sert aussi à chiffrer tes sauvegardes Google Drive.';

  @override
  String get securityLockNow => 'Verrouiller maintenant';

  @override
  String get securityLockOnLeave => 'Verrouiller quand je quitte l\'app';

  @override
  String get securityProtected => 'App protégée';

  @override
  String get securityProtectedDesc =>
      'Code activé. L\'app le demande à l\'ouverture.';

  @override
  String get securityProtectedDescBio =>
      'Code activé · empreinte. L\'app le demande à l\'ouverture.';

  @override
  String get securityRemove => 'Retirer le code';

  @override
  String get securityTitle => 'Sécurité';

  @override
  String get securityUnprotected => 'App non protégée';

  @override
  String get securityUnprotectedDesc =>
      'N\'importe qui ayant ton téléphone peut ouvrir l\'app.';

  @override
  String get settingsAccountsHint =>
      'Le solde de départ est l\'argent présent sur le compte avant ta première saisie. Pour corriger un solde plus tard, utilise « Ajuster le solde » dans l\'onglet Comptes.';

  @override
  String get settingsAppearanceNote =>
      'La langue et le thème changent après « Enregistrer ».';

  @override
  String get settingsCap => 'Plafond';

  @override
  String get settingsCapsNote =>
      'Les plafonds par catégorie se règlent dans l\'onglet Catégories.';

  @override
  String get settingsCatsArchiveNote =>
      'Une catégorie déjà utilisée est masquée plutôt qu\'effacée, pour garder l\'historique intact.';

  @override
  String get settingsCatsCapHint =>
      'Le plafond mensuel est facultatif : la catégorie passe au rouge s\'il est dépassé.';

  @override
  String get settingsCatsHint => 'Touche l\'icône pour la changer.';

  @override
  String get settingsCurrency => 'Devise';

  @override
  String settingsDataFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opérations au total',
      one: '$count opération au total',
    );
    return '$_temp0. Les données restent sur ce téléphone.';
  }

  @override
  String get settingsDefault => 'Par défaut';

  @override
  String get settingsExpenses => 'Dépenses';

  @override
  String get settingsExportCsv => 'Exporter en CSV';

  @override
  String get settingsExportText =>
      'Un fichier CSV avec toutes tes opérations, lisible dans Excel ou Google Sheets.';

  @override
  String get settingsExportTitle => 'Exporter';

  @override
  String get settingsIncomes => 'Revenus';

  @override
  String get settingsInitialBalance => 'Solde de départ';

  @override
  String get settingsKeepOneAccount => 'Garde au moins un compte.';

  @override
  String get settingsKeepOneCategory =>
      'Garde au moins une catégorie de ce type.';

  @override
  String get settingsMonthlyBudget => 'Budget mensuel total';

  @override
  String get settingsName => 'Nom';

  @override
  String get settingsNewAccount => 'Nouveau compte';

  @override
  String get settingsNewCategory => 'Nouvelle catégorie';

  @override
  String get settingsNewIncome => 'Nouveau revenu';

  @override
  String get settingsNone => 'Aucun';

  @override
  String get settingsSamplesNo => 'Aucune donnée d\'exemple.';

  @override
  String get settingsSamplesRemove => 'Retirer les exemples';

  @override
  String get settingsSamplesRemoved => 'Exemples retirés';

  @override
  String get settingsSamplesTitle => 'Données d\'exemple';

  @override
  String get settingsSamplesYes => 'Le carnet contient des données d\'exemple.';

  @override
  String get settingsSaved => 'Paramètres enregistrés';

  @override
  String get settingsTabAppearance => 'Apparence';

  @override
  String get settingsTabData => 'Données';

  @override
  String get settingsTabMoney => 'Devise et budget';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeAuto => 'Automatique';

  @override
  String get settingsThemeAutoDesc => 'Suit le réglage du téléphone';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeDarkDesc => 'Mode nuit permanent';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeLightDesc => 'Toujours clair';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsWipeButton => 'Effacer toutes les données';

  @override
  String get settingsWipeText =>
      'Supprime toutes les opérations, objectifs et dettes. Tes catégories, comptes et réglages sont gardés. Exporte un CSV avant si tu veux garder une trace.';

  @override
  String get settingsWipeTitle => 'Tout effacer';

  @override
  String get settingsWiped => 'Données effacées';

  @override
  String get sheetsAccount => 'Compte';

  @override
  String get sheetsAdjust => 'Ajuster';

  @override
  String get sheetsAdjustExplain =>
      'Un ajustement corrige le solde d\'un compte sans compter comme revenu ou dépense.';

  @override
  String get sheetsAdjustIntro =>
      'Indique ce qu\'il y a vraiment sur le compte. La différence est enregistrée comme un ajustement, qui ne compte ni comme revenu ni comme dépense.';

  @override
  String get sheetsAdjustNoteHint => 'Frais bancaires, oubli…';

  @override
  String sheetsAdjustTitle(String name) {
    return 'Ajuster : $name';
  }

  @override
  String get sheetsAmount => 'Montant';

  @override
  String get sheetsAmountPositive => 'Indique un montant supérieur à zéro.';

  @override
  String sheetsBalanceAdjusted(String amount) {
    return 'Solde ajusté ($amount)';
  }

  @override
  String get sheetsBalanceAlreadyRight => 'Le solde est déjà juste.';

  @override
  String sheetsBookBalance(String amount) {
    return 'Solde dans le carnet : $amount';
  }

  @override
  String get sheetsCategory => 'Catégorie';

  @override
  String get sheetsDate => 'Date';

  @override
  String get sheetsDebtAccountHint =>
      'Choisis un compte pour que l\'argent reçu ou prêté apparaisse dans son solde, ou « Ne pas toucher à mes comptes » pour une dette ancienne.';

  @override
  String get sheetsDebtAdded => 'Dette ajoutée';

  @override
  String get sheetsDebtDeleteHint =>
      'Supprimer la dette efface aussi ses remboursements enregistrés.';

  @override
  String get sheetsDebtDeleted => 'Dette supprimée';

  @override
  String get sheetsDebtDue => 'Échéance';

  @override
  String get sheetsDebtEditTitle => 'Modifier la dette';

  @override
  String get sheetsDebtExplain => 'Ce mouvement se gère depuis Plus › Dettes.';

  @override
  String get sheetsDebtIOwe => 'Je dois';

  @override
  String sheetsDebtLeftMax(String amount) {
    return 'Le reste dû est de $amount.';
  }

  @override
  String sheetsDebtLeftToPay(String left, String total) {
    return 'Reste à payer : $left sur $total';
  }

  @override
  String sheetsDebtLeftToReceive(String left, String total) {
    return 'Reste à recevoir : $left sur $total';
  }

  @override
  String get sheetsDebtNewTitle => 'Nouvelle dette';

  @override
  String get sheetsDebtOwedToMe => 'On me doit';

  @override
  String get sheetsDebtPaidFrom => 'Payé depuis';

  @override
  String get sheetsDebtPaidOutOf => 'L\'argent est sorti de';

  @override
  String get sheetsDebtPerson => 'Personne ou organisme';

  @override
  String get sheetsDebtPersonHintLent => 'À qui as-tu prêté ?';

  @override
  String get sheetsDebtPersonHintOwe => 'Qui t\'a prêté l\'argent ?';

  @override
  String get sheetsDebtPersonMissing => 'Indique la personne ou l\'organisme.';

  @override
  String get sheetsDebtReceivedIn => 'Reçu sur';

  @override
  String get sheetsDebtReceivedOn => 'J\'ai reçu l\'argent sur';

  @override
  String sheetsDebtRepayTitle(String person) {
    return 'Rembourser $person';
  }

  @override
  String sheetsDebtRepaymentFromTitle(String person) {
    return 'Remboursement de $person';
  }

  @override
  String get sheetsDebtSettled => 'Dette soldée';

  @override
  String get sheetsDebtTotal => 'Montant total';

  @override
  String get sheetsDebtUpdated => 'Dette mise à jour';

  @override
  String get sheetsDeleteIfMistake =>
      'Tu peux le supprimer ici si c\'était une erreur.';

  @override
  String get sheetsDeleteMovement => 'Supprimer ce mouvement';

  @override
  String get sheetsExpenseAdded => 'Dépense ajoutée';

  @override
  String get sheetsFromAccount => 'Depuis le compte';

  @override
  String get sheetsGoalCreate => 'Créer l\'objectif';

  @override
  String get sheetsGoalCreated => 'Objectif créé';

  @override
  String get sheetsGoalDeadline => 'Date visée (facultatif)';

  @override
  String get sheetsGoalDeleteHint =>
      'Supprimer l\'objectif efface aussi ses mouvements : l\'argent revient sur les comptes d\'origine.';

  @override
  String get sheetsGoalDeleted => 'Objectif supprimé';

  @override
  String get sheetsGoalEditTitle => 'Modifier l\'objectif';

  @override
  String get sheetsGoalInitial => 'Déjà mis de côté (facultatif)';

  @override
  String get sheetsGoalNameHint => 'Fonds d\'urgence, voyage, voiture…';

  @override
  String get sheetsGoalNameMissing => 'Donne un nom à l\'objectif.';

  @override
  String get sheetsGoalNewTitle => 'Nouvel objectif d\'épargne';

  @override
  String get sheetsGoalPutAside => 'Mettre de côté';

  @override
  String sheetsGoalPutAsideDone(String amount) {
    return '$amount mis de côté';
  }

  @override
  String sheetsGoalPutAsideTitle(String name) {
    return 'Mettre de côté : $name';
  }

  @override
  String sheetsGoalSaved(String amount) {
    return 'Déjà épargné : $amount';
  }

  @override
  String sheetsGoalSavedOf(String amount, String target) {
    return 'Déjà épargné : $amount sur $target';
  }

  @override
  String get sheetsGoalTarget => 'Montant visé';

  @override
  String get sheetsGoalUpdated => 'Objectif mis à jour';

  @override
  String get sheetsGoalWithdraw => 'Retirer';

  @override
  String sheetsGoalWithdrawDone(String amount) {
    return '$amount retirés de l\'épargne';
  }

  @override
  String sheetsGoalWithdrawMax(String amount) {
    return 'Tu ne peux pas retirer plus que $amount.';
  }

  @override
  String sheetsGoalWithdrawTitle(String name) {
    return 'Retirer de : $name';
  }

  @override
  String get sheetsIcon => 'Icône';

  @override
  String get sheetsIncomeAdded => 'Revenu ajouté';

  @override
  String sheetsInfoAccount(String account) {
    return 'Compte : $account';
  }

  @override
  String sheetsInfoAmount(String amount) {
    return 'Montant : $amount';
  }

  @override
  String sheetsInfoDate(String date) {
    return 'Date : $date';
  }

  @override
  String get sheetsLoanAdded => 'Prêt ajouté';

  @override
  String get sheetsMovementDeleted => 'Mouvement supprimé';

  @override
  String get sheetsName => 'Nom';

  @override
  String get sheetsNote => 'Note';

  @override
  String get sheetsPickIcon => 'Choisir une icône';

  @override
  String get sheetsRealBalance => 'Solde réel';

  @override
  String get sheetsRealBalanceMissing => 'Indique le solde réel du compte.';

  @override
  String get sheetsRepaymentSaved => 'Remboursement enregistré';

  @override
  String get sheetsSaveExplain => 'Ce mouvement se gère depuis Plus › Épargne.';

  @override
  String get sheetsSaveRepayment => 'Enregistrer le remboursement';

  @override
  String get sheetsSuggested => 'suggérée d\'après la note';

  @override
  String get sheetsToAccount => 'Vers le compte';

  @override
  String get sheetsTransferSameAccount =>
      'Choisis deux comptes différents pour un transfert.';

  @override
  String get sheetsTransferSaved => 'Transfert enregistré';

  @override
  String get sheetsTxDeleted => 'Opération supprimée';

  @override
  String get sheetsTxEditTitle => 'Modifier l\'opération';

  @override
  String get sheetsTxNoteHint => 'Marché, taxi, facture ENEO…';

  @override
  String get sheetsTxUpdated => 'Opération mise à jour';

  @override
  String get sheetsUpdate => 'Mettre à jour';

  @override
  String get stateGroupTransfer => 'Transfert';

  @override
  String get stateNoCategory => 'Sans catégorie';

  @override
  String get stateSampleDebtTontine => 'Tontine du quartier';

  @override
  String get stateSampleGoalEmergency => 'Fonds d\'urgence';

  @override
  String get stateSampleNoteCinema => 'Cinéma et sortie';

  @override
  String get stateSampleNoteDoctor => 'Consultation';

  @override
  String get stateSampleNoteEneo => 'Électricité ENEO';

  @override
  String get stateSampleNoteFreelance => 'Mission freelance';

  @override
  String get stateSampleNoteFuel => 'Carburant';

  @override
  String get stateSampleNoteGroceries => 'Courses du mois';

  @override
  String get stateSampleNoteInternet => 'Forfait internet';

  @override
  String get stateSampleNoteLessons => 'Cours d\'anglais';

  @override
  String get stateSampleNoteLunch => 'Déjeuner au tourne-dos';

  @override
  String get stateSampleNoteMotoTaxi => 'Moto-taxi';

  @override
  String get stateSampleNoteParents => 'Aide aux parents';

  @override
  String get stateSampleNotePharmacy => 'Pharmacie';

  @override
  String get stateSampleNotePhone => 'Téléphone';

  @override
  String get stateSampleNoteRent => 'Loyer';

  @override
  String get stateSampleNoteRentAdvance => 'Avance pour son loyer';

  @override
  String get stateSampleNoteSalary => 'Salaire';

  @override
  String get stateSampleNoteShoes => 'Chaussures';

  @override
  String get stateSampleNoteSupermarket => 'Supermarché';

  @override
  String get stateSampleNoteTopUp => 'Recharge';

  @override
  String get stateSampleNoteUtilities => 'Électricité et eau';

  @override
  String get stateSampleNoteWeekend => 'Week-end';

  @override
  String get stateSampleNoteWeeklyMarket => 'Marché de la semaine';

  @override
  String get stateSampleNoteWithdrawal => 'Retrait au guichet';

  @override
  String get statementAccounts => 'Comptes';

  @override
  String get statementCustom => 'Dates au choix';

  @override
  String get statementFrom => 'Du';

  @override
  String get statementHelp =>
      '« Aperçu et impression » ouvre l\'impression Android, qui permet aussi d\'enregistrer en PDF. « Partager » l\'envoie par WhatsApp, e-mail ou vers tes fichiers.';

  @override
  String get statementIncludeCats => 'Inclure les dépenses par catégorie';

  @override
  String get statementIncludePlans => 'Inclure l\'épargne et les dettes';

  @override
  String get statementIntro =>
      'Un document A4 prêt à imprimer : soldes d\'ouverture et de clôture, toutes les opérations de la période avec le solde après chaque ligne, puis les dépenses par catégorie.';

  @override
  String get statementPdfFailed => 'La création du PDF a échoué.';

  @override
  String get statementPeriod => 'Période';

  @override
  String get statementPickPeriod => 'Choisis une période valide.';

  @override
  String get statementPlansAllOnly =>
      'Seulement pour le relevé de tous les comptes';

  @override
  String get statementPreview => 'Aperçu et impression';

  @override
  String get statementShare => 'Partager le PDF';

  @override
  String get statementTitle => 'Relevé PDF';

  @override
  String get statementTo => 'Au';

  @override
  String statementYear(String year) {
    return 'Année $year';
  }

  @override
  String get statsDailySpend => 'dépense courante par jour';

  @override
  String get statsNoExpenses => 'Aucune dépense ce mois-ci.';

  @override
  String get statsNothingToCompare => 'Rien à comparer pour l\'instant.';

  @override
  String get statsOpsThisMonth => 'opérations ce mois-ci';

  @override
  String statsPercent(String value) {
    return '$value %';
  }

  @override
  String get statsSavingsRate => 'taux d\'épargne';

  @override
  String get statsSixMonths => 'Six derniers mois';

  @override
  String get statsTopExpenses => 'Plus grosses dépenses';

  @override
  String get statsVsPrevMonth => 'dépenses vs mois précédent';

  @override
  String get statsWhereEmpty =>
      'Les dépenses du mois apparaîtront ici, réparties par catégorie.';

  @override
  String get statsWhereMoneyGoes => 'Où part l\'argent';

  @override
  String get tabAccounts => 'Comptes';

  @override
  String get tabCategories => 'Catégories';

  @override
  String get tabMore => 'Plus';

  @override
  String get tabOps => 'Opérations';

  @override
  String get tabStats => 'Statistiques';

  @override
  String get totalsExpenses => 'Dépenses';

  @override
  String get totalsIncome => 'Revenus';

  @override
  String get typeAdjust => 'Ajustement';

  @override
  String get typeDebt => 'Dette';

  @override
  String get typeExpense => 'Dépense';

  @override
  String get typeIncome => 'Revenu';

  @override
  String get typeSave => 'Épargne';

  @override
  String get typeTransfer => 'Virement';

  @override
  String get unnamedAccount => 'Compte';

  @override
  String get unnamedCategory => 'Sans nom';

  @override
  String get yes => 'Oui';
}
