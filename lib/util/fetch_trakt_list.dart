import 'package:sqflite/sqflite.dart';
import 'package:smartclock/util/config.dart';
import 'package:smartclock/util/trakt_manager.dart';

/// Fetches the Trakt list and compares it to the watchlist database.
/// Returns a tuple of a boolean indicating if the list has changed and a set of item IDs.
Future<(bool, Set<String>, TokenPair?)> fetchTraktList({required Config config, required TraktManager trakt, required Database database}) async {
  final watchlist = await database.query("watchlist");
  late List<ListItem> items;
  TokenPair? tokens;

  final String listId = config.watchlist.trakt.listId;
  try {
    items = await trakt.getListItems(listId);
  } on TraktManagerAPIError catch (e) {
    if (e.statusCode != 401) rethrow;
    tokens = await trakt.refreshAccessToken();
    items = await trakt.getListItems(listId);
  }

  final watchlistIds = watchlist.map((e) => e["id"]).toSet();

  final itemTypes = <String>{"show", "episode", "movie"};
  if (config.watchlist.trakt.includeEpisodesAsShow != null && config.watchlist.trakt.includeEpisodesAsShow == false) {
    itemTypes.remove("episode");
  }

  final itemIds = items.where((e) => itemTypes.contains(e.type)).map((e) {
    if (e.type == "show" || e.type == "episode") {
      return "tv-${e.show!.ids.tmdb}";
    } else {
      return "movie-${e.movie!.ids.tmdb}";
    }
  }).toSet();

  final setsHaveChanged = itemIds.difference(watchlistIds).isNotEmpty || watchlistIds.difference(itemIds).isNotEmpty;
  return (setsHaveChanged, itemIds, tokens);
}
