import 'package:flutter/painting.dart';

/// The only shadow drawn anywhere in the mockup, on the FAB:
/// `0px 4px 16px 0px #00000025`. Kept exact rather than approximated by one
/// of the unused `--shadow-*` tokens.
const fabShadow = BoxShadow(
  color: Color(0x25000000),
  offset: Offset(0, 4),
  blurRadius: 16,
);
