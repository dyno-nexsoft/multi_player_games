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
    @Default(0xFF6C63FF) int color,

    /// 0-based seat index — used by games to assign roles for 3+ players.
    @Default(0) int playerIndex,
  }) = _Player;

  /// Creates a [Player] instance from a JSON map.
  /// Necessary for updating local state when player info is received from the network.
  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
}
