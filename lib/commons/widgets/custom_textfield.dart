// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/commons/widgets/inner_shadow.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';

// App-styled text input with inner-shadow frame and optional
// show/hide-password toggle when obscureText is set.
class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final Color? hintColor;
  final Color? textColor;
  final Widget? prefixIconWidget;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool obscureText;

  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.hintColor,
    this.prefixIconWidget,
    this.prefixIcon,
    this.textColor,
    this.validator,
    this.obscureText = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  // Tracks the current visibility toggle, seeded from the initial obscureText.
  late bool _obscureText = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return InnerShadowContainer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.sizes.xs),
        child: TextFormField(
          textAlignVertical:
              widget.prefixIcon != null ? TextAlignVertical.center : null,
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _obscureText,
          style: TextStyle(
            color: widget.textColor ?? AppColors.white,
          ),
          decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: widget.hintColor ?? Colors.grey,
              ),
              prefixIcon: widget.prefixIconWidget ??
                  (widget.prefixIcon != null ? Icon(widget.prefixIcon) : null),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: widget.hintColor ?? Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    )
                  : null),
        ),
      ),
    );
  }
}
