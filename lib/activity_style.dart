import 'package:flutter/material.dart';
import 'models.dart';

extension ActivityStyle on Activity{
  IconData get icon {
    switch (this) {
      case Activity.video:
        return Icons.play_circle_outline;
      case Activity.games:
        return Icons.sports_esports_outlined;
      case Activity.chat:
        return Icons.chat_bubble_outline;
      case Activity.music:
        return Icons.music_note;
      case Activity.idle:
        return Icons.bedtime_outlined;
    }
  }
}
