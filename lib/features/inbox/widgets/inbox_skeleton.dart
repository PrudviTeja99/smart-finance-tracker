import 'package:flutter/material.dart';

/// Lightweight placeholders that keep the Inbox visually stable while its
/// first database read completes.
class InboxSkeleton extends StatefulWidget {
  const InboxSkeleton({super.key, this.cardCount = 5});

  final int cardCount;

  @override
  State<InboxSkeleton> createState() => _InboxSkeletonState();
}

class _InboxSkeletonState extends State<InboxSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading transaction inbox',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final highlight = 0.06 + (_controller.value * 0.08);
          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            itemCount: widget.cardCount,
            itemBuilder: (context, index) => _SkeletonCard(highlight: highlight),
          );
        },
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.highlight});

  final double highlight;

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: highlight);
    Widget bar(double width, {double height = 12}) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [bar(62, height: 18), bar(74, height: 10)],
            ),
            const SizedBox(height: 14),
            bar(double.infinity),
            const SizedBox(height: 8),
            bar(180, height: 10),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [bar(84, height: 16), bar(120, height: 18)],
            ),
          ],
        ),
      ),
    );
  }
}
