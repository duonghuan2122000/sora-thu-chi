import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/money_format.dart';
import '../core/wallet/wallet.dart';
import '../core/wallet/wallet_controller.dart';
import '../core/wallet/wallet_presets.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../theme/app_colors.dart';

/// Nhãn chip ngắn cho 5 loại ví (khác [WalletTypeLabelX.label] dài cho dòng phụ).
const List<(WalletType, String)> _typeChipLabels = [
  (WalletType.cash, 'Tiền mặt'),
  (WalletType.bank, 'Ngân hàng'),
  (WalletType.credit, 'Thẻ tín dụng'),
  (WalletType.eWallet, 'Ví điện tử'),
  (WalletType.savings, 'Sổ tiết kiệm'),
];

/// Form dùng chung 2 chế độ Thêm/Sửa ví (FR-001/002/009/010/011).
/// [wallet] == null → chế độ thêm; != null → chế độ sửa (nạp sẵn giá trị).
/// [hasTransactions] chỉ chế độ sửa: true → khóa Loại ví/Số dư ban đầu/Tiền tệ
/// (FR-010), còn tên/icon/màu/trường riêng/cờ mặc định sửa được.
class WalletFormScreen extends StatefulWidget {
  const WalletFormScreen({
    super.key,
    this.wallet,
    this.hasTransactions = false,
    required this.controller,
  });

  final Wallet? wallet;
  final bool hasTransactions;
  final WalletController controller;

  @override
  State<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends State<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Wallet? _existing;
  bool get _isAdd => _existing == null;

  /// Khóa Loại ví/Số dư ban đầu/Tiền tệ khi sửa ví đã có giao dịch.
  bool get _locked => !_isAdd && widget.hasTransactions;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _creditLimitCtrl;
  late final TextEditingController _termCtrl;
  late final TextEditingController _institutionCtrl;
  late final TextEditingController _lastDigitsCtrl;

  late WalletType _type;
  late String _icon;
  late int _colorValue;
  late bool _wantDefault;
  DateTime? _statementDate;
  DateTime? _dueDate;
  DateTime? _maturityDate;

  bool get _isCredit => _type == WalletType.credit;
  bool get _isSavings => _type == WalletType.savings;
  bool get _isBankOrEwallet =>
      _type == WalletType.bank || _type == WalletType.eWallet;

