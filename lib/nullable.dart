class Nullable<T> {
  final T? value;

  Nullable(this.value);

  static Nullable<R> empty<R>() => Nullable(null);
}

extension NullableExt<R> on Nullable<R>? {
  R? getOr(R? other) => this != null ? this?.value : other;
}