import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rider_app/utils/dimensions.dart';

class CustomScrollingText extends StatefulWidget {
  final String text;
  const CustomScrollingText({Key? key, required this.text, }) : super(key: key);

  @override
  State<CustomScrollingText> createState() => _CustomScrollingTextState();
}

class _CustomScrollingTextState extends State<CustomScrollingText> {
  final GlobalKey _key = GlobalKey();
  late final ScrollController _scrollController;
  late Timer timer;
  int timerRest = 200;
  bool reverseScroll = false;
  final double _moveDistance = 3.0;
  double position = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if(_scrollController.hasClients) {
        startTimer();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    timer.cancel();
  }

  startTimer() {
      timer = Timer.periodic(Duration(milliseconds: timerRest), (timer) async{
          double maxScrollExtent = _scrollController.position.maxScrollExtent;
          double scrollPosition = _scrollController.position.pixels;
          if (scrollPosition >= maxScrollExtent || reverseScroll) {
            reverseScroll = true;
            if(scrollPosition <= 0){
              position = 0;
              reverseScroll = false;
              // await Future.delayed(const Duration(seconds: 1));
              if(_scrollController.hasClients) {
                _scrollController.jumpTo(position);
                // position += _moveDistance;
                _scrollController.animateTo(position,
                    duration: Duration(milliseconds: timerRest),
                    curve: Curves.linear);
              }
            }
            else if(scrollPosition > maxScrollExtent){
              if(_scrollController.hasClients){
                position = maxScrollExtent;
                _scrollController.jumpTo(position);
                _scrollController.animateTo(position, duration: Duration(milliseconds: timerRest), curve: Curves.linear);
              }
            }
            else{

              // await Future.delayed(const Duration(seconds: 1));
              if(_scrollController.hasClients) {
                // _scrollController.jumpTo(position);
                position -= _moveDistance;
                _scrollController.animateTo(
                    position, duration: Duration(milliseconds: timerRest),
                    curve: Curves.linear);
              }
            }
          } else {
            _scrollController.jumpTo(position);
            position += _moveDistance;
            _scrollController.animateTo(position,
                duration: Duration(milliseconds: timerRest),
                curve: Curves.linear);
          }
      });
      }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: _key,
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Text(
          widget.text,
          style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * textFieldTextSize),
        )
      ],
    );
  }
}
