import 'package:flutter/material.dart';
import 'package:projeto_elifone/theme/app_theme.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';

class EstoqueTable extends StatefulWidget {
  final List<dynamic> data;
  final Future<void> Function()? onRefresh;

  const EstoqueTable({super.key, required this.data, required this.onRefresh});

  @override
  State<EstoqueTable> createState() => _EstoqueTableState();
}

class _EstoqueTableState extends State<EstoqueTable> {
  late List<dynamic> filtered;
  late _EstoqueSource tableSource;

  @override
  void initState() {
    super.initState();
    filtered = widget.data;
    tableSource = _EstoqueSource(filtered);
  }

  @override
  void didUpdateWidget(covariant EstoqueTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data != widget.data) {
      setState(() {
        filtered = widget.data;
        tableSource.updateData(filtered);
      });
    }
  }

  void filtrar(String value) {
    setState(() {
      filtered = widget.data.where((e) {
        final materialName = (e['Material']?['nome'] ?? '')
            .toString()
            .toLowerCase();
        return materialName.contains(value.toLowerCase());
      }).toList();

      tableSource.updateData(filtered);
    });
  }

  @override
  Widget build(BuildContext context) {
    final linhasVisiveis = filtered.length.clamp(1, 5);
    final double altura = (48 * linhasVisiveis) + 120;

    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(AppColors.primary),
          dataRowColor: WidgetStateProperty.all(AppColors.surface),
          headingTextStyle: const TextStyle(
            color: AppColors.invertedText,
            fontWeight: FontWeight.bold,
          ),
          dataTextStyle: const TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
          dividerThickness: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    hintText: "Pesquisar material...",
                    hintStyle: const TextStyle(color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: AppColors.text),
                  onChanged: filtrar,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    AppColors.surfaceAlt,
                  ),
                ),
                onPressed: () async {
                  await widget.onRefresh?.call();
                  setState(() {
                    filtered = widget.data;
                    tableSource.updateData(filtered);
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// 📋 TABELA COM SCROLL LATERAL
          SizedBox(
            height: altura, // altura da tabela
            child: PaginatedDataTable2(
              columns: const [
                DataColumn(label: Text("Material")),
                DataColumn(label: Text("Data")),
                DataColumn(label: Text("Tipo")),
                DataColumn(label: Text("Quantidade")),
                DataColumn(label: Text("Valor")),
              ],
              source: tableSource,
              rowsPerPage: linhasVisiveis,
              availableRowsPerPage: const [5],
              headingRowHeight: 48,
              dataRowHeight: 48,
              columnSpacing: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstoqueSource extends DataTableSource {
  List<dynamic> data;
  _EstoqueSource(this.data);

  void updateData(List<dynamic> newData) {
    data = newData;
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;

    final item = data[index];

    final materialNome = (item['Material']?['nome'] ?? '---').toString();

    final created = item['created_at'] ?? '';
    final dataFormatada = created.isNotEmpty
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(created))
        : '---';

    final isEntrada = item['Entrada'] ?? false;
    final isSaida = item['Saida'] ?? false;

    final tipo = isEntrada
        ? 'Entrada'
        : isSaida
        ? 'Saída'
        : '---';

    final quantidade = (item['Quantidade'] ?? 0).toString();
    final valor = (item['Valor'] ?? 0).toString();

    /// 🎨 COR DA LINHA
    final Color rowColor = isEntrada
        ? AppColors.success.withValues(alpha: 0.18)
        : isSaida
        ? AppColors.danger.withValues(alpha: 0.18)
        : AppColors.surface;

    return DataRow.byIndex(
      index: index,
      color: WidgetStateProperty.all(rowColor),
      cells: [
        DataCell(Text(materialNome)),
        DataCell(Text(dataFormatada)),
        DataCell(Text(tipo)),
        DataCell(Text(quantidade)),
        DataCell(Text(valor)),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}
