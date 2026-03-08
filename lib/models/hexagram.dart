class Hexagram {
  final int id; // 1 to 64
  final String name; // 乾, 坤, 屯...
  final String description; // 卦辭
  final List<String> lines; // 六爻的爻辭 (初九, 九二...)
  final String? greatImage; // 大象
  final List<String>? smallImages; // 小象 (對應六爻)
  final String? tuan; // 彖傳
  final String? wenYan; // 文言傳

  Hexagram({
    required this.id,
    required this.name,
    required this.description,
    required this.lines,
    this.greatImage,
    this.smallImages,
    this.tuan,
    this.wenYan,
  });

  factory Hexagram.fromJson(Map<String, dynamic> json) {
    return Hexagram(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      lines: List<String>.from(json['lines'] ?? []),
      greatImage: json['greatImage'] as String?,
      smallImages: json['smallImages'] != null
          ? List<String>.from(json['smallImages'])
          : null,
      tuan: json['tuan'] as String?,
      wenYan: json['wenYan'] as String?,
    );
  }
}
