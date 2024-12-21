part of 'config.dart';

class Dimension {
  final double x;
  final double y;
  final double width;
  final double height;

  Dimension({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory Dimension.parse(String csv) {
    final parsed = csv.split(',');
    return Dimension(
      x: double.parse(parsed[0]),
      y: double.parse(parsed[1]),
      width: double.parse(parsed[2]),
      height: double.parse(parsed[3]),
    );
  }

  @override
  String toString() => "${x.toInt()},${y.toInt()},${width.toInt()},${height.toInt()}";
  String toJson() => toString();
}
