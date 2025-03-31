import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: EnglishToMarathiTransliterator(),
    );
  }
}

class EnglishToMarathiTransliterator extends StatefulWidget {
  const EnglishToMarathiTransliterator({Key? key}) : super(key: key);

  @override
  _EnglishToMarathiTransliteratorState createState() => _EnglishToMarathiTransliteratorState();
}

class _EnglishToMarathiTransliteratorState extends State<EnglishToMarathiTransliterator> {
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
          Uri.parse('https://inputtools.google.com/request?text=$text&itc=mr-t-i0-und&num=5&cp=0&cs=1&ie=utf-8&oe=utf-8')
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
      appBar: AppBar(
        title: const Text('English to Marathi Converter'),
      ),
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

// class EnglishToMarathiTranslator extends StatefulWidget {
//   const EnglishToMarathiTranslator({Key? key}) : super(key: key);
//
//   @override
//   _EnglishToMarathiTranslatorState createState() => _EnglishToMarathiTranslatorState();
// }
//
// class _EnglishToMarathiTranslatorState extends State<EnglishToMarathiTranslator> {
//   final TextEditingController _englishController = TextEditingController();
//   final TextEditingController _marathiController = TextEditingController();
//   final translator = GoogleTranslator();
//   bool _isTranslating = false;
//   Timer? _debounceTimer;
//   String _lastTranslatedText = '';
//
//   // Cache for storing translations
//   final Map<String, String> _translationCache = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _englishController.addListener(_onTextChanged);
//   }
//
//   void _onTextChanged() {
//     // Cancel any previous debounce timer
//     _debounceTimer?.cancel();
//
//     final text = _englishController.text;
//
//     // Clear Marathi text if English is empty
//     if (text.isEmpty) {
//       setState(() {
//         _marathiController.text = '';
//       });
//       return;
//     }
//
//     // Check if the text is in the cache
//     if (_translationCache.containsKey(text)) {
//       _marathiController.text = _translationCache[text]!;
//       return;
//     }
//
//     // Don't start a new translation if current text is the same as the last translated
//     if (text == _lastTranslatedText) return;
//
//     // Only start a new timer if we're not currently translating
//     if (!_isTranslating) {
//       // Add a debounce to wait for the user to stop typing
//       _debounceTimer = Timer(const Duration(milliseconds: 500), () {
//         _translateText(text);
//       });
//     }
//   }
//
//   Future<void> _translateText(String text) async {
//     // If the text is already being translated, skip
//     if (_isTranslating) return;
//
//     setState(() {
//       _isTranslating = true;
//     });
//
//     try {
//       // Check if the text is in the cache before making API call
//       if (_translationCache.containsKey(text)) {
//         _marathiController.text = _translationCache[text]!;
//       } else {
//         // Show loading indicator
//         _marathiController.text = 'Translating...';
//
//         // Translate the text
//         final translation = await translator.translate(
//           text,
//           from: 'en',
//           to: 'mr',
//         );
//
//         // Add to cache
//         _translationCache[text] = translation.text;
//
//         // Update UI if the text hasn't changed during translation
//         if (mounted && _englishController.text == text) {
//           _marathiController.text = translation.text;
//           _lastTranslatedText = text;
//         }
//       }
//     } catch (e) {
//       print('Translation error: $e');
//       _marathiController.text = 'Translation error';
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isTranslating = false;
//         });
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _debounceTimer?.cancel();
//     _englishController.dispose();
//     _marathiController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('English to Marathi Translator'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _englishController,
//               decoration: const InputDecoration(
//                 labelText: 'Enter English text',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 4,
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _marathiController,
//               decoration: const InputDecoration(
//                 labelText: 'Marathi translation',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 4,
//               readOnly: true,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               _isTranslating ? 'Translating...' : '',
//               style: const TextStyle(fontStyle: FontStyle.italic),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class EnglishToMarathiTranslator extends StatefulWidget {
//   const EnglishToMarathiTranslator({Key? key}) : super(key: key);
//
//   @override
//   _EnglishToMarathiTranslatorState createState() =>
//       _EnglishToMarathiTranslatorState();
// }
//
// class _EnglishToMarathiTranslatorState
//     extends State<EnglishToMarathiTranslator> {
//   final TextEditingController _englishController = TextEditingController();
//   final TextEditingController _marathiController = TextEditingController();
//   final translator = GoogleTranslator();
//   bool _isTranslating = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Add listener to the English text controller
//     _englishController.addListener(_translateText);
//   }
//
//   // Function to translate text from English to Marathi
//   void _translateText() async {
//     // Don't translate if already translating (prevents infinite loops)
//     if (_isTranslating) return;
//
//     setState(() {
//       _isTranslating = true;
//     });
//
//     // If the text is empty, clear the Marathi field
//     if (_englishController.text.isEmpty) {
//       _marathiController.text = '';
//       setState(() {
//         _isTranslating = false;
//       });
//       return;
//     }
//
//     try {
//       // Translate the text
//       final translation = await translator.translate(
//         _englishController.text,
//         from: 'en',
//         to: 'mr',
//       );
//
//       if (mounted && _englishController.text.isNotEmpty) {
//         _marathiController.text = translation.text;
//       }
//     } catch (e) {
//       // Handle any errors
//     } finally {
//       // Reset the flag
//       if (mounted) {
//         setState(() {
//           _isTranslating = false;
//         });
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     // Clean up controllers when the widget is disposed
//     _englishController.dispose();
//     _marathiController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('English to Marathi Translator')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _englishController,
//               decoration: const InputDecoration(
//                 labelText: 'Enter English text',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 4,
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _marathiController,
//               decoration: const InputDecoration(
//                 labelText: 'Marathi translation',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 4,
//               readOnly: true,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
