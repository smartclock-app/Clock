class LrcLine {
  final String timestamp;
  final String lyrics;

  double get timestampInSeconds => int.parse(timestamp.split(":")[0]) * 60 + double.parse(timestamp.split(":")[1]);

  LrcLine(this.timestamp, this.lyrics);
}

class Lrc {
  final List<LrcLine> lyrics;

  Lrc(this.lyrics);

  static bool isValid(String? lyrics) {
    if (lyrics == null) return false;

    return RegExp(
      r"\[\d+:\d+\.\d+\].*",
      multiLine: true,
    ).hasMatch(lyrics);
  }

  static Lrc parse(String lyrics) {
    final lines = lyrics.split("\n");
    final lrcLines = <LrcLine>[];
    for (final line in lines) {
      final match = RegExp(r"\[(\d+:\d+\.\d+)\](.*)").firstMatch(line);
      if (match == null) continue;

      final timestamp = match.group(1)!;
      final lyrics = match.group(2)!.trim();
      if (lyrics.isEmpty) continue;

      lrcLines.add(LrcLine(timestamp, lyrics));
    }
    return Lrc(lrcLines);
  }
}
