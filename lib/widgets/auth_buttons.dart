import 'package:flutter/material.dart';
import 'package:rider_app/utils/colors.dart';

import '../utils/dimensions.dart';

class AuthButton extends StatelessWidget {
  final void Function()? onPressed;
  final String buttonTitle;
  const AuthButton({Key? key, required this.onPressed, required this.buttonTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width*authButtonBorderRadius),
          )
          ),
        backgroundColor: const MaterialStatePropertyAll(authButtonColor),
      ),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height*authButtonsHeight,
        child: Center(
          child: Text(buttonTitle,
            style: TextStyle(
                fontSize: MediaQuery.of(context).size.width*authButtonTextSize
            ),
          ),
        ),
      ),
    );
  }
}
