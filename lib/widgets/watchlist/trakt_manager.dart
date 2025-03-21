import 'dart:convert';
import 'package:http/http.dart';
import 'package:smartclock/config/config.dart';

part 'trakt_manager_types.dart';

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
    final body = jsonEncode({
      "refresh_token": refreshToken,
      "client_id": clientId,
      "client_secret": clientSecret,
      "redirect_uri": redirectURI,
      "grant_type": "refresh_token",
    });
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

  /// Fetches the Trakt list and compares it to the watchlist database.
  /// Returns a tuple of a boolean indicating if the list has changed and a set of item IDs.
  Future<(bool, Set<String>, TokenPair?)> getClockList({required Config config, required Iterable watchlist}) async {
    late List<ListItem> items;
    TokenPair? tokens;

    final String listId = config.watchlist.trakt.listId;
    try {
      items = await getListItems(listId);
    } on TraktManagerAPIError catch (e) {
      if (e.statusCode != 401) rethrow;
      tokens = await refreshAccessToken();
      items = await getListItems(listId);
    }

    final watchlistIds = watchlist.map((e) => e["id"]).toSet();

    final itemTypes = <String>{"show", "movie", if (config.watchlist.trakt.includeEpisodesAsShow) "episode"};

    final itemIds = items.where((e) => itemTypes.contains(e.type)).map((e) {
      if (e.type == "show" || e.type == "episode") {
        return "tv--${e.show?.ids.tmdb}--${e.show?.ids.slug}";
      } else {
        return "movie--${e.movie?.ids.tmdb}--${e.movie?.ids.slug}";
      }
    }).toSet();

    final setsHaveChanged = itemIds.difference(watchlistIds).isNotEmpty || watchlistIds.difference(itemIds).isNotEmpty;
    return (setsHaveChanged, itemIds, tokens);
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

  Future<ShowSummary> getShowSummary(String id) async {
    final request = "shows/$id";
    final headers = _headers;
    headers["Authorization"] = "Bearer $accessToken";

    final url = Uri.https(_baseURL, request, {"extended": "full"});
    final response = await client.get(url, headers: _headers);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);
    return ShowSummary.fromJson(jsonResult);
  }

  Future<MovieSummary> getMovieSummary(String id) async {
    final request = "movies/$id";
    final headers = _headers;
    headers["Authorization"] = "Bearer $accessToken";

    final url = Uri.https(_baseURL, request, {"extended": "full"});
    final response = await client.get(url, headers: _headers);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);
    return MovieSummary.fromJson(jsonResult);
  }
}
