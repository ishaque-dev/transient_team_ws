import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/error/failure.dart';

extension EitherStreamX<T> on Stream<T> {
  /// Turns data into `Right` and errors into `Left(Failure)` so the
  /// presentation layer never has to catch platform exceptions.
  Stream<Either<Failure, T>> toEither() {
    return transform(
      StreamTransformer<T, Either<Failure, T>>.fromHandlers(
        handleData: (data, sink) => sink.add(Right(data)),
        handleError: (error, stackTrace, sink) =>
            sink.add(Left(AppErrorHandler.handle(error))),
      ),
    );
  }
}
