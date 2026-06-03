/// Thực thể đại diện cho một người chơi trong phòng chờ.
class Player {
  final String id;
  final String name;
  final bool isHost;
  int score;

  Player({
    required this.id,
    required this.name,
    this.isHost = false,
    this.score = 0,
  });

  Player copyWith({String? id, String? name, bool? isHost, int? score}) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      isHost: isHost ?? this.isHost,
      score: score ?? this.score,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'is_host': isHost,
        'score': score,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        isHost: json['is_host'] as bool? ?? false,
        score: json['score'] as int? ?? 0,
      );
}
