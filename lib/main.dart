import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Translator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: EnglishToMarathiTransliterator(),
    );
  }
}

class EnglishToMarathiTransliterator extends StatefulWidget {
  const EnglishToMarathiTransliterator({super.key});

  @override
  _EnglishToMarathiTransliteratorState createState() =>
      _EnglishToMarathiTransliteratorState();
}

class _EnglishToMarathiTransliteratorState
    extends State<EnglishToMarathiTransliterator> {
  final TextEditingController _englishController = TextEditingController();
  final TextEditingController _marathiController = TextEditingController();
  bool _isProcessing = false;
  Timer? _debounceTimer;
  final Map<String, String> _transliterationCache = {};

  @override
  void initState() {
    super.initState();
    _englishController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    final text = _englishController.text;

    // Clear output if input is empty
    if (text.isEmpty) {
      setState(() {
        _marathiController.text = '';
      });
      return;
    }

    // Check cache first
    if (_transliterationCache.containsKey(text)) {
      _marathiController.text = _transliterationCache[text]!;
      return;
    }

    // Wait for user to pause typing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _transliterateText(text);
    });
  }

  Future<void> _transliterateText(String text) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _marathiController.text = 'Converting...';
    });

    try {
      // Use Google Input Tools API for transliteration
      final response = await http.get(
        Uri.parse(
          'https://inputtools.google.com/request?text=$text&itc=mr-t-i0-und&num=5&cp=0&cs=1&ie=utf-8&oe=utf-8',
        ),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Parse the response to get transliterated text
        if (jsonResponse[0] == 'SUCCESS') {
          final suggestions = jsonResponse[1][0][1];
          if (suggestions.isNotEmpty) {
            final transliteratedText = suggestions[0];

            // Cache the result
            _transliterationCache[text] = transliteratedText;

            // Update UI if the input hasn't changed
            if (mounted && _englishController.text == text) {
              _marathiController.text = transliteratedText;
            }
          } else {
            _marathiController.text = text; // Fallback to original text
          }
        } else {
          _marathiController.text = text; // Fallback to original text
        }
      } else {
        _marathiController.text = 'Error: ${response.statusCode}';
      }
    } catch (e) {
      print('Transliteration error: $e');
      _marathiController.text = 'Conversion error';
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _englishController.dispose();
    _marathiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('English to Marathi Converter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _englishController,
              decoration: const InputDecoration(
                labelText: 'Type in English (phonetic)',
                hintText: 'Example: namaste',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _marathiController,
              decoration: const InputDecoration(
                labelText: 'Marathi script',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            Text(
              _isProcessing ? 'Converting...' : '',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
