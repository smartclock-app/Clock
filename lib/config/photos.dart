part of 'config.dart';

class Photos {
  final bool enabled;
  final int interval;
  final Uri immichUrl;
  final String immichAccessToken;
  final String immichAlbumId;
  final String immichShareKey;
  final bool useStaticLinks;
  final List<String> images;

  Photos({
    required this.enabled,
    required this.interval,
    required this.immichUrl,
    required this.immichAccessToken,
    required this.immichAlbumId,
    required this.immichShareKey,
    required this.useStaticLinks,
    required this.images,
  });

  factory Photos.asDefault() => Photos(
        enabled: false,
        interval: 2,
        immichUrl: Uri(),
        immichAccessToken: "",
        immichAlbumId: "",
        immichShareKey: "",
        useStaticLinks: false,
        images: [],
      );

  factory Photos.fromJson(Map<String, dynamic> json) => Photos(
        enabled: json["enabled"],
        interval: json["interval"],
        immichUrl: Uri.parse(json["immichUrl"]),
        immichAccessToken: json["immichAccessToken"],
        immichAlbumId: json["immichAlbumId"],
        immichShareKey: json["immichShareKey"],
        useStaticLinks: json["useStaticLinks"],
        images: List<String>.from(json["images"]),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "interval": interval,
        "immichUrl": immichUrl.toString(),
        "immichAccessToken": immichAccessToken,
        "immichAlbumId": immichAlbumId,
        "immichShareKey": immichShareKey,
        "useStaticLinks": useStaticLinks,
        "images": List<dynamic>.from(images),
      };
}
