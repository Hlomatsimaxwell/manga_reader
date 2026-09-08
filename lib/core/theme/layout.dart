import 'package:flutter/widgets.dart';

const double kBottomBarHeight = 60;

const double kBottomBarSideMargin = 16;

const double kBottomBarBottomMargin = 8;

/// Extra breathing room below a list/grid so the floating bar never
/// permanently covers the last row once the user scrolls to the end.
/// = safe area + bar bottom margin + bar height + gap.
double bottomBarClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom +
        kBottomBarBottomMargin +
        kBottomBarHeight +
        12;

/// Top edge of the floating nav pill (measured from the screen bottom),
/// accounting for the safe area. The Continue FAB anchors just above this.
double bottomBarTopEdge(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom +
        kBottomBarBottomMargin +
        kBottomBarHeight;