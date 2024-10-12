import 'package:smartclock/util/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dio/dio.dart';
import 'package:smartclock/util/config.dart' show Config;

Future<void> updateWatchlist({required Config config, required Database database}) async {
  logger.t("Refetching watchlist items");

  final batch = database.batch();
  batch.delete("watchlist");

  final dio = Dio(BaseOptions(baseUrl: "https://api.themoviedb.org/3", headers: {"Authorization": "Bearer ${config.watchlist.apiKey}"}));
  for (final item in config.watchlist.items) {
    final response = await dio.get("/${item.type}/${item.id}");

    late final Map<String, dynamic> data;
    if (item.type == 'movie') {
      data = {
        "id": "${item.id}-${item.type}",
        "name": response.data["title"],
        "status": response.data["status"],
        "nextAirDate": response.data["release_date"],
      };
    } else {
      data = {
        "id": "${item.id}-${item.type}",
        "name": response.data["name"],
        "status": response.data["status"],
        "nextAirDate": response.data["next_episode_to_air"]?["air_date"],
      };
    }

    batch.insert("watchlist", data);
  }

  await batch.commit();
}
