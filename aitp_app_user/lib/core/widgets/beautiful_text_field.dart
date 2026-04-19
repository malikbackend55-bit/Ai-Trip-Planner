import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A clean shared input used across auth and form screens.
class BeautifulTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final IconData? icon;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final bool isPassword;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool showGradient;
  final bool showShadow;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double borderRadius;
  final double elevation;
  final Duration animationDuration;
  final Curve animationCurve;

  const BeautifulTextField({
    super.key,
    required this.label,
    this.hintText,
    this.icon,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.isPassword = false,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.showGradient = false,
    this.showShadow = false,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.borderRadius = 16,
    this.elevation = 0,
    this.animationDuration = const Duration(milliseconds: 180),
    this.animationCurve = Curves.easeOut,
  });

  @override
  State<BeautifulTextField> createState() => _BeautifulTextFieldState();
}

class _BeautifulTextFieldState extends State<BeautifulTextField> {
  late final FocusNode _focusNode;
  late bool _obscureText;

  bool get _isFocused => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    _obscureText = widget.isPassword;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor =
        widget.fillColor ?? (isDark ? const Color(0xff101917) : Colors.white);
    final borderColor =
        widget.borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xffd5ddd8));
    final focusedBorderColor =
        widget.focusedBorderColor ?? theme.colorScheme.primary;
    final radius = BorderRadius.circular(widget.borderRadius);

    OutlineInputBorder outline(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _isFocused
                ? focusedBorderColor
                : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.84),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: widget.animationDuration,
          curve: widget.animationCurve,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: widget.showShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.10 : 0.04,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            focusNode: _focusNode,
            controller: widget.controller,
            obscureText: widget.isPassword ? _obscureText : false,
            enabled: widget.enabled,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            maxLines: widget.expands
                ? null
                : (widget.isPassword ? 1 : widget.maxLines),
            minLines: widget.expands ? null : widget.minLines,
            expands: widget.expands,
            textCapitalization: widget.textCapitalization,
            autofocus: widget.autofocus,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText ?? widget.label,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.55,
                ),
              ),
              filled: true,
              fillColor: fillColor,
              prefixIcon: _buildLeading(theme, focusedBorderColor),
              suffixIcon: _buildTrailing(theme, focusedBorderColor),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              enabledBorder: outline(borderColor),
              focusedBorder: outline(focusedBorderColor, width: 1.4),
              disabledBorder: outline(borderColor.withValues(alpha: 0.65)),
              errorBorder: outline(theme.colorScheme.error),
              focusedErrorBorder: outline(theme.colorScheme.error, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildLeading(ThemeData theme, Color focusedBorderColor) {
    if (widget.prefixIcon != null) {
      return widget.prefixIcon;
    }

    if (widget.icon == null) {
      return null;
    }

    return Icon(
      widget.icon,
      size: 20,
      color: _isFocused
          ? focusedBorderColor
          : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.62),
    );
  }

  Widget? _buildTrailing(ThemeData theme, Color focusedBorderColor) {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    if (!widget.isPassword) {
      return null;
    }

    return IconButton(
      onPressed: _togglePasswordVisibility,
      splashRadius: 18,
      icon: Icon(
        _obscureText
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        size: 20,
        color: _isFocused
            ? focusedBorderColor
            : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.62),
      ),
    );
  }
}

extension BeautifulTextFieldExtension on Widget {
  Widget withBeautifulFieldStyling({
    bool showShadow = false,
    double borderRadius = 16,
    double elevation = 4,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation * 0.5),
                ),
              ]
            : null,
      ),
      child: this,
    );
  }
}
