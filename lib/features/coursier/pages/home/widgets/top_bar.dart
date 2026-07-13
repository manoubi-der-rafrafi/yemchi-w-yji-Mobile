import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/home_controller.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HomeController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: 56,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 1,
              child: Builder(
                builder:
                    (ctx) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SegmentedButton<CommandTab>(
                segments: const [
                  ButtonSegment<CommandTab>(
                    value: CommandTab.envoyees,
                    label: Text('Commandes'),
                  ),
                  ButtonSegment<CommandTab>(
                    value: CommandTab.mes,
                    label: Text('Mes Commandes'),
                  ),
                ],
                selected: {ctrl.commandTab},
                onSelectionChanged: (selected) {
                  if (selected.isNotEmpty) {
                    ctrl.setCommandTab(selected.first);
                  }
                },
                showSelectedIcon: false,
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) =>
                        states.contains(WidgetState.selected)
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) =>
                        states.contains(WidgetState.selected)
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                  side: WidgetStateProperty.resolveWith(
                    (states) => BorderSide(
                      color:
                          states.contains(WidgetState.selected)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                    ),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  elevation: WidgetStateProperty.all(0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
