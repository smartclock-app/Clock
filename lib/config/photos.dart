part of 'config.dart';

class Photos {
  final bool enabled;
  final String scraperApiKey;
  final int interval;
  final String googlePhotoAlbumUrl;
  final bool useStaticLinks;
  final List<String> images;

  Photos({
    required this.enabled,
    required this.scraperApiKey,
    required this.interval,
    required this.googlePhotoAlbumUrl,
    required this.useStaticLinks,
    required this.images,
  });

  factory Photos.asDefault() => Photos(
        enabled: false,
        scraperApiKey: "",
        interval: 2,
        googlePhotoAlbumUrl: "",
        useStaticLinks: false,
        images: [],
      );

  factory Photos.fromJson(Map<String, dynamic> json) => Photos(
        enabled: json["enabled"],
        scraperApiKey: json["scraperApiKey"],
        interval: json["interval"],
        googlePhotoAlbumUrl: json["googlePhotoAlbumUrl"],
        useStaticLinks: json["useStaticLinks"],
        images: List<String>.from(json["images"]),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "scraperApiKey": scraperApiKey,
        "interval": interval,
        "googlePhotoAlbumUrl": googlePhotoAlbumUrl,
        "useStaticLinks": useStaticLinks,
        "images": List<dynamic>.from(images),
      };
}
