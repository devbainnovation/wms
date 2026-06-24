import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/providers.dart';
import 'package:wms/user/features/dashboard/services/tank_service.dart';
import 'package:wms/user/features/auth/screens/session_expiry_navigation.dart';
import 'package:wms/user/features/dashboard/widgets/tank_tab/tank_visualizer.dart';
import 'package:wms/user/features/dashboard/screens/tank_history_screen.dart';

class TankTabView extends ConsumerWidget {
  const TankTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tankAsync = ref.watch(tankListProvider);
    final selectedFilter = ref.watch(tankFilterProvider);
    final searchQuery = ref.watch(tankSearchQueryProvider).toLowerCase();

    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightGreyText),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  ref.read(tankSearchQueryProvider.notifier).setQuery(value);
                },
                decoration: const InputDecoration(
                  icon: Icon(
                    Icons.search_rounded,
                    color: AppColors.blue,
                    size: 28,
                  ),
                  hintText: 'Search tank',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _TankFilterChip(
                  label: 'All',
                  selected: selectedFilter == TankFilter.all,
                  onTap: () => ref
                      .read(tankFilterProvider.notifier)
                      .setFilter(TankFilter.all),
                ),
                _TankFilterChip(
                  label: 'Low',
                  selected: selectedFilter == TankFilter.low,
                  onTap: () => ref
                      .read(tankFilterProvider.notifier)
                      .setFilter(TankFilter.low),
                ),
                _TankFilterChip(
                  label: 'Normal',
                  selected: selectedFilter == TankFilter.normal,
                  onTap: () => ref
                      .read(tankFilterProvider.notifier)
                      .setFilter(TankFilter.normal),
                ),
                _TankFilterChip(
                  label: 'High',
                  selected: selectedFilter == TankFilter.high,
                  onTap: () => ref
                      .read(tankFilterProvider.notifier)
                      .setFilter(TankFilter.high),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(tankListProvider);
                await ref.read(tankListProvider.future);
              },
              child: tankAsync.when(
                data: (list) {
                  final filtered = list.where((tank) {
                    final searchableName =
                        (tank.espDisplayName.isEmpty
                                ? tank.espId
                                : tank.espDisplayName)
                            .toLowerCase();
                    final matchName = searchableName.contains(searchQuery);
                    final byFilter = switch (selectedFilter) {
                      TankFilter.all => true,
                      TankFilter.low => tank.levelPercent < 0.2,
                      TankFilter.normal =>
                        tank.levelPercent >= 0.2 && tank.levelPercent < 0.7,
                      TankFilter.high => tank.levelPercent >= 0.7,
                    };
                    return matchName && byFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text(
                            'No tanks found',
                            style: TextStyle(
                              color: AppColors.greyText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _TankLevelCard(data: filtered[index]),
                  );
                },
                loading: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(child: CircularProgressIndicator()),
                  ],
                ),
                error: (error, _) {
                  final message = error is ApiException
                      ? error.message
                      : 'Unable to load tanks';
                  final isSessionExpired = isSessionExpiredMessage(message);
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Text(
                          message,
                          style: const TextStyle(color: AppColors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => isSessionExpired
                              ? navigateToUserLogin(context)
                              : ref.invalidate(tankListProvider),
                          child: Text(isSessionExpired ? 'Login' : 'Retry'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TankFilterChip extends StatelessWidget {
  const _TankFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.lightGreen,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.darkText : AppColors.greyText,
        ),
      ),
    );
  }
}

class _TankLevelCard extends StatelessWidget {
  const _TankLevelCard({required this.data});

  final TankData data;

  @override
  Widget build(BuildContext context) {
    final percentText = '${(data.levelPercent * 100).round()}%';
    final levelColor = data.levelPercent >= 0.7
        ? AppColors.blue
        : data.levelPercent >= 0.35
        ? AppColors.warning
        : AppColors.red;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGreyText),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedTank(
            levelPercent: data.levelPercent,
            levelColor: levelColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.espDisplayName.isEmpty
                            ? data.espId
                            : data.espDisplayName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TankHistoryScreen(
                              componentId: data.id,
                              tankName: data.espDisplayName.isEmpty
                                  ? data.espId
                                  : data.espDisplayName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.bar_chart_rounded,
                        color: AppColors.blue,
                        size: 28,
                      ),
                      tooltip: 'View History',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Location: ${data.installedArea.isEmpty ? '-' : data.installedArea}',
                  style: const TextStyle(color: AppColors.greyText),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Level: ',
                      style: TextStyle(color: AppColors.greyText),
                    ),
                    Text(
                      percentText,
                      style: TextStyle(
                        color: levelColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (data.levelPercent < 0.2) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'LOW LEVEL ALERT',
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Updated: ${_formatDateTime(data.updatedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return AppDateTimeFormatter.formatDateTime(dt);
  }
}
