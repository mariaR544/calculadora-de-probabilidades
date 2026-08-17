import 'package:flutter/material.dart';
import '../../features/exponential/exponential_chart_painter.dart';
import '../../features/poisson/poisson_chart_painter.dart';
import '../../models/calculation_result.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Contenedor de gráficas reutilizable para cualquier distribución.
///
/// Muestra un selector tipo 'pill' con dos opciones (puntual/densidad
/// y acumulativa) y, debajo, un [PageView] con ambas gráficas. Ambas
/// interacciones —tocar el selector o deslizar la gráfica— quedan
/// sincronizadas entre sí. Justo debajo del PageView se muestra una
/// leyenda de colores compacta que se adapta a la página activa.
///
/// No depende de un tipo de distribución específico: usa
/// `result.isDiscrete` para decidir si pinta con [PoissonChartPainter]
/// (barras) o [ExponentialChartPainter] (curva + área), y consume
/// `result.points` / `result.cumulativePoints` sin más suposiciones.
class DistributionGraphContainer extends StatefulWidget {
  final CalculationResult result;

  /// Etiqueta de la primera página. Ej: 'Probabilidad (PMF)' para
  /// Poisson o 'Densidad (PDF)' para Exponencial.
  final String pointLabel;

  /// Etiqueta de la segunda página. Normalmente 'Acumulativa (CDF)'.
  final String cumulativeLabel;

  const DistributionGraphContainer({
    super.key,
    required this.result,
    required this.pointLabel,
    this.cumulativeLabel = 'Acumulativa (CDF)',
  });

  @override
  State<DistributionGraphContainer> createState() =>
      _DistributionGraphContainerState();
}

class _DistributionGraphContainerState
    extends State<DistributionGraphContainer> {
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

  /// Llamado al tocar el selector 'pill': anima el PageView.
  void _onSegmentSelected(int index) {
    if (index == _pageIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    // No hace falta setState aquí: onPageChanged del PageView lo hará
    // al terminar la animación, manteniendo una única fuente de verdad.
  }

  /// Llamado al deslizar el PageView con el dedo: sincroniza el pill.
  void _onPageChanged(int index) {
    setState(() => _pageIndex = index);
  }

  Widget _buildChart(List<ChartPoint> points) {
    return widget.result.isDiscrete
        ? CustomPaint(painter: PoissonChartPainter(points: points))
        : CustomPaint(painter: ExponentialChartPainter(points: points));
  }

  @override
  Widget build(BuildContext context) {
    final isCumulativePage = _pageIndex == 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(widget.pointLabel)),
                ButtonSegment(value: 1, label: Text(widget.cumulativeLabel)),
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
                    _buildChart(widget.result.points),
                    _buildChart(widget.result.cumulativePoints),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Indicador de páginas (. .)
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
            // Leyenda de colores: cambia según la página activa para no
            // recargar visualmente el área de la gráfica con textos
            // que no aplican a lo que se está mostrando.
            _ChartColorLegend(
              isCumulativePage: isCumulativePage,
              isDiscrete: widget.result.isDiscrete,
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

/// Barra compacta de leyendas de color debajo de la gráfica.
///
/// Usa exactamente los mismos colores que pintan [PoissonChartPainter]
/// y [ExponentialChartPainter], que NO comparten la misma pareja de
/// colores:
/// - Poisson (barras): [AppColors.barBase] para barras normales y
///   [AppColors.highlightStrong] para las que cumplen el criterio.
/// - Exponencial (curva): [AppColors.primaryDark] para la curva y
///   [AppColors.highlight] (relleno) para el área que cumple el
///   criterio.
///
/// Solo cambia la etiqueta de texto según la página activa (PMF/PDF
/// vs CDF); el par de colores se elige según [isDiscrete] para que la
/// leyenda sea siempre fiel a lo que realmente se dibuja en pantalla.
class _ChartColorLegend extends StatelessWidget {
  final bool isCumulativePage;
  final bool isDiscrete;

  const _ChartColorLegend({
    required this.isCumulativePage,
    required this.isDiscrete,
  });

  @override
  Widget build(BuildContext context) {
    final generalColor =
        isDiscrete ? AppColors.barBase : AppColors.primaryDark;
    final highlightColor =
        isDiscrete ? AppColors.highlightStrong : AppColors.highlight;

    final generalLabel = isCumulativePage
        ? (isDiscrete ? 'Barras acumuladas P(X ≤ x)' : 'Curva acumulada P(X ≤ x)')
        : (isDiscrete ? 'Barras de probabilidad' : 'Curva de densidad');

    final items = [
      _LegendItem(color: generalColor, label: generalLabel),
      _LegendItem(color: highlightColor, label: 'Región evaluada'),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: items,
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