import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:projeto_elifone/model/material_model.dart';
import 'package:projeto_elifone/model/orcamento_model.dart';
import 'package:projeto_elifone/services/supabase_material_service.dart';
import 'package:projeto_elifone/services/supabase_orcamento_config_service.dart';
import 'package:projeto_elifone/services/supabase_orcamento_service.dart';
import 'package:projeto_elifone/theme/app_theme.dart';
import 'package:projeto_elifone/widgets/responsive_dialog.dart';
import 'package:projeto_elifone/widgets/material_search_field.dart';
import 'package:printing/printing.dart';

class OrcamentoPage extends StatefulWidget {
  const OrcamentoPage({super.key});

  @override
  State<OrcamentoPage> createState() => _OrcamentoPageState();
}

class _OrcamentoPageState extends State<OrcamentoPage> {
  final orcamentoService = SupabaseOrcamentoService();
  final orcamentoConfigService = SupabaseOrcamentoConfigService();
  final materialService = SupabaseMaterialService();

  final clienteController = TextEditingController();
  final tituloController = TextEditingController();
  final observacoesController = TextEditingController();
  final textoPadraoController = TextEditingController(
    text:
        'Prezado cliente, segue a proposta comercial solicitada. Os valores apresentados consideram as informacoes disponiveis ate a data de emissao deste documento.',
  );

  List<OrcamentoItemModel> itens = [];
  List<OrcamentoModel> historico = [];
  List<MaterialModel> materiais = [];
  bool loading = true;
  bool salvando = false;
  bool possuiValidade = false;
  late DateTime validade;
  int aba = 0;
  String? aviso;
  OrcamentoLayoutModel layout = const OrcamentoLayoutModel(
    textoPadrao:
        'Prezado cliente, segue a proposta comercial solicitada. Os valores apresentados consideram as informacoes disponiveis ate a data de emissao deste documento.',
  );

  @override
  void initState() {
    super.initState();
    validade = DateTime.now().add(const Duration(days: 15));
    carregarDados();
  }

  @override
  void dispose() {
    clienteController.dispose();
    tituloController.dispose();
    observacoesController.dispose();
    textoPadraoController.dispose();
    super.dispose();
  }

  num get subtotal => itens.fold<num>(0, (total, item) => total + item.total);

