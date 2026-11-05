import 'package:carnet237/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a huge amount shrinks and leaves room for the label', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(child: Text('Salaire')),
              FitNumber(child: Text('+38 948 750 000 000 FCFA', style: TextStyle(fontSize: 20))),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull); // no overflow
    expect(tester.getSize(find.byType(FitNumber)).width, lessThanOrEqualTo(320 * 0.46));
    expect(tester.getSize(find.text('Salaire')).width, greaterThan(100));
  });

  testWidgets('an ordinary amount keeps its size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(children: [FitNumber(child: Text('2 500 FCFA', style: TextStyle(fontSize: 14)))]),
        ),
      ),
    );
    final box = tester.getSize(find.byType(FitNumber));
    expect(box.height, tester.getSize(find.text('2 500 FCFA')).height);
  });
}
