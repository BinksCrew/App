import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final _apiService = ApiService();
  List<dynamic> _questions = [];
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isQuizFinished = false;
  bool _isQuizStarted = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _apiService.getRandomQuestions(10);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar preguntas: $e')),
        );
      }
    }
  }

  Future<void> _answerQuestion(String answer) async {
    final question = _questions[_currentQuestionIndex];
    try {
      final result = await _apiService.answerQuestion(question['id'], answer);

      final isCorrect = (result['isCorrect'] ?? result['correct']) == true;
      final correctAnswer = result['correctAnswer']?.toString() ??
          question['correctAnswer']?.toString() ??
          '—';

      if (isCorrect) {
        _score++;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Correcto!'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 600),
            ),
          );
        }
        _goNextQuestion();
      } else {
        if (mounted) {
          _showFailureSheet(correctAnswer);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar respuesta: $e')),
        );
      }
    }
  }

  void _goNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      setState(() {
        _isQuizFinished = true;
      });
    }
  }

  void _showFailureSheet(String correctAnswer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151527),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sentiment_dissatisfied, color: Colors.orange, size: 48),
              const SizedBox(height: 12),
              const Text(
                '¡Fallaste en este turno!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Respuesta correcta: $correctAnswer',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF2E63)),
                        foregroundColor: const Color(0xFFFF2E63),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Retry same question (do nothing else)
                      },
                      child: const Text('Reintentar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).maybePop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2E63),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Salir'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.pinkAccent, width: 2),
          ),
          title: const Text(
            '¿Salir del Quiz?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '¿Estás seguro de que quieres salir? Perderás tu progreso actual.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _isQuizFinished = false;
      _isQuizStarted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _isQuizStarted
          ? AppBar(
              title: const Text('Jugar', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.white),
                  onPressed: _showExitDialog,
                ),
              ],
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D1A), Color(0xFF090912)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF2E63)))
            : _questions.isEmpty
                ? const Center(child: Text('No hay preguntas disponibles', style: TextStyle(color: Colors.white)))
                : !_isQuizStarted
                    ? _buildStartScreen()
                    : _isQuizFinished
                        ? _buildResultScreen()
                        : _buildQuizScreen(),
      ),
    );
  }

  Widget _buildQuizScreen() {
    final question = _questions[_currentQuestionIndex];
    final options = question['options'] != null
      ? List<String>.from(question['options'].map((o) => o.toString()))
      : <String>[];
    final correctAnswer = question['correctAnswer']?.toString();
    if (correctAnswer != null && correctAnswer.isNotEmpty && !options.contains(correctAnswer)) {
      options.add(correctAnswer);
    }
    final isOpenQuestion = options.isEmpty;
    final TextEditingController answerController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF2E63)),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Pregunta ${_currentQuestionIndex + 1} de ${_questions.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 0.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2F), Color(0xFF121223)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFFFF2E63).withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF2E63).withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (question['anime'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Text(
                        question['anime'] is Map
                            ? (question['anime']['name'] ?? '')
                            : question['anime'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    question['question'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (isOpenQuestion) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: answerController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tu respuesta',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _answerQuestion(answerController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Enviar respuesta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ] else
            ...options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _answerQuestion(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1F1F35), Color(0xFF151527)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_unchecked, color: Colors.white70, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1E35), Color(0xFF121222)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFFF2E63).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2E63).withOpacity(0.35),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.12),
                border: Border.all(color: Colors.amber.withOpacity(0.6)),
              ),
              child: const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            ),
            const SizedBox(height: 18),
            const Text(
              '¡Quiz terminado!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tu puntuación: $_score / ${_questions.length}',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFFFF2E63),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _restartQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Jugar de nuevo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B0B14), Color(0xFF0F0F1F)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF2E63), Color(0xFFB026FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2E63).withOpacity(0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_circle_fill,
                size: 90,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              '¡Prepárate para el quiz!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '${_questions.length} preguntas te esperan',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isQuizStarted = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 10,
              ),
              child: const Text(
                '¡Comenzar!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
