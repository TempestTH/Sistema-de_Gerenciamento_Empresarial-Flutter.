import 'package:flutter/material.dart';
import 'package:projeto_elifone/model/agendamento_historico_model.dart';
import 'package:projeto_elifone/model/agendamento_model.dart';
import 'package:projeto_elifone/services/supabase_agendamento_service.dart';

class AgendaPage extends StatefulWidget {
  final Future<List<AgendamentoModel>> Function()? loadAgendamentos;
  final ValueChanged<AgendamentoModel>? onAbrirDetalhes;

  const AgendaPage({super.key, this.loadAgendamentos, this.onAbrirDetalhes});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final SupabaseAgendamentoService agendamentoService =
      SupabaseAgendamentoService();

  List<AgendamentoModel> agendamentos = [];
  bool loading = true;
  String modo = 'mes';
  DateTime dataReferencia = DateTime.now();
  String? aviso;

  @override
  void initState() {
    super.initState();
    carregarAgendamentos();
  }

  Future<void> carregarAgendamentos() async {
    setState(() {
      loading = true;
      aviso = null;
    });

    try {
      final loader = widget.loadAgendamentos;
      final data = loader != null
          ? await loader()
          : await agendamentoService.listar();

      if (!mounted) return;
      setState(() {
        agendamentos = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        agendamentos = [];
        loading = false;
        aviso =
            'Nao foi possivel carregar os agendamentos. Verifique as tabelas e policies no Supabase.';
      });
    }
  }

  Future<void> _abrirModalNovoServico() async {
    final novoAgendamento = await showDialog<AgendamentoModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NovoServicoModal(dataInicial: dataReferencia),
    );

    if (novoAgendamento == null) return;

