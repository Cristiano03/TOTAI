import 'package:flutter/material.dart';
import 'dart:async';
import 'package:test_drive/Animazioni.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

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
  String _textToShow = "Ciao sono TOTAI!\nChiedimi pure qualsiasi informazione sui deodoranti";
  late AnimationController _textController;
  late Animation<int> _letterAnimation;
  TextEditingController _textEditingController = TextEditingController();
  late stt.SpeechToText _speech;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _initializeTts();
    _audioPlayer = AudioPlayer();
    _speech = stt.SpeechToText();
    _initializeSpeech();
    //_getAvailableVoices();

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
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    // Imposta una voce specifica (sostituisci con una voce disponibile)
    await flutterTts.setVoice({
      'name': 'Microsoft Zira Desktop',
    });
  }


  void _getAvailableVoices() async {
    var voices = await flutterTts.getVoices;
    print("Voci disponibili:");
    for (var voice in voices) {
      print("- ${voice['name']}");
    }
  }



  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('onStatus: $status'),
      onError: (error) => print('onError: $error'),
    );
    if (available) {
      setState(() {});
    } else {
      print('Speech recognition not available');
    }
  }

  String _replaceTotai(String text) {
    return text.replaceAll('TOTAI', 'Totai');
  }

  Future<void> _speak(String text) async {
    String processedText = _replaceTotai(text);
    await sendTTSRequest(processedText);
    //await flutterTts.speak(processedText);
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
    _audioPlayer.dispose();
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

  Future<void> sendTTSRequest(String text) async {
    String encodedText = Uri.encodeComponent(text);
    String endpoint = '/api/tts';
    String voice = 'nanotts:it-IT'; // Set Italian voice
    String vocoder = 'high';
    double denoiserStrength = 0.03;
    bool cache = false;

    String url = 'http://192.168.2.217:5500/api/tts?voice=nanotts%3Ait-IT&text=$encodedText&vocoder=high&denoiserStrength=0.03&cache=false';

    print(url);

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Success: handle the TTS audio file content here
        print('TTS request sent successfully.');
        await _audioPlayer.play(UrlSource(url));

        // Play the audio received from OpenTTS
        //await _audioPlayer.setUrl(response.body);

        // Start playing audio
        //await _audioPlayer.play();
      } else {
        // Error handling
        print('Error sending TTS request: ${response.statusCode}');
      }
    } catch (e) {
      // Exception handling
      print('Error sending TTS request: $e');
    }
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
