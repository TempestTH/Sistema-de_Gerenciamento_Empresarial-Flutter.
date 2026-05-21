import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:projeto_elifone/model/orcamento_model.dart';
import 'package:projeto_elifone/theme/app_theme.dart';

class OrcamentoPage extends StatefulWidget {
  const OrcamentoPage({super.key});

  @override
  State<OrcamentoPage> createState() => _OrcamentoPageState();
}

class _OrcamentoPageState extends State<OrcamentoPage> {
  final clienteController = TextEditingController();
  final observacoesController = TextEditingController(
    text: 'Notas para o financeiro ou condicoes especiais.',
  );
  final textoPadraoController = TextEditingController(
    text:
        'Prezado cliente, segue a proposta comercial solicitada. Os valores apresentados consideram as informacoes disponiveis ate a data de emissao deste documento.',
  );

  final List<OrcamentoItemModel> itens = [
    const OrcamentoItemModel(
      descricao: 'Licenca de software',
      quantidade: 1,
      precoUnitario: 1200,
    ),
    const OrcamentoItemModel(
      descricao: 'Implementacao',
      quantidade: 5,
      precoUnitario: 150,
    ),
  ];

  final List<OrcamentoModel> historico = [];
  late DateTime validade;
  String pagamento = 'A vista (PIX/Dinheiro)';
  int aba = 0;
  int contador = 1;
  OrcamentoLayoutModel layout = const OrcamentoLayoutModel(
    textoPadrao:
        'Prezado cliente, segue a proposta comercial solicitada. Os valores apresentados consideram as informacoes disponiveis ate a data de emissao deste documento.',
  );

  @override
  void initState() {
    super.initState();
    validade = DateTime.now().add(const Duration(days: 15));
  }

  @override
  void dispose() {
    clienteController.dispose();
    observacoesController.dispose();
    textoPadraoController.dispose();
    super.dispose();
  }

