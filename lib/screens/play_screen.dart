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
  late final ApiService _apiService;
  late final TextEditingController _openAnswerController;

  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isQuizFinished = false;
  bool _isQuizStarted = false;
  String? _currentSessionId;
  bool _isLoading = true;
  bool _isRetrying = false;
  String? _errorMessage;
  bool _isSubmittingAnswer = false;
  Map<String, dynamic>? _gameStats;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _openAnswerController = TextEditingController();
    _loadGameStats();
    if (widget.autoStart) {
      _startGame();
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
          _totalPoints = stats?['totalPoints'] ?? 0;
        });
      }
    } catch (e) {
      // Ignore errors for stats
    }
  }

  Future<void> _startGame() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isRetrying = false;
    });

    try {
      final gameData = await _apiService.startGame();
      final sessionId = gameData['sessionId'];
      final questions = await _apiService.getQuestions(animeId: widget.animeId);

      if (mounted) {
        setState(() {
          _currentSessionId = sessionId;
          _questions = questions;
          _isLoading = false;
          _isQuizStarted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _retryStartGame() async {
    setState(() {
      _isRetrying = true;
    });
    await _startGame();
  }

  void _confirmStartGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar inicio'),
        content: const Text('¿Estás listo para comenzar el quiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startGame();
            },
            child: const Text('Comenzar'),
          ),
        ],
      ),
    );
  }

  Future<void> _answerQuestion(String answer) async {
    if (_isSubmittingAnswer) return;

    setState(() {
      _isSubmittingAnswer = true;
    });

    try {
      final question = _questions[_currentQuestionIndex];
      final result = await _apiService.answerGameQuestion(_currentSessionId!, question['id'], answer);
      final isCorrect = result['correct'] ?? false;

      if (isCorrect) {
        setState(() {
          _score++;
        });
      }

      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _isSubmittingAnswer = false;
        });
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
        // Ignore
      }
    }

    if (mounted) {
      setState(() {
        _isQuizFinished = true;
        _isSubmittingAnswer = false;
      });
      await _loadGameStats();
    }
  }

  void _resetGame() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _isQuizFinished = false;
      _isQuizStarted = false;
      _currentSessionId = null;
      _questions = [];
      _openAnswerController.clear();
    });
  }

  void _showErrorDialog(String title, String message, VoidCallback onRetry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty && _isQuizStarted && !_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.animeName?.isNotEmpty == true ? 'Jugar • ${widget.animeName}' : 'Jugar'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('No hay preguntas disponibles'),
        ),
      );
    }

    if (!_isQuizStarted || _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Jugar'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _isLoading
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
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            '¡Ups! Algo salió mal',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage ?? 'Error desconocido',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _retryStartGame,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.black, width: 2),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                                    Theme.of(context).colorScheme.surface,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
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
                                      '¡Demuestra tu conocimiento!',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    if (widget.animeName?.isNotEmpty == true) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Demuestra tu conocimiento sobre ${widget.animeName}',
                                        style: Theme.of(context).textTheme.bodyLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Text(
                                      'Responde correctamente todas las preguntas para ganar puntos.',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildStatItem('Puntos', _totalPoints.toString(), Icons.stars),
                                        _buildStatItem('Juegos', (_gameStats?['totalGames'] ?? 0).toString(), Icons.games),
                                        if (_gameStats != null)
                                          _buildStatItem('Promedio', '${(_gameStats!['averageScore'] ?? 0).toString()}%', Icons.trending_up),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _confirmStartGame,
                            icon: const Icon(Icons.play_arrow),
                            label: Text(widget.animeName?.isNotEmpty == true ? 'Comenzar Quiz' : 'Comenzar Quiz'),
                          ),
                        ],
                      ),
                    ),
                  ),
      );
    }

    if (_isQuizFinished) {
      final percentage = (_score / _questions.length * 100).round();
      final isPerfect = _score == _questions.length;

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.animeName?.isNotEmpty == true ? 'Jugar • ${widget.animeName}' : 'Jugar'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.black, width: 2),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                          Theme.of(context).colorScheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            isPerfect ? Icons.emoji_events : Icons.check_circle,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isPerfect ? '¡Perfecto!' : '¡Completado!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Respondiste correctamente $_score de ${_questions.length} preguntas',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$percentage% de aciertos',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              FilledButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('¡Funcionalidad próximamente!')),
                                  );
                                },
                                icon: const Icon(Icons.share),
                                label: const Text('Compartir'),
                              ),
                              FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.home),
                                label: const Text('Inicio'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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

    Widget buildOption(int i) {
      return TweenAnimationBuilder<double>(
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.black, width: 2),
            ),
            child: InkWell(
              onTap: _isSubmittingAnswer ? null : () => _answerQuestion(options[i]),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[i],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.animeName?.isNotEmpty == true ? 'Jugar • ${widget.animeName}' : 'Jugar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.black, width: 2),
                ),
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
                for (int i = 0; i < options.length; i++) buildOption(i),
              ],
            ],
          ),
          if (_isSubmittingAnswer)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: const LinearProgressIndicator(minHeight: 3),
            ),
        ],
      ),
    );
  }
}
