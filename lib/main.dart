import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const ShadowAIApp());
}

class ShadowAIApp extends StatelessWidget {
  const ShadowAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shadow AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurple,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  
  final String _triggerCommand = "تحويل";
  bool _isShadowMode = false;
  
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add({"sender": "user", "text": text});
    });

    if (text.trim() == _triggerCommand) {
      setState(() {
        _isShadowMode = true;
        _messages.add({
          "sender": "bot",
          "text": "أهلاً بك سيدي، ماذا تريد أن أفعل؟"
        });
      });
      return;
    }

    if (text.trim() == "عودة") {
      setState(() {
        _isShadowMode = false;
        _messages.add({
          "sender": "bot",
          "text": "تم العودة إلى الوضع الافتراضي."
        });
      });
      return;
    }

    setState(() {
      if (_isShadowMode) {
        _messages.add({
          "sender": "bot",
          "text": "أمرك سيدي، جاري تنفيذ: ($text)"
        });
      } else {
        _messages.add({
          "sender": "bot",
          "text": "أنا في الوضع العادي، أرسل 'تحويل' لتفعيل وضع الظل."
        });
      }
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: "ar_SA",
          onResult: (val) {
            setState(() {
              _textController.text = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_textController.text.isNotEmpty) {
        _handleSubmitted(_textController.text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isShadowMode ? "وضع الظل (Shadow)" : "المساعد العادي"),
        backgroundColor: _isShadowMode ? Colors.black : Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (_, int index) {
                final message = _messages[_messages.length - 1 - index];
                bool isUser = message["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser
                          ? (_isShadowMode ? Colors.purple[900] : Colors.deepPurple)
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Text(
                      message["text"] ?? "",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  color: _isListening ? Colors.red : null,
                  onPressed: _listen,
                ),
                Flexible(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: _handleSubmitted,
                    decoration: const InputDecoration.collapsed(
                      hintText: "أدخل رسالتك أو كلمة التفعيل...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _handleSubmitted(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
