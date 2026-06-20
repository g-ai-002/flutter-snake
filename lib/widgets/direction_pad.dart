import 'package:flutter/material.dart';
import '../models/game_state.dart';

class DirectionPad extends StatelessWidget {
  final void Function(Direction) onDirection;

  const DirectionPad({super.key, required this.onDirection});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final btnStyle = IconButton.styleFrom(
      backgroundColor: colorScheme.surfaceContainerHighest,
      foregroundColor: colorScheme.onSurface,
      minimumSize: const Size(52, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up),
          onPressed: () => onDirection(Direction.up),
          style: btnStyle,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_left),
              onPressed: () => onDirection(Direction.left),
              style: btnStyle,
            ),
            const SizedBox(width: 8),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_right),
              onPressed: () => onDirection(Direction.right),
              style: btnStyle,
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => onDirection(Direction.down),
          style: btnStyle,
        ),
      ],
    );
  }
}
