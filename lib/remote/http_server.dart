import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:logger/logger.dart';

import 'package:smartclock/util/logger_util.dart';

import 'package:smartclock/config/config.dart' show ConfigModel;

import 'command_service.dart';
import 'json_response.dart';

/// Simple HTTP server for remoteConfig commands.
class RemoteConfigHttpServer {
  HttpServer? _server;
  BonsoirBroadcast? _broadcast;
  Logger logger = LoggerUtil.logger;

  /// Start the server using `configModel.config.remoteConfig.port`.
  Future<void> start(BuildContext context) async {
    final configModel = context.read<ConfigModel>();
    final rc = configModel.config.remoteConfig;

    final address = InternetAddress.anyIPv4;
    _server = await HttpServer.bind(address, rc.port);

    logger.i('[Remote Config] HTTP server started on port ${rc.port}');

    if (rc.useBonjour) {
      _startBonjour(rc);
    }

    // Serve requests asynchronously
    _server!.listen((HttpRequest request) async {
      try {
        await _handleRequest(request, configModel);
      } catch (e) {
        try {
          request.response.statusCode = HttpStatus.internalServerError;
          request.response.headers.contentType = ContentType.json;
          request.response.write(encodeError('internal server error'));
        } finally {
          await request.response.close();
        }
      }
    });
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    if (_broadcast != null) {
      try {
        await _broadcast!.stop();
      } catch (_) {}
      _broadcast = null;
    }
  }

  Future<void> _handleRequest(HttpRequest request, ConfigModel configModel) async {
    final rc = configModel.config.remoteConfig;
    final remoteAddr = request.connectionInfo?.remoteAddress.address ?? 'unknown';
    final remotePort = request.connectionInfo?.remotePort ?? 0;
    logger.i('[Remote Config] ${request.method} ${request.uri.path} from $remoteAddr:$remotePort');
    // SSE endpoint removed

    // Only allow POST /api/command for now
    if (request.method != 'POST' || request.uri.path != '/api/command') {
      logger.w('[Remote Config] Not found: ${request.method} ${request.uri.path} from $remoteAddr:$remotePort');
      request.response.statusCode = HttpStatus.notFound;
      request.response.headers.contentType = ContentType.json;
      request.response.write(encodeError('not found'));
      await request.response.close();
      return;
    }

    // Basic Auth check
    if (rc.password.isNotEmpty) {
      final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
      if (!_validateBasicAuth(authHeader, rc.password)) {
        logger.w('[Remote Config] Unauthorized POST /api/command from $remoteAddr:$remotePort');
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.add(HttpHeaders.wwwAuthenticateHeader, 'Basic realm="SmartClock"');
        request.response.headers.contentType = ContentType.json;
        request.response.write(encodeError('unauthorized'));
        await request.response.close();
        return;
      }

      logger.i('[Remote Config] Authenticated POST /api/command from $remoteAddr:$remotePort');
    }

    // Read body
    final body = await utf8.decoder.bind(request).join();
    Map<String, dynamic>? jsonBody;
    try {
      jsonBody = jsonDecode(body) as Map<String, dynamic>?;
    } catch (e) {
      logger.w('[Remote Config] Invalid JSON from $remoteAddr:$remotePort: $e');
      request.response.statusCode = HttpStatus.badRequest;
      request.response.headers.contentType = ContentType.json;
      request.response.write(encodeError('invalid json body'));
      await request.response.close();
      return;
    }

    if (jsonBody == null || (jsonBody['command'] is! String)) {
      logger.w('[Remote Config] Missing command in request from $remoteAddr:$remotePort');
      request.response.statusCode = HttpStatus.badRequest;
      request.response.headers.contentType = ContentType.json;
      request.response.write(encodeError('missing command'));
      await request.response.close();
      return;
    }

    final command = jsonBody['command'] as String;
    final data = jsonBody.containsKey('data') ? jsonBody['data'] as Map<String, dynamic>? : null;

    final headersMap = <String, String>{};
    request.headers.forEach((name, values) {
      if (values.isNotEmpty) headersMap[name] = values.join(',');
    });

    logger.i('[Remote Config] Handling command "$command" from $remoteAddr:$remotePort');
    final result = await commandService.handleCommand(command, data, headersMap);
    logger.i('[Remote Config] Command "$command" result: ${result['status']}');

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(result));
    await request.response.close();
    logger.i('[Remote Config] Responded to $remoteAddr:$remotePort with status ${request.response.statusCode}');
  }

  Future<void> _startBonjour(dynamic rc) async {
    try {
      final bonjourName = rc.bonjourName;
      BonsoirService service = BonsoirService(
        name: (bonjourName is String && bonjourName.isNotEmpty) ? bonjourName : Platform.localHostname,
        type: '_smartclock._tcp',
        port: rc.port,
        attributes: {
          'platform': Platform.operatingSystem,
          'protected': (rc.password is String && rc.password.isNotEmpty).toString(),
        },
      );
      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.ready;
      await _broadcast!.start();
      logger.i('[Remote Config] Bonjour started for port ${rc.port}');
    } catch (e) {
      logger.w('[Remote Config] Failed to start Bonjour: $e');
    }
  }

  bool _validateBasicAuth(String? header, String expectedPassword) {
    if (header == null) return false;
    final parts = header.split(' ');
    if (parts.length != 2) return false;
    if (parts[0].toLowerCase() != 'basic') return false;

    try {
      final decoded = utf8.decode(base64.decode(parts[1]));
      // decoded is "username:password"; username may be empty
      final idx = decoded.indexOf(':');
      final password = idx >= 0 ? decoded.substring(idx + 1) : '';
      return password == expectedPassword;
    } catch (e) {
      return false;
    }
  }
}

final RemoteConfigHttpServer remoteConfigHttpServer = RemoteConfigHttpServer();