  @override
  void initState() {
    super.initState();
    final existing = widget.wallet;
    _existing = existing;
    _type = existing?.type ?? WalletType.cash;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _balanceCtrl = TextEditingController(
      text: existing == null ? '' : '${existing.initialBalanceValue}',
    );
    _icon = existing?.icon ?? defaultIconFor(_type);
    _colorValue = existing?.color ?? defaultColorValueFor(_type);
    _wantDefault = existing?.isDefault ?? false;
    _creditLimitCtrl = TextEditingController(
      text: existing?.creditLimit?.toString() ?? '',
    );
    _statementDate = existing?.statementDate;
    _dueDate = existing?.dueDate;
    _termCtrl = TextEditingController(
      text: existing?.termMonths?.toString() ?? '',
    );
    _maturityDate = existing?.maturityDate;
    _institutionCtrl = TextEditingController(
      text: existing?.institutionName ?? '',
    );
    _lastDigitsCtrl = TextEditingController(
      text: existing?.lastDigits ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _creditLimitCtrl.dispose();
    _termCtrl.dispose();
    _institutionCtrl.dispose();
    _lastDigitsCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(WalletType next) {
    if (_type == next) return;
    setState(() {
      _type = next;
      // Đổi loại → bỏ trường riêng loại cũ, về icon/màu mặc định loại mới.
      _creditLimitCtrl.clear();
      _statementDate = null;
      _dueDate = null;
      _termCtrl.clear();
      _maturityDate = null;
      _institutionCtrl.clear();
      _lastDigitsCtrl.clear();
      _icon = defaultIconFor(next);
      _colorValue = defaultColorValueFor(next);
    });
  }

  /// Không được tắt cờ mặc định khi ví này là default duy nhất còn hoạt động.
  bool get _cannotTurnOffDefault {
    if (_isAdd || !_existing!.isDefault) return false;
    final active = widget.controller.wallets.where((w) => !w.isHidden).length;
    return active <= 1;
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên ví';
    return null;
  }

  String? _validateInitialBalance(String? v) {
    if (_locked) return null;
    if (v == null || v.trim().isEmpty) {
      return _isAdd ? 'Vui lòng nhập số dư ban đầu' : null;
    }
    if (int.tryParse(v.trim()) == null) return 'Số tiền không hợp lệ';
    return null;
  }

  String? _validateCreditLimit(String? v) {
    final value = int.tryParse(v?.trim() ?? '');
    if (value == null || value <= 0) return 'Hạn mức phải lớn hơn 0';
    return null;
  }

  int _parse(String? v) => int.tryParse((v ?? '').trim()) ?? 0;

  Wallet _buildWallet() {
    final existing = _existing;
    final balanceValue = _locked
        ? existing!.balance
        : _parse(_balanceCtrl.text);
    final initialValue = _locked
        ? existing!.initialBalanceValue
        : _parse(_balanceCtrl.text);

    final creditLimit = _isCredit ? _parse(_creditLimitCtrl.text) : null;
    final termMonths = _isSavings ? _parse(_termCtrl.text) : null;
    final institution = _isBankOrEwallet && _institutionCtrl.text.trim().isNotEmpty
        ? _institutionCtrl.text.trim()
        : null;
    final lastDigits = _isBankOrEwallet && _lastDigitsCtrl.text.trim().isNotEmpty
        ? _lastDigitsCtrl.text.trim()
        : null;

    final base = Wallet(
      id: existing?.id ?? 0,
      name: _nameCtrl.text.trim(),
      type: _type,
      icon: _icon,
      initialBalance: initialValue,
      balance: balanceValue,
      currency: 'VND',
      color: _colorValue,
      isDefault: existing?.isDefault ?? false,
      isHidden: existing?.isHidden ?? false,
      sortOrder: existing?.sortOrder ?? 0,
      creditLimit: creditLimit,
      creditUsed: existing?.creditUsed,
      statementDate: _isCredit ? _statementDate : null,
      dueDate: _isCredit ? _dueDate : null,
      termMonths: termMonths,
      maturityDate: _isSavings ? _maturityDate : null,
      institutionName: institution,
      lastDigits: lastDigits,
    );
    return base;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final wallet = _buildWallet();
    try {
      final saved = _isAdd
          ? await widget.controller.create(wallet, wantDefault: _wantDefault)
          : await widget.controller.updateWallet(
              wallet,
              wantDefault: _wantDefault,
            );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      // FR-014: báo lỗi, giữ nguyên dữ liệu đã nhập.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không lưu được ví. Vui lòng thử lại.'),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isAdd ? 'Thêm ví mới' : 'Sửa ví';
    return SubPageScaffold(
      title: title,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: _save,
              child: const Text('Lưu ví'),
            ),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (_locked) const _LockedNote(),
              _fieldLabel('Tên ví'),
              TextFormField(
                key: const ValueKey('field-name'),
                controller: _nameCtrl,
                decoration: _decoration(hint: 'VD: Tiền mặt, Vietcombank…'),
                textInputAction: TextInputAction.next,
                validator: _validateName,
              ),
              const SizedBox(height: 20),
              _fieldLabel('Loại ví'),
              if (_locked)
                _ReadonlyValue(_typeChipLabel(_type))
              else
                _TypeChips(
                  selected: _type,
                  onChanged: _onTypeChanged,
                ),
              const SizedBox(height: 20),
              _fieldLabel(_isAdd ? 'Số dư ban đầu' : 'Số dư'),
              if (_locked)
                _ReadonlyValue(formatMoney(_existing!.initialBalanceValue))
              else
                TextFormField(
                  key: const ValueKey('field-balance'),
                  controller: _balanceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration(suffix: 'đ'),
                  validator: _validateInitialBalance,
                ),
              const SizedBox(height: 4),
              _currencyLine(),
              const SizedBox(height: 20),
              if (_isCredit) ..._creditFields(),
              if (_isSavings) ..._savingsFields(),
              if (_isBankOrEwallet) ..._bankFields(),
              _fieldLabel('Biểu tượng & màu sắc'),
              const SizedBox(height: 8),
              _IconPicker(selected: _icon, onChanged: (v) => setState(() => _icon = v)),
              const SizedBox(height: 12),
              _ColorPicker(
                selected: _colorValue,
                onChanged: (v) => setState(() => _colorValue = v),
              ),
              const SizedBox(height: 20),
              _DefaultSwitch(
                value: _wantDefault,
                disabled: _cannotTurnOffDefault,
                onChanged: (v) {
                  if (v == false && _cannotTurnOffDefault) return;
                  setState(() => _wantDefault = v);
                },
                lockedHint: _cannotTurnOffDefault,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _typeChipLabel(WalletType type) => _typeChipLabels
      .firstWhere((e) => e.$1 == type)
      .$2;

  List<Widget> _creditFields() => [
    _fieldLabel('Hạn mức tín dụng'),
    TextFormField(
      key: const ValueKey('field-credit-limit'),
      controller: _creditLimitCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _decoration(suffix: 'đ'),
      validator: _validateCreditLimit,
    ),
    const SizedBox(height: 4),
    _DateField(
      label: 'Ngày sao kê (tùy chọn)',
      value: _statementDate,
      onPick: _pickDate((d) => setState(() => _statementDate = d)),
      onClear: () => setState(() => _statementDate = null),
    ),
    _DateField(
      label: 'Ngày đến hạn (tùy chọn)',
      value: _dueDate,
      onPick: _pickDate((d) => setState(() => _dueDate = d)),
      onClear: () => setState(() => _dueDate = null),
    ),
    const SizedBox(height: 12),
  ];

  List<Widget> _savingsFields() => [
    _fieldLabel('Kỳ hạn (tháng, tùy chọn)'),
    TextFormField(
      key: const ValueKey('field-term'),
      controller: _termCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _decoration(suffix: 'tháng'),
    ),
    _DateField(
      label: 'Ngày đáo hạn (tùy chọn)',
      value: _maturityDate,
      onPick: _pickDate((d) => setState(() => _maturityDate = d)),
      onClear: () => setState(() => _maturityDate = null),
    ),
    const SizedBox(height: 12),
  ];

  List<Widget> _bankFields() {
    final orgLabel = _type == WalletType.eWallet ? 'Tổ chức' : 'Ngân hàng';
    return [
      _fieldLabel('$orgLabel (tùy chọn)'),
      TextFormField(
        key: const ValueKey('field-institution'),
        controller: _institutionCtrl,
        decoration: _decoration(
          hint: _type == WalletType.eWallet
              ? 'VD: Momo, ZaloPay…'
              : 'VD: Vietcombank…',
        ),
      ),
      const SizedBox(height: 12),
      _fieldLabel('Số cuối tài khoản (tùy chọn)'),
      TextFormField(
        key: const ValueKey('field-last-digits'),
        controller: _lastDigitsCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: _decoration(hint: 'Vài số cuối, chỉ để đối chiếu'),
      ),
      const SizedBox(height: 12),
    ];
  }

  InputDecoration _decoration({String? hint, String? suffix}) => InputDecoration(
    hintText: hint,
    suffixText: suffix,
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  VoidCallback _pickDate(ValueChanged<DateTime?> onPicked) {
    return () async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime(now.year, now.month, now.day),
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year + 20),
      );
      if (picked != null) onPicked(picked);
    };
  }

  Widget _currencyLine() => const Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text(
        'Tiền tệ: VND',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    ],
  );
}

class _LockedNote extends StatelessWidget {
  const _LockedNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tealLightBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.teal),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ví đã có giao dịch nên không đổi được loại ví và số dư ban đầu. '
              'Muốn đổi số dư → tạo giao dịch Điều chỉnh số dư.',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadonlyValue extends StatelessWidget {
  const _ReadonlyValue(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.softCardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),
    );
  }
}

