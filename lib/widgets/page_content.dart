import 'package:flutter/material.dart';

/// Scrollable page body with mobile-friendly padding and a max width so the
/// same screens still look right on tablet and desktop.
class PageContent extends StatelessWidget {
  const PageContent({
    super.key,
    required this.child,
    this.maxWidth = 900,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 28),
    this.onRefresh,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final scrollView = SingleChildScrollView(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );

    if (onRefresh == null) return scrollView;

    return RefreshIndicator(onRefresh: onRefresh!, child: scrollView);
  }
}