  Future<void> carregarDados() async {
    setState(() {
      loading = true;
      aviso = null;
    });

    try {
      final data = await Future.wait([
        materialService.listar(),
        orcamentoService.listar(),
        orcamentoConfigService.buscar(),
      ]);

      if (!mounted) return;
      final config = data[2] as OrcamentoLayoutModel?;
      setState(() {
        materiais = data[0] as List<MaterialModel>;
        historico = data[1] as List<OrcamentoModel>;
        if (config != null) {
          layout = config;
          textoPadraoController.text = config.textoPadrao;
        }
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        aviso =
            'Nao foi possivel carregar materiais ou historico de orcamentos.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarDados,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    if (aviso != null) _AvisoBox(text: aviso!),
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
                  'Gere PDFs, consulte o historico e ajuste o layout.',
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
                  value: _money(historico.fold<num>(0, (v, o) => v + o.total)),
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
                  _label('Titulo do Orcamento'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tituloController,
                    decoration: _decoration('Ex.: Proposta de reforma'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
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
                      Expanded(
                        child: _InfoField(
                          label: 'Data de Emissao',
                          value: _date(DateTime.now()),
                          icon: Icons.event_available_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _validadeControl()),
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
              onGenerate: salvando ? null : _gerarOrcamento,
              onPreview: () => _abrirPreview(_previewAtual()),
            ),
            const SizedBox(height: 14),
            const _HintBox(
              icon: Icons.info_outline,
              title: 'Itens sem saida de estoque',
              text:
                  'Materiais selecionados entram no orcamento, mas nao geram baixa no estoque.',
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

  Widget _validadeControl() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              value: possuiValidade,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Orcamento com validade',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              onChanged: (value) => setState(() => possuiValidade = value),
            ),
          ),
          if (possuiValidade)
            OutlinedButton.icon(
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
            ),
        ],
      ),
    );
  }

  Widget _buildHistorico() {
    final totalGerado = historico.fold<num>(0, (v, o) => v + o.total);

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
                    detail: 'registros no sistema',
                    icon: Icons.description_outlined,
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
                SizedBox(
                  width: width,
                  child: _MetricCard(
                    title: 'Ultimo Orcamento',
                    value: historico.isEmpty
                        ? '---'
                        : _date(historico.first.createdAt),
                    detail: historico.isEmpty
                        ? 'sem registros'
                        : historico.first.cliente,
                    icon: Icons.schedule_outlined,
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
              ? const _EmptyState(message: 'Nenhum orcamento encontrado.')
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
                    onPressed: _salvarConfiguracoes,
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
        headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
        headingTextStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
        dataTextStyle: const TextStyle(color: AppColors.text),
        columnSpacing: 28,
        columns: const [
          DataColumn(label: Text('Orcamento')),
          DataColumn(label: Text('Data de Emissao')),
          DataColumn(label: Text('Validade')),
          DataColumn(numeric: true, label: Text('Valor Total')),
          DataColumn(label: Text('Acoes')),
        ],
        rows: historico.map((orcamento) {
          return DataRow(
            cells: [
              DataCell(Text('${orcamento.codigo} (${orcamento.cliente})')),
              DataCell(Text(_date(orcamento.dataEmissao))),
              DataCell(
                Text(
                  orcamento.possuiValidade && orcamento.validade != null
                      ? _date(orcamento.validade!)
                      : 'Sem validade',
                ),
              ),
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
    if (itens.isEmpty) {
      return const _EmptyState(message: 'Nenhum item adicionado ao orcamento.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
        headingTextStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
        dataTextStyle: const TextStyle(color: AppColors.text),
        columnSpacing: 22,
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
              DataCell(Text(_quantity(item.quantidade))),
              DataCell(Text(_money(item.valorUnitario))),
              DataCell(Text(_money(item.total))),
              if (showActions)
                DataCell(
                  IconButton(
                    tooltip: 'Remover item',
                    onPressed: () => setState(
                      () => itens = itens
                          .where((value) => value != item)
                          .toList(),
                    ),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _abrirModalItem() async {
    final item = await showDialog<OrcamentoItemModel>(
      context: context,
      builder: (_) => _ItemOrcamentoModal(materiais: materiais),
    );

    if (item != null) {
      setState(() => itens = [...itens, item]);
    }
  }

  Future<void> _selecionarImagem({required bool isHeader}) async {
    final result = await FilePicker.pickFile(type: FileType.image);
    if (result == null) return;

    final file = result;
    final bytes = await file.readAsBytes();
    setState(() {
      layout = isHeader
          ? layout.copyWith(cabecalho: bytes, cabecalhoNome: file.name)
          : layout.copyWith(rodape: bytes, rodapeNome: file.name);
    });
  }

  Future<void> _salvarConfiguracoes() async {
    final novoLayout = layout.copyWith(textoPadrao: textoPadraoController.text);
    try {
      final salvo = await orcamentoConfigService.salvar(novoLayout);
      if (!mounted) return;
      setState(() {
        layout = salvo;
        textoPadraoController.text = salvo.textoPadrao;
      });
      _showMessage('Configuracoes do orcamento salvas.');
    } catch (error) {
      debugPrint('Erro ao salvar configuracoes do orcamento: $error');
      _showMessage('Erro ao salvar configuracoes: ${_erroCurto(error)}');
    }
  }

  Future<void> _gerarOrcamento() async {
    if (clienteController.text.trim().isEmpty || itens.isEmpty) {
      _showMessage('Preencha o cliente e adicione ao menos um item.');
      return;
    }

    setState(() => salvando = true);
    final orcamento = _previewAtual(
      codigo: 'ORC-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    OrcamentoModel salvo;
    try {
      salvo = await orcamentoService.inserir(orcamento);
    } catch (error) {
      if (!mounted) return;
      setState(() => salvando = false);
      debugPrint('Erro ao salvar orcamento: $error');
      _showMessage('Erro ao salvar no banco: ${_erroCurto(error)}');
      return;
    }

    try {
      final atualizado = await orcamentoService.listar();
      if (!mounted) return;
      setState(() {
        historico = atualizado;
        aba = 1;
        salvando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        historico = [salvo, ...historico];
        aba = 1;
        salvando = false;
      });
    }

    try {
      await _baixarPdf(orcamento);
    } catch (_) {
      _showMessage('Orcamento salvo, mas nao foi possivel baixar o PDF.');
    }
  }

  OrcamentoModel _previewAtual({String? codigo, DateTime? createdAt}) {
    return OrcamentoModel(
      codigo: codigo ?? 'PREVIEW',
      titulo: tituloController.text.trim().isEmpty
          ? 'Orcamento'
          : tituloController.text.trim(),
      cliente: clienteController.text.trim().isEmpty
          ? 'Nome do Cliente'
          : clienteController.text.trim(),
      dataEmissao: DateTime.now(),
      possuiValidade: possuiValidade,
      validade: possuiValidade ? validade : null,
      createdAt: createdAt ?? DateTime.now(),
      itens: List.unmodifiable(itens),
      observacoes: observacoesController.text,
      layout: layout.copyWith(textoPadrao: textoPadraoController.text),
    );
  }

  Future<void> _baixarPdf(OrcamentoModel orcamento) async {
    final bytes = await _buildPdf(orcamento);
    final filename =
        '${orcamento.codigo}_${_safeFileName(orcamento.cliente)}.pdf';
    final path = await FilePicker.saveFile(
      dialogTitle: 'Salvar orcamento em PDF',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );

    if (path != null) _showMessage('PDF salvo com sucesso.');
  }

  Future<Uint8List> _buildPdf(OrcamentoModel orcamento) async {
    final doc = pw.Document();
    final cabecalho = orcamento.layout.cabecalho ?? layout.cabecalho;
    final rodape = orcamento.layout.rodape ?? layout.rodape;
    final headerImage = cabecalho == null ? null : pw.MemoryImage(cabecalho);
    final footerImage = rodape == null ? null : pw.MemoryImage(rodape);
    final footerImageWidth = PdfPageFormat.a4.width - 20;
    final footerHeight = footerImage == null
        ? 90.0
        : footerImage.width == null ||
              footerImage.width == 0 ||
              footerImage.height == null
        ? 90.0
        : footerImageWidth * footerImage.height! / footerImage.width! + 20;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(bottom: 10),
        footer: (context) => context.pageNumber == context.pagesCount
            ? _pdfImageBand(footerImage, emptyHeight: 90)
            : pw.SizedBox(height: footerHeight),
        build: (context) => [
          _pdfImageBand(headerImage, emptyHeight: 200),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(36, 24, 36, 0),
            child: pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    orcamento.titulo.isEmpty ? 'Orcamento' : orcamento.titulo,
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    orcamento.cliente,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 36),
            child: pw.Text('Data de emissao: ${_date(orcamento.dataEmissao)}'),
          ),
          if (orcamento.possuiValidade && orcamento.validade != null)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 36),
              child: pw.Text('Validade: ${_date(orcamento.validade!)}'),
            ),
          pw.SizedBox(height: 18),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 36),
            child: pw.Text(
              orcamento.layout.textoPadrao,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 36),
            child: pw.TableHelper.fromTextArray(
              headers: ['Descricao', 'Qtd.', 'Unitario', 'Total'],
              data: orcamento.itens
                  .map(
                    (item) => [
                      item.descricao,
                      _quantity(item.quantidade),
                      _money(item.valorUnitario),
                      _money(item.total),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 12),
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
          ),
          pw.SizedBox(height: 16),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 36),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total: ${_money(orcamento.total)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          if (orcamento.observacoes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(36, 0, 36, 20),
              child: pw.Text('Observacoes: ${orcamento.observacoes}'),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfImageBand(
    pw.ImageProvider? image, {
    required double emptyHeight,
  }) {
    if (image == null) return pw.SizedBox(height: emptyHeight);

    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Image(
        image,
        width: PdfPageFormat.a4.width - 20,
        fit: pw.BoxFit.contain,
        alignment: pw.Alignment.center,
      ),
    );
  }

  void _abrirPreview(OrcamentoModel orcamento) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.all(18),
        child: SizedBox(
          width: 860,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Preview do PDF',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _PdfFilePreview(buildPdf: () => _buildPdf(orcamento)),
              ),
            ],
          ),
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

class _ItemOrcamentoModal extends StatefulWidget {
  final List<MaterialModel> materiais;

  const _ItemOrcamentoModal({required this.materiais});

  @override
  State<_ItemOrcamentoModal> createState() => _ItemOrcamentoModalState();
}

class _ItemOrcamentoModalState extends State<_ItemOrcamentoModal> {
  final descricaoController = TextEditingController();
  final quantidadeController = TextEditingController(text: '1');
  final valorController = TextEditingController(text: '0');
  MaterialModel? materialSelecionado;
  bool usarMaterial = true;

  @override
  void dispose() {
    descricaoController.dispose();
    quantidadeController.dispose();
    valorController.dispose();
    super.dispose();
  }

  void salvar() {
    final descricao = usarMaterial
        ? materialSelecionado?.nome ?? ''
        : descricaoController.text.trim();
    final quantidade =
        num.tryParse(quantidadeController.text.replaceAll(',', '.')) ?? 1;
    final valorUnitario = usarMaterial
        ? materialSelecionado?.valor ?? 0
        : num.tryParse(valorController.text.replaceAll(',', '.')) ?? 0;

    if (descricao.isEmpty || quantidade <= 0) return;

    Navigator.pop(
      context,
      OrcamentoItemModel(
        idMaterial: usarMaterial ? materialSelecionado?.id : null,
        descricao: descricao,
        quantidade: quantidade,
        valorUnitario: valorUnitario,
        material: usarMaterial,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: responsiveDialogConstraints(context, maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Adicionar Item',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: CheckboxListTile(
                          value: usarMaterial,
                          onChanged: (value) {
                            setState(() {
                              usarMaterial = value ?? false;
                              if (!usarMaterial) {
                                materialSelecionado = null;
                                valorController.text = '0';
                              }
                            });
                          },
                          title: const Text('Este item e material do estoque'),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (usarMaterial) ...[
                        _label('Material do estoque'),
                        const SizedBox(height: 8),
                        MaterialSearchField(
                          materiais: widget.materiais,
                          selecionado: materialSelecionado,
                          decoration: _decoration(
                            'Pesquise e selecione o material',
                          ),
                          labelBuilder: (material) =>
                              '${material.nome} - ${_money(material.valor)}',
                          onSelected: (value) {
                            setState(() => materialSelecionado = value);
                          },
                        ),
                        if (materialSelecionado != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Preco unitario: ${_money(materialSelecionado!.valor)}',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ] else ...[
                        _label('Descricao do item'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descricaoController,
                          decoration: _decoration('Descricao'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compacto = constraints.maxWidth < 420;
                          final quantidadeField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Quantidade'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: quantidadeController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _decoration('Ex: 1'),
                              ),
                            ],
                          );

                          if (usarMaterial) return quantidadeField;

                          final valorField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Valor unitario'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: valorController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _decoration('Ex: 85,00'),
                              ),
                            ],
                          );

                          if (compacto) {
                            return Column(
                              children: [
                                quantidadeField,
                                const SizedBox(height: 12),
                                valorField,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: quantidadeField),
                              const SizedBox(width: 10),
                              Expanded(child: valorField),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: salvar,
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ImagePreviewSlot(
                    bytes: orcamento.layout.cabecalho,
                    height: compact ? 42 : 60,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      orcamento.titulo.isEmpty
                                          ? 'Orcamento'
                                          : orcamento.titulo,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      orcamento.cliente,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _money(orcamento.total),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            'Emissao: ${_date(orcamento.dataEmissao)}',
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 12,
                            ),
                          ),
                          if (orcamento.possuiValidade &&
                              orcamento.validade != null)
                            Text(
                              'Validade: ${_date(orcamento.validade!)}',
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            orcamento.layout.textoPadrao,
                            maxLines: compact ? 3 : 5,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 12,
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
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Text(
                                        _money(item.total),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'TOTAL ${_money(orcamento.total)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ImagePreviewSlot(
                    bytes: orcamento.layout.rodape,
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

class _PdfFilePreview extends StatelessWidget {
  final Future<Uint8List> Function() buildPdf;

  const _PdfFilePreview({required this.buildPdf});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _renderFirstPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Nao foi possivel renderizar o PDF para preview.\n${snapshot.error ?? ''}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Container(
          color: const Color(0xFFE5E7EB),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Image.memory(snapshot.data!, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List> _renderFirstPage() async {
    final pdfBytes = await buildPdf();
    final page = await Printing.raster(
      pdfBytes,
      pages: const [0],
      dpi: 144,
    ).first;
    return page.toPng();
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
              ?action,
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
  final num subtotal;
  final VoidCallback? onGenerate;
  final VoidCallback onPreview;

  const _TotalBox({
    required this.subtotal,
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
            _money(subtotal),
            style: const TextStyle(
              color: AppColors.invertedText,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
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
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
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
  final double height;

  const _ImagePreviewSlot({required this.bytes, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: bytes == null
          ? const SizedBox.expand()
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Image.memory(bytes!, fit: BoxFit.contain),
            ),
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

class _AvisoBox extends StatelessWidget {
  final String text;

  const _AvisoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.warning,
          fontWeight: FontWeight.w700,
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
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) buffer.write('.');
  }
  return 'R\$ ${buffer.toString()},${parts.last}';
}

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _quantity(num value) {
  if (value % 1 == 0) return value.toInt().toString();
  return value.toStringAsFixed(2).replaceAll('.', ',');
}

String _safeFileName(String value) {
  return value
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .toLowerCase();
}

String _erroCurto(Object error) {
  final text = error.toString();
  if (text.length <= 220) return text;
  return '${text.substring(0, 220)}...';
}