/// Nhãn mục nhỏ xám (bên trên từng trường).
Widget _fieldLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(
    text,
    style: const TextStyle(
      color: AppColors.listLabel,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  ),
);

class _TypeChips extends StatelessWidget {
  const _TypeChips({required this.selected, required this.onChanged});

  final WalletType selected;
  final ValueChanged<WalletType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (type, label) in _typeChipLabels)
          ChoiceChip(
            label: Text(label),
            selected: type == selected,
            onSelected: (_) => onChanged(type),
            selectedColor: AppColors.teal,
            labelStyle: TextStyle(
              color: type == selected ? AppColors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            backgroundColor: AppColors.softCardBg,
            showCheckmark: false,
            side: const BorderSide(color: Colors.transparent),
          ),
      ],
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final icon in walletIconChoices)
          InkWell(
            onTap: () => onChanged(icon),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: icon == selected
                    ? AppColors.tealLightBg
                    : AppColors.softCardBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: icon == selected ? AppColors.teal : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in walletPresetColors)
          InkWell(
            onTap: () => onChanged(color.toARGB32()),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.toARGB32() == selected
                      ? AppColors.textPrimary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: color.toARGB32() == selected
                  ? const Icon(Icons.check, size: 16, color: AppColors.white)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value == null ? 'Chọn ngày' : _fmt(value!),
                  style: TextStyle(
                    color: value == null
                        ? AppColors.tabInactive
                        : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              if (value != null)
                InkWell(
                  onTap: onClear,
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.tabInactive,
                  ),
                )
              else
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.tabInactive,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultSwitch extends StatelessWidget {
  const _DefaultSwitch({
    required this.value,
    required this.disabled,
    required this.onChanged,
    required this.lockedHint,
  });

  final bool value;
  final bool disabled;
  final ValueChanged<bool> onChanged;
  final bool lockedHint;

  @override
  Widget build(BuildContext context) {
    // Dùng Material (không phải Container/DecoratedBox màu) để ink của
    // ListTile không bị che — tránh debug exception của Flutter.
    return Material(
      color: AppColors.softCardBg,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            value: value,
            onChanged: disabled ? null : onChanged,
            activeTrackColor: AppColors.teal,
            title: const Text(
              'Đặt làm ví mặc định',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (lockedHint)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'Ví này là ví mặc định duy nhất đang hoạt động nên không thể tắt.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
