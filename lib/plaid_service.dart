import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plaid_flutter/plaid_flutter.dart';
import 'models.dart';

class PlaidService {
  // Android emulator: http://10.0.2.2:8080
  // iOS simulator:    http://localhost:8080
  final String baseUrl;
  PlaidService(this.baseUrl);

  Future<String> _createLinkToken() async {
    final r = await http.post(
      Uri.parse('$baseUrl/link_token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': 'demo-user-123'}),
    );
    if (r.statusCode != 200) throw Exception('link_token failed');
    return (jsonDecode(r.body) as Map<String, dynamic>)['link_token'] as String;
  }

  Future<String> _exchangePublicToken(String publicToken) async {
    final r = await http.post(
      Uri.parse('$baseUrl/exchange_public_token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'public_token': publicToken}),
    );
    if (r.statusCode != 200) throw Exception('exchange failed');
    return (jsonDecode(r.body) as Map<String, dynamic>)['access_token']
        as String;
  }

  /// Opens Plaid Link and exchanges the public_token. Returns true if linked.
  Future<bool> openLinkAndExchange() async {
    final linkToken = await _createLinkToken();
    final completer = Completer<bool>();

    // Listen for success/exit once
    late final StreamSubscription<LinkSuccess> successSub;
    late final StreamSubscription<LinkExit> exitSub;

    successSub = PlaidLink.onSuccess.listen((LinkSuccess event) async {
      try {
        await _exchangePublicToken(event.publicToken);
        if (!completer.isCompleted) completer.complete(true);
      } catch (e) {
        if (!completer.isCompleted) completer.completeError(e);
      } finally {
        await successSub.cancel();
        await exitSub.cancel();
      }
    });

    exitSub = PlaidLink.onExit.listen((_) async {
      if (!completer.isCompleted) completer.complete(false);
      await successSub.cancel();
      await exitSub.cancel();
    });

    await PlaidLink.create(
      configuration: LinkTokenConfiguration(token: linkToken),
    );
    PlaidLink.open();

    return completer.future;
  }

  /// Fetch sandbox transactions from backend and map to model
  Future<List<Txn>> fetchTransactionsMapped() async {
    final r = await http.get(Uri.parse('$baseUrl/transactions'));
    if (r.statusCode != 200) throw Exception('transactions failed');

    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final List txns = (data['transactions'] as List?) ?? const [];

    return txns.map<Txn>((t) {
      final id = t['transaction_id'] as String;
      final name = (t['merchant_name'] ?? t['name'] ?? 'Unknown').toString();
      final date = DateTime.parse(t['date'] as String);
      final amount = (t['amount'] as num).toDouble();
      final signed = amount > 0 ? -amount : amount;

      final cats =
          (t['category'] as List?)?.map((e) => e.toString()).toList() ?? [];
      Category cat = Category.transfer;
      if (cats.any((c) => c.toLowerCase().contains('grocer'))) {
        cat = Category.groceries;
      } else if (cats.any(
        (c) =>
            c.toLowerCase().contains('restaurant') ||
            c.toLowerCase().contains('dining'),
      )) {
        cat = Category.dining;
      } else if (name.toLowerCase().contains('rent')) {
        cat = Category.rent;
      }

      return Txn(
        id: 'p_$id',
        date: date,
        merchant: name,
        amount: signed,
        category: cat,
      );
    }).toList();
  }
}
