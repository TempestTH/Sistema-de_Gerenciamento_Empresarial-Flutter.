import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

class MateriaisTable extends StatefulWidget {
  final List<dynamic> data;
  final Future<void> Function()? onRefresh;
  const MateriaisTable({
    super.key,
    required this.data,
    required this.onRefresh,
  });

  @override
  State<MateriaisTable> createState() => _MateriaisTableState();
}

class _MateriaisTableState extends State<MateriaisTable> {
  late List<dynamic> filtered;
  late _TableSource tableSource;

  @override
  void initState() {
    super.initState();
    filtered = widget.data;
    tableSource = _TableSource(filtered);
  }

  @override
  void didUpdateWidget(covariant MateriaisTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data != widget.data) {
      setState(() {
        filtered = widget.data;
      });
    }
  }

  void filtrar(String value) {
    setState(() {
      filtered = widget.data
          .where(
            (u) =>
                u.nome.toString().toLowerCase().contains(value.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final linhasVisiveis = filtered.length.clamp(1, 5);
    final double altura = (48 * linhasVisiveis) + 120;
    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF2A2A2A)),
          dataRowColor: WidgetStateProperty.all(const Color(0xFF1E1E1E)),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          dataTextStyle: const TextStyle(color: Colors.white70),
          dividerThickness: 1,
        ),
      ),
      child: Column(
        children: [
          // 🔎 SEARCH
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    hintText: "Pesquisar material...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF121212),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: filtrar,
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Color(0xFF121212)),
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

          // 📋 TABELA PAGINADA
          SizedBox(
            height: altura, // ajuste se quiser
            child: PaginatedDataTable2(
              columns: const [
                DataColumn(label: Text("Material")),
                DataColumn(label: Text("Quantidade")),
                DataColumn(label: Text("Valor")),
              ],
              source: tableSource,
              rowsPerPage: filtered.length.clamp(1, 5),
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

// =============================
// 🔽 Fonte de dados da tabela
// =============================
class _TableSource extends DataTableSource {
  List<dynamic> data;
  _TableSource(this.data);

  void updateData(List<dynamic> newData) {
    data = newData;
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;

    final item = data[index];

    return DataRow.byIndex(
      index: index,
      color: WidgetStateProperty.all(const Color(0xFF1E1E1E)),
      cells: [
        DataCell(Text(item.nome.toString())),
        DataCell(Text(item.quantidade.toString())),
        DataCell(Text(item.valor.toString())),
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
