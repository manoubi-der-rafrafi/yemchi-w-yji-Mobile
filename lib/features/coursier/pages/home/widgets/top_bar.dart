import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/commande/data/commande_service.dart';
import '../controllers/home_controller.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HomeController>();
    final auth = context.read<AuthController>();

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
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (ctrl.canResetCurrentIncident)
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final userId = auth.currentUser.value?.id;
                    if (userId == null || userId.isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final service = CommandeService(context.read<Api>());
                      final updated = await service
                          .reinitialiserEtatIncidentTransporteur(userId);
                      auth.currentUser.value = updated;
                      ctrl.clearSelection(notify: false);
                      final zone = ctrl.currentZone;
                      if (zone != null && zone.isNotEmpty) {
                        await ctrl.refreshByZone(zone);
                      }
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Etat incident reinitialise.'),
                          ),
                        );
                    } catch (e) {
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              'Impossible de reinitialiser l etat incident. ($e)',
                            ),
                          ),
                        );
                    }
                  },
                  child: const Text('Reprendre le service'),
                ),
              )
            else if (!ctrl.isCurrentTransporteurIndisponible)
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
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    backgroundColor: MaterialStateProperty.resolveWith(
                      (states) => states.contains(MaterialState.selected)
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                    ),
                    foregroundColor: MaterialStateProperty.resolveWith(
                      (states) => states.contains(MaterialState.selected)
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    side: MaterialStateProperty.resolveWith(
                      (states) => BorderSide(
                        color: states.contains(MaterialState.selected)
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    elevation: MaterialStateProperty.all(0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
