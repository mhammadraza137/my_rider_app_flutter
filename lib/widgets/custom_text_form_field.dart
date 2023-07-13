import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../utils/dimensions.dart';

class CustomTextFormField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final TextInputType textInputType;
  final bool obscureText;
  final Widget suffixIcon;
  final TextInputAction textInputAction;
  final String? Function(String?)? validate;
  final TextEditingController textEditingController;
  const CustomTextFormField(
      {Key? key,
      required this.labelText,
      required this.hintText,
      required this.textInputType,
      this.obscureText = false,
      this.suffixIcon = const SizedBox(),
      required this.textInputAction,
      required this.validate,
      required this.textEditingController
      })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: textInputType,
      obscureText: obscureText,
      controller: textEditingController,
      decoration: InputDecoration(
          fillColor: textFieldBgColor,
          filled: true,
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5)),
          labelText: labelText,
          labelStyle: TextStyle(
              color: textFieldLabelColor,
              fontSize: MediaQuery.of(context).size.width * textFieldLabelSize),
          hintText: hintText,
          hintStyle: TextStyle(
              color: textFieldHintColor,
              fontSize: MediaQuery.of(context).size.width * textFieldHintSize),
          suffixIcon: suffixIcon,
          errorMaxLines: 2),
      style: TextStyle(
          fontSize: MediaQuery.of(context).size.width* textFieldTextSize),
      textInputAction: textInputAction,
      validator: validate,

    );
  }
}
