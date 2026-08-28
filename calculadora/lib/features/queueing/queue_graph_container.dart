import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/queue_result.dart';
import 'queue_chart_painter.dart';

/// Contenedor de gráficas del sistema de colas: selector tipo 'pill'
/// (Distribución P_n / Acumulada) + `PageView` deslizable, con el
/// mismo patrón visual que `DistributionGraphContainer` del Módulo 1.
class QueueGraphContainer extends StatefulWidget {
  final QueueResult result;

  const QueueGraphContainer({super.key, required this.result});

  @override
  State<QueueGraphContainer> createState() => _QueueGraphContainerState();
}

class _QueueGraphContainerState extends State<QueueGraphContainer> {
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
                      painter: QueueChartPainter.fromDistribution(
                        points,
                        cumulative: false,
                      ),
                    ),
                    CustomPaint(
                      painter: QueueChartPainter.fromDistribution(
                        points,
                        cumulative: true,
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Desliza para ver la otra gráfica',
                style: AppTextStyles.subtitle.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
