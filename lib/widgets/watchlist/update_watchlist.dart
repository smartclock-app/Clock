import 'package:smartclock/util/logger_util.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:dio/dio.dart';
import 'package:smartclock/config/config.dart' show Config;

Future<void> updateWatchlist({required Config config, required Set<String> items, required Database database}) async {
  final logger = LoggerUtil.logger;
  logger.t("Refetching watchlist items");

  database.execute("DELETE FROM watchlist");
  final insert = database.prepare("INSERT INTO watchlist (id, name, status, nextAirDate) VALUES (?, ?, ?, ?)");

  final dio = Dio(BaseOptions(baseUrl: "https://api.themoviedb.org/3", headers: {"Authorization": "Bearer ${config.watchlist.tmdbApiKey}"}));
  for (final item in items) {
    final [type, id] = item.split("-");

    late final Map<String, dynamic> data;
    try {
      Response details = await dio.get("/$type/$id");

      if (type == 'movie') {
        // Get release date from API for clock's region
        Response releaseDates = await dio.get("/movie/$id/release_dates");
        final List results = releaseDates.data["results"];

        final dates = results.where((e) => e["iso_3166_1"] == config.watchlist.region);
        final regionRelease = dates.isNotEmpty ? (dates.first["release_dates"] as List).where((e) => e["type"] >= 3).firstOrNull : null;
        final date = regionRelease?["release_date"];

        data = {
          "id": item,
          "name": details.data["title"],
          "status": details.data["status"],
          "nextAirDate": date,
        };
      } else {
        // Set the date to the next episode air date, ensuring the time is 00:00:00Z
        final date = details.data["next_episode_to_air"]?["air_date"].split("T")[0];
        data = {
          "id": item,
          "name": details.data["name"],
          "status": details.data["status"],
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
