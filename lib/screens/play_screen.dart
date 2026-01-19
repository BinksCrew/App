import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

class PlayScreen extends StatefulWidget {
  final String? animeId;
  final String? animeName;
  final bool autoStart;

  const PlayScreen({
    super.key,
    this.animeId,
    this.animeName,
    this.autoStart = false,
  });

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final _apiService = ApiService();
  List<dynamic> _questions = [];
  bool _isLoading = true;
  bool _isSubmittingAnswer = false;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isQuizFinished = false;
  bool _isQuizStarted = false;
  String? _currentSessionId;
  Map<String, dynamic>? _gameStats;
  int _totalPoints = 0;
  String? _errorMessage;
  bool _isRetrying = false;
  final TextEditingController _openAnswerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_loadGameStats());

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startNewGame();
      });
    } else {
      // Show the start screen quickly if we're not auto-starting.
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _openAnswerController.dispose();
    super.dispose();
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
      _isSubmittingAnswer = false;
    });

    try {
      final session = await _apiService.startGame(questionCount: 10);
      _currentSessionId = session['id'];

      // If coming from an anime card, prefer anime-specific questions (cached by ApiService).
      var questions = widget.animeId != null
          ? await _apiService.getQuestions(animeId: widget.animeId)
          : await _apiService.getRandomQuestions(10);

      if (questions.length > 10) {
        questions = questions.take(10).toList();
      }
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

  Future<void> _confirmStartGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Comenzar el quiz?'),
        content: Text(
          widget.animeName?.isNotEmpty == true
              ? '¿Estás listo para comenzar el quiz de ${widget.animeName}? Tendrás 10 preguntas.'
              : '¿Estás listo para comenzar el quiz? Tendrás 10 preguntas aleatorias.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Comenzar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _startNewGame();
    }
  }

  Future<void> _answerQuestion(String answer) async {
    if (_currentSessionId == null) return;

    setState(() {
      _isSubmittingAnswer = true;
      _errorMessage = null;
    });

    final question = _questions[_currentQuestionIndex];
    final options = question['options'] != null
      ? List<String>.from(question['options'].map((o) => o.toString()))
      : <String>[];
    final correctAnswer = question['correctAnswer']?.toString();
    if (correctAnswer != null && correctAnswer.isNotEmpty && !options.contains(correctAnswer)) {
      options.add(correctAnswer);
    }
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
          _isSubmittingAnswer = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCorrect
                ? '¡Correcto! +$pointsEarned puntos'
                : 'Incorrecto. Respuesta correcta: ${result['correctAnswer'] ?? 'N/A'}',
            ),
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
          _isSubmittingAnswer = false;
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

  void _showErrorDialog(String title, String message, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
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
          title: const Text('¿Salir del Quiz?'),
          content: const Text('¿Estás seguro de que quieres salir? Perderás tu progreso actual.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to home
              },
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
      _questions = [];
      _currentSessionId = null;
      _openAnswerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isQuizStarted
          ? AppBar(
              title: Text(
                widget.animeName?.isNotEmpty == true ? 'Jugar • ${widget.animeName}' : 'Jugar',
                overflow: TextOverflow.ellipsis,
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: _showExitDialog,
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_isRetrying ? 'Reintentando...' : 'Cargando...'),
                  ],
                ),
              )
            : _errorMessage != null && !_isQuizStarted
                ? _buildErrorScreen()
                : _questions.isEmpty
                    ? const Center(child: Text('No hay preguntas disponibles'))
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

    final String? animeLabel = question['anime'] == null
        ? null
        : (question['anime'] is Map
            ? (question['anime']['name']?.toString())
            : question['anime'].toString());

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LinearProgressIndicator(value: (_currentQuestionIndex + 1) / _questions.length),
            const SizedBox(height: 12),
            Text(
              'Pregunta ${_currentQuestionIndex + 1} de ${_questions.length}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (animeLabel != null && animeLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Chip(
                            label: Text(animeLabel),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.question_mark,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question['question']?.toString() ?? '',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isOpenQuestion) ...[
              TextField(
                controller: _openAnswerController,
                enabled: !_isSubmittingAnswer,
                decoration: const InputDecoration(
                  labelText: 'Tu respuesta',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: _isSubmittingAnswer ? null : (v) => _answerQuestion(v),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isSubmittingAnswer
                    ? null
                    : () => _answerQuestion(_openAnswerController.text.trim()),
                child: const Text('Enviar respuesta'),
              ),
            ] else ...[
              for (int i = 0; i < options.length; i++)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + i * 100),
                  curve: Curves.easeOut,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: _isSubmittingAnswer ? null : () => _answerQuestion(options[i]),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + i),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                options[i],
                                style: Theme.of(context).textTheme.bodyLarge,
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
        if (_isSubmittingAnswer)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(minHeight: 3),
          ),
      ],
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text('¡Ups! Algo salió mal', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Error desconocido',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Volver'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(onPressed: _retryStartGame, child: const Text('Reintentar')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = (_score / _questions.length * 100).round();
    final isPerfect = _score == _questions.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPerfect ? Icons.emoji_events : Icons.check_circle,
                        size: 80,
                        color: isPerfect
                            ? Colors.amber
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPerfect ? '¡Perfecto!' : '¡Quiz terminado!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Respondiste correctamente $_score de ${_questions.length} preguntas',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$percentage% de acierto',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Gracias por jugar!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          Navigator.of(context).pop(); // Go back to home
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Volver al inicio'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    final averageScore = _gameStats == null ? null : _gameStats!['averageScore'];
    final averageText = averageScore?.toString();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.quiz,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '¡Prepárate para el Quiz!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.animeName?.isNotEmpty == true
                                ? 'Demuestra tu conocimiento sobre ${widget.animeName}'
                                : 'Responde preguntas aleatorias y gana puntos',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Tus estadísticas',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Puntos', _totalPoints.toString(), Icons.stars),
                              _buildStatItem('Juegos', (_gameStats?['totalGames'] ?? 0).toString(), Icons.games),
                              _buildStatItem('Promedio', averageText ?? '—', Icons.analytics),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _confirmStartGame,
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: Text(
                    widget.animeName?.isNotEmpty == true ? 'Comenzar Quiz' : 'Comenzar Quiz',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
