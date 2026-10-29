import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @accountsAdjust.
  ///
  /// In fr, this message translates to:
  /// **'Ajuster le solde'**
  String get accountsAdjust;

  /// No description provided for @accountsDefault.
  ///
  /// In fr, this message translates to:
  /// **'par défaut'**
  String get accountsDefault;

  /// No description provided for @accountsIOwe.
  ///
  /// In fr, this message translates to:
  /// **'Je dois'**
  String get accountsIOwe;

  /// No description provided for @accountsMine.
  ///
  /// In fr, this message translates to:
  /// **'Mes comptes'**
  String get accountsMine;

  /// No description provided for @accountsNetWorth.
  ///
  /// In fr, this message translates to:
  /// **'Patrimoine net'**
  String get accountsNetWorth;

  /// No description provided for @accountsOnAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Sur mes comptes'**
  String get accountsOnAccounts;

  /// No description provided for @accountsOps.
  ///
  /// In fr, this message translates to:
  /// **'Opérations'**
  String get accountsOps;

  /// No description provided for @accountsOwedToMe.
  ///
  /// In fr, this message translates to:
  /// **'On me doit'**
  String get accountsOwedToMe;

  /// No description provided for @accountsShare.
  ///
  /// In fr, this message translates to:
  /// **'{pct} % de ton argent disponible'**
  String accountsShare(int pct);

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'my-nkap'**
  String get appTitle;

  /// No description provided for @assistantApplied.
  ///
  /// In fr, this message translates to:
  /// **'Budget et plafonds appliqués'**
  String get assistantApplied;

  /// No description provided for @assistantApply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer ce budget'**
  String get assistantApply;

  /// No description provided for @assistantApplyNote.
  ///
  /// In fr, this message translates to:
  /// **'Remplace ton budget mensuel et les plafonds de tes catégories de dépenses. Tu pourras les modifier ensuite dans Paramètres.'**
  String get assistantApplyNote;

  /// No description provided for @assistantCapPerCat.
  ///
  /// In fr, this message translates to:
  /// **'Plafond par catégorie'**
  String get assistantCapPerCat;

  /// No description provided for @assistantCreateGoal.
  ///
  /// In fr, this message translates to:
  /// **'Créer un objectif'**
  String get assistantCreateGoal;

  /// No description provided for @assistantGoals.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs d\'épargne'**
  String get assistantGoals;

  /// No description provided for @assistantGoalsReached.
  ///
  /// In fr, this message translates to:
  /// **'Tous tes objectifs sont atteints.'**
  String get assistantGoalsReached;

  /// No description provided for @assistantIncomeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Revenus mensuels'**
  String get assistantIncomeLabel;

  /// No description provided for @assistantIntro.
  ///
  /// In fr, this message translates to:
  /// **'Indique ce que tu gagnes par mois : l\'assistant propose un budget, un plafond par catégorie et ce qu\'il faut mettre de côté pour tes objectifs.'**
  String get assistantIntro;

  /// No description provided for @assistantMethod.
  ///
  /// In fr, this message translates to:
  /// **'Méthode'**
  String get assistantMethod;

  /// No description provided for @assistantMonthlyBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget mensuel (dépenses courantes)'**
  String get assistantMonthlyBudget;

  /// No description provided for @assistantNeeds.
  ///
  /// In fr, this message translates to:
  /// **'Besoins'**
  String get assistantNeeds;

  /// No description provided for @assistantNeedsSub.
  ///
  /// In fr, this message translates to:
  /// **'Logement, factures, alimentation, transport…'**
  String get assistantNeedsSub;

  /// No description provided for @assistantNoGoals.
  ///
  /// In fr, this message translates to:
  /// **'Aucun objectif pour l\'instant. Commence par un fonds d\'urgence d\'environ 3 mois de dépenses, soit à peu près {amount}.'**
  String assistantNoGoals(String amount);

  /// No description provided for @assistantPerMonth.
  ///
  /// In fr, this message translates to:
  /// **'{amount} / mois'**
  String assistantPerMonth(String amount);

  /// No description provided for @assistantPrefilled.
  ///
  /// In fr, this message translates to:
  /// **'Pré-rempli avec ta moyenne des 3 derniers mois.'**
  String get assistantPrefilled;

  /// No description provided for @assistantProposal.
  ///
  /// In fr, this message translates to:
  /// **'Proposition'**
  String get assistantProposal;

  /// No description provided for @assistantRule503020Desc.
  ///
  /// In fr, this message translates to:
  /// **'La règle classique : 50 % pour les besoins, 30 % pour les envies, 20 % pour l\'épargne.'**
  String get assistantRule503020Desc;

  /// No description provided for @assistantRule702010Desc.
  ///
  /// In fr, this message translates to:
  /// **'Plus réaliste quand le loyer et la nourriture pèsent lourd : 70 % besoins, 20 % envies, 10 % épargne.'**
  String get assistantRule702010Desc;

  /// No description provided for @assistantRuleHistory.
  ///
  /// In fr, this message translates to:
  /// **'Mes habitudes'**
  String get assistantRuleHistory;

  /// No description provided for @assistantRuleHistoryDesc.
  ///
  /// In fr, this message translates to:
  /// **'Part de tes dépenses réelles des 3 derniers mois, et garde le reste pour l\'épargne.'**
  String get assistantRuleHistoryDesc;

  /// No description provided for @assistantTitle.
  ///
  /// In fr, this message translates to:
  /// **'Assistant budget'**
  String get assistantTitle;

  /// No description provided for @assistantWants.
  ///
  /// In fr, this message translates to:
  /// **'Envies'**
  String get assistantWants;

  /// No description provided for @assistantWantsSub.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant, loisirs, shopping…'**
  String get assistantWantsSub;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @backupCodeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le code de verrouillage qui était actif quand cette sauvegarde a été faite'**
  String get backupCodeSubtitle;

  /// No description provided for @backupCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code de la sauvegarde'**
  String get backupCodeTitle;

  /// No description provided for @backupConnectIntro.
  ///
  /// In fr, this message translates to:
  /// **'Connecte ton compte Google pour enregistrer une copie chiffrée de tes données dans un espace privé de ton propre Drive. Tu pourras la restaurer sur un autre téléphone.'**
  String get backupConnectIntro;

  /// No description provided for @backupConnected.
  ///
  /// In fr, this message translates to:
  /// **'Compte Google connecté'**
  String get backupConnected;

  /// No description provided for @backupDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde supprimée'**
  String get backupDeleted;

  /// No description provided for @backupDisconnect.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter le compte Google'**
  String get backupDisconnect;

  /// No description provided for @backupDisconnected.
  ///
  /// In fr, this message translates to:
  /// **'Compte Google déconnecté de l\'app'**
  String get backupDisconnected;

  /// No description provided for @backupDriveRefused.
  ///
  /// In fr, this message translates to:
  /// **'Google Drive a refusé la demande ({status}).'**
  String backupDriveRefused(String status);

  /// No description provided for @backupDriveRefusedDetail.
  ///
  /// In fr, this message translates to:
  /// **'Google Drive a refusé la demande ({status} : {detail}).'**
  String backupDriveRefusedDetail(String status, String detail);

  /// No description provided for @backupEnablePin.
  ///
  /// In fr, this message translates to:
  /// **'Activer un code'**
  String get backupEnablePin;

  /// No description provided for @backupInfo.
  ///
  /// In fr, this message translates to:
  /// **'L\'app ne se connecte à internet que quand tu touches un de ces boutons. Les {count} dernières sauvegardes sont gardées, chiffrées avec ton code, dans un dossier caché de ton Drive que seule my-nkap peut lire.'**
  String backupInfo(int count);

  /// No description provided for @backupInvalidFile.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier n\'est pas une sauvegarde my-nkap valide.'**
  String get backupInvalidFile;

  /// No description provided for @backupLast.
  ///
  /// In fr, this message translates to:
  /// **'Dernière synchronisation : {date}'**
  String backupLast(String date);

  /// No description provided for @backupListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardes sur Drive'**
  String get backupListTitle;

  /// No description provided for @backupNeedPin.
  ///
  /// In fr, this message translates to:
  /// **'Active un code de verrouillage : il sert à chiffrer tes sauvegardes.'**
  String get backupNeedPin;

  /// No description provided for @backupNetworkError.
  ///
  /// In fr, this message translates to:
  /// **'Opération impossible. Vérifie ta connexion internet.'**
  String get backupNetworkError;

  /// No description provided for @backupNever.
  ///
  /// In fr, this message translates to:
  /// **'Jamais synchronisé depuis ce téléphone'**
  String get backupNever;

  /// No description provided for @backupNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sauvegarde pour ce compte.'**
  String get backupNone;

  /// No description provided for @backupNotConfigured.
  ///
  /// In fr, this message translates to:
  /// **'La synchronisation Google Drive n\'est pas configurée dans cette version de l\'app.'**
  String get backupNotConfigured;

  /// No description provided for @backupRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get backupRefresh;

  /// No description provided for @backupRestore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer'**
  String get backupRestore;

  /// No description provided for @backupRestoreText.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les données actuelles de ce téléphone seront remplacées par celles du {date}. Synchronise d\'abord si tu veux garder l\'état actuel.'**
  String backupRestoreText(String date);

  /// No description provided for @backupRestoreTitle.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer cette sauvegarde ?'**
  String get backupRestoreTitle;

  /// No description provided for @backupRestored.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde restaurée'**
  String get backupRestored;

  /// No description provided for @backupSent.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde envoyée sur ton Google Drive'**
  String get backupSent;

  /// No description provided for @backupShow.
  ///
  /// In fr, this message translates to:
  /// **'Afficher'**
  String get backupShow;

  /// No description provided for @backupShowHint.
  ///
  /// In fr, this message translates to:
  /// **'Touche « Afficher » pour voir les sauvegardes de ce compte (connexion internet nécessaire).'**
  String get backupShowHint;

  /// No description provided for @backupSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec Google'**
  String get backupSignIn;

  /// No description provided for @backupSignInCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Connexion annulée.'**
  String get backupSignInCancelled;

  /// No description provided for @backupSignInFailed.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google impossible ({code}).'**
  String backupSignInFailed(String code);

  /// No description provided for @backupSignInFailedDetail.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google impossible ({code} : {detail}).'**
  String backupSignInFailedDetail(String code, String detail);

  /// No description provided for @backupSize.
  ///
  /// In fr, this message translates to:
  /// **'{size} Ko'**
  String backupSize(String size);

  /// No description provided for @backupSizeLatest.
  ///
  /// In fr, this message translates to:
  /// **'{size} Ko · la plus récente'**
  String backupSizeLatest(String size);

  /// No description provided for @backupSyncNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser maintenant'**
  String get backupSyncNow;

  /// No description provided for @backupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation'**
  String get backupTitle;

  /// No description provided for @backupUnreadable.
  ///
  /// In fr, this message translates to:
  /// **'Cette sauvegarde est illisible ou vient d\'une autre application.'**
  String get backupUnreadable;

  /// No description provided for @backupWhen.
  ///
  /// In fr, this message translates to:
  /// **'{date} à {time}'**
  String backupWhen(String date, String time);

  /// No description provided for @backupWrongCode.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect pour cette sauvegarde. Il faut le code qui était actif au moment où elle a été faite.'**
  String get backupWrongCode;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @catsByCategory.
  ///
  /// In fr, this message translates to:
  /// **'Par catégorie'**
  String get catsByCategory;

  /// No description provided for @catsCap.
  ///
  /// In fr, this message translates to:
  /// **'plafond {amount}'**
  String catsCap(String amount);

  /// No description provided for @catsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} catégorie} other{{count} catégories}}'**
  String catsCount(int count);

  /// No description provided for @catsManage.
  ///
  /// In fr, this message translates to:
  /// **'Gérer'**
  String get catsManage;

  /// No description provided for @catsNoOps.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération ce mois-ci'**
  String get catsNoOps;

  /// No description provided for @catsOver.
  ///
  /// In fr, this message translates to:
  /// **'Dépassé'**
  String get catsOver;

  /// No description provided for @catsOverCaps.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} plafond dépassé} other{{count} plafonds dépassés}}'**
  String catsOverCaps(int count);

  /// No description provided for @catsReceivedIn.
  ///
  /// In fr, this message translates to:
  /// **'Reçu en {month}'**
  String catsReceivedIn(String month);

  /// No description provided for @catsShareOfTotal.
  ///
  /// In fr, this message translates to:
  /// **'{pct} % du total'**
  String catsShareOfTotal(int pct);

  /// No description provided for @catsSpentIn.
  ///
  /// In fr, this message translates to:
  /// **'Dépensé en {month}'**
  String catsSpentIn(String month);

  /// No description provided for @catsTop.
  ///
  /// In fr, this message translates to:
  /// **'la plus forte : {name}'**
  String catsTop(String name);

  /// No description provided for @catsUnused.
  ///
  /// In fr, this message translates to:
  /// **'Sans opération ce mois-ci'**
  String get catsUnused;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @commonBorrowFrom.
  ///
  /// In fr, this message translates to:
  /// **'Emprunt auprès de {who}'**
  String commonBorrowFrom(String who);

  /// No description provided for @commonClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get commonClear;

  /// No description provided for @commonConfirmDelete.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get commonConfirmDelete;

  /// No description provided for @commonDebtDeleted.
  ///
  /// In fr, this message translates to:
  /// **'dette supprimée'**
  String get commonDebtDeleted;

  /// No description provided for @commonFromAccount.
  ///
  /// In fr, this message translates to:
  /// **'Depuis {account}'**
  String commonFromAccount(String account);

  /// No description provided for @commonGoalDeleted.
  ///
  /// In fr, this message translates to:
  /// **'objectif supprimé'**
  String get commonGoalDeleted;

  /// No description provided for @commonLeaveAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Ne pas toucher à mes comptes'**
  String get commonLeaveAccounts;

  /// No description provided for @commonLendTo.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à {who}'**
  String commonLendTo(String who);

  /// No description provided for @commonNextMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois suivant'**
  String get commonNextMonth;

  /// No description provided for @commonNoCategory.
  ///
  /// In fr, this message translates to:
  /// **'Sans catégorie'**
  String get commonNoCategory;

  /// No description provided for @commonNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get commonNone;

  /// No description provided for @commonOffAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Hors comptes'**
  String get commonOffAccounts;

  /// No description provided for @commonPrevMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois précédent'**
  String get commonPrevMonth;

  /// No description provided for @commonRepayFrom.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement de {who}'**
  String commonRepayFrom(String who);

  /// No description provided for @commonRepayTo.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement à {who}'**
  String commonRepayTo(String who);

  /// No description provided for @commonSample.
  ///
  /// In fr, this message translates to:
  /// **'EXEMPLE'**
  String get commonSample;

  /// No description provided for @commonSavingFrom.
  ///
  /// In fr, this message translates to:
  /// **'Retrait d\'épargne : {name}'**
  String commonSavingFrom(String name);

  /// No description provided for @commonSavingTo.
  ///
  /// In fr, this message translates to:
  /// **'Épargne : {name}'**
  String commonSavingTo(String name);

  /// No description provided for @commonToAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vers {account}'**
  String commonToAccount(String account);

  /// No description provided for @commonTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get commonTransfer;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @curEUR.
  ///
  /// In fr, this message translates to:
  /// **'Euro (EUR)'**
  String get curEUR;

  /// No description provided for @curGHS.
  ///
  /// In fr, this message translates to:
  /// **'Cedi (GHS)'**
  String get curGHS;

  /// No description provided for @curGNF.
  ///
  /// In fr, this message translates to:
  /// **'Franc guinéen (GNF)'**
  String get curGNF;

  /// No description provided for @curMAD.
  ///
  /// In fr, this message translates to:
  /// **'Dirham marocain (MAD)'**
  String get curMAD;

  /// No description provided for @curNGN.
  ///
  /// In fr, this message translates to:
  /// **'Naira (NGN)'**
  String get curNGN;

  /// No description provided for @curUSD.
  ///
  /// In fr, this message translates to:
  /// **'Dollar US (USD)'**
  String get curUSD;

  /// No description provided for @curXAF.
  ///
  /// In fr, this message translates to:
  /// **'Franc CFA (XAF)'**
  String get curXAF;

  /// No description provided for @curXOF.
  ///
  /// In fr, this message translates to:
  /// **'Franc CFA (XOF)'**
  String get curXOF;

  /// No description provided for @debtsAddDebt.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une dette'**
  String get debtsAddDebt;

  /// No description provided for @debtsAddLoan.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un prêt'**
  String get debtsAddLoan;

  /// No description provided for @debtsBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde des dettes'**
  String get debtsBalance;

  /// No description provided for @debtsEmptyLent.
  ///
  /// In fr, this message translates to:
  /// **'Note l\'argent que tu as prêté et suis ce qu\'on te rembourse.'**
  String get debtsEmptyLent;

  /// No description provided for @debtsEmptyOwe.
  ///
  /// In fr, this message translates to:
  /// **'Note l\'argent que tu as emprunté et suis tes remboursements.'**
  String get debtsEmptyOwe;

  /// No description provided for @debtsIOwe.
  ///
  /// In fr, this message translates to:
  /// **'Je dois'**
  String get debtsIOwe;

  /// No description provided for @debtsIRepay.
  ///
  /// In fr, this message translates to:
  /// **'Je rembourse'**
  String get debtsIRepay;

  /// No description provided for @debtsLate.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get debtsLate;

  /// No description provided for @debtsNoneOpen.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dette en cours'**
  String get debtsNoneOpen;

  /// No description provided for @debtsOpenCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} dette en cours} other{{count} dettes en cours}}'**
  String debtsOpenCount(int count);

  /// No description provided for @debtsOwedToMe.
  ///
  /// In fr, this message translates to:
  /// **'On me doit'**
  String get debtsOwedToMe;

  /// No description provided for @debtsRepaidOf.
  ///
  /// In fr, this message translates to:
  /// **'{paid} remboursés sur {total}'**
  String debtsRepaidOf(String paid, String total);

  /// No description provided for @debtsSettled.
  ///
  /// In fr, this message translates to:
  /// **'Soldée'**
  String get debtsSettled;

  /// No description provided for @debtsSince.
  ///
  /// In fr, this message translates to:
  /// **'depuis le {date}'**
  String debtsSince(String date);

  /// No description provided for @debtsTheyRepay.
  ///
  /// In fr, this message translates to:
  /// **'On me rembourse'**
  String get debtsTheyRepay;

  /// No description provided for @debtsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dettes'**
  String get debtsTitle;

  /// No description provided for @defAccBank.
  ///
  /// In fr, this message translates to:
  /// **'Banque'**
  String get defAccBank;

  /// No description provided for @defAccCash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get defAccCash;

  /// No description provided for @defAccMomo.
  ///
  /// In fr, this message translates to:
  /// **'Mobile Money'**
  String get defAccMomo;

  /// No description provided for @defCatActivite.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get defCatActivite;

  /// No description provided for @defCatAlim.
  ///
  /// In fr, this message translates to:
  /// **'Alimentation'**
  String get defCatAlim;

  /// No description provided for @defCatAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get defCatAutre;

  /// No description provided for @defCatAutreIn.
  ///
  /// In fr, this message translates to:
  /// **'Autre revenu'**
  String get defCatAutreIn;

  /// No description provided for @defCatCadeau.
  ///
  /// In fr, this message translates to:
  /// **'Cadeau'**
  String get defCatCadeau;

  /// No description provided for @defCatEducation.
  ///
  /// In fr, this message translates to:
  /// **'Éducation'**
  String get defCatEducation;

  /// No description provided for @defCatFactures.
  ///
  /// In fr, this message translates to:
  /// **'Factures'**
  String get defCatFactures;

  /// No description provided for @defCatFamille.
  ///
  /// In fr, this message translates to:
  /// **'Famille'**
  String get defCatFamille;

  /// No description provided for @defCatLogement.
  ///
  /// In fr, this message translates to:
  /// **'Logement'**
  String get defCatLogement;

  /// No description provided for @defCatLoisirs.
  ///
  /// In fr, this message translates to:
  /// **'Loisirs'**
  String get defCatLoisirs;

  /// No description provided for @defCatResto.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant'**
  String get defCatResto;

  /// No description provided for @defCatSalaire.
  ///
  /// In fr, this message translates to:
  /// **'Salaire'**
  String get defCatSalaire;

  /// No description provided for @defCatSante.
  ///
  /// In fr, this message translates to:
  /// **'Santé'**
  String get defCatSante;

  /// No description provided for @defCatShopping.
  ///
  /// In fr, this message translates to:
  /// **'Shopping'**
  String get defCatShopping;

  /// No description provided for @defCatTelephone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone et internet'**
  String get defCatTelephone;

  /// No description provided for @defCatTransport.
  ///
  /// In fr, this message translates to:
  /// **'Transport'**
  String get defCatTransport;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @exportAllAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Tous les comptes'**
  String get exportAllAccounts;

  /// No description provided for @exportByCategory.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses par catégorie'**
  String get exportByCategory;

  /// No description provided for @exportClosing.
  ///
  /// In fr, this message translates to:
  /// **'Solde de clôture'**
  String get exportClosing;

  /// No description provided for @exportColAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get exportColAccount;

  /// No description provided for @exportColAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get exportColAmount;

  /// No description provided for @exportColBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde'**
  String get exportColBalance;

  /// No description provided for @exportColCap.
  ///
  /// In fr, this message translates to:
  /// **'Plafond mensuel'**
  String get exportColCap;

  /// No description provided for @exportColCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get exportColCategory;

  /// No description provided for @exportColCredit.
  ///
  /// In fr, this message translates to:
  /// **'Crédit'**
  String get exportColCredit;

  /// No description provided for @exportColDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get exportColDate;

  /// No description provided for @exportColDebit.
  ///
  /// In fr, this message translates to:
  /// **'Débit'**
  String get exportColDebit;

  /// No description provided for @exportColDirection.
  ///
  /// In fr, this message translates to:
  /// **'Sens'**
  String get exportColDirection;

  /// No description provided for @exportColDue.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get exportColDue;

  /// No description provided for @exportColGoal.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get exportColGoal;

  /// No description provided for @exportColLabel.
  ///
  /// In fr, this message translates to:
  /// **'Libellé'**
  String get exportColLabel;

  /// No description provided for @exportColLeft.
  ///
  /// In fr, this message translates to:
  /// **'Reste'**
  String get exportColLeft;

  /// No description provided for @exportColPerson.
  ///
  /// In fr, this message translates to:
  /// **'Personne'**
  String get exportColPerson;

  /// No description provided for @exportColProgress.
  ///
  /// In fr, this message translates to:
  /// **'Avancement'**
  String get exportColProgress;

  /// No description provided for @exportColRepaid.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé'**
  String get exportColRepaid;

  /// No description provided for @exportColSaved.
  ///
  /// In fr, this message translates to:
  /// **'Épargné'**
  String get exportColSaved;

  /// No description provided for @exportColShare.
  ///
  /// In fr, this message translates to:
  /// **'Part'**
  String get exportColShare;

  /// No description provided for @exportColTarget.
  ///
  /// In fr, this message translates to:
  /// **'Cible'**
  String get exportColTarget;

  /// No description provided for @exportColTargetDate.
  ///
  /// In fr, this message translates to:
  /// **'Date visée'**
  String get exportColTargetDate;

  /// No description provided for @exportCredits.
  ///
  /// In fr, this message translates to:
  /// **'Total crédits'**
  String get exportCredits;

  /// No description provided for @exportCsvSubject.
  ///
  /// In fr, this message translates to:
  /// **'Export my-nkap'**
  String get exportCsvSubject;

  /// No description provided for @exportCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise : {currency}'**
  String exportCurrency(String currency);

  /// No description provided for @exportDebits.
  ///
  /// In fr, this message translates to:
  /// **'Total débits'**
  String get exportDebits;

  /// No description provided for @exportDebtsLoans.
  ///
  /// In fr, this message translates to:
  /// **'Dettes et prêts'**
  String get exportDebtsLoans;

  /// No description provided for @exportEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération sur cette période.'**
  String get exportEmpty;

  /// No description provided for @exportFileName.
  ///
  /// In fr, this message translates to:
  /// **'releve-{from}-au-{to}'**
  String exportFileName(String from, String to);

  /// No description provided for @exportFooter.
  ///
  /// In fr, this message translates to:
  /// **'Relevé du {from} au {to} - document personnel, sans valeur bancaire officielle'**
  String exportFooter(String from, String to);

  /// No description provided for @exportIOwe.
  ///
  /// In fr, this message translates to:
  /// **'Je dois'**
  String get exportIOwe;

  /// No description provided for @exportIssued.
  ///
  /// In fr, this message translates to:
  /// **'Édité le {date}'**
  String exportIssued(String date);

  /// No description provided for @exportOpening.
  ///
  /// In fr, this message translates to:
  /// **'Solde d\'ouverture'**
  String get exportOpening;

  /// No description provided for @exportOwedToMe.
  ///
  /// In fr, this message translates to:
  /// **'On me doit'**
  String get exportOwedToMe;

  /// No description provided for @exportPage.
  ///
  /// In fr, this message translates to:
  /// **'Page {page} / {pages}'**
  String exportPage(String page, String pages);

  /// No description provided for @exportPdfDocTitle.
  ///
  /// In fr, this message translates to:
  /// **'Relevé my-nkap'**
  String get exportPdfDocTitle;

  /// No description provided for @exportPercent.
  ///
  /// In fr, this message translates to:
  /// **'{value} %'**
  String exportPercent(String value);

  /// No description provided for @exportPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Du {from} au {to}'**
  String exportPeriod(String from, String to);

  /// No description provided for @exportPeriodSummary.
  ///
  /// In fr, this message translates to:
  /// **'Revenus de la période : {income}   ·   Dépenses de la période : {expense}   ·   {ops}'**
  String exportPeriodSummary(String income, String expense, String ops);

  /// No description provided for @exportSettled.
  ///
  /// In fr, this message translates to:
  /// **'Soldée'**
  String get exportSettled;

  /// No description provided for @exportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Relevé de compte'**
  String get exportTitle;

  /// No description provided for @exportTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get exportTotal;

  /// No description provided for @exportTotals.
  ///
  /// In fr, this message translates to:
  /// **'Totaux'**
  String get exportTotals;

  /// No description provided for @exportTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get exportTransfer;

  /// No description provided for @exportTransferInternal.
  ///
  /// In fr, this message translates to:
  /// **'Transfert interne'**
  String get exportTransferInternal;

  /// No description provided for @fileBackupExport.
  ///
  /// In fr, this message translates to:
  /// **'Créer le fichier de sauvegarde'**
  String get fileBackupExport;

  /// No description provided for @fileBackupFailed.
  ///
  /// In fr, this message translates to:
  /// **'Opération impossible. Réessaie.'**
  String get fileBackupFailed;

  /// No description provided for @fileBackupImport.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer depuis un fichier'**
  String get fileBackupImport;

  /// No description provided for @fileBackupMoreSub.
  ///
  /// In fr, this message translates to:
  /// **'Tout dans un fichier protégé, sans compte Google'**
  String get fileBackupMoreSub;

  /// No description provided for @fileBackupPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get fileBackupPassword;

  /// No description provided for @fileBackupPasswordAgain.
  ///
  /// In fr, this message translates to:
  /// **'Confirme le mot de passe'**
  String get fileBackupPasswordAgain;

  /// No description provided for @fileBackupPasswordEnter.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe du fichier'**
  String get fileBackupPasswordEnter;

  /// No description provided for @fileBackupPasswordHelp.
  ///
  /// In fr, this message translates to:
  /// **'Il sera demandé pour restaurer. Note-le bien : il ne peut pas être récupéré.'**
  String get fileBackupPasswordHelp;

  /// No description provided for @fileBackupPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux mots de passe ne sont pas identiques.'**
  String get fileBackupPasswordMismatch;

  /// No description provided for @fileBackupPasswordNew.
  ///
  /// In fr, this message translates to:
  /// **'Protéger le fichier'**
  String get fileBackupPasswordNew;

  /// No description provided for @fileBackupPasswordShort.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 6 caractères.'**
  String get fileBackupPasswordShort;

  /// No description provided for @fileBackupPointAll.
  ///
  /// In fr, this message translates to:
  /// **'Un seul fichier avec tout : opérations, comptes, catégories, épargne, dettes, réglages et justificatifs.'**
  String get fileBackupPointAll;

  /// No description provided for @fileBackupPointOffline.
  ///
  /// In fr, this message translates to:
  /// **'Garde-le où tu veux (téléphone, clé USB, e-mail, WhatsApp…) et réimporte-le sur n\'importe quel téléphone.'**
  String get fileBackupPointOffline;

  /// No description provided for @fileBackupPointPassword.
  ///
  /// In fr, this message translates to:
  /// **'Chiffré avec un mot de passe que tu choisis : sans lui, personne ne peut l\'ouvrir.'**
  String get fileBackupPointPassword;

  /// No description provided for @fileBackupReplace.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer'**
  String get fileBackupReplace;

  /// No description provided for @fileBackupReplaceText.
  ///
  /// In fr, this message translates to:
  /// **'Les opérations, comptes, catégories, épargne, dettes et justificatifs actuels seront remplacés par ceux du fichier.'**
  String get fileBackupReplaceText;

  /// No description provided for @fileBackupReplaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer toutes les données ?'**
  String get fileBackupReplaceTitle;

  /// No description provided for @fileBackupRestored.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde restaurée'**
  String get fileBackupRestored;

  /// No description provided for @fileBackupSubject.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde my-nkap'**
  String get fileBackupSubject;

  /// No description provided for @fileBackupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde complète (fichier)'**
  String get fileBackupTitle;

  /// No description provided for @fileBackupWarning.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer remplace toutes les données de ce téléphone par celles du fichier. Si tu oublies le mot de passe, le fichier ne peut plus être ouvert.'**
  String get fileBackupWarning;

  /// No description provided for @greetingDay.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get greetingDay;

  /// No description provided for @greetingEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir'**
  String get greetingEvening;

  /// No description provided for @importBadLines.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} ligne illisible} other{{count} lignes illisibles}}'**
  String importBadLines(int count);

  /// No description provided for @importButton.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Importer {count} opération} other{Importer {count} opérations}}'**
  String importButton(int count);

  /// No description provided for @importCantRead.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire ce fichier.'**
  String get importCantRead;

  /// No description provided for @importCurrencyWarn.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier est en {file}, l\'app en {app} : les montants sont importés tels quels, sans conversion.'**
  String importCurrencyWarn(String file, String app);

  /// No description provided for @importDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} opération importée} other{{count} opérations importées}}'**
  String importDone(int count);

  /// No description provided for @importDuplicates.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} doublon ignoré (déjà dans l\'app)} other{{count} doublons ignorés (déjà dans l\'app)}}'**
  String importDuplicates(int count);

  /// No description provided for @importErrDebt.
  ///
  /// In fr, this message translates to:
  /// **'ligne {line} : dette sans personne ni sens'**
  String importErrDebt(String line);

  /// No description provided for @importErrEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier est vide.'**
  String get importErrEmpty;

  /// No description provided for @importErrNotExport.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier n\'est pas un export my-nkap : il manque les colonnes date, type ou montant.'**
  String get importErrNotExport;

  /// No description provided for @importErrUnreadable.
  ///
  /// In fr, this message translates to:
  /// **'ligne {line} : date, type ou montant illisible'**
  String importErrUnreadable(String line);

  /// No description provided for @importFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'import a échoué ; rien n\'a été modifié.'**
  String get importFailed;

  /// No description provided for @importIntro.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un fichier exporté par my-nkap (Plus › Exporter en CSV), même modifié dans Excel. Les opérations déjà présentes sont ignorées, et les catégories, comptes, objectifs et dettes manquants sont créés.'**
  String get importIntro;

  /// No description provided for @importMoreErrors.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{… et {count} autre} other{… et {count} autres}}'**
  String importMoreErrors(int count);

  /// No description provided for @importNewAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Comptes créés : {names}'**
  String importNewAccounts(String names);

  /// No description provided for @importNewCats.
  ///
  /// In fr, this message translates to:
  /// **'Catégories créées : {names}'**
  String importNewCats(String names);

  /// No description provided for @importNewDebts.
  ///
  /// In fr, this message translates to:
  /// **'Dettes créées : {names}'**
  String importNewDebts(String names);

  /// No description provided for @importNewGoals.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs créés : {names}'**
  String importNewGoals(String names);

  /// No description provided for @importNothing.
  ///
  /// In fr, this message translates to:
  /// **'Rien à importer'**
  String get importNothing;

  /// No description provided for @importPick.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier'**
  String get importPick;

  /// No description provided for @importPickOther.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un autre fichier'**
  String get importPickOther;

  /// No description provided for @importSavingsGoal.
  ///
  /// In fr, this message translates to:
  /// **'Épargne importée'**
  String get importSavingsGoal;

  /// No description provided for @importTitle.
  ///
  /// In fr, this message translates to:
  /// **'Importer un CSV'**
  String get importTitle;

  /// No description provided for @importToImport.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} opération à importer} other{{count} opérations à importer}}'**
  String importToImport(int count);

  /// No description provided for @importTooBig.
  ///
  /// In fr, this message translates to:
  /// **'Fichier trop volumineux (plus de 20 Mo).'**
  String get importTooBig;

  /// No description provided for @insGoodTextCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Bien joué : {amount} de moins que ta moyenne si tu gardes ce rythme.'**
  String insGoodTextCurrent(String amount);

  /// No description provided for @insGoodTextPast.
  ///
  /// In fr, this message translates to:
  /// **'Bien joué : {amount} de moins que ta moyenne.'**
  String insGoodTextPast(String amount);

  /// No description provided for @insGoodTitle.
  ///
  /// In fr, this message translates to:
  /// **'{pct} % en {name}'**
  String insGoodTitle(int pct, String name);

  /// No description provided for @insNoSavingText.
  ///
  /// In fr, this message translates to:
  /// **'D\'habitude tu mets {amount} de côté par mois.'**
  String insNoSavingText(String amount);

  /// No description provided for @insNoSavingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'épargne ce mois-ci'**
  String get insNoSavingTitle;

  /// No description provided for @insWarnTextCurrent.
  ///
  /// In fr, this message translates to:
  /// **'{spent} dépensés, à ce rythme, tu finirais le mois à {projected} contre {avg} en moyenne.'**
  String insWarnTextCurrent(String spent, String projected, String avg);

  /// No description provided for @insWarnTextPast.
  ///
  /// In fr, this message translates to:
  /// **'{spent} dépensés, soit {projected} contre {avg} en moyenne.'**
  String insWarnTextPast(String spent, String projected, String avg);

  /// No description provided for @insWarnTitle.
  ///
  /// In fr, this message translates to:
  /// **'+{pct} % en {name}'**
  String insWarnTitle(int pct, String name);

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageAuto.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get languageAuto;

  /// No description provided for @languageAutoDesc.
  ///
  /// In fr, this message translates to:
  /// **'Suit la langue du téléphone'**
  String get languageAutoDesc;

  /// No description provided for @languageEn.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageFr.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFr;

  /// No description provided for @lockBiometricTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte ou visage'**
  String get lockBiometricTooltip;

  /// No description provided for @lockChooseCode.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un code'**
  String get lockChooseCode;

  /// No description provided for @lockCode.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get lockCode;

  /// No description provided for @lockCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code de verrouillage'**
  String get lockCodeTitle;

  /// No description provided for @lockConfirmCode.
  ///
  /// In fr, this message translates to:
  /// **'Confirme le code'**
  String get lockConfirmCode;

  /// No description provided for @lockDigits.
  ///
  /// In fr, this message translates to:
  /// **'De 4 à 6 chiffres'**
  String get lockDigits;

  /// No description provided for @lockEnterAgain.
  ///
  /// In fr, this message translates to:
  /// **'Saisis-le une deuxième fois'**
  String get lockEnterAgain;

  /// No description provided for @lockForgot.
  ///
  /// In fr, this message translates to:
  /// **'Code oublié ?'**
  String get lockForgot;

  /// No description provided for @lockForgotBody.
  ///
  /// In fr, this message translates to:
  /// **'Le code ne peut pas être récupéré. La seule solution est d\'effacer toutes les données de l\'app sur ce téléphone et de retirer le code.\n\nSi tu as une sauvegarde Google Drive, tu pourras la restaurer ensuite, mais il faudra le code utilisé au moment de cette sauvegarde.'**
  String get lockForgotBody;

  /// No description provided for @lockForgotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code oublié'**
  String get lockForgotTitle;

  /// No description provided for @lockMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux codes sont différents. Recommence.'**
  String get lockMismatch;

  /// No description provided for @lockSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get lockSubmit;

  /// No description provided for @lockSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisis ton code pour continuer'**
  String get lockSubtitle;

  /// No description provided for @lockTitle.
  ///
  /// In fr, this message translates to:
  /// **'my-nkap est verrouillé'**
  String get lockTitle;

  /// No description provided for @lockTooManyLater.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais. Réessaie plus tard.'**
  String get lockTooManyLater;

  /// No description provided for @lockTooManyWait.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais. Réessaie dans {seconds} s.'**
  String lockTooManyWait(int seconds);

  /// No description provided for @lockWipeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get lockWipeAll;

  /// No description provided for @lockWiped.
  ///
  /// In fr, this message translates to:
  /// **'Données effacées et code retiré'**
  String get lockWiped;

  /// No description provided for @lockWrongCode.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect.'**
  String get lockWrongCode;

  /// No description provided for @lockWrongCodeTries.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Code incorrect. {count} essai avant une pause.} other{Code incorrect. {count} essais avant une pause.}}'**
  String lockWrongCodeTries(int count);

  /// No description provided for @moreAssistant.
  ///
  /// In fr, this message translates to:
  /// **'Assistant budget'**
  String get moreAssistant;

  /// No description provided for @moreAssistantSub.
  ///
  /// In fr, this message translates to:
  /// **'Budget et plafonds selon tes revenus et tes objectifs'**
  String get moreAssistantSub;

  /// No description provided for @moreBadgeDrive.
  ///
  /// In fr, this message translates to:
  /// **'Drive connecté'**
  String get moreBadgeDrive;

  /// No description provided for @moreBadgeLocked.
  ///
  /// In fr, this message translates to:
  /// **'Protégée'**
  String get moreBadgeLocked;

  /// No description provided for @moreBadgeNoCode.
  ///
  /// In fr, this message translates to:
  /// **'Sans code'**
  String get moreBadgeNoCode;

  /// No description provided for @moreBadgeOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get moreBadgeOffline;

  /// No description provided for @moreDebts.
  ///
  /// In fr, this message translates to:
  /// **'Dettes'**
  String get moreDebts;

  /// No description provided for @moreDebtsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Suis ce que tu dois et ce qu\'on te doit'**
  String get moreDebtsEmpty;

  /// No description provided for @moreDebtsSub.
  ///
  /// In fr, this message translates to:
  /// **'Je dois {owed} · On me doit {lent}'**
  String moreDebtsSub(String owed, String lent);

  /// No description provided for @moreDrive.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation Google Drive'**
  String get moreDrive;

  /// No description provided for @moreDriveSub.
  ///
  /// In fr, this message translates to:
  /// **'Copie chiffrée dans ton Drive, à restaurer ailleurs'**
  String get moreDriveSub;

  /// No description provided for @moreExportCsv.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en CSV'**
  String get moreExportCsv;

  /// No description provided for @moreExportCsvSub.
  ///
  /// In fr, this message translates to:
  /// **'Toutes tes opérations dans un fichier pour Excel'**
  String get moreExportCsvSub;

  /// No description provided for @moreFooter.
  ///
  /// In fr, this message translates to:
  /// **'my-nkap · fait au Cameroun'**
  String get moreFooter;

  /// No description provided for @moreGroupApp.
  ///
  /// In fr, this message translates to:
  /// **'Application'**
  String get moreGroupApp;

  /// No description provided for @moreGroupData.
  ///
  /// In fr, this message translates to:
  /// **'Données'**
  String get moreGroupData;

  /// No description provided for @moreGroupMoney.
  ///
  /// In fr, this message translates to:
  /// **'Argent'**
  String get moreGroupMoney;

  /// No description provided for @moreHeroSub.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} opération} other{{count} opérations}} · données sur ce téléphone'**
  String moreHeroSub(int count);

  /// No description provided for @moreImportCsv.
  ///
  /// In fr, this message translates to:
  /// **'Importer un CSV'**
  String get moreImportCsv;

  /// No description provided for @moreImportCsvSub.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer un export my-nkap, sans doublons'**
  String get moreImportCsvSub;

  /// No description provided for @moreNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get moreNotifications;

  /// No description provided for @moreNotificationsSub.
  ///
  /// In fr, this message translates to:
  /// **'Rappels, budget, échéances, synchronisation'**
  String get moreNotificationsSub;

  /// No description provided for @moreSavings.
  ///
  /// In fr, this message translates to:
  /// **'Épargne'**
  String get moreSavings;

  /// No description provided for @moreSavingsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Crée un objectif et mets de l\'argent de côté'**
  String get moreSavingsEmpty;

  /// No description provided for @moreSavingsSub.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} objectif} other{{count} objectifs}} · {amount} mis de côté'**
  String moreSavingsSub(int count, String amount);

  /// No description provided for @moreSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get moreSecurity;

  /// No description provided for @moreSecurityOff.
  ///
  /// In fr, this message translates to:
  /// **'Protège l\'app par un code et ton empreinte'**
  String get moreSecurityOff;

  /// No description provided for @moreSecurityOn.
  ///
  /// In fr, this message translates to:
  /// **'Code activé'**
  String get moreSecurityOn;

  /// No description provided for @moreSecurityOnBio.
  ///
  /// In fr, this message translates to:
  /// **'Code activé · empreinte'**
  String get moreSecurityOnBio;

  /// No description provided for @moreSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get moreSettings;

  /// No description provided for @moreSettingsSub.
  ///
  /// In fr, this message translates to:
  /// **'Langue, thème, devise, budget, catégories, comptes'**
  String get moreSettingsSub;

  /// No description provided for @moreStatement.
  ///
  /// In fr, this message translates to:
  /// **'Relevé PDF'**
  String get moreStatement;

  /// No description provided for @moreStatementSub.
  ///
  /// In fr, this message translates to:
  /// **'Imprimable, par mois, par période ou par compte'**
  String get moreStatementSub;

  /// No description provided for @newOperation.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle opération'**
  String get newOperation;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @notificationsAllow.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser'**
  String get notificationsAllow;

  /// No description provided for @notificationsBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Les notifications sont bloquées pour my-nkap.'**
  String get notificationsBlocked;

  /// No description provided for @notificationsBlockedHelp.
  ///
  /// In fr, this message translates to:
  /// **'Autorise-les pour recevoir les rappels. Si rien ne s\'affiche, va dans Réglages Android › Applications › my-nkap › Notifications.'**
  String get notificationsBlockedHelp;

  /// No description provided for @notificationsBudgetDesc.
  ///
  /// In fr, this message translates to:
  /// **'Alerte à 80 %, puis en cas de dépassement'**
  String get notificationsBudgetDesc;

  /// No description provided for @notificationsDailyDesc.
  ///
  /// In fr, this message translates to:
  /// **'« As-tu noté tes dépenses ? », sauf si tu as déjà saisi quelque chose ce jour-là'**
  String get notificationsDailyDesc;

  /// No description provided for @notificationsDebtsDesc.
  ///
  /// In fr, this message translates to:
  /// **'3 jours avant et le jour de l\'échéance, à 9 h'**
  String get notificationsDebtsDesc;

  /// No description provided for @notificationsFooter.
  ///
  /// In fr, this message translates to:
  /// **'Les notifications sont préparées sur le téléphone, sans internet. Sur un écran verrouillé, Android masque les montants.'**
  String get notificationsFooter;

  /// No description provided for @notificationsSyncDesc.
  ///
  /// In fr, this message translates to:
  /// **'Si ta dernière sauvegarde Google Drive date de plus de 7 jours'**
  String get notificationsSyncDesc;

  /// No description provided for @notificationsTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure du rappel'**
  String get notificationsTime;

  /// No description provided for @notificationsTimeValue.
  ///
  /// In fr, this message translates to:
  /// **'{hour} h {minute}'**
  String notificationsTimeValue(String hour, String minute);

  /// No description provided for @notificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notifyChBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget et plafonds'**
  String get notifyChBudget;

  /// No description provided for @notifyChDaily.
  ///
  /// In fr, this message translates to:
  /// **'Rappel quotidien'**
  String get notifyChDaily;

  /// No description provided for @notifyChDebts.
  ///
  /// In fr, this message translates to:
  /// **'Échéances de dettes'**
  String get notifyChDebts;

  /// No description provided for @notifyChSync.
  ///
  /// In fr, this message translates to:
  /// **'Rappel de synchronisation'**
  String get notifyChSync;

  /// No description provided for @notifyDaily1.
  ///
  /// In fr, this message translates to:
  /// **'As-tu noté tes dépenses aujourd\'hui ?'**
  String get notifyDaily1;

  /// No description provided for @notifyDaily2.
  ///
  /// In fr, this message translates to:
  /// **'Deux minutes pour mettre ton carnet à jour ?'**
  String get notifyDaily2;

  /// No description provided for @notifyDaily3.
  ///
  /// In fr, this message translates to:
  /// **'Un taxi, un repas, une recharge ? Note-les avant d\'oublier.'**
  String get notifyDaily3;

  /// No description provided for @notifyDaily4.
  ///
  /// In fr, this message translates to:
  /// **'Ton carnet t\'attend : note les opérations du jour.'**
  String get notifyDaily4;

  /// No description provided for @notifyDebtIOwe.
  ///
  /// In fr, this message translates to:
  /// **'Tu dois rembourser {amount} à {person} {when}.'**
  String notifyDebtIOwe(String amount, String person, String when);

  /// No description provided for @notifyDebtOwedToMe.
  ///
  /// In fr, this message translates to:
  /// **'{person} doit te rembourser {amount} {when}.'**
  String notifyDebtOwedToMe(String person, String amount, String when);

  /// No description provided for @notifyDebtTitle.
  ///
  /// In fr, this message translates to:
  /// **'Échéance : {person}'**
  String notifyDebtTitle(String person);

  /// No description provided for @notifyIn3Days.
  ///
  /// In fr, this message translates to:
  /// **'dans 3 jours'**
  String get notifyIn3Days;

  /// No description provided for @notifyMonthBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget du mois'**
  String get notifyMonthBudget;

  /// No description provided for @notifyNearBody.
  ///
  /// In fr, this message translates to:
  /// **'Déjà {spent} sur {cap}. Il reste {left} pour le mois.'**
  String notifyNearBody(String spent, String cap, String left);

  /// No description provided for @notifyNearTitle.
  ///
  /// In fr, this message translates to:
  /// **'{name} : 80 % atteint'**
  String notifyNearTitle(String name);

  /// No description provided for @notifyOverBody.
  ///
  /// In fr, this message translates to:
  /// **'Tu as dépensé {spent} ce mois-ci pour un plafond de {cap}.'**
  String notifyOverBody(String spent, String cap);

  /// No description provided for @notifyOverTitle.
  ///
  /// In fr, this message translates to:
  /// **'{name} : dépassé'**
  String notifyOverTitle(String name);

  /// No description provided for @notifySyncNever.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as pas encore sauvegardé tes données sur Google Drive.'**
  String get notifySyncNever;

  /// No description provided for @notifySyncOld.
  ///
  /// In fr, this message translates to:
  /// **'Ta dernière sauvegarde Google Drive date de plus de 7 jours.'**
  String get notifySyncOld;

  /// No description provided for @notifySyncTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pense à synchroniser'**
  String get notifySyncTitle;

  /// No description provided for @notifyToday.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get notifyToday;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @onboardingBudget.
  ///
  /// In fr, this message translates to:
  /// **'Préparer mon budget'**
  String get onboardingBudget;

  /// No description provided for @onboardingSamples.
  ///
  /// In fr, this message translates to:
  /// **'Voir avec des exemples'**
  String get onboardingSamples;

  /// No description provided for @onboardingSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// No description provided for @onboardingStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// No description provided for @onboardingText1.
  ///
  /// In fr, this message translates to:
  /// **'Note tes dépenses et tes revenus en quelques secondes : marché, taxi, ENEO, Mobile Money… Tu vois où part ton argent, mois après mois.'**
  String get onboardingText1;

  /// No description provided for @onboardingText2.
  ///
  /// In fr, this message translates to:
  /// **'Tout est enregistré sur ce téléphone, sans compte et sans internet. Tu peux protéger l\'app par un code ou ton empreinte, et la sauvegarder chiffrée sur ton propre Google Drive.'**
  String get onboardingText2;

  /// No description provided for @onboardingText3.
  ///
  /// In fr, this message translates to:
  /// **'L\'app devine la catégorie à partir de la note, repère tes dépenses habituelles, te prévient avant de dépasser ton budget et propose un budget adapté à tes revenus.'**
  String get onboardingText3;

  /// No description provided for @onboardingTitle1.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans my-nkap'**
  String get onboardingTitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In fr, this message translates to:
  /// **'Tes données restent chez toi'**
  String get onboardingTitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In fr, this message translates to:
  /// **'Un carnet qui t\'aide'**
  String get onboardingTitle3;

  /// No description provided for @opsAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Conseils'**
  String get opsAdvice;

  /// No description provided for @opsBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget'**
  String get opsBudget;

  /// No description provided for @opsBudgetAssistant.
  ///
  /// In fr, this message translates to:
  /// **'Préparer mon budget avec l\'assistant'**
  String get opsBudgetAssistant;

  /// No description provided for @opsBudgetLeft.
  ///
  /// In fr, this message translates to:
  /// **'Reste {amount}'**
  String opsBudgetLeft(String amount);

  /// No description provided for @opsBudgetNote.
  ///
  /// In fr, this message translates to:
  /// **'L\'épargne et les dettes ne comptent pas dans le budget.'**
  String get opsBudgetNote;

  /// No description provided for @opsBudgetOver.
  ///
  /// In fr, this message translates to:
  /// **'Dépassé de {amount}'**
  String opsBudgetOver(String amount);

  /// No description provided for @opsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} opération} other{{count} opérations}}'**
  String opsCount(int count);

  /// No description provided for @opsDueTitle.
  ///
  /// In fr, this message translates to:
  /// **'Habituels pas encore saisis'**
  String get opsDueTitle;

  /// No description provided for @opsEmptyFirst.
  ///
  /// In fr, this message translates to:
  /// **'Ton carnet est vide. Ajoute ta première dépense avec le bouton +, ou charge quelques exemples pour voir le carnet rempli.'**
  String get opsEmptyFirst;

  /// No description provided for @opsEmptyMonth.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération en {month}.'**
  String opsEmptyMonth(String month);

  /// No description provided for @opsEmptyMonthAccount.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération en {month} sur ce compte.'**
  String opsEmptyMonthAccount(String month);

  /// No description provided for @opsFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get opsFilterAll;

  /// No description provided for @opsForecastBalance.
  ///
  /// In fr, this message translates to:
  /// **' · solde ≈ '**
  String get opsForecastBalance;

  /// No description provided for @opsForecastDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour {day} sur {days}, d\'après ton rythme et tes habitudes.'**
  String opsForecastDay(int day, int days);

  /// No description provided for @opsForecastExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses ≈ '**
  String get opsForecastExpenses;

  /// No description provided for @opsForecastOver.
  ///
  /// In fr, this message translates to:
  /// **'À ce rythme, le budget serait dépassé de {amount}.'**
  String opsForecastOver(String amount);

  /// No description provided for @opsForecastTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prévision de fin de mois'**
  String get opsForecastTitle;

  /// No description provided for @opsHeroBalance.
  ///
  /// In fr, this message translates to:
  /// **'SOLDE DU MOIS'**
  String get opsHeroBalance;

  /// No description provided for @opsJournal.
  ///
  /// In fr, this message translates to:
  /// **'Journal'**
  String get opsJournal;

  /// No description provided for @opsLoadSamples.
  ///
  /// In fr, this message translates to:
  /// **'Charger des exemples'**
  String get opsLoadSamples;

  /// No description provided for @opsRecurringPlanned.
  ///
  /// In fr, this message translates to:
  /// **'prévu le {date}'**
  String opsRecurringPlanned(String date);

  /// No description provided for @opsRecurringUsual.
  ///
  /// In fr, this message translates to:
  /// **'habituellement vers le {day}'**
  String opsRecurringUsual(int day);

  /// No description provided for @opsSamplesLoaded.
  ///
  /// In fr, this message translates to:
  /// **'Exemples chargés. Tu pourras les retirer dans Paramètres › Données.'**
  String get opsSamplesLoaded;

  /// No description provided for @proofAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un justificatif (photo, reçu)'**
  String get proofAdd;

  /// No description provided for @proofCamera.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get proofCamera;

  /// No description provided for @proofGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get proofGallery;

  /// No description provided for @proofRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get proofRemove;

  /// No description provided for @proofReplace.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer'**
  String get proofReplace;

  /// No description provided for @proofTapToView.
  ///
  /// In fr, this message translates to:
  /// **'Touche l\'image pour l\'agrandir'**
  String get proofTapToView;

  /// No description provided for @proofTitle.
  ///
  /// In fr, this message translates to:
  /// **'Justificatif'**
  String get proofTitle;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @savingsBefore.
  ///
  /// In fr, this message translates to:
  /// **'avant le {date}'**
  String savingsBefore(String date);

  /// No description provided for @savingsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Crée un objectif (fonds d\'urgence, voyage, voiture…) puis mets de l\'argent de côté depuis tes comptes. L\'argent épargné quitte le compte et s\'ajoute à l\'objectif.'**
  String get savingsEmpty;

  /// No description provided for @savingsMyGoals.
  ///
  /// In fr, this message translates to:
  /// **'Mes objectifs'**
  String get savingsMyGoals;

  /// No description provided for @savingsNewGoal.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel objectif'**
  String get savingsNewGoal;

  /// No description provided for @savingsNoTarget.
  ///
  /// In fr, this message translates to:
  /// **'Fixe un montant à tes objectifs pour suivre tes progrès'**
  String get savingsNoTarget;

  /// No description provided for @savingsOfTarget.
  ///
  /// In fr, this message translates to:
  /// **'sur {amount}'**
  String savingsOfTarget(String amount);

  /// No description provided for @savingsOfTargets.
  ///
  /// In fr, this message translates to:
  /// **'sur {amount} d\'objectifs'**
  String savingsOfTargets(String amount);

  /// No description provided for @savingsPerMonth.
  ///
  /// In fr, this message translates to:
  /// **'{amount} par mois pour y arriver'**
  String savingsPerMonth(String amount);

  /// No description provided for @savingsPercent.
  ///
  /// In fr, this message translates to:
  /// **'{pct} %'**
  String savingsPercent(String pct);

  /// No description provided for @savingsPutAside.
  ///
  /// In fr, this message translates to:
  /// **'Mettre de côté'**
  String get savingsPutAside;

  /// No description provided for @savingsReached.
  ///
  /// In fr, this message translates to:
  /// **'Atteint'**
  String get savingsReached;

  /// No description provided for @savingsReachedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} objectif atteint} other{{count} objectifs atteints}}'**
  String savingsReachedCount(int count);

  /// No description provided for @savingsSampleTag.
  ///
  /// In fr, this message translates to:
  /// **'EXEMPLE'**
  String get savingsSampleTag;

  /// No description provided for @savingsTotalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Total mis de côté'**
  String get savingsTotalLabel;

  /// No description provided for @savingsWithdraw.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get savingsWithdraw;

  /// No description provided for @securityBioCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Vérification biométrique annulée'**
  String get securityBioCancelled;

  /// No description provided for @securityBioEnableReason.
  ///
  /// In fr, this message translates to:
  /// **'Confirme pour activer le déverrouillage biométrique'**
  String get securityBioEnableReason;

  /// No description provided for @securityBioNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune empreinte ou visage enregistré sur ce téléphone. Ajoute-en dans les réglages d\'Android.'**
  String get securityBioNone;

  /// No description provided for @securityBioOn.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouille sans taper le code. Le code reste possible.'**
  String get securityBioOn;

  /// No description provided for @securityBioTitle.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte ou reconnaissance faciale'**
  String get securityBioTitle;

  /// No description provided for @securityBioUnlockReason.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouille my-nkap'**
  String get securityBioUnlockReason;

  /// No description provided for @securityChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer le code'**
  String get securityChange;

  /// No description provided for @securityCodeChanged.
  ///
  /// In fr, this message translates to:
  /// **'Code modifié. Les prochaines sauvegardes utiliseront le nouveau code.'**
  String get securityCodeChanged;

  /// No description provided for @securityCodeOn.
  ///
  /// In fr, this message translates to:
  /// **'Code activé'**
  String get securityCodeOn;

  /// No description provided for @securityCodeRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Code retiré'**
  String get securityCodeRemoved;

  /// No description provided for @securityCurrentCode.
  ///
  /// In fr, this message translates to:
  /// **'Code actuel'**
  String get securityCurrentCode;

  /// No description provided for @securityDelayMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Après {count} minute} other{Après {count} minutes}}'**
  String securityDelayMinutes(int count);

  /// No description provided for @securityDelayNow.
  ///
  /// In fr, this message translates to:
  /// **'Immédiatement'**
  String get securityDelayNow;

  /// No description provided for @securityDelaySeconds.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Après {count} seconde} other{Après {count} secondes}}'**
  String securityDelaySeconds(int count);

  /// No description provided for @securityDelayShort.
  ///
  /// In fr, this message translates to:
  /// **'Après {seconds} s'**
  String securityDelayShort(int seconds);

  /// No description provided for @securityEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer un code'**
  String get securityEnable;

  /// No description provided for @securityEnterCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Saisis ton code actuel'**
  String get securityEnterCurrent;

  /// No description provided for @securityEnterToRemove.
  ///
  /// In fr, this message translates to:
  /// **'Saisis ton code pour le retirer'**
  String get securityEnterToRemove;

  /// No description provided for @securityFootnote.
  ///
  /// In fr, this message translates to:
  /// **'Le code n\'est jamais enregistré en clair : seule une empreinte chiffrée est gardée dans le coffre sécurisé d\'Android. Après 5 erreurs, la saisie est bloquée un moment, et ce délai double à chaque nouvelle erreur. Le code sert aussi à chiffrer tes sauvegardes Google Drive.'**
  String get securityFootnote;

  /// No description provided for @securityLockNow.
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller maintenant'**
  String get securityLockNow;

  /// No description provided for @securityLockOnLeave.
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller quand je quitte l\'app'**
  String get securityLockOnLeave;

  /// No description provided for @securityProtected.
  ///
  /// In fr, this message translates to:
  /// **'App protégée'**
  String get securityProtected;

  /// No description provided for @securityProtectedDesc.
  ///
  /// In fr, this message translates to:
  /// **'Code activé. L\'app le demande à l\'ouverture.'**
  String get securityProtectedDesc;

  /// No description provided for @securityProtectedDescBio.
  ///
  /// In fr, this message translates to:
  /// **'Code activé · empreinte. L\'app le demande à l\'ouverture.'**
  String get securityProtectedDescBio;

  /// No description provided for @securityRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le code'**
  String get securityRemove;

  /// No description provided for @securityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get securityTitle;

  /// No description provided for @securityUnprotected.
  ///
  /// In fr, this message translates to:
  /// **'App non protégée'**
  String get securityUnprotected;

  /// No description provided for @securityUnprotectedDesc.
  ///
  /// In fr, this message translates to:
  /// **'N\'importe qui ayant ton téléphone peut ouvrir l\'app.'**
  String get securityUnprotectedDesc;

  /// No description provided for @settingsAccountsHint.
  ///
  /// In fr, this message translates to:
  /// **'Le solde de départ est l\'argent présent sur le compte avant ta première saisie. Pour corriger un solde plus tard, utilise « Ajuster le solde » dans l\'onglet Comptes.'**
  String get settingsAccountsHint;

  /// No description provided for @settingsAppearanceNote.
  ///
  /// In fr, this message translates to:
  /// **'La langue et le thème changent après « Enregistrer ».'**
  String get settingsAppearanceNote;

  /// No description provided for @settingsCap.
  ///
  /// In fr, this message translates to:
  /// **'Plafond'**
  String get settingsCap;

  /// No description provided for @settingsCapsNote.
  ///
  /// In fr, this message translates to:
  /// **'Les plafonds par catégorie se règlent dans l\'onglet Catégories.'**
  String get settingsCapsNote;

  /// No description provided for @settingsCatsArchiveNote.
  ///
  /// In fr, this message translates to:
  /// **'Une catégorie déjà utilisée est masquée plutôt qu\'effacée, pour garder l\'historique intact.'**
  String get settingsCatsArchiveNote;

  /// No description provided for @settingsCatsCapHint.
  ///
  /// In fr, this message translates to:
  /// **'Le plafond mensuel est facultatif : la catégorie passe au rouge s\'il est dépassé.'**
  String get settingsCatsCapHint;

  /// No description provided for @settingsCatsHint.
  ///
  /// In fr, this message translates to:
  /// **'Touche l\'icône pour la changer.'**
  String get settingsCatsHint;

  /// No description provided for @settingsCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get settingsCurrency;

  /// No description provided for @settingsDataFooter.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} opération au total} other{{count} opérations au total}}. Les données restent sur ce téléphone.'**
  String settingsDataFooter(int count);

  /// No description provided for @settingsDefault.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut'**
  String get settingsDefault;

  /// No description provided for @settingsExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get settingsExpenses;

  /// No description provided for @settingsExportCsv.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en CSV'**
  String get settingsExportCsv;

  /// No description provided for @settingsExportText.
  ///
  /// In fr, this message translates to:
  /// **'Un fichier CSV avec toutes tes opérations, lisible dans Excel ou Google Sheets.'**
  String get settingsExportText;

  /// No description provided for @settingsExportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get settingsExportTitle;

  /// No description provided for @settingsIncomes.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get settingsIncomes;

  /// No description provided for @settingsInitialBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde de départ'**
  String get settingsInitialBalance;

  /// No description provided for @settingsKeepOneAccount.
  ///
  /// In fr, this message translates to:
  /// **'Garde au moins un compte.'**
  String get settingsKeepOneAccount;

  /// No description provided for @settingsKeepOneCategory.
  ///
  /// In fr, this message translates to:
  /// **'Garde au moins une catégorie de ce type.'**
  String get settingsKeepOneCategory;

  /// No description provided for @settingsMonthlyBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget mensuel total'**
  String get settingsMonthlyBudget;

  /// No description provided for @settingsName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get settingsName;

  /// No description provided for @settingsNewAccount.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau compte'**
  String get settingsNewAccount;

  /// No description provided for @settingsNewCategory.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get settingsNewCategory;

  /// No description provided for @settingsNewIncome.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau revenu'**
  String get settingsNewIncome;

  /// No description provided for @settingsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get settingsNone;

  /// No description provided for @settingsSamplesNo.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée d\'exemple.'**
  String get settingsSamplesNo;

  /// No description provided for @settingsSamplesRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer les exemples'**
  String get settingsSamplesRemove;

  /// No description provided for @settingsSamplesRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Exemples retirés'**
  String get settingsSamplesRemoved;

  /// No description provided for @settingsSamplesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Données d\'exemple'**
  String get settingsSamplesTitle;

  /// No description provided for @settingsSamplesYes.
  ///
  /// In fr, this message translates to:
  /// **'Le carnet contient des données d\'exemple.'**
  String get settingsSamplesYes;

  /// No description provided for @settingsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres enregistrés'**
  String get settingsSaved;

  /// No description provided for @settingsTabAppearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get settingsTabAppearance;

  /// No description provided for @settingsTabData.
  ///
  /// In fr, this message translates to:
  /// **'Données'**
  String get settingsTabData;

  /// No description provided for @settingsTabMoney.
  ///
  /// In fr, this message translates to:
  /// **'Devise et budget'**
  String get settingsTabMoney;

  /// No description provided for @settingsTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settingsTheme;

  /// No description provided for @settingsThemeAuto.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get settingsThemeAuto;

  /// No description provided for @settingsThemeAutoDesc.
  ///
  /// In fr, this message translates to:
  /// **'Suit le réglage du téléphone'**
  String get settingsThemeAutoDesc;

  /// No description provided for @settingsThemeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeDarkDesc.
  ///
  /// In fr, this message translates to:
  /// **'Mode nuit permanent'**
  String get settingsThemeDarkDesc;

  /// No description provided for @settingsThemeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeLightDesc.
  ///
  /// In fr, this message translates to:
  /// **'Toujours clair'**
  String get settingsThemeLightDesc;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsWipeButton.
  ///
  /// In fr, this message translates to:
  /// **'Effacer toutes les données'**
  String get settingsWipeButton;

  /// No description provided for @settingsWipeText.
  ///
  /// In fr, this message translates to:
  /// **'Supprime toutes les opérations, objectifs et dettes. Tes catégories, comptes et réglages sont gardés. Exporte un CSV avant si tu veux garder une trace.'**
  String get settingsWipeText;

  /// No description provided for @settingsWipeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get settingsWipeTitle;

  /// No description provided for @settingsWiped.
  ///
  /// In fr, this message translates to:
  /// **'Données effacées'**
  String get settingsWiped;

  /// No description provided for @sheetsAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get sheetsAccount;

  /// No description provided for @sheetsAdjust.
  ///
  /// In fr, this message translates to:
  /// **'Ajuster'**
  String get sheetsAdjust;

  /// No description provided for @sheetsAdjustExplain.
  ///
  /// In fr, this message translates to:
  /// **'Un ajustement corrige le solde d\'un compte sans compter comme revenu ou dépense.'**
  String get sheetsAdjustExplain;

  /// No description provided for @sheetsAdjustIntro.
  ///
  /// In fr, this message translates to:
  /// **'Indique ce qu\'il y a vraiment sur le compte. La différence est enregistrée comme un ajustement, qui ne compte ni comme revenu ni comme dépense.'**
  String get sheetsAdjustIntro;

  /// No description provided for @sheetsAdjustNoteHint.
  ///
  /// In fr, this message translates to:
  /// **'Frais bancaires, oubli…'**
  String get sheetsAdjustNoteHint;

  /// No description provided for @sheetsAdjustTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajuster : {name}'**
  String sheetsAdjustTitle(String name);

  /// No description provided for @sheetsAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get sheetsAmount;

  /// No description provided for @sheetsAmountPositive.
  ///
  /// In fr, this message translates to:
  /// **'Indique un montant supérieur à zéro.'**
  String get sheetsAmountPositive;

  /// No description provided for @sheetsBalanceAdjusted.
  ///
  /// In fr, this message translates to:
  /// **'Solde ajusté ({amount})'**
  String sheetsBalanceAdjusted(String amount);

  /// No description provided for @sheetsBalanceAlreadyRight.
  ///
  /// In fr, this message translates to:
  /// **'Le solde est déjà juste.'**
  String get sheetsBalanceAlreadyRight;

  /// No description provided for @sheetsBookBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde dans le carnet : {amount}'**
  String sheetsBookBalance(String amount);

  /// No description provided for @sheetsCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get sheetsCategory;

  /// No description provided for @sheetsDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get sheetsDate;

  /// No description provided for @sheetsDebtAccountHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un compte pour que l\'argent reçu ou prêté apparaisse dans son solde, ou « Ne pas toucher à mes comptes » pour une dette ancienne.'**
  String get sheetsDebtAccountHint;

  /// No description provided for @sheetsDebtAdded.
  ///
  /// In fr, this message translates to:
  /// **'Dette ajoutée'**
  String get sheetsDebtAdded;

  /// No description provided for @sheetsDebtDeleteHint.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la dette efface aussi ses remboursements enregistrés.'**
  String get sheetsDebtDeleteHint;

  /// No description provided for @sheetsDebtDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Dette supprimée'**
  String get sheetsDebtDeleted;

  /// No description provided for @sheetsDebtDue.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get sheetsDebtDue;

  /// No description provided for @sheetsDebtEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la dette'**
  String get sheetsDebtEditTitle;

  /// No description provided for @sheetsDebtExplain.
  ///
  /// In fr, this message translates to:
  /// **'Ce mouvement se gère depuis Plus › Dettes.'**
  String get sheetsDebtExplain;

  /// No description provided for @sheetsDebtIOwe.
  ///
  /// In fr, this message translates to:
  /// **'Je dois'**
  String get sheetsDebtIOwe;

  /// No description provided for @sheetsDebtLeftMax.
  ///
  /// In fr, this message translates to:
  /// **'Le reste dû est de {amount}.'**
  String sheetsDebtLeftMax(String amount);

  /// No description provided for @sheetsDebtLeftToPay.
  ///
  /// In fr, this message translates to:
  /// **'Reste à payer : {left} sur {total}'**
  String sheetsDebtLeftToPay(String left, String total);

  /// No description provided for @sheetsDebtLeftToReceive.
  ///
  /// In fr, this message translates to:
  /// **'Reste à recevoir : {left} sur {total}'**
  String sheetsDebtLeftToReceive(String left, String total);

  /// No description provided for @sheetsDebtNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle dette'**
  String get sheetsDebtNewTitle;

  /// No description provided for @sheetsDebtOwedToMe.
  ///
  /// In fr, this message translates to:
  /// **'On me doit'**
  String get sheetsDebtOwedToMe;

  /// No description provided for @sheetsDebtPaidFrom.
  ///
  /// In fr, this message translates to:
  /// **'Payé depuis'**
  String get sheetsDebtPaidFrom;

  /// No description provided for @sheetsDebtPaidOutOf.
  ///
  /// In fr, this message translates to:
  /// **'L\'argent est sorti de'**
  String get sheetsDebtPaidOutOf;

  /// No description provided for @sheetsDebtPerson.
  ///
  /// In fr, this message translates to:
  /// **'Personne ou organisme'**
  String get sheetsDebtPerson;

  /// No description provided for @sheetsDebtPersonHintLent.
  ///
  /// In fr, this message translates to:
  /// **'À qui as-tu prêté ?'**
  String get sheetsDebtPersonHintLent;

  /// No description provided for @sheetsDebtPersonHintOwe.
  ///
  /// In fr, this message translates to:
  /// **'Qui t\'a prêté l\'argent ?'**
  String get sheetsDebtPersonHintOwe;

  /// No description provided for @sheetsDebtPersonMissing.
  ///
  /// In fr, this message translates to:
  /// **'Indique la personne ou l\'organisme.'**
  String get sheetsDebtPersonMissing;

  /// No description provided for @sheetsDebtReceivedIn.
  ///
  /// In fr, this message translates to:
  /// **'Reçu sur'**
  String get sheetsDebtReceivedIn;

  /// No description provided for @sheetsDebtReceivedOn.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai reçu l\'argent sur'**
  String get sheetsDebtReceivedOn;

  /// No description provided for @sheetsDebtRepayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser {person}'**
  String sheetsDebtRepayTitle(String person);

  /// No description provided for @sheetsDebtRepaymentFromTitle.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement de {person}'**
  String sheetsDebtRepaymentFromTitle(String person);

  /// No description provided for @sheetsDebtSettled.
  ///
  /// In fr, this message translates to:
  /// **'Dette soldée'**
  String get sheetsDebtSettled;

  /// No description provided for @sheetsDebtTotal.
  ///
  /// In fr, this message translates to:
  /// **'Montant total'**
  String get sheetsDebtTotal;

  /// No description provided for @sheetsDebtUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Dette mise à jour'**
  String get sheetsDebtUpdated;

  /// No description provided for @sheetsDeleteIfMistake.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux le supprimer ici si c\'était une erreur.'**
  String get sheetsDeleteIfMistake;

  /// No description provided for @sheetsDeleteMovement.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce mouvement'**
  String get sheetsDeleteMovement;

  /// No description provided for @sheetsExpenseAdded.
  ///
  /// In fr, this message translates to:
  /// **'Dépense ajoutée'**
  String get sheetsExpenseAdded;

  /// No description provided for @sheetsFromAccount.
  ///
  /// In fr, this message translates to:
  /// **'Depuis le compte'**
  String get sheetsFromAccount;

  /// No description provided for @sheetsGoalCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer l\'objectif'**
  String get sheetsGoalCreate;

  /// No description provided for @sheetsGoalCreated.
  ///
  /// In fr, this message translates to:
  /// **'Objectif créé'**
  String get sheetsGoalCreated;

  /// No description provided for @sheetsGoalDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Date visée (facultatif)'**
  String get sheetsGoalDeadline;

  /// No description provided for @sheetsGoalDeleteHint.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'objectif efface aussi ses mouvements : l\'argent revient sur les comptes d\'origine.'**
  String get sheetsGoalDeleteHint;

  /// No description provided for @sheetsGoalDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Objectif supprimé'**
  String get sheetsGoalDeleted;

  /// No description provided for @sheetsGoalEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'objectif'**
  String get sheetsGoalEditTitle;

  /// No description provided for @sheetsGoalInitial.
  ///
  /// In fr, this message translates to:
  /// **'Déjà mis de côté (facultatif)'**
  String get sheetsGoalInitial;

  /// No description provided for @sheetsGoalNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Fonds d\'urgence, voyage, voiture…'**
  String get sheetsGoalNameHint;

  /// No description provided for @sheetsGoalNameMissing.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à l\'objectif.'**
  String get sheetsGoalNameMissing;

  /// No description provided for @sheetsGoalNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel objectif d\'épargne'**
  String get sheetsGoalNewTitle;

  /// No description provided for @sheetsGoalPutAside.
  ///
  /// In fr, this message translates to:
  /// **'Mettre de côté'**
  String get sheetsGoalPutAside;

  /// No description provided for @sheetsGoalPutAsideDone.
  ///
  /// In fr, this message translates to:
  /// **'{amount} mis de côté'**
  String sheetsGoalPutAsideDone(String amount);

  /// No description provided for @sheetsGoalPutAsideTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mettre de côté : {name}'**
  String sheetsGoalPutAsideTitle(String name);

  /// No description provided for @sheetsGoalSaved.
  ///
  /// In fr, this message translates to:
  /// **'Déjà épargné : {amount}'**
  String sheetsGoalSaved(String amount);

  /// No description provided for @sheetsGoalSavedOf.
  ///
  /// In fr, this message translates to:
  /// **'Déjà épargné : {amount} sur {target}'**
  String sheetsGoalSavedOf(String amount, String target);

  /// No description provided for @sheetsGoalTarget.
  ///
  /// In fr, this message translates to:
  /// **'Montant visé'**
  String get sheetsGoalTarget;

  /// No description provided for @sheetsGoalUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Objectif mis à jour'**
  String get sheetsGoalUpdated;

  /// No description provided for @sheetsGoalWithdraw.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get sheetsGoalWithdraw;

  /// No description provided for @sheetsGoalWithdrawDone.
  ///
  /// In fr, this message translates to:
  /// **'{amount} retirés de l\'épargne'**
  String sheetsGoalWithdrawDone(String amount);

  /// No description provided for @sheetsGoalWithdrawMax.
  ///
  /// In fr, this message translates to:
  /// **'Tu ne peux pas retirer plus que {amount}.'**
  String sheetsGoalWithdrawMax(String amount);

  /// No description provided for @sheetsGoalWithdrawTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de : {name}'**
  String sheetsGoalWithdrawTitle(String name);

  /// No description provided for @sheetsIcon.
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get sheetsIcon;

  /// No description provided for @sheetsIncomeAdded.
  ///
  /// In fr, this message translates to:
  /// **'Revenu ajouté'**
  String get sheetsIncomeAdded;

  /// No description provided for @sheetsInfoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte : {account}'**
  String sheetsInfoAccount(String account);

  /// No description provided for @sheetsInfoAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant : {amount}'**
  String sheetsInfoAmount(String amount);

  /// No description provided for @sheetsInfoDate.
  ///
  /// In fr, this message translates to:
  /// **'Date : {date}'**
  String sheetsInfoDate(String date);

  /// No description provided for @sheetsLoanAdded.
  ///
  /// In fr, this message translates to:
  /// **'Prêt ajouté'**
  String get sheetsLoanAdded;

  /// No description provided for @sheetsMovementDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Mouvement supprimé'**
  String get sheetsMovementDeleted;

  /// No description provided for @sheetsName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get sheetsName;

  /// No description provided for @sheetsNote.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get sheetsNote;

  /// No description provided for @sheetsPickIcon.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une icône'**
  String get sheetsPickIcon;

  /// No description provided for @sheetsRealBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde réel'**
  String get sheetsRealBalance;

  /// No description provided for @sheetsRealBalanceMissing.
  ///
  /// In fr, this message translates to:
  /// **'Indique le solde réel du compte.'**
  String get sheetsRealBalanceMissing;

  /// No description provided for @sheetsRepaymentSaved.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement enregistré'**
  String get sheetsRepaymentSaved;

  /// No description provided for @sheetsSaveExplain.
  ///
  /// In fr, this message translates to:
  /// **'Ce mouvement se gère depuis Plus › Épargne.'**
  String get sheetsSaveExplain;

  /// No description provided for @sheetsSaveRepayment.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le remboursement'**
  String get sheetsSaveRepayment;

  /// No description provided for @sheetsSuggested.
  ///
  /// In fr, this message translates to:
  /// **'suggérée d\'après la note'**
  String get sheetsSuggested;

  /// No description provided for @sheetsToAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vers le compte'**
  String get sheetsToAccount;

  /// No description provided for @sheetsTransferSameAccount.
  ///
  /// In fr, this message translates to:
  /// **'Choisis deux comptes différents pour un transfert.'**
  String get sheetsTransferSameAccount;

  /// No description provided for @sheetsTransferSaved.
  ///
  /// In fr, this message translates to:
  /// **'Transfert enregistré'**
  String get sheetsTransferSaved;

  /// No description provided for @sheetsTxDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Opération supprimée'**
  String get sheetsTxDeleted;

  /// No description provided for @sheetsTxEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'opération'**
  String get sheetsTxEditTitle;

  /// No description provided for @sheetsTxNoteHint.
  ///
  /// In fr, this message translates to:
  /// **'Marché, taxi, facture ENEO…'**
  String get sheetsTxNoteHint;

  /// No description provided for @sheetsTxUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Opération mise à jour'**
  String get sheetsTxUpdated;

  /// No description provided for @sheetsUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get sheetsUpdate;

  /// No description provided for @stateGroupTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get stateGroupTransfer;

  /// No description provided for @stateNoCategory.
  ///
  /// In fr, this message translates to:
  /// **'Sans catégorie'**
  String get stateNoCategory;

  /// No description provided for @stateSampleDebtTontine.
  ///
  /// In fr, this message translates to:
  /// **'Tontine du quartier'**
  String get stateSampleDebtTontine;

  /// No description provided for @stateSampleGoalEmergency.
  ///
  /// In fr, this message translates to:
  /// **'Fonds d\'urgence'**
  String get stateSampleGoalEmergency;

  /// No description provided for @stateSampleNoteCinema.
  ///
  /// In fr, this message translates to:
  /// **'Cinéma et sortie'**
  String get stateSampleNoteCinema;

  /// No description provided for @stateSampleNoteDoctor.
  ///
  /// In fr, this message translates to:
  /// **'Consultation'**
  String get stateSampleNoteDoctor;

  /// No description provided for @stateSampleNoteEneo.
  ///
  /// In fr, this message translates to:
  /// **'Électricité ENEO'**
  String get stateSampleNoteEneo;

  /// No description provided for @stateSampleNoteFreelance.
  ///
  /// In fr, this message translates to:
  /// **'Mission freelance'**
  String get stateSampleNoteFreelance;

  /// No description provided for @stateSampleNoteFuel.
  ///
  /// In fr, this message translates to:
  /// **'Carburant'**
  String get stateSampleNoteFuel;

  /// No description provided for @stateSampleNoteGroceries.
  ///
  /// In fr, this message translates to:
  /// **'Courses du mois'**
  String get stateSampleNoteGroceries;

  /// No description provided for @stateSampleNoteInternet.
  ///
  /// In fr, this message translates to:
  /// **'Forfait internet'**
  String get stateSampleNoteInternet;

  /// No description provided for @stateSampleNoteLessons.
  ///
  /// In fr, this message translates to:
  /// **'Cours d\'anglais'**
  String get stateSampleNoteLessons;

  /// No description provided for @stateSampleNoteLunch.
  ///
  /// In fr, this message translates to:
  /// **'Déjeuner au tourne-dos'**
  String get stateSampleNoteLunch;

  /// No description provided for @stateSampleNoteMotoTaxi.
  ///
  /// In fr, this message translates to:
  /// **'Moto-taxi'**
  String get stateSampleNoteMotoTaxi;

  /// No description provided for @stateSampleNoteParents.
  ///
  /// In fr, this message translates to:
  /// **'Aide aux parents'**
  String get stateSampleNoteParents;

  /// No description provided for @stateSampleNotePharmacy.
  ///
  /// In fr, this message translates to:
  /// **'Pharmacie'**
  String get stateSampleNotePharmacy;

  /// No description provided for @stateSampleNotePhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get stateSampleNotePhone;

  /// No description provided for @stateSampleNoteRent.
  ///
  /// In fr, this message translates to:
  /// **'Loyer'**
  String get stateSampleNoteRent;

  /// No description provided for @stateSampleNoteRentAdvance.
  ///
  /// In fr, this message translates to:
  /// **'Avance pour son loyer'**
  String get stateSampleNoteRentAdvance;

  /// No description provided for @stateSampleNoteSalary.
  ///
  /// In fr, this message translates to:
  /// **'Salaire'**
  String get stateSampleNoteSalary;

  /// No description provided for @stateSampleNoteShoes.
  ///
  /// In fr, this message translates to:
  /// **'Chaussures'**
  String get stateSampleNoteShoes;

  /// No description provided for @stateSampleNoteSupermarket.
  ///
  /// In fr, this message translates to:
  /// **'Supermarché'**
  String get stateSampleNoteSupermarket;

  /// No description provided for @stateSampleNoteTopUp.
  ///
  /// In fr, this message translates to:
  /// **'Recharge'**
  String get stateSampleNoteTopUp;

  /// No description provided for @stateSampleNoteUtilities.
  ///
  /// In fr, this message translates to:
  /// **'Électricité et eau'**
  String get stateSampleNoteUtilities;

  /// No description provided for @stateSampleNoteWeekend.
  ///
  /// In fr, this message translates to:
  /// **'Week-end'**
  String get stateSampleNoteWeekend;

  /// No description provided for @stateSampleNoteWeeklyMarket.
  ///
  /// In fr, this message translates to:
  /// **'Marché de la semaine'**
  String get stateSampleNoteWeeklyMarket;

  /// No description provided for @stateSampleNoteWithdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Retrait au guichet'**
  String get stateSampleNoteWithdrawal;

  /// No description provided for @statementAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Comptes'**
  String get statementAccounts;

  /// No description provided for @statementCustom.
  ///
  /// In fr, this message translates to:
  /// **'Dates au choix'**
  String get statementCustom;

  /// No description provided for @statementFrom.
  ///
  /// In fr, this message translates to:
  /// **'Du'**
  String get statementFrom;

  /// No description provided for @statementHelp.
  ///
  /// In fr, this message translates to:
  /// **'« Aperçu et impression » ouvre l\'impression Android, qui permet aussi d\'enregistrer en PDF. « Partager » l\'envoie par WhatsApp, e-mail ou vers tes fichiers.'**
  String get statementHelp;

  /// No description provided for @statementIncludeCats.
  ///
  /// In fr, this message translates to:
  /// **'Inclure les dépenses par catégorie'**
  String get statementIncludeCats;

  /// No description provided for @statementIncludePlans.
  ///
  /// In fr, this message translates to:
  /// **'Inclure l\'épargne et les dettes'**
  String get statementIncludePlans;

  /// No description provided for @statementIntro.
  ///
  /// In fr, this message translates to:
  /// **'Un document A4 prêt à imprimer : soldes d\'ouverture et de clôture, toutes les opérations de la période avec le solde après chaque ligne, puis les dépenses par catégorie.'**
  String get statementIntro;

  /// No description provided for @statementPdfFailed.
  ///
  /// In fr, this message translates to:
  /// **'La création du PDF a échoué.'**
  String get statementPdfFailed;

  /// No description provided for @statementPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get statementPeriod;

  /// No description provided for @statementPickPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une période valide.'**
  String get statementPickPeriod;

  /// No description provided for @statementPlansAllOnly.
  ///
  /// In fr, this message translates to:
  /// **'Seulement pour le relevé de tous les comptes'**
  String get statementPlansAllOnly;

  /// No description provided for @statementPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu et impression'**
  String get statementPreview;

  /// No description provided for @statementShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager le PDF'**
  String get statementShare;

  /// No description provided for @statementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Relevé PDF'**
  String get statementTitle;

  /// No description provided for @statementTo.
  ///
  /// In fr, this message translates to:
  /// **'Au'**
  String get statementTo;

  /// No description provided for @statementYear.
  ///
  /// In fr, this message translates to:
  /// **'Année {year}'**
  String statementYear(String year);

  /// No description provided for @statsDailySpend.
  ///
  /// In fr, this message translates to:
  /// **'dépense courante par jour'**
  String get statsDailySpend;

  /// No description provided for @statsNoExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense ce mois-ci.'**
  String get statsNoExpenses;

  /// No description provided for @statsNothingToCompare.
  ///
  /// In fr, this message translates to:
  /// **'Rien à comparer pour l\'instant.'**
  String get statsNothingToCompare;

  /// No description provided for @statsOpsThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'opérations ce mois-ci'**
  String get statsOpsThisMonth;

  /// No description provided for @statsPercent.
  ///
  /// In fr, this message translates to:
  /// **'{value} %'**
  String statsPercent(String value);

  /// No description provided for @statsSavingsRate.
  ///
  /// In fr, this message translates to:
  /// **'taux d\'épargne'**
  String get statsSavingsRate;

  /// No description provided for @statsSixMonths.
  ///
  /// In fr, this message translates to:
  /// **'Six derniers mois'**
  String get statsSixMonths;

  /// No description provided for @statsTopExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Plus grosses dépenses'**
  String get statsTopExpenses;

  /// No description provided for @statsVsPrevMonth.
  ///
  /// In fr, this message translates to:
  /// **'dépenses vs mois précédent'**
  String get statsVsPrevMonth;

  /// No description provided for @statsWhereEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Les dépenses du mois apparaîtront ici, réparties par catégorie.'**
  String get statsWhereEmpty;

  /// No description provided for @statsWhereMoneyGoes.
  ///
  /// In fr, this message translates to:
  /// **'Où part l\'argent'**
  String get statsWhereMoneyGoes;

  /// No description provided for @tabAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Comptes'**
  String get tabAccounts;

  /// No description provided for @tabCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get tabCategories;

  /// No description provided for @tabMore.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get tabMore;

  /// No description provided for @tabOps.
  ///
  /// In fr, this message translates to:
  /// **'Opérations'**
  String get tabOps;

  /// No description provided for @tabStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get tabStats;

  /// No description provided for @totalsExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get totalsExpenses;

  /// No description provided for @totalsIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get totalsIncome;

  /// No description provided for @typeAdjust.
  ///
  /// In fr, this message translates to:
  /// **'Ajustement'**
  String get typeAdjust;

  /// No description provided for @typeDebt.
  ///
  /// In fr, this message translates to:
  /// **'Dette'**
  String get typeDebt;

  /// No description provided for @typeExpense.
  ///
  /// In fr, this message translates to:
  /// **'Dépense'**
  String get typeExpense;

  /// No description provided for @typeIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenu'**
  String get typeIncome;

  /// No description provided for @typeSave.
  ///
  /// In fr, this message translates to:
  /// **'Épargne'**
  String get typeSave;

  /// No description provided for @typeTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Virement'**
  String get typeTransfer;

  /// No description provided for @unnamedAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get unnamedAccount;

  /// No description provided for @unnamedCategory.
  ///
  /// In fr, this message translates to:
  /// **'Sans nom'**
  String get unnamedCategory;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
