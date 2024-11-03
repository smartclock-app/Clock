import 'package:dio/dio.dart';
import 'package:smartclock/util/lrc.dart';
import 'package:sqlite3/sqlite3.dart';

Future<Lrc?> fetchLyrics(Database db, String title, String artist) async {
  final lyricsFromDb = db.select("SELECT * FROM lyrics WHERE id = ?", ["$title - $artist"]);
  if (lyricsFromDb.isNotEmpty) return Lrc.parse(lyricsFromDb.first["lyrics"] as String);

  final response = await Dio().get("https://lrclib.net/api/search?q=$title+$artist");
  final data = response.data as List<dynamic>;
  final lyrics = data.firstOrNull?["syncedLyrics"];
  if (lyrics != null && Lrc.isValid(lyrics)) {
    db.execute("INSERT INTO lyrics (id, lyrics) VALUES (?, ?)", ["$title - $artist", lyrics]);
    return Lrc.parse(lyrics);
  } else {
    return null;
  }
}
