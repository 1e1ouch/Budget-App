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
    _PlaceholderPage(title: 'Goals'),
    _PlaceholderPage(title: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(_index)),
        actions: [
          // Show "Edit budgets" action only on the Budget tab
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

      // FAB only on Transactions tab
      floatingActionButton: _index == 2
          ? FloatingActionButton.extended(
              onPressed: () => _openAddTxnSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
    );
  }

  String _titleForIndex(int i) =>
      ['Dashboard', 'Budget', 'Transactions', 'Goals', 'Profile'][i];

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

    // content only (no inner scaffold)
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
    if (app.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final txns = app.monthTxns;

    // content only
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: txns.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final t = txns[i];
        return ListTile(
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
        );
      },
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

    // content only
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
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

          // Per-category list
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
  const _AddTxnSheet({super.key});

  @override
  State<_AddTxnSheet> createState() => _AddTxnSheetState();
}

class _AddTxnSheetState extends State<_AddTxnSheet> {
  final _formKey = GlobalKey<FormState>();
  final _merchant = TextEditingController();
  final _amount = TextEditingController();
  DateTime _date = DateTime.now();
  Category _cat = Category.groceries;
  bool _isExpense = true;

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    const cats = [
      Category.groceries,
      Category.dining,
      Category.rent,
      Category.transfer,
    ];

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
                const Text(
                  'Add transaction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
              label: const Text('Save'),
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

    final txn = Txn(
      id: 't${DateTime.now().microsecondsSinceEpoch}',
      date: _date,
      merchant: _merchant.text.trim(),
      amount: amt,
      category: _cat,
    );

    context.read<AppState>().addTxn(txn);
    Navigator.pop(context);
  }
}
