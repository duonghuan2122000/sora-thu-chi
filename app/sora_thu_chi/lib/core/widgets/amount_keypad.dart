import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Numpad số tiền của màn thêm giao dịch (mockup `02`, R6) — VND số nguyên:
/// 3×4 phím tròn viền; hàng cuối trái phím `,` (no-op — phần thập phân là
/// quyết định sau), giữa `0`, phải backspace. Số tiền là trạng thái ở màn cha,
/// keypad chỉ báo qua callback — không chứa TextField.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

  static const double _rowHeight = 58;
  static const double _diameter = 52;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowHeight * 4,
      child: Column(
        children: [
          _keyRow(['1', '2', '3']),
          _keyRow(['4', '5', '6']),
          _keyRow(['7', '8', '9']),
          _keyRowCommaZeroBackspace(),
        ],
      ),
    );
  }

  Widget _keyRow(List<String> labels) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          for (final label in labels)
            Expanded(
              child: Center(
                child: _digitKey(label, enabled: label != ','),
              ),
            ),
        ],
      ),
    );
  }

  /// Hàng cuối: `,` (no-op) | `0` | backspace.
  Widget _keyRowCommaZeroBackspace() {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          Expanded(child: Center(child: _digitKey(',', enabled: false))),
          Expanded(child: Center(child: _digitKey('0', enabled: true))),
          Expanded(
            child: Center(
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: const ValueKey('keypad-backspace'),
                  onTap: onBackspace,
                  child: SizedBox(
                    width: _diameter,
                    height: _diameter,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: const Icon(
                        Icons.backspace_outlined,
                        color: AppColors.textPrimary,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Phím tròn viền: số tô đậm; `,` màu nhạt **no-op** (số nguyên VND).
  Widget _digitKey(String label, {required bool enabled}) {
    final digit = int.tryParse(label);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled && digit != null ? () => onDigit(digit) : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: _diameter,
          height: _diameter,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled ? AppColors.divider : AppColors.tabInactive,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: enabled ? FontWeight.w600 : FontWeight.w400,
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.tabInactive.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
