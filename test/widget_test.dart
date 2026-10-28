import 'package:carnet237/format.dart';
import 'package:carnet237/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseAmount accepts French formats', () {
    expect(parseAmount('12 500'), 12500);
    expect(parseAmount('12500,50'), 12500.5);
    expect(parseAmount(''), isNull);
  });

  test('shiftMonth crosses years', () {
    expect(shiftMonth('2026-01', -1), '2025-12');
    expect(shiftMonth('2026-12', 1), '2027-01');
  });

  test('settings keep one active account and category of each kind', () {
    final s = Settings.defaults();
    for (final a in s.accounts) {
      a.archived = true;
    }
    for (final c in s.cats) {
      c.archived = true;
    }
    s.normalize();
    expect(s.accounts.where((a) => !a.archived), isNotEmpty);
    expect(s.cats.where((c) => c.income && !c.archived), isNotEmpty);
    expect(s.cats.where((c) => !c.income && !c.archived), isNotEmpty);
  });
}
