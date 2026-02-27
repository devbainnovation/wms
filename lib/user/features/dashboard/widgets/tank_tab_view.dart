import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/providers.dart';
import 'package:wms/user/features/dashboard/services/tank_service.dart';

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
                  border: InputBorder.none,
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
                    final matchName = tank.name.toLowerCase().contains(
                      searchQuery,
                    );
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
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 100),
                    const Center(
                      child: Text(
                        'Unable to load tanks',
                        style: TextStyle(color: AppColors.red),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => ref.invalidate(tankListProvider),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
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
        ? AppColors.accentGreen
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
          _AnimatedTank(
            levelPercent: data.levelPercent,
            levelColor: levelColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Capacity: ${data.capacityLabel}',
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
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$h:$m:$s $ampm $d/$mo/$y';
  }
}

class _AnimatedTank extends StatefulWidget {
  const _AnimatedTank({required this.levelPercent, required this.levelColor});

  final double levelPercent;
  final Color levelColor;

  @override
  State<_AnimatedTank> createState() => _AnimatedTankState();
}

class _AnimatedTankState extends State<_AnimatedTank>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.levelPercent.clamp(0, 1)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          width: 124,
          height: 152,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 6,
                top: 8,
                right: 20,
                bottom: 16,
                child: _buildTankBody(value),
              ),
              Positioned(
                right: 3,
                top: 8,
                bottom: 16,
                child: _buildGauge(value),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTankBody(double value) {
    return Stack(
      children: [
        Positioned(
          left: 14,
          right: 14,
          top: 0,
          height: 14,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.lightGreyText, width: 1.2),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF2F6FB), Color(0xFFE0E8F2)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 14,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.lightGreyText, width: 1.4),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF5F8FC), Color(0xFFE7EEF7)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  FractionallySizedBox(
                    heightFactor: value,
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    widget.levelColor.withValues(alpha: 0.72),
                                    widget.levelColor,
                                  ],
                                ),
                              ),
                            ),
                            CustomPaint(
                              painter: _WavePainter(
                                animationValue: _waveController.value,
                                waveColor: Colors.white.withValues(alpha: 0.30),
                                amplitude: 3.4,
                                frequency: 1.9,
                                baseHeight: 6.0,
                              ),
                            ),
                            CustomPaint(
                              painter: _WavePainter(
                                animationValue:
                                    (_waveController.value + 0.38) % 1,
                                waveColor: widget.levelColor.withValues(
                                  alpha: 0.28,
                                ),
                                amplitude: 4.4,
                                frequency: 1.3,
                                baseHeight: 7.4,
                              ),
                            ),
                            CustomPaint(
                              painter: _BubblePainter(
                                animationValue: _waveController.value,
                                bubbleColor: Colors.white.withValues(
                                  alpha: 0.24,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.36),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGauge(double value) {
    return SizedBox(
      width: 13,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final markerTop = constraints.maxHeight * (1 - value.clamp(0, 1)) - 2;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreyText,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              ...List.generate(5, (index) {
                return Positioned(
                  top: index * (constraints.maxHeight / 4),
                  left: 0,
                  right: 7,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreyText.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
              Positioned(
                top: markerTop.clamp(0.0, constraints.maxHeight - 4),
                left: 3,
                child: Container(
                  width: 10,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: widget.levelColor,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: widget.levelColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({
    required this.animationValue,
    required this.waveColor,
    required this.amplitude,
    required this.frequency,
    required this.baseHeight,
  });

  final double animationValue;
  final Color waveColor;
  final double amplitude;
  final double frequency;
  final double baseHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = waveColor;
    final path = Path()..moveTo(0, size.height);

    final waveOffset = animationValue * 2 * math.pi;
    final centerY = baseHeight;
    for (double x = 0; x <= size.width; x++) {
      final waveY =
          centerY +
          amplitude *
              math.sin((x / size.width) * 2 * math.pi * frequency + waveOffset);
      path.lineTo(x, waveY);
    }

    path
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.waveColor != waveColor ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.frequency != frequency;
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({
    required this.animationValue,
    required this.bubbleColor,
  });

  final double animationValue;
  final Color bubbleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    final bubbles =
        <({double xFactor, double radius, double speed, double offset})>[
          (xFactor: 0.24, radius: 1.8, speed: 1.0, offset: 0.05),
          (xFactor: 0.51, radius: 2.4, speed: 0.8, offset: 0.32),
          (xFactor: 0.74, radius: 1.6, speed: 1.2, offset: 0.61),
          (xFactor: 0.39, radius: 1.9, speed: 0.9, offset: 0.83),
        ];

    for (final b in bubbles) {
      final progress = ((animationValue * b.speed) + b.offset) % 1.0;
      final x = size.width * b.xFactor + math.sin(progress * 2 * math.pi) * 1.8;
      final y = size.height * (1 - progress);
      canvas.drawCircle(Offset(x, y), b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.bubbleColor != bubbleColor;
  }
}
