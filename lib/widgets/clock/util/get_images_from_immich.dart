import 'package:dio/dio.dart';

import 'package:smartclock/config/config.dart';
import 'package:smartclock/util/logger_util.dart';

Future<List<String>> getImagesFromImmich(Config config) async {
  final logger = LoggerUtil.logger;
  try {
    final dio = Dio(BaseOptions(
      baseUrl: config.photos.immichUrl.toString(),
      headers: {"Authorization": "Bearer ${config.photos.immichAccessToken}"},
    ));

    final albumResponse = await dio.get("/api/albums/${config.photos.immichAlbumId}");
    final List<dynamic> assets = albumResponse.data["assets"];
    final images = assets.map((e) => "${config.photos.immichUrl}/api/assets/${e["id"]}/thumbnail?key=${config.photos.immichShareKey}&size=preview").toList();

    logger.t("Fetched ${images.length} images from Immich");

    return images;
  } catch (e) {
    logger.e("[Photos] Error fetching images from Immich: $e");
    return [];
  }
}