  double get subtotal => itens.fold(0, (total, item) => total + item.total);
  double get total => subtotal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildTabs(),
            const SizedBox(height: 18),
            IndexedStack(
              index: aba,
              children: [
                _buildGerarOrcamento(),
                _buildHistorico(),
                _buildConfiguracoes(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        return Flex(
          direction: compact ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: compact
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orcamentos',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gere PDFs, acompanhe o historico e ajuste o layout.',
                  style: TextStyle(color: AppColors.mutedText),
                ),
              ],
            ),
            if (compact) const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricPill(
                  icon: Icons.description_outlined,
                  label: 'Total',
                  value: historico.length.toString(),
                ),
                _MetricPill(
                  icon: Icons.payments_outlined,
                  label: 'Gerado',
                  value: _money(historico.fold(0, (v, o) => v + o.total)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabs() {
    final tabs = [
      (Icons.add_box_outlined, 'Gerar Orcamento'),
      (Icons.history, 'Historico'),
      (Icons.tune, 'Layout do PDF'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(tabs.length, (index) {
        final selected = aba == index;
        return OutlinedButton.icon(
          onPressed: () => setState(() => aba = index),
          icon: Icon(tabs[index].$1, size: 18),
          label: Text(tabs[index].$2),
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? AppColors.primary : AppColors.surface,
            foregroundColor: selected
                ? AppColors.invertedText
                : AppColors.primary,
            side: const BorderSide(color: AppColors.border),
          ),
        );
      }),
    );
  }

  Widget _buildGerarOrcamento() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1050;

        final form = Column(
          children: [
            _Panel(
              title: 'Informacoes Basicas',
              child: Column(
                children: [
                  _label('Nome do Cliente / Para quem o orcamento vai'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: clienteController,
                    decoration: _decoration(
                      'Digite o nome completo ou razao social',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _dateButton()),
                      const SizedBox(width: 12),
                      Expanded(child: _paymentField()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Panel(
              title: 'Itens do Orcamento',
              action: TextButton.icon(
                onPressed: _abrirModalItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar Item'),
              ),
              child: Column(
                children: [
                  _itemsTable(showActions: true),
                  const SizedBox(height: 14),
                  _label('Observacoes Internas (Opcional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: observacoesController,
                    maxLines: 2,
                    decoration: _decoration('Notas para a proposta...'),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        );

        final summary = Column(
          children: [
            _TotalBox(
              subtotal: subtotal,
              total: total,
              onGenerate: _gerarOrcamento,
              onPreview: () => _abrirPreview(_previewAtual()),
            ),
            const SizedBox(height: 14),
            _HintBox(
              icon: Icons.info_outline,
              title: 'Dica de validade',
              text:
                  'Orcamentos com validade superior a 15 dias tendem a ter taxas de conversao menores. Ajuste a data conforme a proposta.',
            ),
          ],
        );

        if (compact) {
          return Column(
            children: [
              form,
              const SizedBox(height: 14),
              summary,
              const SizedBox(height: 14),
              _PreviewPanel(orcamento: _previewAtual()),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: form),
            const SizedBox(width: 16),
            SizedBox(width: 300, child: summary),
            const SizedBox(width: 16),
            SizedBox(
              width: 320,
              child: _PreviewPanel(orcamento: _previewAtual()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistorico() {
    final totalGerado = historico.fold<double>(0, (v, o) => v + o.total);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 3 : 1;
            final width =
                (constraints.maxWidth - ((columns - 1) * 12)) / columns;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: _MetricCard(
                    title: 'Total de Orcamentos',
                    value: historico.length.toString(),
                    detail: 'registros gerados',
                    icon: Icons.description_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: const _MetricCard(
                    title: 'Taxa de Aprovacao',
                    value: '0%',
                    detail: 'controle inicial',
                    icon: Icons.verified_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _MetricCard(
                    title: 'Valor Total Gerado',
                    value: _money(totalGerado),
                    detail: 'em orcamentos',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _Panel(
          title: 'Listagem de Orcamentos',
          child: historico.isEmpty
              ? const _EmptyState(
                  message:
                      'Nenhum orcamento gerado ainda. Gere o primeiro PDF para ele aparecer aqui.',
                )
              : _historicoTable(),
        ),
      ],
    );
  }

  Widget _buildConfiguracoes() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        final form = Column(
          children: [
            _Panel(
              title: 'Personalizacao do Documento',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ImageUploadBox(
                          title: 'Imagem do Cabecalho',
                          subtitle:
                              layout.cabecalhoNome ?? 'Upload Logo / Banner',
                          bytes: layout.cabecalho,
                          onPick: () => _selecionarImagem(isHeader: true),
                          onClear: () => setState(
                            () =>
                                layout = layout.copyWith(limparCabecalho: true),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ImageUploadBox(
                          title: 'Imagem do Rodape',
                          subtitle: layout.rodapeNome ?? 'Upload Rodape',
                          bytes: layout.rodape,
                          onPick: () => _selecionarImagem(isHeader: false),
                          onClear: () => setState(
                            () => layout = layout.copyWith(limparRodape: true),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _label('Texto padrao do PDF'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textoPadraoController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: _decoration(
                      'Texto introdutorio da proposta...',
                    ),
                    onChanged: (value) => setState(
                      () => layout = layout.copyWith(textoPadrao: value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        layout = layout.copyWith(
                          textoPadrao: textoPadraoController.text,
                        );
                      });
                      _showMessage('Alteracoes aplicadas ao preview.');
                    },
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Salvar Alteracoes'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _restaurarLayout,
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Restaurar Padrao'),
                  ),
                ],
              ),
            ),
          ],
        );

        final preview = _PreviewPanel(
          orcamento: _previewAtual(),
          compact: false,
        );

        if (compact) {
          return Column(children: [form, const SizedBox(height: 14), preview]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: form),
            const SizedBox(width: 16),
            SizedBox(width: 340, child: preview),
          ],
        );
      },
    );
  }

  Widget _historicoTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        columns: const [
          DataColumn(label: Text('ID Orcamento')),
          DataColumn(label: Text('Nome do Cliente')),
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Status')),
          DataColumn(numeric: true, label: Text('Valor Total')),
          DataColumn(label: Text('Acoes')),
        ],
        rows: historico.map((orcamento) {
          return DataRow(
            cells: [
              DataCell(Text(orcamento.id)),
              DataCell(Text(orcamento.cliente)),
              DataCell(Text(_date(orcamento.criadoEm))),
              const DataCell(_StatusBadge(label: 'Gerado')),
              DataCell(Text(_money(orcamento.total))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Visualizar preview',
                      onPressed: () => _abrirPreview(orcamento),
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                    IconButton(
                      tooltip: 'Baixar PDF',
                      onPressed: () => _baixarPdf(orcamento),
                      icon: const Icon(Icons.download_outlined),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _itemsTable({required bool showActions}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 22,
        headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
        columns: [
          const DataColumn(label: Text('Descricao do Item')),
          const DataColumn(numeric: true, label: Text('Qtd.')),
          const DataColumn(numeric: true, label: Text('Preco Unit.')),
          const DataColumn(numeric: true, label: Text('Total')),
          if (showActions) const DataColumn(label: Text('')),
        ],
        rows: itens.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item.descricao)),
              DataCell(Text(item.quantidade.toString())),
              DataCell(Text(_money(item.precoUnitario))),
              DataCell(Text(_money(item.total))),
              if (showActions)
                DataCell(
                  IconButton(
                    tooltip: 'Remover item',
                    onPressed: () => setState(() => itens.remove(item)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _dateButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: validade,
          firstDate: DateTime.now(),
          lastDate: DateTime(DateTime.now().year + 5),
        );
        if (selected != null) setState(() => validade = selected);
      },
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(_date(validade)),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    );
  }

  Widget _paymentField() {
    return DropdownButtonFormField<String>(
      initialValue: pagamento,
      decoration: _decoration('Condicao de pagamento'),
      items: const [
        DropdownMenuItem(
          value: 'A vista (PIX/Dinheiro)',
          child: Text('A vista (PIX/Dinheiro)'),
        ),
        DropdownMenuItem(value: 'Cartao de credito', child: Text('Cartao')),
        DropdownMenuItem(
          value: 'Boleto 15 dias',
          child: Text('Boleto 15 dias'),
        ),
        DropdownMenuItem(value: 'Parcelado', child: Text('Parcelado')),
      ],
      onChanged: (value) {
        if (value != null) setState(() => pagamento = value);
      },
    );
  }

  void _abrirModalItem() {
    showDialog<void>(
      context: context,
      builder: (_) =>
          _NovoItemDialog(onSave: (item) => setState(() => itens.add(item))),
    );
  }

  Future<void> _selecionarImagem({required bool isHeader}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    setState(() {
      layout = isHeader
          ? layout.copyWith(cabecalho: file.bytes, cabecalhoNome: file.name)
          : layout.copyWith(rodape: file.bytes, rodapeNome: file.name);
    });
  }

  Future<void> _gerarOrcamento() async {
    if (clienteController.text.trim().isEmpty || itens.isEmpty) {
      _showMessage('Preencha o cliente e adicione ao menos um item.');
      return;
    }

    final orcamentoSemPdf = _previewAtual(
      id: '#ORC-${DateTime.now().year}-${contador.toString().padLeft(3, '0')}',
      criadoEm: DateTime.now(),
    );
    final pdfBytes = await _buildPdf(orcamentoSemPdf);
    final orcamento = OrcamentoModel(
      id: orcamentoSemPdf.id,
      cliente: orcamentoSemPdf.cliente,
      validade: orcamentoSemPdf.validade,
      pagamento: orcamentoSemPdf.pagamento,
      criadoEm: orcamentoSemPdf.criadoEm,
      itens: orcamentoSemPdf.itens,
      observacoes: orcamentoSemPdf.observacoes,
      layout: orcamentoSemPdf.layout,
      pdfBytes: pdfBytes,
    );

    setState(() {
      historico.insert(0, orcamento);
      contador++;
      aba = 1;
    });

    await _baixarPdf(orcamento);
  }

  OrcamentoModel _previewAtual({String? id, DateTime? criadoEm}) {
    return OrcamentoModel(
      id: id ?? '#ORC-PREVIEW',
      cliente: clienteController.text.trim().isEmpty
          ? 'Nome do Cliente'
          : clienteController.text.trim(),
      validade: validade,
      pagamento: pagamento,
      criadoEm: criadoEm ?? DateTime.now(),
      itens: List.unmodifiable(itens),
      observacoes: observacoesController.text,
      layout: layout.copyWith(textoPadrao: textoPadraoController.text),
      pdfBytes: Uint8List(0),
    );
  }

  Future<void> _baixarPdf(OrcamentoModel orcamento) async {
    final bytes = orcamento.pdfBytes.isEmpty
        ? await _buildPdf(orcamento)
        : orcamento.pdfBytes;
    final path = await FilePicker.saveFile(
      dialogTitle: 'Salvar orcamento em PDF',
      fileName: '${orcamento.id.replaceAll('#', '')}.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );

    if (path != null) _showMessage('PDF salvo com sucesso.');
  }

  Future<Uint8List> _buildPdf(OrcamentoModel orcamento) async {
    final doc = pw.Document();
    final headerImage = orcamento.layout.cabecalho == null
        ? null
        : pw.MemoryImage(orcamento.layout.cabecalho!);
    final footerImage = orcamento.layout.rodape == null
        ? null
        : pw.MemoryImage(orcamento.layout.rodape!);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (headerImage != null)
                pw.Container(
                  height: 82,
                  width: double.infinity,
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Image(headerImage, fit: pw.BoxFit.contain),
                )
              else
                pw.Container(
                  height: 58,
                  width: double.infinity,
                  alignment: pw.Alignment.centerLeft,
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14),
                  child: pw.Text(
                    'ELIFONE',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'ORCAMENTO ${orcamento.id}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text('Data: ${_date(orcamento.criadoEm)}'),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text('Cliente: ${orcamento.cliente}'),
              pw.Text('Validade: ${_date(orcamento.validade)}'),
              pw.Text('Pagamento: ${orcamento.pagamento}'),
              pw.SizedBox(height: 18),
              pw.Text(orcamento.layout.textoPadrao),
              pw.SizedBox(height: 18),
              pw.TableHelper.fromTextArray(
                headers: ['Descricao', 'Qtd.', 'Unitario', 'Total'],
                data: orcamento.itens
                    .map(
                      (item) => [
                        item.descricao,
                        item.quantidade.toString(),
                        _money(item.precoUnitario),
                        _money(item.total),
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 16),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ${_money(orcamento.subtotal)}'),
                    pw.Text('Impostos: ${_money(orcamento.impostos)}'),
                    pw.Text('Desconto: ${_money(orcamento.desconto)}'),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Total: ${_money(orcamento.total)}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (orcamento.observacoes.trim().isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text('Observacoes: ${orcamento.observacoes}'),
              ],
              pw.Spacer(),
              if (footerImage != null)
                pw.SizedBox(
                  height: 64,
                  width: double.infinity,
                  child: pw.Image(footerImage, fit: pw.BoxFit.contain),
                )
              else
                pw.Text(
                  'Documento gerado pelo sistema Elifone.',
                  style: const pw.TextStyle(color: PdfColors.grey600),
                ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  void _abrirPreview(OrcamentoModel orcamento) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _PreviewPanel(orcamento: orcamento, compact: false),
        ),
      ),
    );
  }

  void _restaurarLayout() {
    const text =
        'Prezado cliente, segue a proposta comercial solicitada. Os valores apresentados consideram as informacoes disponiveis ate a data de emissao deste documento.';
    setState(() {
      textoPadraoController.text = text;
      layout = const OrcamentoLayoutModel(textoPadrao: text);
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _NovoItemDialog extends StatefulWidget {
  final ValueChanged<OrcamentoItemModel> onSave;

  const _NovoItemDialog({required this.onSave});

  @override
  State<_NovoItemDialog> createState() => _NovoItemDialogState();
}

class _NovoItemDialogState extends State<_NovoItemDialog> {
  final descricaoController = TextEditingController();
  final quantidadeController = TextEditingController(text: '1');
  final precoController = TextEditingController();

  @override
  void dispose() {
    descricaoController.dispose();
    quantidadeController.dispose();
    precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Item'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descricaoController,
              decoration: _decoration('Descricao'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantidadeController,
                    keyboardType: TextInputType.number,
                    decoration: _decoration('Quantidade'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: precoController,
                    keyboardType: TextInputType.number,
                    decoration: _decoration('Preco unitario'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Adicionar')),
      ],
    );
  }

  void _salvar() {
    final descricao = descricaoController.text.trim();
    final quantidade = int.tryParse(quantidadeController.text) ?? 0;
    final preco =
        double.tryParse(precoController.text.replaceAll(',', '.')) ?? 0;

    if (descricao.isEmpty || quantidade <= 0 || preco <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha descricao, quantidade e preco.'),
        ),
      );
      return;
    }

    widget.onSave(
      OrcamentoItemModel(
        descricao: descricao,
        quantidade: quantidade,
        precoUnitario: preco,
      ),
    );
    Navigator.pop(context);
  }
}

class _PreviewPanel extends StatelessWidget {
  final OrcamentoModel orcamento;
  final bool compact;

  const _PreviewPanel({required this.orcamento, this.compact = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pre-visualizacao',
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 0.72,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ImagePreviewSlot(
                    bytes: orcamento.layout.cabecalho,
                    fallback: 'ELIFONE',
                    height: compact ? 42 : 56,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ORCAMENTO ${orcamento.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        _money(orcamento.total),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    orcamento.cliente,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    orcamento.layout.textoPadrao,
                    maxLines: compact ? 3 : 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...orcamento.itens
                      .take(4)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.descricao,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              Text(
                                _money(item.total),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'TOTAL ${_money(orcamento.total)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ImagePreviewSlot(
                    bytes: orcamento.layout.rodape,
                    fallback: 'Documento gerado pelo sistema Elifone',
                    height: compact ? 32 : 44,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _Panel({required this.title, required this.child, this.action});

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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  final double subtotal;
  final double total;
  final VoidCallback onGenerate;
  final VoidCallback onPreview;

  const _TotalBox({
    required this.subtotal,
    required this.total,
    required this.onGenerate,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'TOTAL DO ORCAMENTO',
            style: TextStyle(
              color: AppColors.invertedText,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _money(total),
            style: const TextStyle(
              color: AppColors.invertedText,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Divider(height: 26, color: AppColors.secondary),
          _totalLine('Subtotal', subtotal),
          _totalLine('Impostos', 0),
          _totalLine('Desconto', 0),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Gerar Orcamento'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onPreview,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Visualizar Preview'),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalLine(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.invertedText),
            ),
          ),
          Text(
            _money(value),
            style: const TextStyle(
              color: AppColors.invertedText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageUploadBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final Uint8List? bytes;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ImageUploadBox({
    required this.title,
    required this.subtitle,
    required this.bytes,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      child: Container(
        height: 156,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (bytes != null)
                  IconButton(
                    tooltip: 'Remover imagem',
                    onPressed: onClear,
                    icon: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),
            Expanded(
              child: Center(
                child: bytes == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      )
                    : Image.memory(bytes!, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewSlot extends StatelessWidget {
  final Uint8List? bytes;
  final String fallback;
  final double height;

  const _ImagePreviewSlot({
    required this.bytes,
    required this.fallback,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: bytes == null
          ? Container(
              alignment: Alignment.center,
              color: AppColors.surfaceAlt,
              child: Text(
                fallback,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            )
          : Image.memory(bytes!, fit: BoxFit.contain),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String detail;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(16),
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
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(icon, color: AppColors.primary),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(detail, style: const TextStyle(color: AppColors.mutedText)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _HintBox({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: AppColors.mutedText)),
              ],
            ),
          ),
        ],
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

Widget _label(String text) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.mutedText,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

InputDecoration _decoration(String hint) {
  return InputDecoration(hintText: hint);
}

String _money(num value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  final parts = fixed.split(',');
  final buffer = StringBuffer();
  for (var i = 0; i < parts.first.length; i++) {
    final positionFromEnd = parts.first.length - i;
    buffer.write(parts.first[i]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'R\$ ${buffer.toString()},${parts.last}';
}

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
