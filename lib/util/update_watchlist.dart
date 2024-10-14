import 'package:smartclock/util/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dio/dio.dart';
import 'package:smartclock/util/config.dart' show Config;

Future<void> updateWatchlist({required Config config, required Set<String> items, required Database database}) async {
  logger.t("Refetching watchlist items");

  final batch = database.batch();
  batch.delete("watchlist");

  final dio = Dio(BaseOptions(baseUrl: "https://api.themoviedb.org/3", headers: {"Authorization": "Bearer ${config.watchlist.tmdbApiKey}"}));
  for (final item in items) {
    final [type, id] = item.split("-");
    final response = await dio.get("/$type/$id");

    late final Map<String, dynamic> data;
    if (type == 'movie') {
      data = {
        "id": "$id-$type",
        "name": response.data["title"],
        "status": response.data["status"],
        "nextAirDate": response.data["release_date"],
      };
    } else {
      data = {
        "id": "$id-$type",
        "name": response.data["name"],
        "status": response.data["status"],
        "nextAirDate": response.data["next_episode_to_air"]?["air_date"],
      };
    }

    batch.insert("watchlist", data);
  }

  await batch.commit();
}
