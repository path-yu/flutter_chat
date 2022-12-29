import 'package:flutter/material.dart';
import 'package:flutter_chat/components/common.dart';

class BaseTextFormFiled extends StatefulWidget {
  final String? Function(String?)? validator;
  final String? hintText;
  final IconData? prefixIcon;
  final void Function(String?)? onChanged;
  final bool? obscureText;
  final void Function(String value)? onEditingComplete;
  final TextInputAction? textInputAction;
  final String? labelText;
  final String? initialValue;
  final int? maxLines;
  final TextInputType? keyboardType;
  const BaseTextFormFiled(
      {super.key,
      this.prefixIcon,
      this.hintText,
      this.validator,
      this.onChanged,
      this.obscureText = false,
      this.onEditingComplete,
      this.labelText,
      this.initialValue = '',
      this.maxLines,
      this.textInputAction,
      this.keyboardType});

  @override
  State<BaseTextFormFiled> createState() => _BaseTextFormFiledState();
}

class _BaseTextFormFiledState extends State<BaseTextFormFiled> {
  final TextEditingController _controller = TextEditingController();

  String value = '';
  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      value = widget.initialValue!;
    }
    _controller.text = value;

    _controller.addListener(() {
      setState(() => value = _controller.text);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      obscureText: widget.obscureText!,
      validator: widget.validator,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onEditingComplete: () {
        widget.onEditingComplete!(_controller.text);
      },
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
          labelText: widget.labelText,
          suffixIcon: value.isNotEmpty
              ? buildClearInputIcon((() {
                  _controller.clear();
                  if (widget.onChanged != null) {
                    widget.onChanged!('');
                  }
                }))
              : null,
          hintText: widget.hintText,
          prefixIcon:
              widget.prefixIcon != null ? buildIcon(widget.prefixIcon!) : null),
    );
  }
}
