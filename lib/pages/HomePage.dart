import 'package:flutter/material.dart';
import 'package:projeto_elifone/theme/app_theme.dart';
import 'package:projeto_elifone/model/material_model.dart';
import 'package:projeto_elifone/services/supabase_estoque_service.dart';
import 'package:projeto_elifone/services/supabase_material_service.dart';
import 'package:projeto_elifone/widgets/estoque_table.dart';
import 'package:projeto_elifone/widgets/materiais_table.dart';

class MyHomePage extends StatefulWidget {
  final Future<List<MaterialModel>> Function()? loadMateriais;
  final Future<List<dynamic>> Function()? loadEstoque;

  const MyHomePage({super.key, this.loadMateriais, this.loadEstoque});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<MaterialModel> materiais = [];
  List<dynamic> estoque = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    carregarDashboard();
  }

  Future<void> carregarDashboard() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final materiaisData = await _loadMateriais();
      final estoqueData = await _loadEstoque();

      if (!mounted) return;

      setState(() {
        materiais = materiaisData;
        estoque = estoqueData;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Nao foi possivel carregar os dados do dashboard.';
      });
    }
  }

  Future<List<MaterialModel>> _loadMateriais() {
    final loader = widget.loadMateriais;
    if (loader != null) return loader();
    return SupabaseMaterialService().listar();
  }

  Future<List<dynamic>> _loadEstoque() {
    final loader = widget.loadEstoque;
    if (loader != null) return loader();
    return SupabaseEstoqueService().listarComMaterial();
  }

  int get totalEmEstoque {
    return materiais.fold<int>(0, (total, item) => total + item.quantidade);
  }

  int get entradas24h {
    return estoque.where((item) => _isEntrada(item) && _isLast24h(item)).length;
  }

  int get saidas24h {
    return estoque.where((item) => _isSaida(item) && _isLast24h(item)).length;
  }

  int get movimentacoes24h {
    return estoque.where(_isLast24h).length;
  }

  List<MaterialModel> get materiaisEmBaixa {
    final ordenados = [...materiais]
      ..sort((a, b) => a.quantidade.compareTo(b.quantidade));

    final criticos = ordenados.where((item) => item.quantidade <= 10).toList();
    return (criticos.isNotEmpty ? criticos : ordenados).take(3).toList();
  }

  List<dynamic> get atividadesRecentes {
    return estoque.take(5).toList();
  }

  bool _isEntrada(dynamic item) {
    return item is Map && item['Entrada'] == true;
  }

  bool _isSaida(dynamic item) {
    return item is Map && item['Saida'] == true;
  }

  bool _isLast24h(dynamic item) {
    final created = _createdAt(item);
    if (created == null) return false;
    return created.isAfter(DateTime.now().subtract(const Duration(hours: 24)));
  }

  DateTime? _createdAt(dynamic item) {
    if (item is! Map) return null;

    final value = item['created_at'];
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  String _materialName(dynamic item) {
    if (item is! Map) return '---';
    return (item['Material']?['nome'] ?? '---').toString();
  }

  String _tipoMovimentacao(dynamic item) {
    if (_isEntrada(item)) return 'Entrada';
    if (_isSaida(item)) return 'Saida';
    return '---';
  }

  Color _tipoColor(dynamic item) {
    if (_isEntrada(item)) return AppColors.success;
    if (_isSaida(item)) return AppColors.danger;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    if (errorMessage != null) _buildError(),
                    _buildMetricGrid(context),
                    const SizedBox(height: 18),
                    _buildLowStockSection(context),
                    const SizedBox(height: 18),
                    _buildActivityLog(context),
                    const SizedBox(height: 18),
                    _buildDetailsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        return Flex(
          direction: isCompact ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: isCompact
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visao Geral do Sistema',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Metricas em tempo real e saude do inventario.',
                  style: TextStyle(fontSize: 14, color: AppColors.mutedText),
                ),
              ],
            ),
            if (isCompact) const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: carregarDashboard,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Atualizar'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, 'rodape');
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nova Entrada'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
      ),
      child: Text(
        errorMessage!,
        style: const TextStyle(
          color: AppColors.danger,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMetricGrid(BuildContext context) {
    final cards = [
      _MetricCardData(
        title: 'Total em Estoque',
        value: _formatNumber(totalEmEstoque),
        subtitle: '${materiais.length} materiais cadastrados',
        icon: Icons.inventory_2_outlined,
        color: AppColors.primary,
      ),
      _MetricCardData(
        title: 'Entradas Recentes',
        value: entradas24h.toString(),
        subtitle: 'Ultimas 24h',
        icon: Icons.login,
        color: AppColors.secondary,
      ),
      _MetricCardData(
        title: 'Saidas Recentes',
        value: saidas24h.toString(),
        subtitle: 'Ultimas 24h',
        icon: Icons.logout,
        color: AppColors.danger,
      ),
      _MetricCardData(
        title: 'Movimentacoes',
        value: movimentacoes24h.toString(),
        subtitle: 'Entradas e saidas nas ultimas 24h',
        icon: Icons.sync_alt,
        color: AppColors.tertiary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1050
            ? 4
            : width >= 760
            ? 2
            : 1;
        final itemWidth = (width - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: _MetricCard(data: card),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildLowStockSection(BuildContext context) {
    return _DashboardPanel(
      title: 'Materiais em Baixa',
      actionLabel: 'Gerenciar Estoque',
      icon: Icons.warning_amber_rounded,
      child: materiaisEmBaixa.isEmpty
          ? const _EmptyState(message: 'Nenhum material cadastrado ainda.')
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 900
                    ? 3
                    : width >= 620
                    ? 2
                    : 1;
                final itemWidth = (width - ((columns - 1) * 12)) / columns;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: materiaisEmBaixa
                      .map(
                        (material) => SizedBox(
                          width: itemWidth,
                          child: _LowStockCard(material: material),
                        ),
                      )
                      .toList(),
                );
              },
            ),
    );
  }

  Widget _buildActivityLog(BuildContext context) {
    return _DashboardPanel(
      title: 'Log de Atividades',
      actionLabel: 'Ver Tudo',
      icon: Icons.history,
      child: atividadesRecentes.isEmpty
          ? const _EmptyState(message: 'Nenhuma movimentacao registrada.')
          : LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 760
                    ? 760.0
                    : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: WidgetStateProperty.all(
                        AppColors.surfaceAlt,
                      ),
                      dataRowMinHeight: 54,
                      dataRowMaxHeight: 54,
                      columns: const [
                        DataColumn(label: Text('Material')),
                        DataColumn(label: Text('Tipo')),
                        DataColumn(numeric: true, label: Text('Quantidade')),
                        DataColumn(label: Text('Horario')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: atividadesRecentes.map((item) {
                        final created = _createdAt(item);
                        final quantidade = item is Map
                            ? (item['Quantidade'] ?? 0).toString()
                            : '0';
                        final color = _tipoColor(item);

                        return DataRow(
                          cells: [
                            DataCell(Text(_materialName(item))),
                            DataCell(
                              _TypeLabel(
                                label: _tipoMovimentacao(item),
                                color: color,
                              ),
                            ),
                            DataCell(Text(quantidade)),
                            DataCell(
                              Text(
                                created == null ? '---' : _formatTime(created),
                              ),
                            ),
                            const DataCell(_StatusBadge(label: 'Verificado')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      children: [
        _buildExpansionCard(
          title: 'Materiais',
          emptyMessage:
              'Sem materiais cadastrados.\nCadastre materiais para visualizar aqui.',
          isEmpty: materiais.isEmpty,
          child: MateriaisTable(data: materiais, onRefresh: carregarDashboard),
        ),
        const SizedBox(height: 14),
        _buildExpansionCard(
          title: 'Estoque',
          emptyMessage:
              'Estoque vazio.\nCadastre materiais no estoque para visualizar aqui.',
          isEmpty: estoque.isEmpty,
          child: EstoqueTable(data: estoque, onRefresh: carregarDashboard),
        ),
      ],
    );
  }

  Widget _buildExpansionCard({
    required String title,
    required String emptyMessage,
    required bool isEmpty,
    required Widget child,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: AppColors.secondary,
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.surfaceAlt,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          collapsedIconColor: AppColors.surface,
          iconColor: AppColors.surface,
          childrenPadding: const EdgeInsets.all(16),
          children: [
            isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 16,
                      ),
                    ),
                  )
                : child,
          ],
        ),
      ),
    );
  }
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    final positionFromEnd = text.length - i;
    buffer.write(text[i]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  return buffer.toString();
}

String _formatTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class _MetricCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricCardData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(data.icon, color: data.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.subtitle,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.value,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final String title;
  final String actionLabel;
  final IconData icon;
  final Widget child;

  const _DashboardPanel({
    required this.title,
    required this.actionLabel,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.danger, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                actionLabel,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  final MaterialModel material;

  const _LowStockCard({required this.material});

  @override
  Widget build(BuildContext context) {
    final isCritical = material.quantidade <= 10;

    return Container(
      height: 96,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceAlt),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  material.nome,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _AlertBadge(
                label: isCritical ? 'Critico' : 'Atencao',
                color: isCritical ? AppColors.danger : AppColors.warning,
              ),
            ],
          ),
          Text(
            'Quantidade atual'.toUpperCase(),
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: material.quantidade.toString(),
                  style: TextStyle(
                    color: isCritical ? AppColors.danger : AppColors.secondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: material.metro ? ' m' : ' unid.',
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _AlertBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TypeLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.success,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
