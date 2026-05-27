import 'api_exception.dart';

sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);

  final T data;
}

final class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.error);

  final ApiException error;
}

extension ApiResultX<T> on ApiResult<T> {
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(ApiException error) onFailure,
  ) {
    return switch (this) {
      ApiSuccess<T>(:final data) => onSuccess(data),
      ApiFailure<T>(:final error) => onFailure(error),
    };
  }
}
