import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../models/master_item_model.dart';

class PilihAsetWidget extends StatelessWidget {
  final List<MasterItemModel> masterItems;
  final Map<int, int> selectedQuantities; // itemId -> qty
  final Function(MasterItemModel item, int newQty) onQuantityChanged;

  const PilihAsetWidget({
    super.key,
    required this.masterItems,
    required this.selectedQuantities,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: masterItems.length,
      itemBuilder: (context, index) {
        final item = masterItems[index];
        final currentQty = selectedQuantities[item.id] ?? 0;
        final isSelected = currentQty > 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: AppCard(
            border: isSelected
                ? Border.all(color: primaryTeal, width: 2)
                : Border.all(color: strokeColor, width: 1.5),
            backgroundColor: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
                : theme.colorScheme.surface,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 430;
                final thumbnail = Container(
                  width: compact ? 56 : 72,
                  height: compact ? 56 : 72,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: strokeColor, width: 1),
                  ),
                  child: item.foto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item.foto!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.devices_rounded,
                              color: primaryTeal,
                              size: 30,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.devices_rounded,
                          color: primaryTeal,
                          size: 30,
                        ),
                );
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nama,
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.deskripsi,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: mutedText),
                    ),
                  ],
                );
                final metadata = Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(status: item.kondisi),
                    Text(
                      'Stok: ${item.stok} unit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: item.stok > 0
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                );
                final stepper = Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: strokeColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: currentQty > 0
                            ? () => onQuantityChanged(item, currentQty - 1)
                            : null,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.remove_rounded,
                            size: 18,
                            color: currentQty > 0
                                ? primaryTeal
                                : mutedText.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '$currentQty',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? primaryTeal
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: currentQty < item.stok
                            ? () => onQuantityChanged(item, currentQty + 1)
                            : null,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: currentQty < item.stok
                                ? primaryTeal
                                : mutedText.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          thumbnail,
                          const SizedBox(width: 12),
                          Expanded(child: details),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [metadata, stepper],
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    thumbnail,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          details,
                          const SizedBox(height: 8),
                          metadata,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    stepper,
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
