/// Corner radii, hand-picked in the mockup. None derive from the CSS
/// `--radius` scale, so they are named constants rather than a scale.
abstract final class AppRadius {
  /// Bottom sheets and the main panels.
  static const double sheet = 28;

  /// The `Mark Completed` pill.
  static const double pill = 100;

  /// The reminder and deadline chips.
  static const double chip = 20;

  static const double fab = 15;

  /// The date/time and deadline picker dialogs.
  static const double dialog = 24;

  /// The tinted background behind an active icon in the Create Task actions row.
  static const double actionPill = 14;
}
