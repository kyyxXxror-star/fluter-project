import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// =======================
/// MODEL
/// =======================
class CoinHistoryItem {
  final String id;
  final String username;
  final String action; // use | transfer_out | transfer_in | topup
  final String coinType; // bitcoin | lcoin
  final int amount;
  final int balanceAfterBtc;
  final int balanceAfterLtc;
  final int createdAt; // epoch ms
  final String note; // optional (target / code / dll)

  CoinHistoryItem({
    required this.id,
    required this.username,
    required this.action,
    required this.coinType,
    required this.amount,
    required this.balanceAfterBtc,
    required this.balanceAfterLtc,
    required this.createdAt,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "action": action,
        "coinType": coinType,
        "amount": amount,
        "balanceAfterBtc": balanceAfterBtc,
        "balanceAfterLtc": balanceAfterLtc,
        "createdAt": createdAt,
        "note": note,
      };

  static CoinHistoryItem fromJson(Map<String, dynamic> j) => CoinHistoryItem(
        id: (j["id"] ?? "").toString(),
        username: (j["username"] ?? "").toString(),
        action: (j["action"] ?? "").toString(),
        coinType: (j["coinType"] ?? "").toString(),
        amount: (j["amount"] is int) ? j["amount"] : int.tryParse("${j["amount"]}") ?? 0,
        balanceAfterBtc: (j["balanceAfterBtc"] is int)
            ? j["balanceAfterBtc"]
            : int.tryParse("${j["balanceAfterBtc"]}") ?? 0,
        balanceAfterLtc: (j["balanceAfterLtc"] is int)
            ? j["balanceAfterLtc"]
            : int.tryParse("${j["balanceAfterLtc"]}") ?? 0,
        createdAt: (j["createdAt"] is int)
            ? j["createdAt"]
            : int.tryParse("${j["createdAt"]}") ?? DateTime.now().millisecondsSinceEpoch,
        note: (j["note"] ?? "").toString(),
      );
}

/// =======================
/// STORAGE (LOCAL)
/// =======================
class CoinHistoryStore {
  static const String _key = "coin_history_v1";

  static Future<List<CoinHistoryItem>> getAll({String? username}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    final items = decoded
        .whereType<Map>()
        .map((m) => CoinHistoryItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (username == null) return items;
    return items.where((e) => e.username == username).toList();
  }

  static Future<void> add(CoinHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getAll();
    items.insert(0, item);

    // biar ga numpuk: simpan max 200 history
    final trimmed = items.take(200).toList();

    await prefs.setString(_key, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  static Future<void> clear({String? username}) async {
    final prefs = await SharedPreferences.getInstance();
    if (username == null) {
      await prefs.remove(_key);
      return;
    }

    final items = await getAll();
    final kept = items.where((e) => e.username != username).toList();
    await prefs.setString(_key, jsonEncode(kept.map((e) => e.toJson()).toList()));
  }
}

/// =======================
/// UI SCREEN
/// =======================
class CoinHistoryPage extends StatefulWidget {
  final String username;
  const CoinHistoryPage({super.key, required this.username});

  @override
  State<CoinHistoryPage> createState() => _CoinHistoryPageState();
}

class _CoinHistoryPageState extends State<CoinHistoryPage> {
  List<CoinHistoryItem> _items = [];
  bool _loading = true;

  String _filterCoin = "all"; // all | bitcoin | lcoin
  String _filterAction = "all"; // all | use | transfer_out | transfer_in | topup

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await CoinHistoryStore.getAll(username: widget.username);
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _labelCoin(String coinType) => coinType == "bitcoin" ? "BTC" : "LTC";

  String _labelAction(String action) {
    switch (action) {
      case "use":
        return "Pakai Coin";
      case "transfer_out":
        return "Transfer Keluar";
      case "transfer_in":
        return "Transfer Masuk";
      case "topup":
        return "Top Up";
      default:
        return action;
    }
  }

  IconData _iconAction(String action, String coinType) {
    if (coinType == "bitcoin") return Icons.currency_bitcoin;
    return Icons.monetization_on;
  }

  List<CoinHistoryItem> get _filtered {
    return _items.where((e) {
      final okCoin = _filterCoin == "all" || e.coinType == _filterCoin;
      final okAction = _filterAction == "all" || e.action == _filterAction;
      return okCoin && okAction;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text("History Coin"),
        actions: [
          IconButton(
            onPressed: () async {
              await CoinHistoryStore.clear(username: widget.username);
              await _load();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ History dihapus"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFilters(),
                  const SizedBox(height: 12),
                  if (_filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          "Belum ada history coin",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    ..._filtered.map(_buildItemCard),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Filter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _chipGroup(
                  title: "Coin",
                  options: const [
                    ("all", "ALL"),
                    ("bitcoin", "BTC"),
                    ("lcoin", "LTC"),
                  ],
                  value: _filterCoin,
                  onChanged: (v) => setState(() => _filterCoin = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _chipGroup(
                  title: "Aksi",
                  options: const [
                    ("all", "ALL"),
                    ("use", "USE"),
                    ("transfer_out", "OUT"),
                    ("transfer_in", "IN"),
                    ("topup", "TOPUP"),
                  ],
                  value: _filterAction,
                  onChanged: (v) => setState(() => _filterAction = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipGroup({
    required String title,
    required List<(String, String)> options,
    required String value,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final selected = value == opt.$1;
            return ChoiceChip(
              label: Text(opt.$2),
              selected: selected,
              selectedColor: Colors.amber,
              labelStyle: TextStyle(color: selected ? Colors.black : Colors.white70),
              backgroundColor: const Color(0xFF1A1A1A),
              onSelected: (_) => onChanged(opt.$1),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildItemCard(CoinHistoryItem item) {
    final dt = DateTime.fromMillisecondsSinceEpoch(item.createdAt);
    final dateStr =
        "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}  "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

    final coinLabel = _labelCoin(item.coinType);
    final actionLabel = _labelAction(item.action);

    final sign = (item.action == "use" || item.action == "transfer_out") ? "-" : "+";
    final amountText = "$sign${item.amount} $coinLabel";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Icon(_iconAction(item.action, item.coinType), color: Colors.amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  amountText,
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "Saldo setelah: BTC ${item.balanceAfterBtc} • LTC ${item.balanceAfterLtc}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.note,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}