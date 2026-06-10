import 'package:flutter/material.dart';
import '../core/theme.dart';

class HamsaInput extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool autofocus;
  final TextDirection? textDirection;
  final int? maxLines;

  const HamsaInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffix,
    this.autofocus = false,
    this.textDirection,
    this.maxLines = 1,
  });

  @override
  State<HamsaInput> createState() => _HamsaInputState();
}

class _HamsaInputState extends State<HamsaInput> {
  bool _focused = false;
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final isObscure = widget.obscure && _obscured;
    // Arabic/RTL fields must use the Noor font — Peignot (body) has no
    // Arabic glyphs, so typed Arabic would render blank.
    final isRtl = widget.textDirection == TextDirection.rtl;
    final inputStyle = isRtl
        ? HamsaText.arabic(size: 15, color: HamsaColors.cream)
        : HamsaText.body(size: 15, color: HamsaColors.cream);

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused
                ? HamsaColors.greenAccent.withValues(alpha: 0.8)
                : HamsaColors.border,
            width: _focused ? 1.5 : 1,
          ),
          color: HamsaColors.inputBg,
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: isObscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          autofocus: widget.autofocus,
          maxLines: widget.maxLines,
          textDirection: widget.textDirection,
          style: inputStyle,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _focused
                        ? HamsaColors.greenAccent
                        : HamsaColors.muted,
                    size: 20,
                  )
                : null,
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: HamsaColors.muted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : widget.suffix,
            labelStyle: HamsaText.body(
              size: 13,
              color: _focused ? HamsaColors.greenAccent : HamsaColors.muted,
            ),
            hintStyle: HamsaText.body(size: 14, color: HamsaColors.subtle),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
          ),
        ),
      ),
    );
  }
}
