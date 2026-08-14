sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network connection failed.']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Your session has expired.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error.']);
}

class OfflineFailure extends Failure {
  const OfflineFailure([super.message = 'Saved for offline synchronization.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
