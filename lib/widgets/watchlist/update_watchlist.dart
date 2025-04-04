import 'package:smartclock/util/logger_util.dart';
import 'package:smartclock/widgets/watchlist/convert_to_next_date.dart';
import 'package:smartclock/widgets/watchlist/trakt_manager.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:dio/dio.dart';
import 'package:smartclock/config/config.dart' show Config;

Future<void> updateWatchlist({required Config config, required TraktManager trakt, required Set<String> items, required Database database}) async {
  final logger = LoggerUtil.logger;
  logger.t("[Watchlist] Refetching list item details");

  database.execute("DELETE FROM watchlist");
  final insert = database.prepare("INSERT INTO watchlist (id, name, status, nextAirDate) VALUES (?, ?, ?, ?)");

  final dio = Dio(BaseOptions(baseUrl: "https://api.themoviedb.org/3", headers: {"Authorization": "Bearer ${config.watchlist.tmdbApiKey}"}));
  for (final item in items) {
    final [type, id, slug] = item.split("--");

    late final Map<String, dynamic> data;
    try {
      Response details = await dio.get("/$type/$id");

      if (type == 'movie') {
        final summary = await trakt.getMovieSummary(slug);

        data = {
          "id": item,
          "name": details.data["title"],
          "status": details.data["status"],
          "nextAirDate": summary.released,
        };
      } else {
        // Check if there is a next episode to air within the next week
        final date = details.data["next_episode_to_air"]?["air_date"];
        if (date == null || DateTime.parse(date).isAfter(DateTime.now().add(Duration(days: 6)))) continue;

        // Fetch the show summary to get the exact next air date and time
        final summary = await trakt.getShowSummary(slug);
        final airDate = convertToNextDate(summary.airs, config.watchlist.timezone);

        data = {
          "id": item,
          "name": details.data["name"],
          "status": details.data["status"],
          "nextAirDate": airDate.toIso8601String(),
        };
      }

      insert.execute([data["id"], data["name"], data["status"], data["nextAirDate"]]);
    } on DioException catch (e) {
      logger.t("[Watchlist] Failed to fetch '${e.response?.realUri}': ${e.response?.statusCode} ${e.type}");
    } on SqliteException catch (e) {
      logger.e("[Watchlist] Failed to insert item: $e");
    }
  }

  insert.dispose();
}
