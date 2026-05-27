// lib/features/focus/focus_provider.dart
// 番茄钟状态管理

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FocusPhase { work, shortBreak, longBreak }

class FocusState {
  final FocusPhase phase;
  final int totalSeconds;
  final int remainingSeconds;
  final int completedPomodoros;
  final bool isRunning;

  const FocusState({
    this.phase = FocusPhase.work,
    this.totalSeconds = 25 * 60,
    this.remainingSeconds = 25 * 60,
    this.completedPomodoros = 0,
    this.isRunning = false,
  });

  FocusState copyWith({
    FocusPhase? phase,
    int? totalSeconds,
    int? remainingSeconds,
    int? completedPomodoros,
    bool? isRunning,
  }) {
    return FocusState(
      phase: phase ?? this.phase,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  double get progress => totalSeconds > 0
      ? (totalSeconds - remainingSeconds) / totalSeconds
      : 0.0;

  String get timeDisplay {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get phaseLabel {
    switch (phase) {
      case FocusPhase.work:
        return '专注中';
      case FocusPhase.shortBreak:
        return '短休息';
      case FocusPhase.longBreak:
        return '长休息';
    }
  }
}

class FocusNotifier extends StateNotifier<FocusState> {
  Timer? _timer;

  FocusNotifier() : super(const FocusState());

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 1) {
        _onPhaseComplete();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    state = FocusState(
      completedPomodoros: state.completedPomodoros,
    );
  }

  void skip() {
    _timer?.cancel();
    _onPhaseComplete();
  }

  void _onPhaseComplete() {
    _timer?.cancel();

    if (state.phase == FocusPhase.work) {
      final newCount = state.completedPomodoros + 1;
      // 每 4 个番茄钟后长休息
      if (newCount % 4 == 0) {
        state = state.copyWith(
          phase: FocusPhase.longBreak,
          totalSeconds: 15 * 60,
          remainingSeconds: 15 * 60,
          completedPomodoros: newCount,
          isRunning: false,
        );
      } else {
        state = state.copyWith(
          phase: FocusPhase.shortBreak,
          totalSeconds: 5 * 60,
          remainingSeconds: 5 * 60,
          completedPomodoros: newCount,
          isRunning: false,
        );
      }
    } else {
      // 休息结束，回到工作
      state = state.copyWith(
        phase: FocusPhase.work,
        totalSeconds: 25 * 60,
        remainingSeconds: 25 * 60,
        isRunning: false,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final focusProvider =
    StateNotifierProvider<FocusNotifier, FocusState>((ref) {
  return FocusNotifier();
});
