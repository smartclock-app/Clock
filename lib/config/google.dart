part of 'config.dart';

class Google {
  final String clientId;
  final String clientSecret;
  String accessToken;
  String refreshToken;
  DateTime tokenExpiry;

  Google({
    required this.clientId,
    required this.clientSecret,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiry,
  });

  factory Google.asDefault() => Google(
        clientId: "",
        clientSecret: "",
        accessToken: "",
        refreshToken: "",
        tokenExpiry: DateTime.now(),
      );

  factory Google.fromJson(Map<String, dynamic> json) => Google(
        clientId: json["clientId"],
        clientSecret: json["clientSecret"],
        accessToken: json["accessToken"],
        refreshToken: json["refreshToken"],
        tokenExpiry: DateTime.parse(json["tokenExpiry"]).toUtc(),
      );

  Map<String, dynamic> toJson() => {
        "clientId": clientId,
        "clientSecret": clientSecret,
        "accessToken": accessToken,
        "refreshToken": refreshToken,
        "tokenExpiry": tokenExpiry.toIso8601String(),
      };
}
