import 'package:flutter/material.dart';
import 'package:smartclock/util/config.dart';
import 'package:smartclock/util/lrc.dart';

class NowPlayingLyrics extends StatelessWidget {
  final int progress;
  final Lrc lyrics;
  final Config config;

  const NowPlayingLyrics({super.key, required this.progress, required this.lyrics, required this.config});

  @override
  Widget build(BuildContext context) {
    LrcLine? currentLine;
    LrcLine? nextLine;
    LrcLine? previousLine;

    for (final line in lyrics.lyrics) {
      if (line.timestampInSeconds <= (progress / 1000)) {
        currentLine = line;
      } else if (line.timestampInSeconds > (progress / 1000)) {
        break;
      }
    }

    final currentIndex = lyrics.lyrics.indexOf(currentLine ?? lyrics.lyrics.first);
    if (currentIndex > 0) previousLine = lyrics.lyrics[currentIndex - 1];
    if (currentIndex < lyrics.lyrics.length - 1) nextLine = lyrics.lyrics[currentIndex + 1];

    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.grey, width: 1))),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        key: ValueKey(currentLine),
        children: [
          Text(
            previousLine?.lyrics ?? "",
            style: TextStyle(color: Colors.grey, fontSize: config.alexa.lyricsNextFontSize, overflow: TextOverflow.ellipsis),
          ),
          Text(
            currentLine?.lyrics ?? lyrics.lyrics.first.lyrics,
            style: TextStyle(fontSize: config.alexa.lyricsCurrentFontSize, fontWeight: FontWeight.bold),
            maxLines: 2,
          ),
          Text(
            nextLine?.lyrics ?? "",
            style: TextStyle(color: Colors.grey, fontSize: config.alexa.lyricsNextFontSize, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
