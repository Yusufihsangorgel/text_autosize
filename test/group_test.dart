import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

import 'utils.dart';

class GroupTest extends StatefulWidget {
  const GroupTest({super.key});

  @override
  State<GroupTest> createState() => GroupTestState();
}

class GroupTestState extends State<GroupTest> {
  final group = AutoSizeGroup();
  var width1 = 300.0;
  var width2 = 300.0;
  var showSecond = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Column(
        children: <Widget>[
          SizedBox(
            width: width1,
            height: 100,
            child: AutoSizeText(
              'XXXXXX',
              style: const TextStyle(fontSize: 60),
              minFontSize: 1,
              maxLines: 1,
              group: group,
            ),
          ),
          if (showSecond)
            SizedBox(
              width: width2,
              height: 100,
              child: AutoSizeText(
                'XXXXXX',
                style: const TextStyle(fontSize: 60),
                minFontSize: 1,
                maxLines: 1,
                group: group,
              ),
            ),
        ],
      ),
    );
  }

  void refresh() {
    setState(() {});
  }
}

void expectFontSizes(WidgetTester tester, double fontSize) {
  final texts = tester.widgetList(find.byType(Text));
  expect(texts, isNotEmpty);
  for (final text in texts) {
    expect(effectiveFontSize(text as Text), fontSize);
  }
}

void main() {
  testWidgets('all group members synchronize their font size', (tester) async {
    await tester.pumpWidget(const GroupTest());

    expectFontSizes(tester, 50);

    final state = tester.state<GroupTestState>(find.byType(GroupTest));

    state.width1 = 200;
    state.refresh();
    await tester.pump(Duration.zero);
    expectFontSizes(tester, 33);

    state.width2 = 150;
    state.refresh();
    await tester.pump(Duration.zero);
    expectFontSizes(tester, 25);

    state.width2 = 100;
    state.refresh();
    await tester.pump(Duration.zero);
    expectFontSizes(tester, 16);

    state.width1 = 60;
    state.width2 = 60;
    state.refresh();
    await tester.pump(Duration.zero);
    expectFontSizes(tester, 10);

    state.width1 = 200;
    state.refresh();
    await tester.pump(Duration.zero);
    expectFontSizes(tester, 10);

    state.width2 = 250;
    state.refresh();
    await tester.pump(Duration.zero);
    expectFontSizes(tester, 33);

    state.width1 = 250;
    state.refresh();
    await tester.pump(Duration.zero);
    expectFontSizes(tester, 41);

    state.width1 = 300;
    state.width2 = 300;
    state.refresh();
    await tester.pump(Duration.zero);
    await tester.pump(Duration.zero);
    expectFontSizes(tester, 50);

    await tester.pump(Duration.zero);
  });

  testWidgets('a disposed member leaves the group', (tester) async {
    await tester.pumpWidget(const GroupTest());

    final state = tester.state<GroupTestState>(find.byType(GroupTest));

    state.width2 = 60;
    state.refresh();
    await tester.pump(Duration.zero);
    expectFontSizes(tester, 10);

    // Removing the constrained member lets the remaining one grow again. The
    // group notifies its members in a microtask, so growing back takes one
    // extra frame.
    state.showSecond = false;
    state.refresh();
    await tester.pump(Duration.zero);
    await tester.pump(Duration.zero);
    expectFontSizes(tester, 50);
  });

  testWidgets('changing the group moves the membership', (tester) async {
    final groupA = AutoSizeGroup();
    final groupB = AutoSizeGroup();
    var group = groupA;

    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Column(
              children: <Widget>[
                SizedBox(
                  width: 60,
                  height: 100,
                  child: AutoSizeText(
                    'AAAAAA',
                    style: const TextStyle(fontSize: 60),
                    minFontSize: 1,
                    maxLines: 1,
                    group: groupA,
                  ),
                ),
                SizedBox(
                  width: 300,
                  height: 100,
                  child: AutoSizeText(
                    'BBBBBB',
                    style: const TextStyle(fontSize: 60),
                    minFontSize: 1,
                    maxLines: 1,
                    group: group,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump(Duration.zero);
    expectFontSizes(tester, 10);

    rebuild(() {
      group = groupB;
    });
    await tester.pump(Duration.zero);
    await tester.pump(Duration.zero);

    Text textFor(String data) => tester.widget<Text>(find.text(data));
    expect(effectiveFontSize(textFor('AAAAAA')), 10);
    expect(effectiveFontSize(textFor('BBBBBB')), 50);
  });

  // The convergence guarantee, pinned. Each member computes its own largest
  // fitting size from its own constraints, independently of what the group has
  // settled on, so reporting it can only lower the group minimum or leave it
  // alone. That makes the fixed point reachable in a single extra frame and
  // means a rebuild cannot feed back into a member's own candidate size.
  testWidgets('a group settles after one frame and does not oscillate', (
    tester,
  ) async {
    final group = AutoSizeGroup();

    Widget cell(double width) => SizedBox(
      width: width,
      height: 40,
      child: AutoSizeText(
        'the same text in both cells',
        group: group,
        minFontSize: 4,
        maxFontSize: 40,
        maxLines: 1,
        style: const TextStyle(fontSize: 40),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: Row(children: [cell(300), cell(120)])),
    );

    List<double> rendered() => tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.style!.fontSize!)
        .toList();

    // First frame: the roomier cell has laid out at its own maximum, because
    // the narrow cell had not reported yet when it built.
    final firstFrame = rendered();
    expect(firstFrame.first, greaterThan(firstFrame.last));

    // Second frame: both are at the narrow cell's size.
    await tester.pump();
    final settled = rendered();
    expect(settled.first, settled.last);

    // And it stays there: no further pump changes anything.
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      expect(rendered(), settled, reason: 'frame ${i + 3} changed the size');
    }
  });

  testWidgets('removing the constraining member releases the group', (
    tester,
  ) async {
    final group = AutoSizeGroup();
    var showNarrow = true;

    Widget cell(double width) => SizedBox(
      width: width,
      height: 40,
      child: AutoSizeText(
        'shared text here',
        group: group,
        minFontSize: 4,
        maxFontSize: 40,
        maxLines: 1,
        style: const TextStyle(fontSize: 40),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              cell(300),
              if (showNarrow) cell(90),
              TextButton(
                onPressed: () => setState(() => showNarrow = false),
                child: const Text('drop'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    double first() => tester
        .widgetList<RichText>(find.byType(RichText))
        .first
        .text
        .style!
        .fontSize!;

    final constrained = first();

    await tester.tap(find.text('drop'));
    await tester.pumpAndSettle();

    expect(
      first(),
      greaterThan(constrained),
      reason: 'the group should grow back once the narrow member is gone',
    );
  });
}
