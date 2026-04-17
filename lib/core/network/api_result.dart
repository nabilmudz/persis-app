class ApiResult<T> {
  final T? data;
  final String? message;
  final bool isSuccess;

  const ApiResult._({
    required this.data,
    required this.message,
    required this.isSuccess,
  });

  factory ApiResult.success(T data) {
    return ApiResult._(data: data, message: null, isSuccess: true);
  }

  factory ApiResult.failure(String message) {
    return ApiResult._(data: null, message: message, isSuccess: false);
  }
}
