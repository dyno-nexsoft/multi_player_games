import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';
part 'player.g.dart';

/// Thực thể đại diện cho một người chơi trong phòng chờ.
@freezed
abstract class Player with _$Player {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Player({
    required String id,
    required String name,
    @Default(false) bool isHost,
    @Default(0) int score,
  }) = _Player;

  /// Creates a [Player] instance from a JSON map.
  /// Necessary for updating local state when player info is received from the network.
  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
}
