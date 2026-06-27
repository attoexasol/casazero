import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Responsive wrapper around [AlertDialog] with tablet max width,
/// keyboard-aware insets, and helpers for scrollable list content.
class ResponsiveAlertDialog extends StatelessWidget {
  const ResponsiveAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.shape,
    this.scrollable = false,
    this.actionsAlignment,
    this.actionsPadding,
    this.contentPadding,
    this.titlePadding,
    this.icon,
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.clipBehavior = Clip.none,
    this.tabletMaxWidth = 480,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final ShapeBorder? shape;
  final bool scrollable;
  final MainAxisAlignment? actionsAlignment;
  final EdgeInsetsGeometry? actionsPadding;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? titlePadding;
  final Widget? icon;
  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final Clip clipBehavior;
  final double tabletMaxWidth;

  static double maxWidthFor(
    BuildContext context, {
    double tabletMaxWidth = 480,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth >= 600) return tabletMaxWidth;
    return (screenWidth - 32.w).clamp(280.w, tabletMaxWidth.w);
  }

  static EdgeInsets insetPaddingFor(
    BuildContext context, {
    double tabletMaxWidth = 480,
  }) {
    final screenSize = MediaQuery.sizeOf(context);
    final maxWidth = maxWidthFor(context, tabletMaxWidth: tabletMaxWidth);
    final horizontalInset =
        ((screenSize.width - maxWidth).clamp(16.w, screenSize.width)) / 2;

    // [Dialog] adds [MediaQuery.viewInsets] to this padding automatically.
    return EdgeInsets.fromLTRB(
      horizontalInset,
      24.h,
      horizontalInset,
      24.h,
    );
  }

  /// IME bottom inset; use inside [Dialog] children where [MediaQuery.viewInsets]
  /// is cleared via [MediaQuery.removeViewInsets].
  static double keyboardBottomInset(BuildContext context) =>
      View.of(context).viewInsets.bottom;

  static bool isKeyboardVisible(BuildContext context) =>
      keyboardBottomInset(context) > 0;

  /// [Column.mainAxisSize] for form dialogs — always [MainAxisSize.max] inside
  /// a bounded [ConstrainedBox]; never toggle on viewInsets (IME focus loss).
  static MainAxisSize formDialogMainAxisSize(BuildContext context) =>
      MainAxisSize.max;

  /// Scrollable form body — always [Expanded]; never swap with [Flexible] on
  /// viewInsets or the focused [TextField] is recreated and the keyboard hides.
  static Widget formDialogScrollBody({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Expanded(
      child: SingleChildScrollView(
        padding: padding,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        child: child,
      ),
    );
  }

  /// Minimum margin around form [Dialog]s. [Dialog] adds [viewInsets] on top.
  static EdgeInsets formDialogInsetPadding(BuildContext context) {
    return EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h);
  }

  /// Max height from [LayoutBuilder] constraints inside [Dialog] (already
  /// keyboard-aware via the framework's [AnimatedPadding]).
  static double formDialogMaxHeightFromConstraints(
    BoxConstraints constraints, {
    double? preferredMaxHeight,
    double minHeight = 280,
  }) {
    final maxConstraint = constraints.maxHeight;
    if (!maxConstraint.isFinite || maxConstraint <= 0) {
      return preferredMaxHeight ?? 400.h;
    }
    final effectiveMin = math.min(minHeight.h, maxConstraint);
    final preferred = preferredMaxHeight ?? maxConstraint;
    return math.min(preferred, maxConstraint)
        .clamp(effectiveMin, maxConstraint);
  }

  /// Wraps form dialog content; height follows parent constraints from [Dialog].
  static Widget boundedFormDialogBody({
    required BuildContext context,
    required double maxWidth,
    double? preferredMaxHeight,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = formDialogMaxHeightFromConstraints(
          constraints,
          preferredMaxHeight: preferredMaxHeight,
        );
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: child,
        );
      },
    );
  }

  /// Anchor above the keyboard when IME is open; centered when closed.
  static Alignment formDialogAlignment(BuildContext context) {
    return isKeyboardVisible(context)
        ? Alignment.bottomCenter
        : Alignment.center;
  }

  /// Max height for full-screen Material overlay form dialogs (e.g. Add Maintenance).
  static double overlayFormMaxHeightFromConstraints(
    BoxConstraints constraints, {
    double? preferredMaxHeight,
    double minHeight = 280,
    required double verticalMargin,
  }) {
    final available = constraints.maxHeight - verticalMargin * 2;
    if (!available.isFinite || available <= 0) {
      return minHeight.h;
    }
    final preferred = preferredMaxHeight ?? available;
    final effectiveMin = math.min(minHeight.h, available);
    return math.min(preferred, available).clamp(effectiveMin, available);
  }

  static double overlayFormMaxHeight(
    BuildContext context, {
    double heightFactor = 0.9,
    double minHeight = 280,
    double verticalMargin = 30,
  }) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final margin = viewInsets.bottom > 0 ? 16.h : verticalMargin.h;
    final layoutHeight = screenHeight - viewInsets.bottom;
    final available = layoutHeight - margin * 2;
    final preferred = screenHeight * heightFactor;
    final effectiveMin = math.min(minHeight.h, available);
    return math.min(preferred, available).clamp(effectiveMin, available);
  }

  static Alignment overlayFormAlignment(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom > 0
        ? Alignment.bottomCenter
        : Alignment.center;
  }

  static double overlayFormVerticalMargin(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom > 0 ? 16.h : 30.h;
  }

  /// Max height for list content inside a dialog body.
  static double listContentMaxHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final available = screenHeight - viewInsets.bottom - 180.h;
    return available.clamp(100.h, 400.h);
  }

  static Widget boundedList({
    required BuildContext context,
    required Widget child,
  }) {
    return SizedBox(
      width: double.maxFinite,
      height: listContentMaxHeight(context),
      child: child,
    );
  }

  static Widget loadingPlaceholder({String? message}) {
    return Builder(
      builder: (context) {
        return SizedBox(
          height: 100.h,
          child: Center(
            child: message == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(height: 12.h),
                      Text(
                        message,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: insetPaddingFor(context, tabletMaxWidth: tabletMaxWidth),
      scrollable: scrollable,
      title: title,
      content: content,
      actions: actions,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
      actionsAlignment: actionsAlignment,
      actionsPadding: actionsPadding,
      contentPadding: contentPadding,
      titlePadding: titlePadding,
      icon: icon,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      clipBehavior: clipBehavior,
    );
  }
}
