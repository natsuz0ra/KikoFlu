import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';

/// Opt-in frame timing diagnostics for profile builds.
///
/// Enable with `--dart-define=KIKO_FRAME_PROBE=true`. The probe reports one
/// aggregate line per sample window so logging does not distort scroll timing.
class FrameTimingProbe {
  FrameTimingProbe._();

  static const bool _enabled = bool.fromEnvironment('KIKO_FRAME_PROBE');
  static const int _sampleWindow = int.fromEnvironment(
    'KIKO_FRAME_PROBE_WINDOW',
    defaultValue: 120,
  );
  static const int _highRefreshBudgetMicros = 8333;
  static const int _standardBudgetMicros = 16667;

  static final List<int> _buildMicros = <int>[];
  static final List<int> _rasterMicros = <int>[];
  static final List<int> _totalMicros = <int>[];
  static bool _started = false;
  static int _windowNumber = 0;
  static File? _reportFile;
  static Future<void> _pendingWrite = Future<void>.value();

  static void start() {
    if (!_enabled || _started) return;

    _started = true;
    unawaited(_start());
  }

  static Future<void> _start() async {
    final cacheDirectory = await getTemporaryDirectory();
    _reportFile = File('${cacheDirectory.path}/kikoflu_frame_probe.log');
    await _reportFile!.writeAsString('');
    SchedulerBinding.instance.addTimingsCallback(_record);
    _writeLine(
      '[FrameProbe] enabled window=${math.max(1, _sampleWindow)} '
      'budget120=${_highRefreshBudgetMicros}us '
      'budget60=${_standardBudgetMicros}us',
    );
  }

  static void _record(List<FrameTiming> timings) {
    for (final timing in timings) {
      _buildMicros.add(timing.buildDuration.inMicroseconds);
      _rasterMicros.add(timing.rasterDuration.inMicroseconds);
      _totalMicros.add(timing.totalSpan.inMicroseconds);
    }

    final windowSize = math.max(1, _sampleWindow);
    while (_buildMicros.length >= windowSize) {
      _reportWindow(windowSize);
    }
  }

  static void _reportWindow(int count) {
    final build = _buildMicros.sublist(0, count)..sort();
    final raster = _rasterMicros.sublist(0, count)..sort();
    final total = _totalMicros.sublist(0, count)..sort();

    _buildMicros.removeRange(0, count);
    _rasterMicros.removeRange(0, count);
    _totalMicros.removeRange(0, count);
    _windowNumber++;

    _writeLine(
      '[FrameProbe] window=$_windowNumber frames=$count '
      'build_us(p50/p90/p99/max)=${_percentiles(build)} '
      'raster_us(p50/p90/p99/max)=${_percentiles(raster)} '
      'total_us(p50/p90/p99/max)=${_percentiles(total)} '
      'over8ms(build/raster/total)='
      '${_overBudget(build, _highRefreshBudgetMicros)}/'
      '${_overBudget(raster, _highRefreshBudgetMicros)}/'
      '${_overBudget(total, _highRefreshBudgetMicros)} '
      'over16ms(build/raster/total)='
      '${_overBudget(build, _standardBudgetMicros)}/'
      '${_overBudget(raster, _standardBudgetMicros)}/'
      '${_overBudget(total, _standardBudgetMicros)}',
    );
  }

  static String _percentiles(List<int> sorted) {
    return '${_percentile(sorted, 0.50)}/'
        '${_percentile(sorted, 0.90)}/'
        '${_percentile(sorted, 0.99)}/'
        '${sorted.last}';
  }

  static int _percentile(List<int> sorted, double percentile) {
    final index = ((sorted.length - 1) * percentile).round();
    return sorted[index];
  }

  static int _overBudget(List<int> values, int budgetMicros) {
    return values.where((value) => value > budgetMicros).length;
  }

  static void _writeLine(String line) {
    debugPrint(line);
    final reportFile = _reportFile;
    if (reportFile == null) return;

    _pendingWrite = _pendingWrite.then(
      (_) => reportFile.writeAsString(
        '$line\n',
        mode: FileMode.append,
        flush: true,
      ),
    );
  }
}
