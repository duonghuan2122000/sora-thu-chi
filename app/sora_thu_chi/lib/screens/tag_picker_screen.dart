import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/transaction/transaction_detail.dart';
import '../data/wallet_deps.dart';
import '../data/wallet_repository.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

/// Màn "Chọn tag" (mockup v2, PBI 38, chốt 2B) — danh sách tag đã từng dùng
/// (suy từ toàn bộ giao dịch qua [distinctTags], không có bảng `tags` riêng)
/// + ô tạo tag mới tại chỗ. Chọn được nhiều tag (chip bật/tắt), xác nhận
/// `pop(List<String>)`. Theo khuôn `CategoryPickerScreen` — Scaffold riêng,
/// không bottom nav.
class TagPickerScreen extends StatefulWidget {
  const TagPickerScreen({
    super.key,
    this.repository,
    this.initialSelected = const [],
  });

  /// Seam test: mặc định null → [ensureWalletRepository] khi vào (R11).
  final WalletRepository? repository;

  /// Tag đã gắn sẵn trên giao dịch (mở lại màn để sửa) — tick sẵn khi vào.
  final List<String> initialSelected;

  @override
  State<TagPickerScreen> createState() => _TagPickerScreenState();
}

class _TagPickerScreenState extends State<TagPickerScreen> {
  late final WalletRepository _repository;
  final TextEditingController _newTagCtrl = TextEditingController();
  bool _loading = true;
  final List<String> _allTags = [];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ensureWalletRepository();
    _selected.addAll(widget.initialSelected);
    _load();
  }

  @override
  void dispose() {
    _newTagCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final transactions = await _repository.allTransactions();
      if (!mounted) return;
      final tags = distinctTags(transactions);
      setState(() {
        _allTags
          ..clear()
          ..addAll(_mergedWithSelected(tags));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allTags
          ..clear()
          ..addAll(_mergedWithSelected(const []));
        _loading = false;
      });
    }
  }

  /// Tag đã chọn sẵn (mở lại để sửa) nhưng không nằm trong gợi ý — vẫn hiện
  /// để không "mất" lựa chọn cũ khi vào lại màn.
  List<String> _mergedWithSelected(List<String> tags) {
    final merged = [...tags];
    final lower = tags.map((t) => t.toLowerCase()).toSet();
    for (final s in widget.initialSelected) {
      if (lower.add(s.toLowerCase())) merged.add(s);
    }
    return merged;
  }

  void _toggle(String tag) {
    setState(() {
      if (!_selected.remove(tag)) _selected.add(tag);
    });
  }

  /// Tạo tag mới tại chỗ (FR-005) — chặn tên rỗng/toàn khoảng trắng, không tạo
  /// trùng với tag đã có (so sánh không phân biệt hoa/thường); tag mới tự chọn.
  void _addNewTag() {
    final name = _newTagCtrl.text.trim();
    if (name.isEmpty) return;
    final exists = _allTags.any((t) => t.toLowerCase() == name.toLowerCase());
    setState(() {
      if (!exists) _allTags.add(name);
      final canonical = exists
          ? _allTags.firstWhere((t) => t.toLowerCase() == name.toLowerCase())
          : name;
      _selected.add(canonical);
      _newTagCtrl.clear();
    });
  }

  void _confirm() {
    Navigator.of(context).pop(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Chọn tag'.tr)),
      body: SafeArea(top: false, child: _body(colors)),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey('confirm-tags'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _confirm,
              child: Text('Xác nhận'.tr),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(SoraColors colors) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('new-tag-field'),
                controller: _newTagCtrl,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Tạo tag mới'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (_) => _addNewTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const ValueKey('add-tag-button'),
              icon: const Icon(Icons.add),
              onPressed: _addNewTag,
              color: colors.tealOnNeutral,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_allTags.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Chưa có tag nào — tạo tag mới ở ô trên.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _allTags)
                FilterChip(
                  label: Text(tag),
                  selected: _selected.contains(tag),
                  selectedColor: colors.tealLightBg,
                  onSelected: (_) => _toggle(tag),
                ),
            ],
          ),
      ],
    );
  }
}
