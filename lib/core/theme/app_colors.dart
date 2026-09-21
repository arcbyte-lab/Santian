import 'package:flutter/material.dart';

/// Colours Material's `ColorScheme` has no role for. Read them with
/// `Theme.of(context).extension<AppColors>()!`.
///
/// Used for `Task Time` text, the `Count Badge` fill, `Checkbox` outlines and
/// empty-field placeholders such as "Add deadline".
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.muted, required this.mutedForeground});

  final Color muted;
  final Color mutedForeground;

  static const light = AppColors(
    muted: Color(0xFFE7E5E4),
    mutedForeground: Color(0xFF57534E),
  );

  static const dark = AppColors(
    muted: Color(0xFF292524),
    mutedForeground: Color(0xFFA8A29E),
  );

  @override
  AppColors copyWith({Color? muted, Color? mutedForeground}) => AppColors(
        muted: muted ?? this.muted,
        mutedForeground: mutedForeground ?? this.mutedForeground,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
    );
  }
}
