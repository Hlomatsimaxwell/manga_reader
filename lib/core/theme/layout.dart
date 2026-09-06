import 'package:flutter/widgets.dart';

const double kBottomBarHeight = 72;

const double kBottomBarSideMargin = 12;

const double kBottomBarBottomMargin = 24;

/// Extra breathing room below a list/grid so the floating bar never
/// permanently covers the last row once the user scrolls to the end.
/// = safe area + bar bottom margin + bar height + gap.
double bottomBarClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom +
        kBottomBarBottomMargin +
        kBottomBarHeight +
        12;