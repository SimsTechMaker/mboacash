import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../icons.dart';
import '../state.dart';
import '../theme.dart';
import 'budget_assistant_screen.dart';

/// Three-page welcome shown on first launch.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final pager = PageController();
  int page = 0;

  static const pages = [
    (
      'notebook-pen',
      'Bienvenue dans carnet237',
      'Note tes dépenses et tes revenus en quelques secondes : marché, taxi, ENEO, Mobile Money… Tu vois où part ton argent, mois après mois.',
    ),
    (
      'shield-check',
      'Tes données restent chez toi',
      "Tout est enregistré sur ce téléphone, sans compte et sans internet. Tu peux protéger l'app par un code ou ton empreinte, et la sauvegarder chiffrée sur ton propre Google Drive.",
    ),
    (
      'sparkles',
      'Un carnet qui t\'aide',
      "L'app devine la catégorie à partir de la note, repère tes dépenses habituelles, te prévient avant de dépasser ton budget et propose un budget adapté à tes revenus.",
    ),
  ];

  @override
  void dispose() {
    pager.dispose();
    super.dispose();
  }

  void next() => pager.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final last = page == pages.length - 1;
    return Scaffold(
      backgroundColor: context.c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(onPressed: last ? null : () => pager.jumpToPage(pages.length - 1), child: const Text('Passer')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pager,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => page = i),
                itemBuilder: (_, i) => AnimatedBuilder(
                  animation: pager,
                  builder: (context, child) {
                    // Slight parallax and fade while swiping.
                    final pos = pager.hasClients && pager.position.haveDimensions ? (pager.page ?? 0) - i : 0.0;
                    return Opacity(
                      opacity: (1 - pos.abs()).clamp(0.0, 1.0),
                      child: Transform.translate(offset: Offset(pos * -60, 0), child: child),
                    );
                  },
                  child: _Page(icon: pages[i].$1, title: pages[i].$2, text: pages[i].$3),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(color: i == page ? context.c.accent : context.c.line, borderRadius: BorderRadius.circular(8)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: last
                    ? Column(
                        key: const ValueKey('last'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                            onPressed: () async {
                              widget.onDone();
                            },
                            child: const Text('Commencer'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () async {
                                    final s = context.read<AppState>();
                                    widget.onDone();
                                    await s.loadSamples();
                                  },
                                  child: const Text('Voir avec des exemples'),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    final nav = Navigator.of(context);
                                    widget.onDone();
                                    nav.push(MaterialPageRoute(builder: (_) => const BudgetAssistantScreen()));
                                  },
                                  child: const Text('Préparer mon budget'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : FilledButton(
                        key: const ValueKey('next'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        onPressed: next,
                        child: const Text('Suivant'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final String icon, title, text;
  const _Page({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1D6A56), Color(0xFF124A3C)]),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [BoxShadow(color: const Color(0xFF1D6A56).withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Icon(appIcon(icon), size: 56, color: Colors.white),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.c.muted, fontSize: 15.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}
