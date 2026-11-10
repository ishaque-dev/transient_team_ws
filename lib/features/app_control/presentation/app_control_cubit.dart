import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/features/app_control/data/app_control_remote_ds.dart';
import 'package:transient_team_ws/features/app_control/domain/feature_flags.dart';
import 'package:transient_team_ws/features/app_control/domain/subscription_entity.dart';

enum BlockReason { appDisabled, subscriptionInvalid }

class AppControlState extends Equatable {
  const AppControlState({
    required this.flags,
    this.subscription,
    this.subscriptionLoaded = false,
    this.subscriptionUnavailable = false,
    this.clockTick = 0,
  });

  final FeatureFlags flags;
  final SubscriptionEntity? subscription;
  final bool subscriptionLoaded;

  /// The record could not be read (e.g. offline with no cache). The app stays
  /// usable rather than locking people out over a network problem.
  final bool subscriptionUnavailable;

  /// Bumped when the subscription end passes, so listeners re-check it.
  final int clockTick;

  bool get isReady => subscriptionLoaded || subscriptionUnavailable;

  BlockReason? blockReason(DateTime now) {
    if (!flags.appEnabled) return BlockReason.appDisabled;
    if (subscriptionLoaded && !(subscription?.isValid(now) ?? false)) {
      return BlockReason.subscriptionInvalid;
    }
    return null;
  }

  AppControlState copyWith({
    FeatureFlags? flags,
    SubscriptionEntity? Function()? subscription,
    bool? subscriptionLoaded,
    bool? subscriptionUnavailable,
    int? clockTick,
  }) {
    return AppControlState(
      flags: flags ?? this.flags,
      subscription: subscription != null ? subscription() : this.subscription,
      subscriptionLoaded: subscriptionLoaded ?? this.subscriptionLoaded,
      subscriptionUnavailable:
          subscriptionUnavailable ?? this.subscriptionUnavailable,
      clockTick: clockTick ?? this.clockTick,
    );
  }

  @override
  List<Object?> get props => [
    flags,
    subscription,
    subscriptionLoaded,
    subscriptionUnavailable,
    clockTick,
  ];
}

/// Live feature switches and subscription status for the whole app.
class AppControlCubit extends Cubit<AppControlState> {
  AppControlCubit(this._remote)
    : super(AppControlState(flags: _remote.currentFlags()));

  final AppControlRemoteDs _remote;
  StreamSubscription<FeatureFlags>? _flags;
  StreamSubscription<SubscriptionEntity?>? _subscription;
  Timer? _expiryTimer;

  void start() {
    _flags = _remote.watchFlags().listen(
      (flags) => emit(state.copyWith(flags: flags)),
    );
    _subscription = _remote.watchSubscription().listen(
      (subscription) {
        emit(
          state.copyWith(
            subscription: () => subscription,
            subscriptionLoaded: true,
            subscriptionUnavailable: false,
          ),
        );
        _scheduleExpiryCheck(subscription);
      },
      onError: (Object error) {
        debugPrint('Subscription unavailable: $error');
        if (!state.subscriptionLoaded) {
          emit(state.copyWith(subscriptionUnavailable: true));
        }
      },
    );
  }

  /// Re-evaluates the gate the moment the subscription runs out, even if the
  /// app is open at that time.
  void _scheduleExpiryCheck(SubscriptionEntity? subscription) {
    _expiryTimer?.cancel();
    final end = subscription?.validUntil;
    if (end == null) return;
    final wait = end.difference(DateTime.now());
    if (wait.isNegative || wait > const Duration(days: 20)) return;
    _expiryTimer = Timer(wait + const Duration(seconds: 1), () {
      if (!isClosed) emit(state.copyWith(clockTick: state.clockTick + 1));
    });
  }

  @override
  Future<void> close() {
    unawaited(_flags?.cancel());
    unawaited(_subscription?.cancel());
    _expiryTimer?.cancel();
    return super.close();
  }
}

extension FeatureFlagsContext on BuildContext {
  /// Current feature switches; rebuilds the caller when they change.
  FeatureFlags get flags =>
      select<AppControlCubit, FeatureFlags>((cubit) => cubit.state.flags);
}
