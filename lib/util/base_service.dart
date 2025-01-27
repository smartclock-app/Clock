import 'package:smartclock/config/config.dart';

abstract class BaseService<T> {
  Config config;
  BaseService(this.config);
  Future<T> fetch();
  Map<String, dynamic> toJson(T data);
  T fromJson(Map<String, dynamic> json);
}
