import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../export.dart';
import '../format.dart';
import '../i18n.dart';
import '../icons.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

/// Tabs: 0 Apparence, 1 Catégories, 2 Comptes, 3 Devise et budget, 4 Données.
/// Edits go to a draft copy; "Enregistrer" saves it, leaving discards it.
class SettingsScreen extends StatefulWidget {
  final int initialTab;
  const SettingsScreen({super.key, this.initialTab = 0});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Settings draft;
  bool catIncome = false;

  @override
  void initState() {
    super.initState();
    draft = context.read<AppState>().settings.copy();
  }

  Future<void> save() async {
    await context.read<AppState>().saveSettings(draft);
    if (!mounted) return;
    Navigator.pop(context);
    toast(context, context.l.settingsSaved);
  }

  void remove({Category? cat, Account? acc}) {
    final s = context.read<AppState>();
    if (cat != null) {
      if (draft.cats.where((c) => c.income == cat.income && !c.archived).length <= 1) return toast(context, context.l.settingsKeepOneCategory);
      final used = s.txs.any((t) => t.cat == cat.id);
      setState(() => used ? cat.archived = true : draft.cats.remove(cat));
    } else if (acc != null) {
      if (draft.accounts.where((a) => !a.archived).length <= 1) return toast(context, context.l.settingsKeepOneAccount);
      final used = s.txs.any((t) => t.account == acc.id || t.to == acc.id);
      setState(() {
        used ? acc.archived = true : draft.accounts.remove(acc);
        if (draft.defaultAccount == acc.id) draft.defaultAccount = draft.accounts.firstWhere((a) => !a.archived).id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l.settingsTitle),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(onPressed: save, child: Text(context.l.save)),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: context.c.accent,
            unselectedLabelColor: context.c.muted,
            indicatorColor: context.c.accent,
            tabs: [
              for (final t in [
                ('palette', context.l.settingsTabAppearance),
                ('tags', context.l.tabCategories),
                ('wallet', context.l.tabAccounts),
                ('coins', context.l.settingsTabMoney),
                ('database', context.l.settingsTabData),
              ])
                Tab(child: Row(children: [Icon(appIcon(t.$1), size: 18), const SizedBox(width: 6), Text(t.$2)])),
            ],
          ),
        ),
        body: TabBarView(children: [_appearance(), _cats(), _accounts(), _money(), _data()]),
      ),
    );
  }

  Widget _appearance() {
    final l = context.l;
    Widget card(bool selected, VoidCallback onTap, Widget leading, String name, String desc) => Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? context.c.accent : context.c.line, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (desc.isNotEmpty) Text(desc, style: TextStyle(color: context.c.muted, fontSize: 13)),
                  ],
                ),
              ),
              if (selected) Icon(appIcon('check'), color: context.c.accent),
            ],
          ),
        ),
      ),
    );
    Widget opt(String v, String name, String desc, List<Color> sw) => card(
      draft.theme == v,
      () => setState(() => draft.theme = v),
      Container(
        width: 56,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: context.c.line),
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(colors: sw, stops: const [0.5, 0.5]),
        ),
      ),
      name,
      desc,
    );
    Widget langOpt(String v, String name, String desc) => card(
      draft.language == v,
      () => setState(() => draft.language = v),
      Container(
        width: 56,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.c.surface2,
          border: Border.all(color: context.c.line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: v == 'auto'
            ? Icon(appIcon('smartphone'), size: 20, color: context.c.muted)
            : Text(v.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      name,
      desc,
    );
    const title = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.language, style: title),
        const SizedBox(height: 10),
        langOpt('auto', l.languageAuto, l.languageAutoDesc),
        const SizedBox(height: 8),
        langOpt('fr', l.languageFr, ''),
        const SizedBox(height: 8),
        langOpt('en', l.languageEn, ''),
        const SizedBox(height: 20),
        Text(l.settingsTheme, style: title),
        const SizedBox(height: 10),
        opt('auto', l.settingsThemeAuto, l.settingsThemeAutoDesc, [AppColors.light.bg, AppColors.dark.bg]),
        const SizedBox(height: 8),
        opt('light', l.settingsThemeLight, l.settingsThemeLightDesc, [AppColors.light.bg, AppColors.light.surface]),
        const SizedBox(height: 8),
        opt('dark', l.settingsThemeDark, l.settingsThemeDarkDesc, [AppColors.dark.bg, AppColors.dark.surface]),
        const SizedBox(height: 10),
        Text(l.settingsAppearanceNote, style: TextStyle(color: context.c.muted, fontSize: 13)),
      ],
    );
  }

  Widget _cats() {
    final list = draft.cats.where((c) => c.income == catIncome && !c.archived).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: Text(context.l.settingsExpenses)),
            ButtonSegment(value: true, label: Text(context.l.settingsIncomes)),
          ],
          selected: {catIncome},
          onSelectionChanged: (v) => setState(() => catIncome = v.first),
        ),
        const SizedBox(height: 10),
        Text(
          catIncome ? context.l.settingsCatsHint : '${context.l.settingsCatsHint} ${context.l.settingsCatsCapHint}',
          style: TextStyle(color: context.c.muted, fontSize: 13),
        ),
        const SizedBox(height: 10),
        for (final c in list)
          Padding(
            key: ValueKey(c.id),
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () async {
                    final n = await pickIcon(context, c.icon, slot(c.color));
                    if (n != null) setState(() => c.icon = n);
                  },
                  child: IconBadge(icon: c.icon, color: slot(c.color), size: 44),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: c.name,
                    decoration: InputDecoration(hintText: context.l.settingsName),
                    onChanged: (v) => c.name = v,
                  ),
                ),
                if (!catIncome) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: c.cap > 0 ? Fmt(draft.currency).number(c.cap) : '',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(hintText: context.l.settingsCap),
                      onChanged: (v) => c.cap = (parseAmount(v) ?? 0).clamp(0, double.infinity).toDouble(),
                    ),
                  ),
                ],
                IconButton(
                  tooltip: context.l.delete,
                  icon: Icon(appIcon('trash-2'), size: 20),
                  onPressed: () => remove(cat: c),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: Icon(appIcon('plus'), size: 18),
            label: Text(context.l.settingsNewCategory),
            onPressed: () {
              final used = draft.cats.map((c) => c.color).toSet();
              setState(
                () => draft.cats.add(
                  Category(
                    id: newId('c-'),
                    name: catIncome ? context.l.settingsNewIncome : context.l.settingsNewCategory,
                    icon: 'tag',
                    income: catIncome,
                    color: palette.firstWhere((p) => !used.contains(p), orElse: () => palette[draft.cats.length % palette.length]),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(context.l.settingsCatsArchiveNote, style: TextStyle(color: context.c.muted, fontSize: 13)),
      ],
    );
  }

  Widget _accounts() {
    final list = draft.accounts.where((a) => !a.archived).toList();
    return RadioGroup<String>(
      groupValue: draft.defaultAccount,
      onChanged: (v) => setState(() => draft.defaultAccount = v!),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.l.settingsAccountsHint, style: TextStyle(color: context.c.muted, fontSize: 13)),
          const SizedBox(height: 12),
          for (final a in list)
            Card(
              key: ValueKey(a.id),
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 4, 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: () async {
                            final n = await pickIcon(context, a.icon, context.c.accent);
                            if (n != null) setState(() => a.icon = n);
                          },
                          child: IconBadge(icon: a.icon, color: context.c.accent, size: 44),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: a.name,
                            decoration: InputDecoration(labelText: context.l.settingsName),
                            onChanged: (v) => a.name = v,
                          ),
                        ),
                        IconButton(
                          tooltip: context.l.delete,
                          icon: Icon(appIcon('trash-2'), size: 20),
                          onPressed: () => remove(acc: a),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 52),
                        Expanded(
                          child: TextFormField(
                            initialValue: a.initial != 0 ? Fmt(draft.currency).number(a.initial) : '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: InputDecoration(labelText: context.l.settingsInitialBalance),
                            onChanged: (v) => a.initial = parseAmount(v) ?? 0,
                          ),
                        ),
                        Radio<String>(value: a.id),
                        Text(context.l.settingsDefault),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: Icon(appIcon('plus'), size: 18),
              label: Text(context.l.settingsNewAccount),
              onPressed: () => setState(() => draft.accounts.add(Account(id: newId('a-'), name: context.l.settingsNewAccount, icon: 'credit-card'))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _money() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          initialValue: draft.currency,
          decoration: InputDecoration(labelText: context.l.settingsCurrency),
          items: [for (final e in currencies.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
          onChanged: (v) => setState(() => draft.currency = v!),
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: draft.budget > 0 ? Fmt(draft.currency).number(draft.budget) : '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: context.l.settingsMonthlyBudget, hintText: context.l.settingsNone, suffixText: Fmt(draft.currency).symbol),
          onChanged: (v) => draft.budget = (parseAmount(v) ?? 0).clamp(0, double.infinity).toDouble(),
        ),
        const SizedBox(height: 10),
        Text(context.l.settingsCapsNote, style: TextStyle(color: context.c.muted, fontSize: 13)),
      ],
    );
  }

  Widget _data() {
    final s = context.watch<AppState>();
    Widget box(String title, String text, List<Widget> actions) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.c.surface2, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(text),
          if (actions.isNotEmpty) ...[const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: actions)],
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        box(context.l.settingsExportTitle, context.l.settingsExportText, [
          OutlinedButton.icon(icon: Icon(appIcon('download'), size: 18), label: Text(context.l.settingsExportCsv), onPressed: () => exportCsv(context)),
        ]),
        box(context.l.settingsSamplesTitle, s.hasSamples ? context.l.settingsSamplesYes : context.l.settingsSamplesNo, [
          if (s.hasSamples)
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: context.c.expense),
              onPressed: () async {
                await s.clearSamples();
                if (mounted) toast(context, context.l.settingsSamplesRemoved);
              },
              child: Text(context.l.settingsSamplesRemove),
            ),
        ]),
        box(context.l.settingsWipeTitle, context.l.settingsWipeText, [
          ConfirmDeleteButton(
            label: context.l.settingsWipeButton,
            onConfirm: () async {
              await s.wipeAll();
              if (mounted) toast(context, context.l.settingsWiped);
            },
          ),
        ]),
        Text(context.l.settingsDataFooter(s.txs.length), style: TextStyle(color: context.c.muted, fontSize: 13)),
      ],
    );
  }
}
