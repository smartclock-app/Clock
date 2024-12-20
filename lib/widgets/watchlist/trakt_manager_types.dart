part of 'trakt_manager.dart';

typedef TokenPair = ({String accessToken, String refreshToken});

class TraktManagerAPIError {
  final int statusCode;
  final String? reasonPhrase;
  final Response response;

  TraktManagerAPIError(this.statusCode, this.reasonPhrase, this.response);
}

class AccessTokenResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String refreshToken;
  final String scope;
  final int createdAt;

  AccessTokenResponse(
    this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.refreshToken,
    this.scope,
    this.createdAt,
  );

  factory AccessTokenResponse.fromJson(Map<String, dynamic> json) {
    return AccessTokenResponse(
      json["access_token"],
      json["token_type"],
      json["expires_in"],
      json["refresh_token"],
      json["scope"],
      json["created_at"],
    );
  }
}

class ListItem {
  final String type;
  final ListItemType? movie;
  final ListItemType? show;

  ListItem({
    required this.type,
    this.movie,
    this.show,
  });

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      type: json["type"],
      movie: json["movie"] != null ? ListItemType.fromJson(json["movie"]) : null,
      show: json["show"] != null ? ListItemType.fromJson(json["show"]) : null,
    );
  }
}

class ListItemType {
  final ({int tmdb}) ids;

  ListItemType({
    required this.ids,
  });

  factory ListItemType.fromJson(Map<String, dynamic> json) {
    return ListItemType(ids: (tmdb: json["ids"]["tmdb"]));
  }
}
