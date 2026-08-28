import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/multiserver_queue_result.dart';
import 'multiserver_chart_painter.dart';

/// Contenedor de gráficas del sistema de colas multicanal: selector tipo 'pill'
/// (Distribución P_n / Acumulada) + `PageView` deslizable con indicador animado de puntos.
class MultiserverGraphContainer extends StatefulWidget {
  final MultiserverQueueResult result;

  const MultiserverGraphContainer({super.key, required this.result});

  @override
  State<MultiserverGraphContainer> createState() => _MultiserverGraphContainerState();
}

class _MultiserverGraphContainerState extends State<MultiserverGraphContainer> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSegmentSelected(int index) {
    if (index == _pageIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) => setState(() => _pageIndex = index);

  @override
  Widget build(BuildContext context) {
    final points = widget.result.distribution;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Distribución Pₙ')),
                ButtonSegment(value: 1, label: Text('Acumulada')),
              ],
              selected: {_pageIndex},
              showSelectedIcon: false,
              onSelectionChanged: (set) => _onSegmentSelected(set.first),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.fromLTRB(8, 12, 12, 4),
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    CustomPaint(
                      painter: MultiserverChartPainter.fromDistribution(
                        points,
                        cumulative: false,
                        servers: widget.result.servers,
                      ),
                    ),
                    CustomPaint(
                      painter: MultiserverChartPainter.fromDistribution(
                        points,
                        cumulative: true,
                        servers: widget.result.servers,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (i) {
                final active = i == _pageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            _MultiserverColorLegend(
              isCumulativePage: _pageIndex == 1,
              servers: widget.result.servers,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Desliza para alternar entre probabilidad puntual y acumulada',
                style: AppTextStyles.subtitle.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiserverColorLegend extends StatelessWidget {
  final bool isCumulativePage;
  final int servers;

  const _MultiserverColorLegend({
    required this.isCumulativePage,
    required this.servers,
  });

  @override
  Widget build(BuildContext context) {
    final generalLabel = isCumulativePage
        ? 'Probabilidad acumulada P(N ≤ n)'
        : 'Probabilidad de estado Pₙ';

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(
          color: AppColors.primaryLight,
          label: generalLabel,
        ),
        _LegendItem(
          color: AppColors.primary,
          label: 'Umbral de servidores (c = $servers)',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.subtitle.copyWith(fontSize: 11)),
      ],
    );
  }
}
