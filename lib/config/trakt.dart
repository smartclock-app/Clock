part of 'config.dart';

class Trakt {
  final String clientId;
  final String clientSecret;
  String accessToken;
  String refreshToken;
  final String redirectUri;
  final String listId;
  final bool includeWatchlist;
  final bool includeEpisodesAsShow;

  Trakt({
    required this.clientId,
    required this.clientSecret,
    required this.accessToken,
    required this.refreshToken,
    required this.redirectUri,
    required this.listId,
    required this.includeWatchlist,
    required this.includeEpisodesAsShow,
  });

  factory Trakt.asDefault() => Trakt(
        clientId: "",
        clientSecret: "",
        accessToken: "",
        refreshToken: "",
        redirectUri: "",
        listId: "",
        includeWatchlist: false,
        includeEpisodesAsShow: false,
      );

  factory Trakt.fromJson(Map<String, dynamic> json) => Trakt(
        clientId: json["clientId"],
        clientSecret: json["clientSecret"],
        accessToken: json["accessToken"],
        refreshToken: json["refreshToken"],
        redirectUri: json["redirectUri"],
        listId: json["listId"],
        includeWatchlist: json["includeWatchlist"],
        includeEpisodesAsShow: json["includeEpisodesAsShow"],
      );

  Map<String, dynamic> toJson() => {
        "clientId": clientId,
        "clientSecret": clientSecret,
        "accessToken": accessToken,
        "refreshToken": refreshToken,
        "redirectUri": redirectUri,
        "listId": listId,
        "includeWatchlist": includeWatchlist,
        "includeEpisodesAsShow": includeEpisodesAsShow,
      };
}
