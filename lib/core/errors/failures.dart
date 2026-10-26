/// Base class for all domain/data failures.
///
/// Modeling errors as values (rather than throwing) lets the presentation
/// layer decide how to surface them and keeps business logic testable
/// without try/catch noise. Each concrete failure should carry enough
/// context for meaningful user-facing messages.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

/// Returned when data could not be found on the data source.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found.']);
}

/// Returned when a JSON payload is missing required keys or has
/// invalid types.
class FormatFailure extends Failure {
  const FormatFailure([super.message = 'Data format is invalid.']);
}

/// Catch-all for unexpected runtime errors. The original error is kept
/// for debugging but should never be shown to end users directly.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong.']);
}
