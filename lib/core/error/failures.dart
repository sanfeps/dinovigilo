sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class DataFailure extends Failure {
  const DataFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
