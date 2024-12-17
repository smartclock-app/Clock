import 'package:smartclock/util/logger.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:dio/dio.dart';
import 'package:smartclock/util/config.dart' show Config;

Future<void> updateWatchlist({required Config config, required Set<String> items, required Database database}) async {
  logger.t("Refetching watchlist items");

  database.execute("DELETE FROM watchlist");
  final insert = database.prepare("INSERT INTO watchlist (id, name, status, nextAirDate) VALUES (?, ?, ?, ?)");

  final dio = Dio(BaseOptions(baseUrl: "https://api.themoviedb.org/3", headers: {"Authorization": "Bearer ${config.watchlist.tmdbApiKey}"}));
  for (final item in items) {
    final [type, id] = item.split("-");

    late final Map<String, dynamic> data;
    try {
      Response response = await dio.get("/$type/$id");

      if (type == 'movie') {
        // Set the date to the release date, ensuring the time is 00:00:00Z
        final date = response.data["release_date"].split("T")[0];
        data = {
          "id": item,
          "name": response.data["title"],
          "status": response.data["status"],
          "nextAirDate": date != null ? "${date}T00:00:00Z" : null,
        };
      } else {
        // Set the date to the next episode air date, ensuring the time is 00:00:00Z
        final date = response.data["next_episode_to_air"]?["air_date"].split("T")[0];
        data = {
          "id": item,
          "name": response.data["name"],
          "status": response.data["status"],
          "nextAirDate": date != null ? "${date}T00:00:00Z" : null,
        };
      }

      insert.execute([data["id"], data["name"], data["status"], data["nextAirDate"]]);
    } on DioException catch (e) {
      logger.t("Failed to fetch '${e.response?.realUri}': ${e.response?.statusCode} ${e.type}");
    } on SqliteException catch (e) {
      logger.e("Failed to insert watchlist item: $e");
    }
  }

  insert.dispose();
}
