import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:smartclock/util/logger_util.dart';

Future<List<String>> scrapeGooglePhotos(String apiKey, String photoUrl) async {
  final logger = LoggerUtil.logger;
  final url = 'https://scraping.narf.ai/api/v1/?api_key=$apiKey&url=$photoUrl';

  final response = await http.get(Uri.parse(url));
  final document = parse(response.body);

  final imgElements = document.querySelectorAll('img[src^="https://lh3.googleusercontent.com/pw"]');
  final imgUrls = imgElements.map((element) => element.attributes['src'] ?? '').where((url) => url.isNotEmpty);

  final dataElements = document.querySelectorAll('[data-latest-bg]');
  final dataUrls = dataElements.map((element) => element.attributes['data-latest-bg'] ?? '').where((url) => url.isNotEmpty);

  logger.t("Scraped Google Photos: ${imgUrls.length} img, ${dataUrls.length} data-latest-bg");

  if (imgUrls.isNotEmpty) {
    return imgUrls.map((e) => e.replaceAll(RegExp(r'(=w[0-9]+-h[0-9]+)|(=s[0-9]+)'), "=w1000-h1000")).toList();
  } else if (dataUrls.isNotEmpty) {
    return dataUrls.map((e) => e.replaceAll(RegExp(r'(=w[0-9]+-h[0-9]+)|(=s[0-9]+)'), "=w1000-h1000")).toList();
  } else {
    return [];
  }
}
