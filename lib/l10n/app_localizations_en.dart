// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountsAdjust => 'Adjust balance';

  @override
  String get accountsDefault => 'default';

  @override
  String get accountsIOwe => 'I owe';

  @override
  String get accountsMine => 'My accounts';

  @override
  String get accountsNetWorth => 'Net worth';

  @override
  String get accountsOnAccounts => 'In my accounts';

  @override
  String get accountsOps => 'Transactions';

  @override
  String get accountsOwedToMe => 'Owed to me';

  @override
  String accountsShare(int pct) {
    return '$pct% of your available money';
  }

  @override
  String get add => 'Add';

  @override
  String get appTitle => 'my-nkap';

  @override
  String get assistantApplied => 'Budget and caps applied';

  @override
  String get assistantApply => 'Apply this budget';

  @override
  String get assistantApplyNote =>
      'Replaces your monthly budget and the caps on your expense categories. You can change them later in Settings.';

  @override
  String get assistantCapPerCat => 'Cap per category';

  @override
  String get assistantCreateGoal => 'Create a goal';

  @override
  String get assistantGoals => 'Savings goals';

  @override
  String get assistantGoalsReached => 'All your goals are reached.';

  @override
  String get assistantIncomeLabel => 'Monthly income';

  @override
  String get assistantIntro =>
      'Enter what you earn each month: the assistant suggests a budget, a cap per category and how much to put aside for your goals.';

  @override
  String get assistantMethod => 'Method';

  @override
  String get assistantMonthlyBudget => 'Monthly budget (everyday spending)';

  @override
  String get assistantNeeds => 'Needs';

  @override
  String get assistantNeedsSub => 'Housing, bills, food, transport…';

  @override
  String assistantNoGoals(String amount) {
    return 'No goals yet. Start with an emergency fund of about 3 months of expenses, roughly $amount.';
  }

  @override
  String assistantPerMonth(String amount) {
    return '$amount / month';
  }

  @override
  String get assistantPrefilled =>
      'Prefilled with your average over the last 3 months.';

  @override
  String get assistantProposal => 'Proposal';

  @override
  String get assistantRule503020Desc =>
      'The classic rule: 50% for needs, 30% for wants, 20% for savings.';

  @override
  String get assistantRule702010Desc =>
      'More realistic when rent and food weigh heavily: 70% needs, 20% wants, 10% savings.';

  @override
  String get assistantRuleHistory => 'My habits';

  @override
  String get assistantRuleHistoryDesc =>
      'Starts from your actual spending over the last 3 months and keeps the rest for savings.';

  @override
  String get assistantTitle => 'Budget assistant';

  @override
  String get assistantWants => 'Wants';

  @override
  String get assistantWantsSub => 'Eating out, leisure, shopping…';

  @override
  String get back => 'Back';

  @override
  String get backupCodeSubtitle =>
      'The lock code that was active when this backup was made';

  @override
  String get backupCodeTitle => 'Backup code';

  @override
  String get backupConnectIntro =>
      'Connect your Google account to save an encrypted copy of your data in a private space of your own Drive. You can restore it on another phone.';

  @override
  String get backupConnected => 'Google account connected';

  @override
  String get backupDeleted => 'Backup deleted';

  @override
  String get backupDisconnect => 'Disconnect Google account';

  @override
  String get backupDisconnected => 'Google account disconnected from the app';

  @override
  String backupDriveRefused(String status) {
    return 'Google Drive refused the request ($status).';
  }

  @override
  String backupDriveRefusedDetail(String status, String detail) {
    return 'Google Drive refused the request ($status: $detail).';
  }

  @override
  String get backupEnablePin => 'Turn on a code';

  @override
  String backupInfo(int count) {
    return 'The app only goes online when you tap one of these buttons. The last $count backups are kept, encrypted with your code, in a hidden folder of your Drive that only my-nkap can read.';
  }

  @override
  String get backupInvalidFile => 'This file is not a valid my-nkap backup.';

  @override
  String backupLast(String date) {
    return 'Last sync: $date';
  }

  @override
  String get backupListTitle => 'Backups on Drive';

  @override
  String get backupNeedPin =>
      'Turn on a lock code: it is used to encrypt your backups.';

  @override
  String get backupNetworkError =>
      'Couldn\'t do that. Check your internet connection.';

  @override
  String get backupNever => 'Never synced from this phone';

  @override
  String get backupNone => 'No backups for this account.';

  @override
  String get backupNotConfigured =>
      'Google Drive sync is not set up in this version of the app.';

  @override
  String get backupRefresh => 'Refresh';

  @override
  String get backupRestore => 'Restore';

  @override
  String backupRestoreText(String date) {
    return 'All current data on this phone will be replaced with the data from $date. Sync first if you want to keep the current state.';
  }

  @override
  String get backupRestoreTitle => 'Restore this backup?';

  @override
  String get backupRestored => 'Backup restored';

  @override
  String get backupSent => 'Backup sent to your Google Drive';

  @override
  String get backupShow => 'Show';

  @override
  String get backupShowHint =>
      'Tap \"Show\" to see this account\'s backups (internet connection needed).';

  @override
  String get backupSignIn => 'Sign in with Google';

  @override
  String get backupSignInCancelled => 'Sign-in cancelled.';

  @override
  String backupSignInFailed(String code) {
    return 'Google sign-in failed ($code).';
  }

  @override
  String backupSignInFailedDetail(String code, String detail) {
    return 'Google sign-in failed ($code: $detail).';
  }

  @override
  String backupSize(String size) {
    return '$size KB';
  }

  @override
  String backupSizeLatest(String size) {
    return '$size KB · most recent';
  }

  @override
  String get backupSyncNow => 'Sync now';

  @override
  String get backupTitle => 'Sync';

  @override
  String get backupUnreadable =>
      'This backup can\'t be read or comes from another app.';

  @override
  String backupWhen(String date, String time) {
    return '$date at $time';
  }

  @override
  String get backupWrongCode =>
      'Wrong code for this backup. You need the code that was active when it was made.';

  @override
  String get cancel => 'Cancel';

  @override
  String get catsByCategory => 'By category';

  @override
  String catsCap(String amount) {
    return 'cap $amount';
  }

  @override
  String catsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '$count category',
    );
    return '$_temp0';
  }

  @override
  String get catsManage => 'Manage';

  @override
  String get catsNoOps => 'No transactions this month';

  @override
  String get catsOver => 'Over';

  @override
  String catsOverCaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caps exceeded',
      one: '$count cap exceeded',
    );
    return '$_temp0';
  }

  @override
  String catsReceivedIn(String month) {
    return 'Received in $month';
  }

  @override
  String catsShareOfTotal(int pct) {
    return '$pct% of total';
  }

  @override
  String catsSpentIn(String month) {
    return 'Spent in $month';
  }

  @override
  String catsTop(String name) {
    return 'top: $name';
  }

  @override
  String get catsUnused => 'No transactions this month';

  @override
  String get close => 'Close';

  @override
  String commonBorrowFrom(String who) {
    return 'Borrowed from $who';
  }

  @override
  String get commonClear => 'Clear';

  @override
  String get commonConfirmDelete => 'Confirm delete';

  @override
  String get commonDebtDeleted => 'deleted debt';

  @override
  String commonFromAccount(String account) {
    return 'From $account';
  }

  @override
  String get commonGoalDeleted => 'deleted goal';

  @override
  String get commonLeaveAccounts => 'Don\'t touch my accounts';

  @override
  String commonLendTo(String who) {
    return 'Loan to $who';
  }

  @override
  String get commonNextMonth => 'Next month';

  @override
  String get commonNoCategory => 'No category';

  @override
  String get commonNone => 'None';

  @override
  String get commonOffAccounts => 'No account';

  @override
  String get commonPrevMonth => 'Previous month';

  @override
  String commonRepayFrom(String who) {
    return 'Repayment from $who';
  }

  @override
  String commonRepayTo(String who) {
    return 'Repayment to $who';
  }

  @override
  String get commonSample => 'SAMPLE';

  @override
  String commonSavingFrom(String name) {
    return 'Savings withdrawal: $name';
  }

  @override
  String commonSavingTo(String name) {
    return 'Savings: $name';
  }

  @override
  String commonToAccount(String account) {
    return 'To $account';
  }

  @override
  String get commonTransfer => 'Transfer';

  @override
  String get confirm => 'Confirm';

  @override
  String get curEUR => 'Euro (EUR)';

  @override
  String get curGHS => 'Cedi (GHS)';

  @override
  String get curGNF => 'Guinean franc (GNF)';

  @override
  String get curMAD => 'Moroccan dirham (MAD)';

  @override
  String get curNGN => 'Naira (NGN)';

  @override
  String get curUSD => 'US dollar (USD)';

  @override
  String get curXAF => 'CFA franc (XAF)';

  @override
  String get curXOF => 'CFA franc (XOF)';

  @override
  String get debtsAddDebt => 'Add a debt';

  @override
  String get debtsAddLoan => 'Add a loan';

  @override
  String get debtsBalance => 'Debt balance';

  @override
  String get debtsEmptyLent =>
      'Write down the money you lent and track what you get back.';

  @override
  String get debtsEmptyOwe =>
      'Write down the money you borrowed and track your repayments.';

  @override
  String get debtsIOwe => 'I owe';

  @override
  String get debtsIRepay => 'I repay';

  @override
  String get debtsLate => 'Overdue';

  @override
  String get debtsNoneOpen => 'No open debts';

  @override
  String debtsOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open debts',
      one: '$count open debt',
    );
    return '$_temp0';
  }

  @override
  String get debtsOwedToMe => 'Owed to me';

  @override
  String debtsRepaidOf(String paid, String total) {
    return '$paid repaid of $total';
  }

  @override
  String get debtsSettled => 'Settled';

  @override
  String debtsSince(String date) {
    return 'since $date';
  }

  @override
  String get debtsTheyRepay => 'Got repaid';

  @override
  String get debtsTitle => 'Debts';

  @override
  String get defAccBank => 'Bank';

  @override
  String get defAccCash => 'Cash';

  @override
  String get defAccMomo => 'Mobile Money';

  @override
  String get defCatActivite => 'Business';

  @override
  String get defCatAlim => 'Groceries';

  @override
  String get defCatAutre => 'Other';

  @override
  String get defCatAutreIn => 'Other income';

  @override
  String get defCatCadeau => 'Gift';

  @override
  String get defCatEducation => 'Education';

  @override
  String get defCatFactures => 'Bills';

  @override
  String get defCatFamille => 'Family';

  @override
  String get defCatLogement => 'Housing';

  @override
  String get defCatLoisirs => 'Leisure';

  @override
  String get defCatResto => 'Restaurant';

  @override
  String get defCatSalaire => 'Salary';

  @override
  String get defCatSante => 'Health';

  @override
  String get defCatShopping => 'Shopping';

  @override
  String get defCatTelephone => 'Phone and internet';

  @override
  String get defCatTransport => 'Transport';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get exportAllAccounts => 'All accounts';

  @override
  String get exportByCategory => 'Expenses by category';

  @override
  String get exportClosing => 'Closing balance';

  @override
  String get exportColAccount => 'Account';

  @override
  String get exportColAmount => 'Amount';

  @override
  String get exportColBalance => 'Balance';

  @override
  String get exportColCap => 'Monthly cap';

  @override
  String get exportColCategory => 'Category';

  @override
  String get exportColCredit => 'Credit';

  @override
  String get exportColDate => 'Date';

  @override
  String get exportColDebit => 'Debit';

  @override
  String get exportColDirection => 'Direction';

  @override
  String get exportColDue => 'Due date';

  @override
  String get exportColGoal => 'Goal';

  @override
  String get exportColLabel => 'Description';

  @override
  String get exportColLeft => 'Remaining';

  @override
  String get exportColPerson => 'Person';

  @override
  String get exportColProgress => 'Progress';

  @override
  String get exportColRepaid => 'Repaid';

  @override
  String get exportColSaved => 'Saved';

  @override
  String get exportColShare => 'Share';

  @override
  String get exportColTarget => 'Target';

  @override
  String get exportColTargetDate => 'Target date';

  @override
  String get exportCredits => 'Total credits';

  @override
  String get exportCsvSubject => 'my-nkap export';

  @override
  String exportCurrency(String currency) {
    return 'Currency: $currency';
  }

  @override
  String get exportDebits => 'Total debits';

  @override
  String get exportDebtsLoans => 'Debts and loans';

  @override
  String get exportEmpty => 'No transactions in this period.';

  @override
  String exportFileName(String from, String to) {
    return 'statement-$from-to-$to';
  }

  @override
  String exportFooter(String from, String to) {
    return 'Statement from $from to $to - personal document, not an official bank statement';
  }

  @override
  String get exportIOwe => 'I owe';

  @override
  String exportIssued(String date) {
    return 'Issued on $date';
  }

  @override
  String get exportOpening => 'Opening balance';

  @override
  String get exportOwedToMe => 'Owed to me';

  @override
  String exportPage(String page, String pages) {
    return 'Page $page / $pages';
  }

  @override
  String get exportPdfDocTitle => 'my-nkap statement';

  @override
  String exportPercent(String value) {
    return '$value%';
  }

  @override
  String exportPeriod(String from, String to) {
    return 'From $from to $to';
  }

  @override
  String exportPeriodSummary(String income, String expense, String ops) {
    return 'Income for the period: $income   ·   Expenses for the period: $expense   ·   $ops';
  }

  @override
  String get exportSettled => 'Settled';

  @override
  String get exportTitle => 'Account statement';

  @override
  String get exportTotal => 'Total';

  @override
  String get exportTotals => 'Totals';

  @override
  String get exportTransfer => 'Transfer';

  @override
  String get exportTransferInternal => 'Internal transfer';

  @override
  String get fileBackupExport => 'Create the backup file';

  @override
  String get fileBackupFailed => 'That didn\'t work. Please try again.';

  @override
  String get fileBackupImport => 'Restore from a file';

  @override
  String get fileBackupMoreSub =>
      'Everything in one protected file, no Google account';

  @override
  String get fileBackupPassword => 'Password';

  @override
  String get fileBackupPasswordAgain => 'Confirm the password';

  @override
  String get fileBackupPasswordEnter => 'File password';

  @override
  String get fileBackupPasswordHelp =>
      'You\'ll need it to restore. Keep it safe: it can\'t be recovered.';

  @override
  String get fileBackupPasswordMismatch => 'The two passwords don\'t match.';

  @override
  String get fileBackupPasswordNew => 'Protect the file';

  @override
  String get fileBackupPasswordShort => 'At least 6 characters.';

  @override
  String get fileBackupPointAll =>
      'One file with everything: transactions, accounts, categories, savings, debts, settings and proofs.';

  @override
  String get fileBackupPointOffline =>
      'Keep it wherever you like (phone, USB stick, email, WhatsApp…) and import it on any phone.';

  @override
  String get fileBackupPointPassword =>
      'Encrypted with a password you choose: without it, nobody can open it.';

  @override
  String get fileBackupReplace => 'Replace';

  @override
  String get fileBackupReplaceText =>
      'Current transactions, accounts, categories, savings, debts and proofs will be replaced with the file\'s.';

  @override
  String get fileBackupReplaceTitle => 'Replace all data?';

  @override
  String get fileBackupRestored => 'Backup restored';

  @override
  String get fileBackupSubject => 'my-nkap backup';

  @override
  String get fileBackupTitle => 'Full backup (file)';

  @override
  String get fileBackupWarning =>
      'Restoring replaces all the data on this phone with the file\'s. If you forget the password, the file can no longer be opened.';

  @override
  String get greetingDay => 'Hello';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String importBadLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unreadable lines',
      one: '$count unreadable line',
    );
    return '$_temp0';
  }

  @override
  String importButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count transactions',
      one: 'Import $count transaction',
    );
    return '$_temp0';
  }

  @override
  String get importCantRead => 'Can\'t read this file.';

  @override
  String importCurrencyWarn(String file, String app) {
    return 'The file is in $file and the app in $app: amounts are imported as they are, with no conversion.';
  }

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions imported',
      one: '$count transaction imported',
    );
    return '$_temp0';
  }

  @override
  String importDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicates skipped (already in the app)',
      one: '$count duplicate skipped (already in the app)',
    );
    return '$_temp0';
  }

  @override
  String importErrDebt(String line) {
    return 'line $line: debt with no person or direction';
  }

  @override
  String get importErrEmpty => 'The file is empty.';

  @override
  String get importErrNotExport =>
      'This file is not a my-nkap export: the date, type or amount column is missing.';

  @override
  String importErrUnreadable(String line) {
    return 'line $line: unreadable date, type or amount';
  }

  @override
  String get importFailed => 'Import failed; nothing was changed.';

  @override
  String get importIntro =>
      'Choose a file exported by my-nkap (More › Export to CSV), even if edited in Excel. Transactions already in the app are skipped, and missing categories, accounts, goals and debts are created.';

  @override
  String importMoreErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '… and $count more',
      one: '… and $count more',
    );
    return '$_temp0';
  }

  @override
  String importNewAccounts(String names) {
    return 'New accounts: $names';
  }

  @override
  String importNewCats(String names) {
    return 'New categories: $names';
  }

  @override
  String importNewDebts(String names) {
    return 'New debts: $names';
  }

  @override
  String importNewGoals(String names) {
    return 'New goals: $names';
  }

  @override
  String get importNothing => 'Nothing to import';

  @override
  String get importPick => 'Choose a file';

  @override
  String get importPickOther => 'Choose another file';

  @override
  String get importSavingsGoal => 'Imported savings';

  @override
  String get importTitle => 'Import a CSV';

  @override
  String importToImport(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions to import',
      one: '$count transaction to import',
    );
    return '$_temp0';
  }

  @override
  String get importTooBig => 'File too large (over 20 MB).';

  @override
  String insGoodTextCurrent(String amount) {
    return 'Well done: $amount less than your average if you keep this pace.';
  }

  @override
  String insGoodTextPast(String amount) {
    return 'Well done: $amount less than your average.';
  }

  @override
  String insGoodTitle(int pct, String name) {
    return '$pct% on $name';
  }

  @override
  String insNoSavingText(String amount) {
    return 'You usually put $amount aside each month.';
  }

  @override
  String get insNoSavingTitle => 'No savings yet this month';

  @override
  String insWarnTextCurrent(String spent, String projected, String avg) {
    return '$spent spent. At this pace you\'d end the month at $projected, vs $avg on average.';
  }

  @override
  String insWarnTextPast(String spent, String projected, String avg) {
    return '$spent spent, i.e. $projected vs $avg on average.';
  }

  @override
  String insWarnTitle(int pct, String name) {
    return '+$pct% on $name';
  }

  @override
  String get language => 'Language';

  @override
  String get languageAuto => 'Automatic';

  @override
  String get languageAutoDesc => 'Follows the phone\'s language';

  @override
  String get languageEn => 'English';

  @override
  String get languageFr => 'Français';

  @override
  String get lockBiometricTooltip => 'Fingerprint or face';

  @override
  String get lockChooseCode => 'Choose a code';

  @override
  String get lockCode => 'Code';

  @override
  String get lockCodeTitle => 'Lock code';

  @override
  String get lockConfirmCode => 'Confirm the code';

  @override
  String get lockDigits => '4 to 6 digits';

  @override
  String get lockEnterAgain => 'Enter it a second time';

  @override
  String get lockForgot => 'Forgot your code?';

  @override
  String get lockForgotBody =>
      'The code can\'t be recovered. The only way out is to erase all the app\'s data on this phone and remove the code.\n\nIf you have a Google Drive backup, you can restore it afterwards, but you\'ll need the code that was in use when that backup was made.';

  @override
  String get lockForgotTitle => 'Forgotten code';

  @override
  String get lockMismatch => 'The two codes don\'t match. Start again.';

  @override
  String get lockSubmit => 'OK';

  @override
  String get lockSubtitle => 'Enter your code to continue';

  @override
  String get lockTitle => 'my-nkap is locked';

  @override
  String get lockTooManyLater => 'Too many tries. Try again later.';

  @override
  String lockTooManyWait(int seconds) {
    return 'Too many tries. Try again in $seconds s.';
  }

  @override
  String get lockWipeAll => 'Erase everything';

  @override
  String get lockWiped => 'Data erased and code removed';

  @override
  String get lockWrongCode => 'Wrong code.';

  @override
  String lockWrongCodeTries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong code. $count tries left before a pause.',
      one: 'Wrong code. $count try left before a pause.',
    );
    return '$_temp0';
  }

  @override
  String get moreAssistant => 'Budget assistant';

  @override
  String get moreAssistantSub =>
      'Budget and caps based on your income and goals';

  @override
  String get moreBadgeDrive => 'Drive connected';

  @override
  String get moreBadgeLocked => 'Protected';

  @override
  String get moreBadgeNoCode => 'No code';

  @override
  String get moreBadgeOffline => 'Offline';

  @override
  String get moreDebts => 'Debts';

  @override
  String get moreDebtsEmpty => 'Track what you owe and what you\'re owed';

  @override
  String moreDebtsSub(String owed, String lent) {
    return 'I owe $owed · Owed to me $lent';
  }

  @override
  String get moreDrive => 'Google Drive sync';

  @override
  String get moreDriveSub =>
      'Encrypted copy in your Drive, to restore elsewhere';

  @override
  String get moreExportCsv => 'Export to CSV';

  @override
  String get moreExportCsvSub => 'All your transactions in a file for Excel';

  @override
  String get moreFooter => 'my-nkap · made in Cameroon';

  @override
  String get moreGroupApp => 'App';

  @override
  String get moreGroupData => 'Data';

  @override
  String get moreGroupMoney => 'Money';

  @override
  String moreHeroSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '$count transaction',
    );
    return '$_temp0 · data on this phone';
  }

  @override
  String get moreImportCsv => 'Import a CSV';

  @override
  String get moreImportCsvSub =>
      'Bring back a my-nkap export, without duplicates';

  @override
  String get moreNotifications => 'Notifications';

  @override
  String get moreNotificationsSub => 'Reminders, budget, due dates, sync';

  @override
  String get moreSavings => 'Savings';

  @override
  String get moreSavingsEmpty => 'Create a goal and put money aside';

  @override
  String moreSavingsSub(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goals',
      one: '$count goal',
    );
    return '$_temp0 · $amount put aside';
  }

  @override
  String get moreSecurity => 'Security';

  @override
  String get moreSecurityOff =>
      'Protect the app with a code and your fingerprint';

  @override
  String get moreSecurityOn => 'Code on';

  @override
  String get moreSecurityOnBio => 'Code on · fingerprint';

  @override
  String get moreSettings => 'Settings';

  @override
  String get moreSettingsSub =>
      'Language, theme, currency, budget, categories, accounts';

  @override
  String get moreStatement => 'PDF statement';

  @override
  String get moreStatementSub => 'Printable, by month, period or account';

  @override
  String get newOperation => 'New transaction';

  @override
  String get next => 'Next';

  @override
  String get no => 'No';

  @override
  String get notificationsAllow => 'Allow';

  @override
  String get notificationsBlocked => 'Notifications are blocked for my-nkap.';

  @override
  String get notificationsBlockedHelp =>
      'Allow them to get reminders. If nothing shows up, go to Android Settings › Apps › my-nkap › Notifications.';

  @override
  String get notificationsBudgetDesc => 'Alert at 80%, then when you go over';

  @override
  String get notificationsDailyDesc =>
      '\"Did you log your expenses?\", unless you already entered something that day';

  @override
  String get notificationsDebtsDesc =>
      '3 days before and on the due date, at 9:00';

  @override
  String get notificationsFooter =>
      'Notifications are prepared on the phone, with no internet. On a locked screen, Android hides the amounts.';

  @override
  String get notificationsSyncDesc =>
      'If your last Google Drive backup is more than 7 days old';

  @override
  String get notificationsTime => 'Reminder time';

  @override
  String notificationsTimeValue(String hour, String minute) {
    return '$hour:$minute';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notifyChBudget => 'Budget and caps';

  @override
  String get notifyChDaily => 'Daily reminder';

  @override
  String get notifyChDebts => 'Debt due dates';

  @override
  String get notifyChSync => 'Sync reminder';

  @override
  String get notifyDaily1 => 'Did you log your expenses today?';

  @override
  String get notifyDaily2 => 'Two minutes to update your log?';

  @override
  String get notifyDaily3 =>
      'A taxi, a meal, a top-up? Log them before you forget.';

  @override
  String get notifyDaily4 => 'Your log is waiting: add today\'s transactions.';

  @override
  String notifyDebtIOwe(String amount, String person, String when) {
    return 'You need to repay $amount to $person $when.';
  }

  @override
  String notifyDebtOwedToMe(String person, String amount, String when) {
    return '$person should repay you $amount $when.';
  }

  @override
  String notifyDebtTitle(String person) {
    return 'Due: $person';
  }

  @override
  String get notifyIn3Days => 'in 3 days';

  @override
  String get notifyMonthBudget => 'Monthly budget';

  @override
  String notifyNearBody(String spent, String cap, String left) {
    return 'Already $spent of $cap. $left left for the month.';
  }

  @override
  String notifyNearTitle(String name) {
    return '$name: 80% reached';
  }

  @override
  String notifyOverBody(String spent, String cap) {
    return 'You\'ve spent $spent this month against a cap of $cap.';
  }

  @override
  String notifyOverTitle(String name) {
    return '$name: over the limit';
  }

  @override
  String get notifySyncNever =>
      'You haven\'t backed up your data to Google Drive yet.';

  @override
  String get notifySyncOld =>
      'Your last Google Drive backup is more than 7 days old.';

  @override
  String get notifySyncTitle => 'Time to sync';

  @override
  String get notifyToday => 'today';

  @override
  String get ok => 'OK';

  @override
  String get onboardingBudget => 'Plan my budget';

  @override
  String get onboardingSamples => 'Try with sample data';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingText1 =>
      'Record your spending and income in seconds: market, taxi, ENEO, Mobile Money… See where your money goes, month after month.';

  @override
  String get onboardingText2 =>
      'Everything is saved on this phone, with no account and no internet. You can protect the app with a code or your fingerprint, and back it up encrypted to your own Google Drive.';

  @override
  String get onboardingText3 =>
      'The app guesses the category from the note, spots your regular expenses, warns you before you go over budget and suggests a budget that fits your income.';

  @override
  String get onboardingTitle1 => 'Welcome to my-nkap';

  @override
  String get onboardingTitle2 => 'Your data stays with you';

  @override
  String get onboardingTitle3 => 'A notebook that helps you';

  @override
  String get opsAdvice => 'Tips';

  @override
  String get opsBudget => 'Budget';

  @override
  String get opsBudgetAssistant => 'Set up my budget with the assistant';

  @override
  String opsBudgetLeft(String amount) {
    return '$amount left';
  }

  @override
  String get opsBudgetNote =>
      'Savings and debts don\'t count toward the budget.';

  @override
  String opsBudgetOver(String amount) {
    return 'Over by $amount';
  }

  @override
  String opsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '$count transaction',
    );
    return '$_temp0';
  }

  @override
  String get opsDueTitle => 'Regulars not entered yet';

  @override
  String get opsEmptyFirst =>
      'Your book is empty. Add your first expense with the + button, or load a few examples to see it filled in.';

  @override
  String opsEmptyMonth(String month) {
    return 'No transactions in $month.';
  }

  @override
  String opsEmptyMonthAccount(String month) {
    return 'No transactions in $month for this account.';
  }

  @override
  String get opsFilterAll => 'All';

  @override
  String get opsForecastBalance => ' · balance ≈ ';

  @override
  String opsForecastDay(int day, int days) {
    return 'Day $day of $days, based on your pace and habits.';
  }

  @override
  String get opsForecastExpenses => 'Spending ≈ ';

  @override
  String opsForecastOver(String amount) {
    return 'At this pace, you\'d go over budget by $amount.';
  }

  @override
  String get opsForecastTitle => 'End-of-month forecast';

  @override
  String get opsHeroBalance => 'MONTH BALANCE';

  @override
  String get opsJournal => 'Journal';

  @override
  String get opsLoadSamples => 'Load examples';

  @override
  String opsRecurringPlanned(String date) {
    return 'due $date';
  }

  @override
  String opsRecurringUsual(int day) {
    return 'usually around day $day';
  }

  @override
  String get opsSamplesLoaded =>
      'Examples loaded. You can remove them in Settings › Data.';

  @override
  String get proofAdd => 'Add a proof (photo, receipt)';

  @override
  String get proofCamera => 'Take a photo';

  @override
  String get proofGallery => 'Choose from gallery';

  @override
  String get proofRemove => 'Remove';

  @override
  String get proofReplace => 'Replace';

  @override
  String get proofTapToView => 'Tap the image to enlarge it';

  @override
  String get proofTitle => 'Proof';

  @override
  String get save => 'Save';

  @override
  String savingsBefore(String date) {
    return 'by $date';
  }

  @override
  String get savingsEmpty =>
      'Create a goal (emergency fund, trip, car…) then put money aside from your accounts. Money you save leaves the account and goes into the goal.';

  @override
  String get savingsMyGoals => 'My goals';

  @override
  String get savingsNewGoal => 'New goal';

  @override
  String get savingsNoTarget =>
      'Set an amount for your goals to track your progress';

  @override
  String savingsOfTarget(String amount) {
    return 'of $amount';
  }

  @override
  String savingsOfTargets(String amount) {
    return 'of $amount in goals';
  }

  @override
  String savingsPerMonth(String amount) {
    return '$amount a month to get there';
  }

  @override
  String savingsPercent(String pct) {
    return '$pct%';
  }

  @override
  String get savingsPutAside => 'Put aside';

  @override
  String get savingsReached => 'Reached';

  @override
  String savingsReachedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goals reached',
      one: '$count goal reached',
    );
    return '$_temp0';
  }

  @override
  String get savingsSampleTag => 'SAMPLE';

  @override
  String get savingsTotalLabel => 'Total put aside';

  @override
  String get savingsWithdraw => 'Withdraw';

  @override
  String get securityBioCancelled => 'Biometric check cancelled';

  @override
  String get securityBioEnableReason => 'Confirm to turn on biometric unlock';

  @override
  String get securityBioNone =>
      'No fingerprint or face is set up on this phone. Add one in Android settings.';

  @override
  String get securityBioOn =>
      'Unlock without typing the code. The code still works.';

  @override
  String get securityBioTitle => 'Fingerprint or face unlock';

  @override
  String get securityBioUnlockReason => 'Unlock my-nkap';

  @override
  String get securityChange => 'Change code';

  @override
  String get securityCodeChanged =>
      'Code changed. Future backups will use the new code.';

  @override
  String get securityCodeOn => 'Code turned on';

  @override
  String get securityCodeRemoved => 'Code removed';

  @override
  String get securityCurrentCode => 'Current code';

  @override
  String securityDelayMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'After $count minutes',
      one: 'After $count minute',
    );
    return '$_temp0';
  }

  @override
  String get securityDelayNow => 'Immediately';

  @override
  String securityDelaySeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'After $count seconds',
      one: 'After $count second',
    );
    return '$_temp0';
  }

  @override
  String securityDelayShort(int seconds) {
    return 'After $seconds s';
  }

  @override
  String get securityEnable => 'Set a code';

  @override
  String get securityEnterCurrent => 'Enter your current code';

  @override
  String get securityEnterToRemove => 'Enter your code to remove it';

  @override
  String get securityFootnote =>
      'The code is never stored as is: only an encrypted fingerprint of it is kept in Android\'s secure storage. After 5 mistakes, entry is blocked for a while, and the wait doubles with each new mistake. The code is also used to encrypt your Google Drive backups.';

  @override
  String get securityLockNow => 'Lock now';

  @override
  String get securityLockOnLeave => 'Lock when I leave the app';

  @override
  String get securityProtected => 'App protected';

  @override
  String get securityProtectedDesc =>
      'Code on. The app asks for it when it opens.';

  @override
  String get securityProtectedDescBio =>
      'Code on · fingerprint. The app asks for it when it opens.';

  @override
  String get securityRemove => 'Remove code';

  @override
  String get securityTitle => 'Security';

  @override
  String get securityUnprotected => 'App not protected';

  @override
  String get securityUnprotectedDesc =>
      'Anyone with your phone can open the app.';

  @override
  String get settingsAccountsHint =>
      'The starting balance is the money in the account before your first entry. To correct a balance later, use \"Adjust balance\" in the Accounts tab.';

  @override
  String get settingsAppearanceNote =>
      'Language and theme change after you tap \"Save\".';

  @override
  String get settingsCap => 'Cap';

  @override
  String get settingsCapsNote => 'Category caps are set in the Categories tab.';

  @override
  String get settingsCatsArchiveNote =>
      'A category that is already in use is hidden rather than deleted, so your history stays intact.';

  @override
  String get settingsCatsCapHint =>
      'The monthly cap is optional: the category turns red when it is exceeded.';

  @override
  String get settingsCatsHint => 'Tap the icon to change it.';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String settingsDataFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions in total',
      one: '$count transaction in total',
    );
    return '$_temp0. Your data stays on this phone.';
  }

  @override
  String get settingsDefault => 'Default';

  @override
  String get settingsExpenses => 'Expenses';

  @override
  String get settingsExportCsv => 'Export to CSV';

  @override
  String get settingsExportText =>
      'A CSV file with all your transactions, readable in Excel or Google Sheets.';

  @override
  String get settingsExportTitle => 'Export';

  @override
  String get settingsIncomes => 'Income';

  @override
  String get settingsInitialBalance => 'Starting balance';

  @override
  String get settingsKeepOneAccount => 'Keep at least one account.';

  @override
  String get settingsKeepOneCategory =>
      'Keep at least one category of this type.';

  @override
  String get settingsMonthlyBudget => 'Total monthly budget';

  @override
  String get settingsName => 'Name';

  @override
  String get settingsNewAccount => 'New account';

  @override
  String get settingsNewCategory => 'New category';

  @override
  String get settingsNewIncome => 'New income';

  @override
  String get settingsNone => 'None';

  @override
  String get settingsSamplesNo => 'No sample data.';

  @override
  String get settingsSamplesRemove => 'Remove samples';

  @override
  String get settingsSamplesRemoved => 'Samples removed';

  @override
  String get settingsSamplesTitle => 'Sample data';

  @override
  String get settingsSamplesYes => 'The notebook contains sample data.';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get settingsTabAppearance => 'Appearance';

  @override
  String get settingsTabData => 'Data';

  @override
  String get settingsTabMoney => 'Currency and budget';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeAuto => 'Automatic';

  @override
  String get settingsThemeAutoDesc => 'Follows the phone setting';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeDarkDesc => 'Night mode all the time';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeLightDesc => 'Always light';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsWipeButton => 'Erase all data';

  @override
  String get settingsWipeText =>
      'Deletes all transactions, goals and debts. Your categories, accounts and settings are kept. Export a CSV first if you want to keep a record.';

  @override
  String get settingsWipeTitle => 'Erase everything';

  @override
  String get settingsWiped => 'Data erased';

  @override
  String get sheetsAccount => 'Account';

  @override
  String get sheetsAdjust => 'Adjust';

  @override
  String get sheetsAdjustExplain =>
      'An adjustment corrects an account balance without counting as income or expense.';

  @override
  String get sheetsAdjustIntro =>
      'Enter what is really in the account. The difference is saved as an adjustment, which counts as neither income nor expense.';

  @override
  String get sheetsAdjustNoteHint => 'Bank fees, forgotten entry…';

  @override
  String sheetsAdjustTitle(String name) {
    return 'Adjust: $name';
  }

  @override
  String get sheetsAmount => 'Amount';

  @override
  String get sheetsAmountPositive => 'Enter an amount greater than zero.';

  @override
  String sheetsBalanceAdjusted(String amount) {
    return 'Balance adjusted ($amount)';
  }

  @override
  String get sheetsBalanceAlreadyRight => 'The balance is already right.';

  @override
  String sheetsBookBalance(String amount) {
    return 'Balance in the app: $amount';
  }

  @override
  String get sheetsCategory => 'Category';

  @override
  String get sheetsDate => 'Date';

  @override
  String get sheetsDebtAccountHint =>
      'Pick an account so the money received or lent shows in its balance, or \"Don\'t touch my accounts\" for an old debt.';

  @override
  String get sheetsDebtAdded => 'Debt added';

  @override
  String get sheetsDebtDeleteHint =>
      'Deleting the debt also deletes its recorded repayments.';

  @override
  String get sheetsDebtDeleted => 'Debt deleted';

  @override
  String get sheetsDebtDue => 'Due date';

  @override
  String get sheetsDebtEditTitle => 'Edit debt';

  @override
  String get sheetsDebtExplain => 'This entry is managed from More › Debts.';

  @override
  String get sheetsDebtIOwe => 'I owe';

  @override
  String sheetsDebtLeftMax(String amount) {
    return 'The amount still due is $amount.';
  }

  @override
  String sheetsDebtLeftToPay(String left, String total) {
    return 'Left to pay: $left of $total';
  }

  @override
  String sheetsDebtLeftToReceive(String left, String total) {
    return 'Left to receive: $left of $total';
  }

  @override
  String get sheetsDebtNewTitle => 'New debt';

  @override
  String get sheetsDebtOwedToMe => 'Owed to me';

  @override
  String get sheetsDebtPaidFrom => 'Paid from';

  @override
  String get sheetsDebtPaidOutOf => 'The money came out of';

  @override
  String get sheetsDebtPerson => 'Person or organisation';

  @override
  String get sheetsDebtPersonHintLent => 'Who did you lend to?';

  @override
  String get sheetsDebtPersonHintOwe => 'Who lent you the money?';

  @override
  String get sheetsDebtPersonMissing => 'Enter the person or organisation.';

  @override
  String get sheetsDebtReceivedIn => 'Received in';

  @override
  String get sheetsDebtReceivedOn => 'I received the money in';

  @override
  String sheetsDebtRepayTitle(String person) {
    return 'Repay $person';
  }

  @override
  String sheetsDebtRepaymentFromTitle(String person) {
    return 'Repayment from $person';
  }

  @override
  String get sheetsDebtSettled => 'Debt settled';

  @override
  String get sheetsDebtTotal => 'Total amount';

  @override
  String get sheetsDebtUpdated => 'Debt updated';

  @override
  String get sheetsDeleteIfMistake =>
      'You can delete it here if it was a mistake.';

  @override
  String get sheetsDeleteMovement => 'Delete this entry';

  @override
  String get sheetsExpenseAdded => 'Expense added';

  @override
  String get sheetsFromAccount => 'From account';

  @override
  String get sheetsGoalCreate => 'Create goal';

  @override
  String get sheetsGoalCreated => 'Goal created';

  @override
  String get sheetsGoalDeadline => 'Target date (optional)';

  @override
  String get sheetsGoalDeleteHint =>
      'Deleting the goal also deletes its entries: the money goes back to the original accounts.';

  @override
  String get sheetsGoalDeleted => 'Goal deleted';

  @override
  String get sheetsGoalEditTitle => 'Edit goal';

  @override
  String get sheetsGoalInitial => 'Already saved (optional)';

  @override
  String get sheetsGoalNameHint => 'Emergency fund, trip, car…';

  @override
  String get sheetsGoalNameMissing => 'Give the goal a name.';

  @override
  String get sheetsGoalNewTitle => 'New savings goal';

  @override
  String get sheetsGoalPutAside => 'Set aside';

  @override
  String sheetsGoalPutAsideDone(String amount) {
    return '$amount set aside';
  }

  @override
  String sheetsGoalPutAsideTitle(String name) {
    return 'Set aside: $name';
  }

  @override
  String sheetsGoalSaved(String amount) {
    return 'Already saved: $amount';
  }

  @override
  String sheetsGoalSavedOf(String amount, String target) {
    return 'Already saved: $amount of $target';
  }

  @override
  String get sheetsGoalTarget => 'Target amount';

  @override
  String get sheetsGoalUpdated => 'Goal updated';

  @override
  String get sheetsGoalWithdraw => 'Withdraw';

  @override
  String sheetsGoalWithdrawDone(String amount) {
    return '$amount withdrawn from savings';
  }

  @override
  String sheetsGoalWithdrawMax(String amount) {
    return 'You can\'t withdraw more than $amount.';
  }

  @override
  String sheetsGoalWithdrawTitle(String name) {
    return 'Withdraw from: $name';
  }

  @override
  String get sheetsIcon => 'Icon';

  @override
  String get sheetsIncomeAdded => 'Income added';

  @override
  String sheetsInfoAccount(String account) {
    return 'Account: $account';
  }

  @override
  String sheetsInfoAmount(String amount) {
    return 'Amount: $amount';
  }

  @override
  String sheetsInfoDate(String date) {
    return 'Date: $date';
  }

  @override
  String get sheetsLoanAdded => 'Loan added';

  @override
  String get sheetsMovementDeleted => 'Entry deleted';

  @override
  String get sheetsName => 'Name';

  @override
  String get sheetsNote => 'Note';

  @override
  String get sheetsPickIcon => 'Choose an icon';

  @override
  String get sheetsRealBalance => 'Actual balance';

  @override
  String get sheetsRealBalanceMissing => 'Enter the account\'s actual balance.';

  @override
  String get sheetsRepaymentSaved => 'Repayment saved';

  @override
  String get sheetsSaveExplain => 'This entry is managed from More › Savings.';

  @override
  String get sheetsSaveRepayment => 'Save repayment';

  @override
  String get sheetsSuggested => 'suggested from the note';

  @override
  String get sheetsToAccount => 'To account';

  @override
  String get sheetsTransferSameAccount =>
      'Pick two different accounts for a transfer.';

  @override
  String get sheetsTransferSaved => 'Transfer saved';

  @override
  String get sheetsTxDeleted => 'Transaction deleted';

  @override
  String get sheetsTxEditTitle => 'Edit transaction';

  @override
  String get sheetsTxNoteHint => 'Market, taxi, ENEO bill…';

  @override
  String get sheetsTxUpdated => 'Transaction updated';

  @override
  String get sheetsUpdate => 'Update';

  @override
  String get stateGroupTransfer => 'Transfer';

  @override
  String get stateNoCategory => 'Uncategorized';

  @override
  String get stateSampleDebtTontine => 'Neighbourhood tontine';

  @override
  String get stateSampleGoalEmergency => 'Emergency fund';

  @override
  String get stateSampleNoteCinema => 'Cinema and night out';

  @override
  String get stateSampleNoteDoctor => 'Doctor\'s visit';

  @override
  String get stateSampleNoteEneo => 'ENEO electricity';

  @override
  String get stateSampleNoteFreelance => 'Freelance job';

  @override
  String get stateSampleNoteFuel => 'Fuel';

  @override
  String get stateSampleNoteGroceries => 'Monthly groceries';

  @override
  String get stateSampleNoteInternet => 'Internet bundle';

  @override
  String get stateSampleNoteLessons => 'French lessons';

  @override
  String get stateSampleNoteLunch => 'Lunch at the tourne-dos';

  @override
  String get stateSampleNoteMotoTaxi => 'Bike taxi';

  @override
  String get stateSampleNoteParents => 'Help for parents';

  @override
  String get stateSampleNotePharmacy => 'Pharmacy';

  @override
  String get stateSampleNotePhone => 'Phone';

  @override
  String get stateSampleNoteRent => 'Rent';

  @override
  String get stateSampleNoteRentAdvance => 'Advance for his rent';

  @override
  String get stateSampleNoteSalary => 'Salary';

  @override
  String get stateSampleNoteShoes => 'Shoes';

  @override
  String get stateSampleNoteSupermarket => 'Supermarket';

  @override
  String get stateSampleNoteTopUp => 'Top-up';

  @override
  String get stateSampleNoteUtilities => 'Electricity and water';

  @override
  String get stateSampleNoteWeekend => 'Weekend';

  @override
  String get stateSampleNoteWeeklyMarket => 'Weekly market';

  @override
  String get stateSampleNoteWithdrawal => 'Cash withdrawal';

  @override
  String get statementAccounts => 'Accounts';

  @override
  String get statementCustom => 'Custom dates';

  @override
  String get statementFrom => 'From';

  @override
  String get statementHelp =>
      '\"Preview and print\" opens Android printing, which can also save as PDF. \"Share\" sends it by WhatsApp, email or to your files.';

  @override
  String get statementIncludeCats => 'Include expenses by category';

  @override
  String get statementIncludePlans => 'Include savings and debts';

  @override
  String get statementIntro =>
      'A print-ready A4 document: opening and closing balances, every transaction in the period with the balance after each line, then expenses by category.';

  @override
  String get statementPdfFailed => 'Couldn\'t create the PDF.';

  @override
  String get statementPeriod => 'Period';

  @override
  String get statementPickPeriod => 'Choose a valid period.';

  @override
  String get statementPlansAllOnly => 'Only for the all-accounts statement';

  @override
  String get statementPreview => 'Preview and print';

  @override
  String get statementShare => 'Share the PDF';

  @override
  String get statementTitle => 'PDF statement';

  @override
  String get statementTo => 'To';

  @override
  String statementYear(String year) {
    return 'Year $year';
  }

  @override
  String get statsDailySpend => 'everyday spending per day';

  @override
  String get statsNoExpenses => 'No expenses this month.';

  @override
  String get statsNothingToCompare => 'Nothing to compare yet.';

  @override
  String get statsOpsThisMonth => 'transactions this month';

  @override
  String statsPercent(String value) {
    return '$value%';
  }

  @override
  String get statsSavingsRate => 'savings rate';

  @override
  String get statsSixMonths => 'Last six months';

  @override
  String get statsTopExpenses => 'Biggest expenses';

  @override
  String get statsVsPrevMonth => 'spending vs last month';

  @override
  String get statsWhereEmpty =>
      'This month\'s expenses will show up here, split by category.';

  @override
  String get statsWhereMoneyGoes => 'Where the money goes';

  @override
  String get tabAccounts => 'Accounts';

  @override
  String get tabCategories => 'Categories';

  @override
  String get tabMore => 'More';

  @override
  String get tabOps => 'Transactions';

  @override
  String get tabStats => 'Statistics';

  @override
  String get totalsExpenses => 'Expenses';

  @override
  String get totalsIncome => 'Income';

  @override
  String get typeAdjust => 'Adjustment';

  @override
  String get typeDebt => 'Debt';

  @override
  String get typeExpense => 'Expense';

  @override
  String get typeIncome => 'Income';

  @override
  String get typeSave => 'Savings';

  @override
  String get typeTransfer => 'Transfer';

  @override
  String get unnamedAccount => 'Account';

  @override
  String get unnamedCategory => 'Untitled';

  @override
  String get yes => 'Yes';
}
