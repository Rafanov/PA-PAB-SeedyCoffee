import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

// Global emoji-blocking formatter - use everywhere except notes/promo
final _emojiBlockFormatter = TextInputFormatter.withFunction((oldVal, newVal) {
  final cleaned = newVal.text.replaceAll(RegExp(r'[^ -~]'), '');
  if (cleaned == newVal.text) return newVal;
  return newVal.copyWith(
    text: cleaned,
    selection: TextSelection.collapsed(offset: cleaned.length),
  );
});

class BrewTextField extends StatefulWidget {
  final String label, hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final Widget? prefixIcon;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const BrewTextField({
    super.key, required this.label, required this.hint,
    required this.controller, this.isPassword = false,
    this.keyboardType = TextInputType.text, this.validator,
    this.maxLines = 1, this.prefixIcon, this.onChanged,
    this.inputFormatters,
  });

  @override
  State<BrewTextField> createState() => _State();
}

class _State extends State<BrewTextField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.label.toUpperCase(), style: AppTextStyles.labelSmall),
      const SizedBox(height: 6),
      TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType,
        maxLines: widget.isPassword ? 1 : widget.maxLines,
        validator: widget.validator,
        onChanged: widget.onChanged,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textMuted, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure))
              : null,
        ),
      ),
    ],
  );
}