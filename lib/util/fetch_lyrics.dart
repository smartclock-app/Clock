import 'package:dio/dio.dart';
import 'package:smartclock/util/lrc.dart';
import 'package:sqflite/sqflite.dart';

Future<Lrc?> fetchLyrics(Database db, String title, String artist) async {
  final lyricsFromDb = await db.query("lyrics", where: "id = ?", whereArgs: ["$title - $artist"]);
  if (lyricsFromDb.isNotEmpty) return Lrc.parse(lyricsFromDb.first["lyrics"] as String);

  final response = await Dio().get("https://lrclib.net/api/search?q=$title+$artist");
  final data = response.data as List<dynamic>;
  final lyrics = data.firstOrNull["syncedLyrics"];
  if (lyrics != null && Lrc.isValid(lyrics)) {
    await db.insert("lyrics", {"id": "$title - $artist", "lyrics": lyrics});
    return Lrc.parse(lyrics);
  } else {
    return null;
  }
}
