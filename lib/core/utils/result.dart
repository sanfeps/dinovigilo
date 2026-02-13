import 'package:dinovigilo/core/error/failures.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ResultFailure<T>;

  T get data => (this as Success<T>).value;
  Failure get error => (this as ResultFailure<T>).failure;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure error) failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success(value),
      final ResultFailure<T> f => failure(f.failure),
    };
  }

  Result<R> map<R>(R Function(T data) fn) {
    return switch (this) {
      Success<T>(:final value) => Result.success(fn(value)),
      final ResultFailure<T> f => Result.failure(f.failure),
    };
  }

  Future<Result<R>> flatMap<R>(
      Future<Result<R>> Function(T data) fn) async {
    return switch (this) {
      Success<T>(:final value) => await fn(value),
      final ResultFailure<T> f => Result<R>.failure(f.failure),
    };
  }

  factory Result.success(T value) = Success<T>;
  factory Result.failure(Failure failure) = ResultFailure<T>;
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class ResultFailure<T> extends Result<T> {
  final Failure failure;
  const ResultFailure(this.failure);
}