    try {
      final agendamentoCriado = await agendamentoService.inserir(
        novoAgendamento,
      );
      var historicoRegistrado = true;
      try {
        await agendamentoService.inserirHistorico(
          AgendamentoHistoricoModel(
            idAgendamento: agendamentoCriado.id,
            titulo: 'Ordem de servico criada',
            descricao: 'Agendamento criado no console de agendamento.',
          ),
        );
      } catch (_) {
        historicoRegistrado = false;
      }
      await carregarAgendamentos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            historicoRegistrado
                ? 'Servico agendado com sucesso!'
                : 'Servico agendado, mas o historico nao foi registrado.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => agendamentos = [...agendamentos, novoAgendamento]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Agendamento adicionado na tela. Crie a tabela para salvar no banco.',
          ),
        ),
      );
    }
  }

  DateTime get inicioSemana {
    final date = _onlyDate(dataReferencia);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime get fimSemana => inicioSemana.add(const Duration(days: 6));

  DateTime get inicioMes => DateTime(dataReferencia.year, dataReferencia.month);

  DateTime get fimMes =>
      DateTime(dataReferencia.year, dataReferencia.month + 1, 0);

  List<AgendamentoModel> get agendamentosDoPeriodo {
    final inicio = modo == 'mes' ? inicioMes : inicioSemana;
    final fim = modo == 'mes' ? fimMes : fimSemana;

    return agendamentos.where((item) {
      final data = _onlyDate(item.inicio);
      return !data.isBefore(inicio) && !data.isAfter(fim);
    }).toList();
  }

  List<AgendamentoModel> get agendamentosDaSemana {
    return agendamentos.where((item) {
      final data = _onlyDate(item.inicio);
      return !data.isBefore(inicioSemana) && !data.isAfter(fimSemana);
    }).toList();
  }

  List<AgendamentoModel> get agendamentosDoDia {
    final selecionado = _onlyDate(dataReferencia);
    final data = agendamentos.where((item) {
      return _onlyDate(item.inicio) == selecionado;
    }).toList()..sort((a, b) => a.inicio.compareTo(b.inicio));

    return data;
  }

  int get totalAgendamentos => agendamentosDoPeriodo.length;

  int get servicosAtivos {
    return agendamentosDoPeriodo
        .where((item) => item.status != 'Cancelado')
        .length;
  }

  num get receitaPrevista {
    return agendamentosDoPeriodo.fold<num>(
      0,
      (total, item) => total + item.valor,
    );
  }

  double get taxaConclusao {
    if (agendamentosDoPeriodo.isEmpty) return 0;
    final concluidos = agendamentosDoPeriodo
        .where((item) => item.status == 'Concluido')
        .length;
    return concluidos / agendamentosDoPeriodo.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarAgendamentos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    if (aviso != null) _buildAviso(),
                    _buildMetricas(),
                    const SizedBox(height: 18),
                    if (modo == 'dia')
                      _buildDiario()
                    else if (modo == 'semana')
                      _buildSemanal()
                    else
                      _buildMensal(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1080;

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
                  'Console de Agendamento',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Servicos distribuidos por mes, semana e agenda diaria.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
            if (isCompact) const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildModoButton('mes', 'Mes'),
                _buildModoButton('semana', 'Semana'),
                _buildModoButton('dia', 'Dia'),
                _buildNavegacaoData(),
                OutlinedButton.icon(
                  onPressed: carregarAgendamentos,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Atualizar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _abrirModalNovoServico,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Novo Servico'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildModoButton(String value, String label) {
    final selected = modo == value;

    return OutlinedButton(
      onPressed: () => setState(() => modo = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFFE5E7EB) : Colors.white,
        foregroundColor: const Color(0xFF111827),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      child: Text(label),
    );
  }

  Widget _buildNavegacaoData() {
    final label = switch (modo) {
      'dia' => _formatDate(dataReferencia),
      'semana' => '${_formatDate(inicioSemana)} - ${_formatDate(fimSemana)}',
      _ => _formatMonthYear(dataReferencia),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _moverPeriodo(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () => _moverPeriodo(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  void _moverPeriodo(int direction) {
    setState(() {
      if (modo == 'dia') {
        dataReferencia = dataReferencia.add(Duration(days: direction));
      } else if (modo == 'semana') {
        dataReferencia = dataReferencia.add(Duration(days: 7 * direction));
      } else {
        dataReferencia = DateTime(
          dataReferencia.year,
          dataReferencia.month + direction,
          1,
        );
      }
    });
  }

  Widget _buildAviso() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Text(
        aviso!,
        style: const TextStyle(
          color: Color(0xFF92400E),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMetricas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 640
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        final cards = [
          _MetricaData(
            'Total de Agendamentos',
            totalAgendamentos.toString(),
            '${agendamentos.length} registros carregados',
            Icons.calendar_month_outlined,
          ),
          _MetricaData(
            'Servicos Ativos',
            servicosAtivos.toString(),
            modo == 'mes' ? 'Neste mes' : 'Nesta semana',
            Icons.miscellaneous_services_outlined,
          ),
          _MetricaData(
            'Previsao de Receita',
            'R\$ ${receitaPrevista.toStringAsFixed(2)}',
            'Meta da semana',
            Icons.payments_outlined,
          ),
          _MetricaData(
            'Taxa de Conclusao',
            '${(taxaConclusao * 100).toStringAsFixed(1)}%',
            'Servicos concluidos',
            Icons.task_alt,
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: width, child: _MetricaCard(card)))
              .toList(),
        );
      },
    );
  }

  Widget _buildSemanal() {
    final dias = List.generate(7, (index) {
      return inicioSemana.add(Duration(days: index));
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          if (compact) {
            return Column(children: dias.map(_buildColunaDiaMobile).toList());
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: dias
                .map(
                  (dia) =>
                      Expanded(child: _buildColunaDia(dia, minHeight: 520)),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildMensal() {
    final primeiroDiaGrade = inicioMes.subtract(
      Duration(days: inicioMes.weekday - 1),
    );
    final dias = List.generate(
      42,
      (index) => primeiroDiaGrade.add(Duration(days: index)),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          if (compact) {
            return Column(
              children: dias
                  .where((dia) => dia.month == dataReferencia.month)
                  .map((dia) => _buildDiaMesMobile(dia))
                  .toList(),
            );
          }

          return Column(
            children: [
              Row(
                children: List.generate(
                  7,
                  (index) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        border: Border(
                          right: BorderSide(color: Color(0xFFE5E7EB)),
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Text(
                        _weekdayName(index + 1).substring(0, 3).toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ...List.generate(6, (weekIndex) {
                final semana = dias.skip(weekIndex * 7).take(7);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: semana
                      .map(
                        (dia) =>
                            Expanded(child: _buildDiaMes(dia, minHeight: 118)),
                      )
                      .toList(),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDiaMesMobile(DateTime dia) {
    return SizedBox(
      width: double.infinity,
      child: _buildDiaMes(dia, minHeight: 120),
    );
  }

  Widget _buildDiaMes(DateTime dia, {required double minHeight}) {
    final itens = agendamentos.where((item) {
      return _onlyDate(item.inicio) == _onlyDate(dia);
    }).toList()..sort((a, b) => a.inicio.compareTo(b.inicio));
    final foraDoMes = dia.month != dataReferencia.month;
    final selected = _onlyDate(dia) == _onlyDate(dataReferencia);
    final visibleItems = itens.take(3).toList();

    return InkWell(
      onTap: () => setState(() {
        dataReferencia = dia;
        modo = 'dia';
      }),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF3F4F6)
              : foraDoMes
              ? const Color(0xFFFAFAFA)
              : Colors.white,
          border: const Border(
            right: BorderSide(color: Color(0xFFE5E7EB)),
            bottom: BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dia.day.toString().padLeft(2, '0'),
              style: TextStyle(
                color: foraDoMes
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF111827),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            if (visibleItems.isEmpty)
              const SizedBox(height: 26)
            else
              ...visibleItems.map(_buildServicoChip),
            if (itens.length > visibleItems.length)
              Text(
                '+${itens.length - visibleItems.length} servicos',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColunaDiaMobile(DateTime dia) {
    return SizedBox(
      width: double.infinity,
      child: _buildColunaDia(dia, minHeight: 180),
    );
  }

  Widget _buildColunaDia(DateTime dia, {required double minHeight}) {
    final itens = agendamentosDaSemana.where((item) {
      return _onlyDate(item.inicio) == _onlyDate(dia);
    }).toList()..sort((a, b) => a.inicio.compareTo(b.inicio));

    final selected = _onlyDate(dia) == _onlyDate(dataReferencia);

    return InkWell(
      onTap: () => setState(() {
        dataReferencia = dia;
        modo = 'dia';
      }),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF3F4F6) : Colors.white,
          border: const Border(
            right: BorderSide(color: Color(0xFFE5E7EB)),
            bottom: BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _weekdayName(dia.weekday).toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dia.day.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            if (itens.isEmpty)
              const Text(
                'Sem servicos',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              )
            else
              ...itens.map(_buildServicoChip),
          ],
        ),
      ),
    );
  }

  Widget _buildServicoChip(AgendamentoModel item) {
    final color = _statusColor(item.status);

    return InkWell(
      onTap: () => widget.onAbrirDetalhes?.call(item),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatHour(item.inicio)} ${item.servico}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.cliente,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiario() {
    final horarios = List.generate(24, (index) => index);
    final scrollHeight = (MediaQuery.of(context).size.height * 0.62)
        .clamp(360.0, 560.0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agenda diaria - ${_formatDate(dataReferencia)}',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: scrollHeight,
            child: ListView(
              children: horarios.map(_buildHorarioLinha).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorarioLinha(int hora) {
    final itens = agendamentosDoDia.where((item) => item.inicio.hour == hora);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(
              '${hora.toString().padLeft(2, '0')}:00',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: itens.isEmpty
                ? const Text(
                    'Horario livre',
                    style: TextStyle(color: Color(0xFF9CA3AF)),
                  )
                : Column(children: itens.map(_buildServicoLista).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildServicoLista(AgendamentoModel item) {
    final color = _statusColor(item.status);

    return InkWell(
      onTap: () => widget.onAbrirDetalhes?.call(item),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.servico,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.cliente} - ${item.responsavel}',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${_formatHour(item.inicio)} - ${_formatHour(item.fim)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _NovoServicoModal extends StatefulWidget {
  final DateTime dataInicial;

  const _NovoServicoModal({required this.dataInicial});

  @override
  State<_NovoServicoModal> createState() => _NovoServicoModalState();
}

class _NovoServicoModalState extends State<_NovoServicoModal> {
  final clienteController = TextEditingController();
  final servicoController = TextEditingController();
  final responsavelController = TextEditingController();
  final valorController = TextEditingController(text: '0');
  final observacaoController = TextEditingController();

  late DateTime data;
  TimeOfDay hora = const TimeOfDay(hour: 9, minute: 0);
  int duracao = 60;
  String status = 'Agendado';

  @override
  void initState() {
    super.initState();
    data = widget.dataInicial;
  }

  @override
  void dispose() {
    clienteController.dispose();
    servicoController.dispose();
    responsavelController.dispose();
    valorController.dispose();
    observacaoController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (clienteController.text.isEmpty ||
        servicoController.text.isEmpty ||
        responsavelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha cliente, servico e responsavel'),
        ),
      );
      return;
    }

    final inicio = DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );
    final fim = inicio.add(Duration(minutes: duracao));

    Navigator.pop(
      context,
      AgendamentoModel(
        cliente: clienteController.text,
        servico: servicoController.text,
        responsavel: responsavelController.text,
        inicio: inicio,
        fim: fim,
        status: status,
        valor: num.tryParse(valorController.text.replaceAll(',', '.')) ?? 0,
        observacao: observacaoController.text,
      ),
    );
  }

  Future<void> _selecionarData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (selecionada != null) {
      setState(() => data = selecionada);
    }
  }

  Future<void> _selecionarHora() async {
    final selecionada = await showTimePicker(
      context: context,
      initialTime: hora,
    );

    if (selecionada != null) {
      setState(() => hora = selecionada);
    }
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFF111827), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9FA),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
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
                        'Adicionar Novo Servico',
                        style: TextStyle(
                          color: Color(0xFF2F3137),
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
              const Divider(height: 1, color: Color(0xFFD9D9DE)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _label('Cliente'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: clienteController,
                        decoration: _fieldDecoration('Ex: Carlos Andrade'),
                      ),
                      const SizedBox(height: 16),
                      _label('Nome do servico'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: servicoController,
                        decoration: _fieldDecoration(
                          'Ex: Manutencao Preventiva',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label('Responsavel'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: responsavelController,
                        decoration: _fieldDecoration('Ex: Equipe A'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selecionarData,
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(_formatDate(data)),
                              style: _modalOutlineButtonStyle(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selecionarHora,
                              icon: const Icon(Icons.schedule, size: 18),
                              label: Text(_formatTimeOfDay(hora)),
                              style: _modalOutlineButtonStyle(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: duracao,
                              decoration: _fieldDecoration('Duracao'),
                              items: const [
                                DropdownMenuItem(
                                  value: 30,
                                  child: Text('30 min'),
                                ),
                                DropdownMenuItem(
                                  value: 60,
                                  child: Text('1 hora'),
                                ),
                                DropdownMenuItem(
                                  value: 90,
                                  child: Text('1h 30min'),
                                ),
                                DropdownMenuItem(
                                  value: 120,
                                  child: Text('2 horas'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => duracao = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: status,
                              decoration: _fieldDecoration('Status'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Agendado',
                                  child: Text('Agendado'),
                                ),
                                DropdownMenuItem(
                                  value: 'Urgente',
                                  child: Text('Urgente'),
                                ),
                                DropdownMenuItem(
                                  value: 'Concluido',
                                  child: Text('Concluido'),
                                ),
                                DropdownMenuItem(
                                  value: 'Cancelado',
                                  child: Text('Cancelado'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => status = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _label('Preco'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: valorController,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDecoration('R\$ 0,00'),
                      ),
                      const SizedBox(height: 16),
                      _label('Descricao'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: observacaoController,
                        minLines: 3,
                        maxLines: 4,
                        decoration: _fieldDecoration(
                          'Descreva os detalhes do servico...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: _modalSecondaryButtonStyle(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _salvar,
                      style: _modalPrimaryButtonStyle(),
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

class _MetricaData {
  final String titulo;
  final String valor;
  final String legenda;
  final IconData icon;

  const _MetricaData(this.titulo, this.valor, this.legenda, this.icon);
}

class _MetricaCard extends StatelessWidget {
  final _MetricaData data;

  const _MetricaCard(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.titulo.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  data.icon,
                  size: 20,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.legenda,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

ButtonStyle _modalPrimaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    shape: const RoundedRectangleBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
  );
}

ButtonStyle _modalSecondaryButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF374151),
    side: const BorderSide(color: Color(0xFFD1D5DB)),
    shape: const RoundedRectangleBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
  );
}

ButtonStyle _modalOutlineButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF374151),
    side: const BorderSide(color: Color(0xFFD1D5DB)),
    shape: const RoundedRectangleBorder(),
    padding: const EdgeInsets.symmetric(vertical: 16),
  );
}

DateTime _onlyDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String _weekdayName(int weekday) {
  const dias = [
    'Segunda',
    'Terca',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sabado',
    'Domingo',
  ];
  return dias[weekday - 1];
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatMonthYear(DateTime date) {
  const meses = [
    'Janeiro',
    'Fevereiro',
    'Marco',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  return '${meses[date.month - 1]} ${date.year}';
}

String _formatHour(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Color _statusColor(String status) {
  switch (status) {
    case 'Concluido':
      return const Color(0xFF059669);
    case 'Urgente':
      return const Color(0xFFDC2626);
    case 'Cancelado':
      return const Color(0xFF6B7280);
    default:
      return const Color(0xFF2563EB);
  }
}
