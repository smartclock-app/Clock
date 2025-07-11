part of 'trakt_manager.dart';

typedef TokenPair = ({String accessToken, String refreshToken});

class TraktManagerAPIError {
  final int statusCode;
  final String? reasonPhrase;
  final Response response;

  TraktManagerAPIError(this.statusCode, this.reasonPhrase, this.response);

  @override
  String toString() {
    return 'TraktManagerAPIError(statusCode: $statusCode, reasonPhrase: $reasonPhrase)';
  }
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
  final ({
    int tmdb,
    String slug,
  }) ids;

  ListItemType({
    required this.ids,
  });

  factory ListItemType.fromJson(Map<String, dynamic> json) {
    return ListItemType(ids: (
      tmdb: json["ids"]["tmdb"],
      slug: json["ids"]["slug"],
    ));
  }
}

class ShowSummary {
  final String title;
  final String status;

  ShowSummary({
    required this.title,
    required this.status,
  });

  factory ShowSummary.fromJson(Map<String, dynamic> json) {
    return ShowSummary(
      title: json["title"],
      status: json["status"],
    );
  }
}

class MovieSummary {
  final String title;
  final String released;
  final String status;

  MovieSummary({
    required this.title,
    required this.released,
    required this.status,
  });

  factory MovieSummary.fromJson(Map<String, dynamic> json) {
    return MovieSummary(
      title: json["title"],
      released: json["released"],
      status: json["status"],
    );
  }
}
