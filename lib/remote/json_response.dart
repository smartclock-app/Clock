import 'dart:convert';

/// Standardized JSON response helpers for remote config endpoints.
///
/// Two top-level shapes are used:
/// - { "status": "ok", "result": <value> }
/// - { "status": "error", "error": "message" }
class JsonResponse {
  final String status;
  final dynamic result;
  final String? error;

  JsonResponse._(this.status, this.result, this.error);

  factory JsonResponse.ok(dynamic result) => JsonResponse._('ok', result, null);
  factory JsonResponse.error(String message) => JsonResponse._('error', null, message);

  Map<String, dynamic> toJson() {
    if (status == 'ok') return {'status': status, 'result': result};
    return {'status': status, 'error': error};
  }

  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() => toJsonString();
}

/// Convenience helpers
Map<String, dynamic> okResponse(dynamic result) => JsonResponse.ok(result).toJson();
Map<String, dynamic> errorResponse(String message) => JsonResponse.error(message).toJson();

String encodeOk(dynamic result) => JsonResponse.ok(result).toJsonString();
String encodeError(String message) => JsonResponse.error(message).toJsonString();
