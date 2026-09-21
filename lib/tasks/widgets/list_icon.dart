import 'package:flutter/material.dart';

/// Maps a List's stored icon key (a lucide identifier such as "rocket") to a
/// widget icon. Only the three lucide icons the mockup draws are mapped, to
/// Material stand-ins, with a neutral fallback. The add-list ticket decides the
/// real icon set and replaces this.
IconData iconForList(String key) => switch (key) {
      'rocket' => Icons.rocket_launch_outlined,
      'footprints' => Icons.directions_walk,
      'hammer' => Icons.hardware_outlined,
      _ => Icons.list_alt_outlined,
    };
