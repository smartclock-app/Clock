import 'dart:convert';
import 'package:http/http.dart';

part './trakt_manager_types.dart';

/// Manages the Trakt API.
///
/// Based off of package:trakt_dart, only includes the code necessary for retrieving list items.
class TraktManager {
  final String clientId;
  final String clientSecret;
  final String redirectURI;
  String accessToken;
  String refreshToken;

  final String _baseURL = "api.trakt.tv";
  final Map<String, String> _headers;

  Client client;

  TraktManager({
    required this.clientId,
    required this.clientSecret,
    required this.redirectURI,
    required this.accessToken,
    required this.refreshToken,
  })  : client = Client(),
        _headers = {
          "Content-Type": "application/json",
          "trakt-api-version": "2",
          "trakt-api-key": clientId,
        };

  Future<TokenPair> refreshAccessToken() async {
    final url = Uri.https(_baseURL, "oauth/token");
    final body = {
      "refresh_token": refreshToken,
      "client_id": clientId,
      "client_secret": clientSecret,
      "redirect_uri": redirectURI,
      "grant_type": "authorization_code",
    };
    final response = await client.post(url, headers: {"Content-Type": "application/json"}, body: body);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);
    final accessTokenResponse = AccessTokenResponse.fromJson(jsonResult);

    accessToken = accessTokenResponse.accessToken;
    refreshToken = accessTokenResponse.refreshToken;

    return (accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<List<ListItem>> getListItems(String listId) async {
    final request = "users/me/lists/$listId/items";
    final headers = _headers;
    headers["Authorization"] = "Bearer $accessToken";

    final url = Uri.https(_baseURL, request);
    final response = await client.get(url, headers: _headers);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);

    if (jsonResult is Iterable) {
      return jsonResult.map((e) => ListItem.fromJson(e)).toList();
    }
    return [];
  }
}
