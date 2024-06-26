import 'package:flutter/material.dart';
import 'dart:async';

import 'package:test_drive/Animazioni.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  bool _isStarted = false;
  bool _isLooping = false;
  int _currentFrame = 0;
  late Timer _loopTimer;
  Animazioni thinking = new Animazioni(1, 36, 8, 400, 50);
  Animazioni speaking = new Animazioni(37, 49, 38, 50, 50);
  String _textToShow="Testo iniziale";
  List<String> _words = [];
  late AnimationController _textController;
  late Animation<int> _wordAnimation;

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    _words = _textToShow.split(' ');
    _wordAnimation = IntTween(begin: 0, end: _words.length).animate(_textController)
      ..addListener(() {
        setState(() {});
      });
  }

  void _initializeAnimation(Animazioni animazione) {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: animazione.durationfirstpart), // Durata della prima parte dell'animazione
    );

    _animation = IntTween(begin: animazione.firstFrame, end: animazione.startLoop).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isLooping = true;
          });
          _startLoop(animazione);
        }
      })
      ..addListener(() {
        setState(() {
          _currentFrame = _animation.value;
        });
      });
  }

  void _startLoop(Animazioni animazione) {
    _loopTimer = Timer.periodic(Duration(milliseconds: animazione.durationloop), (timer) {
      if (!_isLooping && (_currentFrame - animazione.startLoop + 1) % (animazione.lastFrame - animazione.startLoop) == 0) {
        timer.cancel();
        _startReverseAnimation(animazione);
      } else {
        setState(() {
          _currentFrame = animazione.startLoop + ((_currentFrame - animazione.startLoop + 1) % (animazione.lastFrame - animazione.startLoop)); // Loop da 13 a 48
        });
      }
    });
  }

  void _startReverseAnimation(Animazioni animazione) {
    _controller.reverse(from: animazione.startLoop.toDouble()).then((_) {
      setState(() {
        _isStarted = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _loopTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _startAnimation(Animazioni animazione) {
    setState(() {
      _isStarted = true;
      _isLooping = false;
      _currentFrame = 0; // Reset the frame to 0 when starting
    });
    _initializeAnimation(animazione);
    _controller.forward(from: 0);
  }

  void _stopLoop() {
    setState(() {
      _isLooping = false;
    });
  }

  void _setLoopDuration(Animazioni animazione, int numero) {
    animazione.SetDurationLoop(numero);
  }

  void _updateText(String newText) {
    setState(() {
      _textToShow = newText;
      _words = _textToShow.split(' ');
      _wordAnimation = IntTween(begin: 0, end: _words.length).animate(_textController);
      _textController.reset();
      _textController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GIF Player'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: _isStarted
                    ? Image.asset(
                  'assets/Frame/${_currentFrame + 1}.png',
                  gaplessPlayback: true,
                )
                    : Image.asset(
                  'assets/Frame/1.png',
                  gaplessPlayback: true,
                ),
              ),
            ),
            SizedBox(height: 40),
            Text(
              _textToShow,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 5),
                ElevatedButton(
                  onPressed: _isStarted ? null : () => _startAnimation(speaking),
                  child: Text('Speaking'),
                ),
                SizedBox(width: 5),
                ElevatedButton(
                  onPressed: _isLooping ? _stopLoop : null,
                  child: Text('Stop'),
                ),
                SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () => _updateText("Prova testo credo vada"),
                  child: Text('Update Text'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
