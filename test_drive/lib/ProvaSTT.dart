import 'package:flutter/material.dart';
import 'dart:async';
import 'package:test_drive/Animazioni.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Kanit'),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late FlutterTts flutterTts;
  late AnimationController _controller;
  late Animation<int> _animation;
  bool _isStarted = false;
  bool _isLooping = false;
  int _currentFrame = 0;
  late Timer _loopTimer;
  Animazioni thinking = Animazioni(1, 36, 8, 400, 50); // Example Animazioni class initialization
  Animazioni speaking = Animazioni(37, 49, 38, 50, 50); // Example Animazioni class initialization
  String _textToShow =
      "Ciao sono TOTAI!\n Chiedimi pure qualsiasi informazione sui deodoranti";
  late AnimationController _textController;
  late Animation<int> _letterAnimation;
  TextEditingController _textEditingController = TextEditingController();
  stt.SpeechToText _speech = stt.SpeechToText();

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _initializeTts();

    _textController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _textToShow.length * 50), // Faster speed
    );
    _letterAnimation = IntTween(begin: 0, end: _textToShow.length).animate(_textController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _stopAnimation();
        }
      });

    // Start text animation
    _textController.forward();
    _speak(_textToShow);

    // Start speaking animation
    _startAnimation(speaking);
  }

  void _initializeTts() async {
    await flutterTts.setLanguage("it-IT");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    // Imposta una voce specifica (sostituisci con una voce disponibile)
    /*await flutterTts.setVoice({
      'name': 'it-it-x-kda-network',
    });*/
  }

  String _replaceTotai(String text) {
    return text.replaceAll('TOTAI', 'Totai');
  }

  Future<void> _speak(String text) async {
    String processedText = _replaceTotai(text);
    await flutterTts.speak(processedText);
  }

  void _initializeAnimation(Animazioni animazione) {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: animazione.durationfirstpart),
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
          _currentFrame = animazione.startLoop + ((_currentFrame - animazione.startLoop + 1) % (animazione.lastFrame - animazione.startLoop));
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
    _textEditingController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _startAnimation(Animazioni animazione) {
    setState(() {
      _isStarted = true;
      _isLooping = false;
      _currentFrame = 0;
    });
    _initializeAnimation(animazione);
    _controller.forward(from: 0);
  }

  void _stopAnimation() {
    _controller.stop();
    setState(() {
      _isStarted = false;
      _isLooping = false;
    });
  }

  void _updateText(String newText) {
    setState(() {
      _textToShow = newText;
      _textController.duration = Duration(milliseconds: _textToShow.length*100);
      _letterAnimation = IntTween(begin: 0, end: _textToShow.length).animate(_textController);
      _textController.reset();
      _textController.forward();
      _startAnimation(speaking);
      _speak(newText);
    });
  }

  void _handleSubmitted(String value) {
    setState(() {
      // Save the text entered in a variable or perform desired actions
      _updateText(value);
      _textEditingController.clear(); // Clear TextField after submission
    });
  }

  void _handleSpeechButtonPressed() {
    if (!_speech.isListening) {
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _handleSubmitted(result.recognizedWords);
          }
        },
      );
    } else {
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TOTAI'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 3,
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
              Expanded(
                flex: 1,
                child: Container(),
              ),
            ],
          ),
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                int lettersToShow = _letterAnimation.value;
                return Text(
                  _textToShow.substring(0, lettersToShow),
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  softWrap: true,
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: TextField(
              controller: _textEditingController,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                hintText: 'Scrivi qui...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleSpeechButtonPressed,
        child: Icon(_speech.isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}
