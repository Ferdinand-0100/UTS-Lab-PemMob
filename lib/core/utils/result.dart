import 'package:quiz_app/core/errors/failures.dart';

/// A lightweight [Either] substitute scoped to our domain.
///
/// Using `Result<T>` rather than raw exceptions in use cases and
/// repository contracts makes the success/failure paths explicit in
/// signatures and forces callers to handle the error case.
sealed class Result<T> {
  const Result();
}

/// Successful result wrapping the produced [value].
class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

/// Failed result wrapping the underlying [failure].
class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}
