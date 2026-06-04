/// 5.1 — Centralised string constants for all mini-game IDs.
///
/// Using these constants instead of raw string literals prevents typos and
/// ensures that adding a new game only requires editing one place for the ID itself.
abstract class GameIds {
  static const tugOfWar = 'tug_of_war';
  static const sumoBumper = 'sumo_bumper';
  static const penaltyShootout = 'penalty_shootout';
  static const airHockey = 'air_hockey';
  static const reactionTap = 'reaction_tap';
  static const minesweeper = 'minesweeper';
  static const billiards = 'billiards';
  static const drawGuess = 'draw_guess';
  static const battleship = 'battleship';
  static const hotPotato = 'hot_potato';
  static const codeBreaker = 'code_breaker';
  static const liarsDice = 'liars_dice';
  static const neonDodge = 'neon_dodge';
}
