import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'models.dart';
import 'edit_budgets.dart';
import 'local_repository.dart';
import 'repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = LocalRepository();
  await repo.init();
  runApp(BudgetApp(repo: repo));
}

class BudgetApp extends StatelessWidget {
  final Repository repo;
  const BudgetApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(repo)..loadInitial(),
      child: MaterialApp(
        title: 'Blue Budget',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    BudgetScreen(),
    TransactionsScreen(),
    GoalsScreen(), // <-- real Goals screen
    _PlaceholderPage(title: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        // month navigation in title
        title: Builder(
          builder: (context) {
            final app = context.watch<AppState>();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => context.read<AppState>().stepMonth(-1),
                ),
                Text(app.monthLabel),
                IconButton(
                  tooltip: 'Next month',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => context.read<AppState>().stepMonth(1),
                ),
              ],
            );
          },
        ),
        actions: [
          if (_index == 1)
            IconButton(
              tooltip: 'Edit budgets',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditBudgetsScreen()),
                );
              },
            ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),

      floatingActionButton: _index == 2
          ? FloatingActionButton.extended(
              onPressed: () => _openAddTxnSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
    );
  }

  void _openAddTxnSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddTxnSheet(),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title (placeholder)',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    String money(double v) => '\$${v.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance: ${money(app.monthly.net)}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text('This month spent: ${money(app.monthly.spending)}'),
          const SizedBox(height: 24),
          Text(
            'Recent transactions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: app.recent.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final t = app.recent[i];
                return ListTile(
                  dense: true,
                  title: Text(t.merchant),
                  subtitle: Text(
                    '${t.date.month}/${t.date.day}/${t.date.year}',
                  ),
                  trailing: Text(
                    t.amountString,
                    style: TextStyle(
                      color: t.amount < 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.loading) return const Center(child: CircularProgressIndicator());
    final txns = app.monthTxns;

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: txns.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final t = txns[i];
        return Dismissible(
          key: ValueKey(t.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.red.withOpacity(0.85),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete transaction?'),
                    content: Text(
                      'Remove "${t.merchant}" for ${t.amountString}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) => context.read<AppState>().deleteTxn(t.id),
          child: ListTile(
            onTap: () => _openAddTxnSheet(context, existing: t),
            title: Text(t.merchant),
            subtitle: Text(
              '${t.date.month}/${t.date.day}/${t.date.year} • ${t.category.name}',
            ),
            trailing: Text(
              t.amountString,
              style: TextStyle(
                color: t.amount < 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  void _openAddTxnSheet(BuildContext context, {Txn? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddTxnSheet(existing: existing),
    );
  }
}

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    String money(num v) => '\$${v.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budgeted: ${money(app.totalBudgetLimit)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                'Spent: ${money(app.totalBudgetSpent)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Remaining: ${money(app.totalBudgetRemaining)}'),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: app.budgets.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final line = app.budgets[i];
                final spent = app.spentForCategory(line.category.id);
                final limit = line.limit;
                final pct = limit == 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
                final over = spent > limit;

                return ListTile(
                  title: Text(line.category.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          color: over
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${money(spent)} of ${money(limit)} spent'),
                    ],
                  ),
                  trailing: Text(
                    over ? '-${money(spent - limit)}' : money(limit - spent),
                    style: TextStyle(
                      color: over ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTxnSheet extends StatefulWidget {
  final Txn? existing; // null = create, not null = edit
  const _AddTxnSheet({super.key, this.existing});

  @override
  State<_AddTxnSheet> createState() => _AddTxnSheetState();
}

class _AddTxnSheetState extends State<_AddTxnSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchant;
  late final TextEditingController _amount;
  late DateTime _date;
  late Category _cat;
  late bool _isExpense;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _merchant = TextEditingController(text: e?.merchant ?? '');
    _amount = TextEditingController(
      text: e == null ? '' : e.amount.abs().toStringAsFixed(2),
    );
    _date = e?.date ?? DateTime.now();
    _cat = e?.category ?? Category.groceries;
    _isExpense = e == null ? true : e.amount < 0;
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    const cats = Category.all;

    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit transaction' : 'Add transaction',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter an amount';
                final parsed = double.tryParse(v);
                if (parsed == null) return 'Invalid number';
                if (parsed <= 0) return 'Use a positive number';
                return null;
              },
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                ChoiceChip(
                  selected: _isExpense,
                  label: const Text('Expense'),
                  onSelected: (_) => setState(() => _isExpense = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  selected: !_isExpense,
                  label: const Text('Income'),
                  onSelected: (_) => setState(() => _isExpense = false),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _merchant,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Merchant / Source'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),

            InputDecorator(
              decoration: const InputDecoration(labelText: 'Category'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Category>(
                  value: _cat,
                  items: [
                    for (final c in cats)
                      DropdownMenuItem(value: c, child: Text(c.name)),
                  ],
                  onChanged: (c) => setState(() => _cat = c!),
                ),
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text('${_date.month}/${_date.day}/${_date.year}'),
              subtitle: const Text('Date'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(_date.year - 2),
                  lastDate: DateTime(_date.year + 2),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: Text(isEdit ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final parsed = double.parse(_amount.text.trim());
    final amt = _isExpense ? -parsed : parsed;

    final existing = widget.existing;
    final txn = Txn(
      id: existing?.id ?? 't${DateTime.now().microsecondsSinceEpoch}',
      date: _date,
      merchant: _merchant.text.trim(),
      amount: amt,
      category: _cat,
    );

    final app = context.read<AppState>();
    if (existing == null) {
      app.addTxn(txn);
    } else {
      app.updateTxn(txn);
    }
    Navigator.pop(context);
  }
}

/// GOALS (CRUD + progress)
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.loading) return const Center(child: CircularProgressIndicator());
    final goals = app.goals;

    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: goals.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Goals', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Saved: \$${app.totalGoalsSaved.toStringAsFixed(2)}'
                  ' / \$${app.totalGoalsTarget.toStringAsFixed(2)}',
                ),
              ],
            );
          }
          final g = goals[i - 1];
          final pct = g.pct;
          final remaining = (g.target - g.saved).clamp(0, double.infinity);
          return Dismissible(
            key: ValueKey(g.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.red.withOpacity(0.85),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete goal?'),
                      content: Text('Remove "${g.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
            },
            onDismissed: (_) => context.read<AppState>().deleteGoal(g.id),
            child: ListTile(
              onTap: () => _openEditGoal(context, existing: g),
              title: Text(g.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${g.saved.toStringAsFixed(2)} of \$${g.target.toStringAsFixed(2)}'
                    '${g.due != null ? ' • due ${g.due!.month}/${g.due!.day}/${g.due!.year}' : ''}',
                  ),
                ],
              ),
              trailing: Text(
                remaining <= 0 ? 'Done' : '\$${remaining.toStringAsFixed(2)}',
                style: TextStyle(
                  color: remaining <= 0 ? Colors.green : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditGoal(context),
        icon: const Icon(Icons.add),
        label: const Text('Add goal'),
      ),
    );
  }

  void _openEditGoal(BuildContext context, {Goal? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditGoalSheet(existing: existing),
    );
  }
}

class _EditGoalSheet extends StatefulWidget {
  final Goal? existing;
  const _EditGoalSheet({super.key, this.existing});

  @override
  State<_EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends State<_EditGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _saved;
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _target = TextEditingController(text: e?.target.toStringAsFixed(2) ?? '');
    _saved = TextEditingController(text: e?.saved.toStringAsFixed(2) ?? '0');
    _due = e?.due;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit goal' : 'Add goal',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Target amount',
                prefixText: '\$',
              ),
              validator: (v) {
                final d = double.tryParse(v ?? '');
                if (d == null || d <= 0) return 'Enter a positive number';
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _saved,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Already saved',
                prefixText: '\$',
              ),
              validator: (v) {
                final d = double.tryParse(v ?? '');
                if (d == null || d < 0) return 'Enter 0 or more';
                final t = double.tryParse(_target.text) ?? 0;
                if (d > t) return 'Cannot exceed target';
                return null;
              },
            ),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(
                _due == null
                    ? 'No due date'
                    : '${_due!.month}/${_due!.day}/${_due!.year}',
              ),
              subtitle: const Text('Due date (optional)'),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _due ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 5),
                );
                if (picked != null) setState(() => _due = picked);
              },
            ),
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: Text(isEdit ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final id =
        widget.existing?.id ?? 'g${DateTime.now().microsecondsSinceEpoch}';
    final g = Goal(
      id: id,
      name: _name.text.trim(),
      target: double.parse(_target.text.trim()),
      saved: double.parse(_saved.text.trim()),
      due: _due,
    );
    final app = context.read<AppState>();
    if (widget.existing == null) {
      app.addGoal(g);
    } else {
      app.updateGoal(g);
    }
    Navigator.pop(context);
  }
}
