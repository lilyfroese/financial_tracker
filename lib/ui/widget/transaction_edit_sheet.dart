import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entity/transaction_entity.dart';
import '../../common/patterns/command.dart';

class TransactionEditSheet extends StatefulWidget {
  final TransactionEntity transaction;
  final Command1<void, dynamic, TransactionEntity> submitCommand;

  const TransactionEditSheet({
    super.key,
    required this.transaction,
    required this.submitCommand,
  });

  static void show({
    required BuildContext context,
    required TransactionEntity transaction,
    required Command1<void, dynamic, TransactionEntity> submitCommand,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TransactionEditSheet(
        transaction: transaction,
        submitCommand: submitCommand,
      ),
    );
  }

  @override
  State<TransactionEditSheet> createState() => _TransactionEditSheetState();
}

class _TransactionEditSheetState extends State<TransactionEditSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction.title);
    _amountController = TextEditingController(
        text: widget.transaction.amount.toStringAsFixed(2));
    _selectedDate = widget.transaction.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _cancel() => Navigator.of(context).pop();

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final edited = widget.transaction.copyWith(
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
      );

      widget.submitCommand.execute(edited);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Wrap(
            runSpacing: 16,
            children: [
              Text(
                'Editar Transação',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira um título válido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira um valor';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Insira um valor numérico maior que zero';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: Text('Data: ${formatter.format(_selectedDate)}'),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Selecionar Data'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _cancel,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Concluir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
