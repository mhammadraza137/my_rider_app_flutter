import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {
  final String dialogText;
  const ProgressDialog({Key? key, required this.dialogText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.height*0.03),
        child: Row(
          children: [
            SizedBox(width: MediaQuery.of(context).size.width*0.01,),
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black),),
            SizedBox(width: MediaQuery.of(context).size.width*0.03,),
            Expanded(
              child: Text(dialogText,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: MediaQuery.of(context).size.width*0.04
                ),
                maxLines: 2,
              ),
            )
          ],
        ),
      ),
    );
  }
}
