import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One entry in the add-list icon picker grid: the string key stored on
/// `TaskList.icon` (a lucide identifier, kebab-case to match lucide's own
/// naming) paired with its widget.
class ListIconOption {
  const ListIconOption(this.key, this.icon);

  final String key;
  final IconData icon;
}

/// The icon picker's grid, in display order. A curated set, not lucide's
/// full ~1500-icon catalog - the spec says "the same lucide set already in
/// use" but only ever names three (rocket, footprints, hammer); this widens
/// that to a broader spread of common list themes (work, home, hobbies) as a
/// reasoned default, not a ruling from the owner's own spec.
const List<ListIconOption> listIconOptions = [
  ListIconOption('rocket', LucideIcons.rocket),
  ListIconOption('footprints', LucideIcons.footprints),
  ListIconOption('hammer', LucideIcons.hammer),
  ListIconOption('briefcase', LucideIcons.briefcase),
  ListIconOption('home', LucideIcons.home),
  ListIconOption('heart', LucideIcons.heart),
  ListIconOption('book-open', LucideIcons.bookOpen),
  ListIconOption('shopping-cart', LucideIcons.shoppingCart),
  ListIconOption('dumbbell', LucideIcons.dumbbell),
  ListIconOption('plane', LucideIcons.plane),
  ListIconOption('coffee', LucideIcons.coffee),
  ListIconOption('star', LucideIcons.star),
  ListIconOption('target', LucideIcons.target),
  ListIconOption('palette', LucideIcons.palette),
  ListIconOption('music', LucideIcons.music),
  ListIconOption('graduation-cap', LucideIcons.graduationCap),
];

/// Maps a List's stored icon key to its widget. Falls back to a generic list
/// icon for anything outside [listIconOptions] - a key from a version of the
/// app with a different set, not something the picker itself can produce.
IconData iconForList(String key) {
  for (final option in listIconOptions) {
    if (option.key == key) return option.icon;
  }
  return LucideIcons.list;
}
