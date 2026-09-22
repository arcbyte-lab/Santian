/// One entry in the add-list color row: the ARGB int `TaskList.color` itself
/// stores (wrap it in `Color(...)` to render it), paired with a human name
/// for its semantics label - a color row with no way to name which dot is
/// which is not usable with a screen reader.
class ListColorOption {
  const ListColorOption(this.name, this.value);

  final String name;
  final int value;
}

/// The add-list color row's options, in display order. Not specified by the
/// spec (no color row is drawn); this reuses tones already meaningful
/// elsewhere in the app - the light and dark themes' own `primary` (sky and
/// orange) plus the debug seed's stone gray - filled out to a fuller row
/// with the same Tailwind-scale shades the rest of the palette is drawn
/// from. A reasoned default, not a ruling from the owner's own spec.
const List<ListColorOption> listColorOptions = [
  ListColorOption('Sky', 0xFF0284C7), // light theme's `primary`
  ListColorOption('Orange', 0xFFF97316), // dark theme's `primary`
  ListColorOption('Green', 0xFF16A34A),
  // Rose, not `error`'s red - so a red List never reads as an error state.
  ListColorOption('Rose', 0xFFE11D48),
  ListColorOption('Purple', 0xFF9333EA),
  ListColorOption('Teal', 0xFF0D9488),
  ListColorOption('Amber', 0xFFD97706),
  ListColorOption('Stone', 0xFF57534E), // the debug seed's "Building" list
];
