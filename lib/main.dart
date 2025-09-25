import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'fake_repository.dart';
import 'models.dart';

void main() => runApp(const BudgetApp());

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    // provide app state to the whole app
    return ChangeNotifierProvider(
      create: (_) => AppState(FakeRepository())..loadInitial(),
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

  // real screens for Home & Transactions, placeholders for the rest
  final List<Widget> _pages = const [
    DashboardScreen(),
    _PlaceholderPage(title: 'Budget'),
    TransactionsScreen(),
    _PlaceholderPage(title: 'Goals'),
    _PlaceholderPage(title: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleForIndex(_index))),
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
    );
  }

  String _titleForIndex(int i) =>
      ['Dashboard', 'Budget', 'Transactions', 'Goals', 'Profile'][i];
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

/// real screens below

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    String money(double v) => '\$${v.toStringAsFixed(2)}';

    // content only (no inner scaffold/appbar)
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

    // content only (no inner scaffold/appBar)
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
