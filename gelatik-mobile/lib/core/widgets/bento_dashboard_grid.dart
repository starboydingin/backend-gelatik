import 'package:flutter/material.dart';

class BentoDashboardItem {
  final Widget child;
  final int span;

  const BentoDashboardItem({required this.child, this.span = 1})
    : assert(span == 1 || span == 2);
}

/// Responsive two-column dashboard composition with explicit item spans.
class BentoDashboardGrid extends StatelessWidget {
  final List<BentoDashboardItem> items;
  final double gap;

  const BentoDashboardGrid({super.key, required this.items, this.gap = 12});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Preserve two columns on phones, but collapse on exceptionally narrow
      // windows so labels and controls remain accessible.
      final columns = constraints.maxWidth < 300 ? 1 : 2;
      final rows = <Widget>[];
      var cursor = 0;

      while (cursor < items.length) {
        final first = items[cursor];
        if (columns == 1 || first.span == 2) {
          rows.add(first.child);
          cursor++;
        } else {
          final hasPair =
              cursor + 1 < items.length && items[cursor + 1].span == 1;
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: first.child),
                  SizedBox(width: gap),
                  Expanded(
                    child: hasPair
                        ? items[cursor + 1].child
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
          cursor += hasPair ? 2 : 1;
        }
        if (cursor < items.length) rows.add(SizedBox(height: gap));
      }

      return Column(children: rows);
    },
  );
}
