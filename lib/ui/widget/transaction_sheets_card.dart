import 'package:financial_tracker/common/errors/errors_classes.dart';
import 'package:financial_tracker/common/patterns/command.dart';

import '../../common/utils/formatter.dart';
import '../../domain/entity/transaction_entity.dart';
import 'package:flutter/material.dart';

/// widget que exibe uma lista de transações de receitas e despesas
class TransactionCardSheets extends StatefulWidget {
  final List<TransactionEntity>
      incomeTransactions; // Lista de transações de receitas
  final List<TransactionEntity>
      expenseTransactions; // Lista de transações de despesas
  final Function(String id) onDelete; // Callback para deletar uma transação pelo ID

  final Command1<void, Failure, TransactionEntity>
      undoDelete; // Callback para desfazer exclusão
  final BuildContext
      scaffoldContext; // Contexto do Scaffold para exibir SnackBars

  /// Novo callback para edição
  final Function(TransactionEntity transaction) onEdit;

  const TransactionCardSheets({
    super.key,
    required this.incomeTransactions,
    required this.expenseTransactions,
    required this.onDelete,
    required this.undoDelete,
    required this.scaffoldContext,
    required this.onEdit, // recebe callback de edição
  });

  @override
  State<TransactionCardSheets> createState() => _TransactionCardSheetsState();
}

class _TransactionCardSheetsState extends State<TransactionCardSheets>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // Controlador para o TabBar e TabBarView

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // 2 abas: Receitas e Despesas
    _tabController.addListener(() {
      if (mounted) setState(() {}); // Atualiza o estado quando troca de aba acontece
    });
  }

  @override
  void dispose() {
    _tabController.dispose(); // Limpa o controlador para evitar leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 8, // Elevação do card para sombra
      margin: const EdgeInsets.all(12), // Margem externa do card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ), // Bordas arredondadas
      child: Column(
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withAlpha(38), // fundo translúcido
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ), // Apenas bordas superiores arredondadas
                ),
                child: TabBar(
                  controller: _tabController, // Controlador das abas
                  tabs: [
                    _buildTab(
                      TransactionType.income.namePlural, // Título da aba
                      Icons.arrow_upward, // Ícone da aba
                      0, // Índice da aba
                      colorScheme.primary, // Cor ativa
                      colorScheme.primary.withAlpha(128), // Cor inativa
                    ),
                    _buildTab(
                      TransactionType.expense.namePlural,
                      Icons.arrow_downward,
                      1,
                      colorScheme.secondary,
                      colorScheme.secondary.withAlpha(128),
                    ),
                  ],
                  indicatorColor:
                      _tabController.index == 0 // Cor do indicador da aba selecionada
                          ? colorScheme.primary
                          : colorScheme.secondary,
                  indicatorSize: TabBarIndicatorSize.label,
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ), // Arredonda bordas inferiores para combinar com o card
                child: SizedBox(
                  height: 290, // Altura fixa do conteúdo da aba
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionList(
                        context,
                        widget.incomeTransactions, // Lista de receitas
                        colorScheme.primary,
                        TransactionType.income.namePlural,
                      ),
                      _buildTransactionList(
                        context,
                        widget.expenseTransactions, // Lista de despesas
                        colorScheme.secondary,
                        TransactionType.expense.namePlural,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    String title,
    IconData icon,
    int index,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isSelected = _tabController.index == index;
    final color = isSelected ? activeColor : inactiveColor;

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<TransactionEntity> transactions,
    Color color,
    String title,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              title == TransactionType.income.namePlural
                  ? Icons.savings
                  : Icons.shopping_cart,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              'Sem ${title.toLowerCase()} registradas',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final undoTransaction = transaction.copyWith();

          return _buildDismissibleTransactionItem(
              context, transaction, undoTransaction, color, title);
        },
      ),
    );
  }


  Widget _buildDismissibleTransactionItem(
    BuildContext context,
    TransactionEntity transaction,
    TransactionEntity undoTransaction,
    Color color,
    String title,
  ) {
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.horizontal, // permite ambos os lados
      background: _buildEditBackground(), // esquerda para direita
      secondaryBackground: _buildDeleteBackground(), // direita para esquerda
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Lógica para edição - não remove o item da lista, só chama o callback
          widget.onEdit(transaction);
          return false; // não remove o item da lista
        } else if (direction == DismissDirection.endToStart) {
          // Confirma exclusão
          // Aqui você pode adicionar um diálogo para confirmar, se quiser
          return true; // permite a exclusão
        }
        return false;
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await widget.onDelete(transaction.id);

          ScaffoldMessenger.of(widget.scaffoldContext).clearSnackBars();

          ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
            SnackBar(
              content: Text('${transaction.title} excluída!!!'),
              backgroundColor: Colors.pinkAccent,
              action: SnackBarAction(
                label: 'DESFAZER',
                textColor: Colors.white,
                onPressed: () async {
                  await widget.undoDelete.execute(undoTransaction);
                  if (widget.undoDelete.resultSignal.value?.isSuccess ?? false) {
                    ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
                      SnackBar(
                        content: Text('${transaction.title} restaurada!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${widget.undoDelete.resultSignal.value?.failureValueOrNull ?? 'Erro desconhecido'}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: color.withAlpha(50),
            child: Icon(
              title == TransactionType.income.namePlural ? Icons.attach_money : Icons.shopping_bag,
              color: color,
            ),
          ),
          title: Text(
            transaction.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            Formatter.formatDate(transaction.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Text(
            Formatter.formatCurrency(transaction.amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditBackground() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        color: Colors.blue, // Fundo azul para editar
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.edit,
        color: Colors.white,
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red, // Fundo vermelho para deletar
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.delete,
        color: Colors.white,
      ),
    );
  }
}
