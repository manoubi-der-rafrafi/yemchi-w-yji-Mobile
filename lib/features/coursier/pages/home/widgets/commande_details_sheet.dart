import 'package:flutter/material.dart';
import 'package:yemchi_wyji/core/models/commande.dart';

class CommandeDetailsSheet extends StatelessWidget {
  final Commande commande;

  const CommandeDetailsSheet({super.key, required this.commande});

  @override
  Widget build(BuildContext context) {
    String coordText() {
      if (commande.latitudeDepart == null || commande.longitudeDepart == null) {
        return 'Coordonnées indisponibles';
      }
      return '${commande.latitudeDepart!.toStringAsFixed(5)}, ${commande.longitudeDepart!.toStringAsFixed(5)}';
    }

    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commande ${commande.id}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            CommandeInfoLine(
              label: 'Départ',
              value: commande.localisationDepart ?? 'Non indiqué',
            ),
            CommandeInfoLine(
              label: 'Destination',
              value: commande.destination ?? 'Non indiquée',
            ),
            CommandeInfoLine(label: 'Coordonnées', value: coordText()),
            if (commande.telDepart != null)
              CommandeInfoLine(
                label: 'Téléphone pickup',
                value: commande.telDepart!,
              ),
            if (commande.instructions != null &&
                commande.instructions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  commande.instructions!,
                  style: textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommandeInfoLine extends StatelessWidget {
  final String label;
  final String value;

  const CommandeInfoLine({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
