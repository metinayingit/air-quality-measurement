class AirPollution {
  final String? enlem; // Made nullable
  var kalite;
  var zaman;
  final String? boylam; // Made nullable
  var yuksek;
  var dusuk;
  List<AirPollution> son5;

  AirPollution({
    required this.kalite,
    required this.zaman,
    this.enlem, // Nullable
    this.boylam, // Nullable
    required this.yuksek,
    required this.dusuk,
    required this.son5,
  });

  factory AirPollution.fromJson(Map<String, dynamic> json) {
    var son5List = <AirPollution>[];
    if (json['son5'] != null) {
      json['son5'].forEach((v) {
        son5List
            .add(AirPollution.fromJson(Map<String, dynamic>.from(v as Map)));
      });
      son5List = son5List.reversed.toList(); // Listeyi ters çevir
    }
    return AirPollution(
        kalite: json['kalite'] ?? 0,
        zaman: json['zaman'] ?? 0,
        enlem: json['enlem'] as String?,
        boylam: json['boylam'] as String?,
        yuksek: json['yuksek'] ?? 0,
        dusuk: json['dusuk'] ?? 0,
        son5: son5List);
  }
}
