import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';

abstract interface class UseCase<R, P> {
  Future<Either<Failure, R>> call({required P parameters});
}

abstract interface class UseCaseSync<R, P> {
  Either<Failure, R> call({required P parameters});
}

abstract interface class UseCaseStream<R, P> {
  Stream<Either<Failure, R>> call({required P parameters});
}

abstract interface class UseCaseGeneric<R, P> {
  R call({required P parameters});
}

class NoParam extends Equatable {
  @override
  List<Object?> get props => [];
}
