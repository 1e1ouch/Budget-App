import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'models.dart';

class EditBudgetsScreen extends StatefulWidget {
  const EditBudgetsScreen({super.key});

  @override
  State<EditBudgetsScreen> createState() => _EditBudgetsScreenState();
}

class _EditBudgetsScreenState extends State<EditBudgetsScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    for (final b in app.budgets) {
      _controllers[b.category.id] = TextEditingController(
        text: b.limit.toStringAsFixed(0),
      );
    }
    for (final c in Category.all) {
      _controllers.putIfAbsent(c.id, () => TextEditingController(text: '0'));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cats = Category.all;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit budgets'),
        actions: [
          TextButton(onPressed: () => _save(app), child: const Text('Save')),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final cat = cats[i];
          final ctrl = _controllers[cat.id]!;
          return ListTile(
            title: Text(cat.name),
            trailing: SizedBox(
              width: 140,
              child: TextField(
                controller: ctrl,
                textAlign: TextAlign.right,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Limit',
                  prefixText: '\$ ',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _save(AppState app) async {
    final lines = <BudgetLine>[];
    for (final entry in _controllers.entries) {
      final cat = _allCats.firstWhere((c) => c.id == entry.key);
      final v = double.tryParse(entry.value.text.trim()) ?? 0.0;
      lines.add(BudgetLine(category: cat, limit: v));
    }
    await app.saveBudgets(lines);
    if (mounted) Navigator.pop(context);
  }

  List<Category> get _allCats => Category.all;
}
