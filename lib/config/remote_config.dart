part of 'config.dart';

class RemoteConfig {
  final bool enabled;
  final int port;
  final String password;
  final bool useBonjour;
  final String bonjourName;
  final String toggleDisplayPath;

  RemoteConfig({
    required this.enabled,
    required this.port,
    required this.password,
    required this.useBonjour,
    required this.bonjourName,
    required this.toggleDisplayPath,
  });

  factory RemoteConfig.asDefault() => RemoteConfig(
        enabled: true,
        port: 8080,
        password: "",
        useBonjour: true,
        bonjourName: "",
        toggleDisplayPath: "",
      );

  factory RemoteConfig.fromJson(Map<String, dynamic> json) => RemoteConfig(
        enabled: json["enabled"],
        port: json["port"],
        password: json["password"],
        useBonjour: json["useBonjour"],
        bonjourName: json["bonjourName"],
        toggleDisplayPath: json["toggleDisplayPath"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "port": port,
        "password": password,
        "useBonjour": useBonjour,
        "bonjourName": bonjourName,
        "toggleDisplayPath": toggleDisplayPath,
      };
}
