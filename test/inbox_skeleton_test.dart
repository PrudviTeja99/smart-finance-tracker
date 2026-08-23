import 'package:finance_tracker/features/inbox/widgets/inbox_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows stable Inbox placeholders while data is loading',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: InboxSkeleton())));

    expect(find.bySemanticsLabel('Loading transaction inbox'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(5));
  });
}
