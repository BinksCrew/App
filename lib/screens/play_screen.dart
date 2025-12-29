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
  String? _currentSessionId;
  Map<String, dynamic>? _gameStats;
  int _totalPoints = 0;
  String? _errorMessage;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _loadGameStats();
  }

  Future<void> _loadGameStats() async {
    try {
      final stats = await _apiService.getGameStats();
      if (mounted) {
        setState(() {
          _gameStats = stats;
          _totalPoints = (stats['totalPoints'] ?? 0).toInt();
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _startNewGame() async {
    setState(() {
      _isLoading = true;
      _isQuizStarted = false;
      _isQuizFinished = false;
      _currentQuestionIndex = 0;
      _score = 0;
      _errorMessage = null;
      _isRetrying = false;
    });

    try {
      final session = await _apiService.startGame(questionCount: 10);
      _currentSessionId = session['id'];

      // For now, get random questions (we'll integrate with session questions later)
      final questions = await _apiService.getRandomQuestions(10);
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
          _isQuizStarted = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        _showErrorDialog('Error al iniciar el juego', _errorMessage!, _retryStartGame);
      }
    }
  }

  void _retryStartGame() {
    setState(() {
      _isRetrying = true;
    });
    _startNewGame();
  }

  Future<void> _answerQuestion(String answer) async {
    if (_currentSessionId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final question = _questions[_currentQuestionIndex];
    try {
      final result = await _apiService.answerGameQuestion(
        _currentSessionId!,
        question['id'],
        answer,
      );

      final isCorrect = result['isCorrect'] ?? false;
      final int pointsEarned = (result['pointsEarned'] ?? 0).toInt();

      if (mounted) {
        setState(() {
          if (isCorrect) _score++;
          _totalPoints += pointsEarned;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCorrect
                ? '¡Correcto! +$pointsEarned puntos'
                : 'Incorrecto. Respuesta correcta: ${result['correctAnswer'] ?? 'N/A'}',
            ),
            backgroundColor: isCorrect ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Move to next question or finish
      if (_currentQuestionIndex < _questions.length - 1) {
        if (mounted) {
          setState(() {
            _currentQuestionIndex++;
          });
        }
      } else {
        await _finishGame();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        _showErrorDialog('Error al enviar respuesta', _errorMessage!, () => _answerQuestion(answer));
      }
    }
  }

  Future<void> _finishGame() async {
    if (_currentSessionId != null) {
      try {
        await _apiService.endGame(_currentSessionId!);
      } catch (e) {
        // Ignore error
      }
    }

    setState(() {
      _isQuizFinished = true;
    });

    await _loadGameStats(); // Refresh stats
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

  void _showErrorDialog(String title, String message, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFF2E63), width: 2),
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
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
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2E63),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
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
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFFF2E63)),
                    const SizedBox(height: 16),
                    Text(
                      _isRetrying ? 'Reintentando...' : 'Cargando...',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            : _errorMessage != null && !_isQuizStarted
                ? _buildErrorScreen()
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
              onPressed: _isLoading ? null : () => _answerQuestion(answerController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoading ? Colors.grey : const Color(0xFFFF2E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Enviar respuesta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ] else
            ...options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: _isLoading ? null : () => _answerQuestion(option),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: _isLoading
                          ? const LinearGradient(
                              colors: [Color(0xFF2A2A3A), Color(0xFF1F1F2F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF1F1F35), Color(0xFF151527)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isLoading ? Icons.hourglass_empty : Icons.radio_button_unchecked,
                          color: _isLoading ? Colors.white54 : Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              color: _isLoading ? Colors.white54 : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!_isLoading)
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

  Widget _buildErrorScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF2A1A1F), Color(0xFF1A1215)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.red.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.35),
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
                color: Colors.red.withOpacity(0.12),
                border: Border.all(color: Colors.red.withOpacity(0.6)),
              ),
              child: const Icon(Icons.error_outline, size: 64, color: Colors.red),
            ),
            const SizedBox(height: 18),
            const Text(
              '¡Ups! Algo salió mal',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Error desconocido',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Volver'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _retryStartGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ],
        ),
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
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Stats Card
                      if (_gameStats != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 32),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A1A2F), Color(0xFF121223)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: const Color(0xFFFF2E63).withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Tus Estadísticas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem('Puntos Totales', _totalPoints.toString(), Icons.stars),
                                  _buildStatItem('Juegos', (_gameStats!['totalGames'] ?? 0).toString(), Icons.games),
                                  _buildStatItem('Promedio', '${(_gameStats!['averageScore'] ?? 0).toStringAsFixed(1)}%', Icons.analytics),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Play Button Section
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
                        onPressed: _startNewGame,
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

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF2E63), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
