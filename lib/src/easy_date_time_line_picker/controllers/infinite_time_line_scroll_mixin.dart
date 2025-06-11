import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:easy_date_timeline/src/utils/utils.dart';
import 'package:flutter/material.dart';
import '../sealed_classes/sealed_classes.exports.dart';

/// A mixin that provides infinite timeline scrolling functionality
/// for ScrollController implementations.
mixin InfiniteTimeLineScrollMixin on ScrollController {
  static const int _maxCacheSize = 5;

  // Cache for date position calculations
  final Map<String, double> _datePositionCache = {};

  /// Returns the viewport dimensions and scroll extents
  double get _viewportDimension => position.viewportDimension;
  double get _halfViewportDimension => _viewportDimension / 2;
  double get _maxScrollExtent => position.maxScrollExtent;

  /// Generates a cache key for date position calculations
  String _generateCacheKey(DateTime first, DateTime last, double itemExtent) =>
      '${first.millisecondsSinceEpoch}-${last.millisecondsSinceEpoch}-$itemExtent';

  /// Calculate the days difference between two dates
  int _calculateDaysDifference(DateTime first, DateTime last) {
    final normalizedFirst = first.normalized;
    final normalizedLast = last.normalized;
    final differencesInHours =
        normalizedLast.difference(normalizedFirst).inHours;
    return (differencesInHours / Duration.hoursPerDay).round();
  }

  /// Calculate the months difference between two dates
  int _calculateMonthsDifference(DateTime first, DateTime last) {
    final normalizedFirst = first.normalized;
    final normalizedLast = last.normalized;

    int numberOfMonths = 0;
    while (normalizedFirst.addMonths(numberOfMonths).isBefore(normalizedLast)) {
      numberOfMonths++;
    }

    return numberOfMonths;
  }

  /// Calculate scroll offset adjustments for centering
  double _calculateCenteringOffset({
    required double itemExtent,
    required EdgeInsets padding,
  }) {
    final halfItemExtent = itemExtent / 2;
    final halfPadding = padding.horizontal / 2;
    return _halfViewportDimension - halfItemExtent - halfPadding;
  }

  /// Manages the date position cache and ensures it doesn't exceed size limits
  double _getCachedOrCalculatePosition(
    DateTime firstDate,
    DateTime lastDate,
    double itemExtent,
    EasyDateTimeLinePickerMode timeLineMode,
  ) {
    final cacheKey = _generateCacheKey(firstDate, lastDate, itemExtent);

    if (_datePositionCache.containsKey(cacheKey)) {
      return _datePositionCache[cacheKey]!;
    }

    final daysDifference = switch (timeLineMode) {
      EasyDateTimeLinePickerMode.days => _calculateDaysDifference(firstDate, lastDate),
      EasyDateTimeLinePickerMode.months => _calculateMonthsDifference(firstDate, lastDate),
    };
    final position = daysDifference * itemExtent;

    if (_datePositionCache.length >= _maxCacheSize) {
      _datePositionCache.remove(_datePositionCache.keys.first);
    }
    _datePositionCache[cacheKey] = position;

    return position;
  }

  /// Calculates scroll position for centering a date
  double _calculateCenteredPosition({
    required double itemExtent,
    required DateTime firstDate,
    required DateTime lastDate,
    required EasyDateTimeLinePickerMode timeLineMode,
    required EdgeInsets padding,
  }) {
    final basePosition = _getCachedOrCalculatePosition(
      firstDate,
      lastDate,
      itemExtent,
      timeLineMode,
    );

    final centeringOffset = _calculateCenteringOffset(
      itemExtent: itemExtent,
      padding: padding,
    );
    //Ensure scroll offset stays within bounds
    return (basePosition - centeringOffset).clamp(0.0, _maxScrollExtent);
  }

  /// Calculates scroll position for first position alignment
  double _calculateFirstPosition({
    required double itemExtent,
    required DateTime firstDate,
    required DateTime lastDate,
    required EasyDateTimeLinePickerMode timeLineMode,
    required EdgeInsets padding,
  }) {
    final basePosition = _getCachedOrCalculatePosition(
      firstDate,
      lastDate,
      itemExtent,
      timeLineMode,
    );
    //Ensure scroll offset stays within bounds
    return (basePosition + padding.left).clamp(0.0, _maxScrollExtent);
  }

  /// Public method to get scroll offset based on selection mode
  @protected
  double getScrollOffsetFromSelectionMode({
    required double itemExtent,
    required DateTime firstDate,
    required DateTime lastDate,
    required EasyDateTimeLinePickerMode timeLineMode,
    required SelectionMode selectionMode,
    required EdgeInsets timelinePadding,
  }) {
    return switch (selectionMode) {
      SelectionModeNone() ||
      SelectionModeAlwaysFirst() =>
        _calculateFirstPosition(
          itemExtent: itemExtent,
          firstDate: firstDate,
          lastDate: lastDate,
          timeLineMode: timeLineMode,
          padding: timelinePadding,
        ),
      SelectionModeAutoCenter() => _calculateCenteredPosition(
          itemExtent: itemExtent,
          firstDate: firstDate,
          lastDate: lastDate,
          timeLineMode: timeLineMode,
          padding: timelinePadding,
        ),
    };
  }

  /// Clears the position cache
  @protected
  void clearCache() => _datePositionCache.clear();
}
