/// Strongly typed upload result to prevent snackbar routing bugs
enum UploadStatus {
  success,
  error,
}

/// Typed result for document upload operations
/// Prevents success messages from being routed to error snackbars
class UploadResult {
  final UploadStatus status;
  final String message;

  const UploadResult.success(this.message)
      : status = UploadStatus.success;

  const UploadResult.error(this.message)
      : status = UploadStatus.error;

  bool get isSuccess => status == UploadStatus.success;
  bool get isError => status == UploadStatus.error;
}

