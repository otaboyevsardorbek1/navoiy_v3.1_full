// lib/presentation/asarlar/asar_reader_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/utils/settings_service.dart';
import '../../core/network/auth_service.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/models/models.dart';

class AsarReaderScreen extends StatefulWidget {
  final AsarModel asar;
  const AsarReaderScreen({super.key, required this.asar});

  @override
  State<AsarReaderScreen> createState() => _AsarReaderScreenState();
}

class _AsarReaderScreenState extends State<AsarReaderScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 1;
  int get _totalPages => widget.asar.totalPages ?? 1;

  Map<String, dynamic>? _currentPageData;
  bool _loading = true;
  bool _downloading = false;
  String? _error;

  // Quiz state
  Map<int, List<int>> _selectedAnswers = {};
  Map<int, bool?> _quizResults = {};

  @override
  void initState() {
    super.initState();
    _loadSavedProgress().then((_) => _loadPage(_currentPage));
  }

  @override
  void dispose() {
    _saveProgress();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedProgress() async {
    final progress = await DatabaseHelper.instance.getProgress(widget.asar.id!);
    if (progress != null && mounted) {
      setState(() => _currentPage = progress.currentPage);
    }
  }

  Future<void> _loadPage(int pageNumber) async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    final slug = widget.asar.slug ?? '';

    // 1. Offline JSON dan o'qish
    Map<String, dynamic>? page = await SyncManager.instance.readAsarPage(slug, pageNumber);

    // 2. Online holatda API dan olish
    if (page == null && !SettingsService.instance.isOfflineMode) {
      try {
        final token = await AuthService.instance.getAccessToken();
        if (token != null) {
          // Download full content first if not downloaded
          final hasContent = await SyncManager.instance.hasAsarContent(slug);
          if (!hasContent) {
            setState(() => _downloading = true);
            await SyncManager.instance.downloadAsar(slug);
            setState(() => _downloading = false);
          }
          page = await SyncManager.instance.readAsarPage(slug, pageNumber);
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _currentPageData = page;
        _loading = false;
        _error = page == null ? 'Bu sahifa mavjud emas. Iltimos sinxronlash qiling.' : null;
      });
    }

    await _saveProgress();
  }

  Future<void> _saveProgress() async {
    if (widget.asar.id == null) return;
    await DatabaseHelper.instance.upsertProgress(
      asarId: widget.asar.id!,
      currentPage: _currentPage,
      scrollOffset: 0.0,
      isCompleted: _currentPage >= _totalPages,
      totalPages: _totalPages,
    );
    // Online holatda serverga ham yuborish
    if (!SettingsService.instance.isOfflineMode) {
      SyncManager.instance.syncProgressToServer().catchError((_) {});
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
    _loadPage(page);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.asar.titleUz, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // Page indicator
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '$_currentPage / $_totalPages',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.appBarTheme.foregroundColor?.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Go to page
          IconButton(
            icon: const Icon(Icons.format_list_numbered),
            tooltip: 'Sahifaga o\'tish',
            onPressed: () => _showPagePicker(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _totalPages > 0 ? _currentPage / _totalPages : 0),
            duration: const Duration(milliseconds: 300),
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              backgroundColor: theme.dividerColor,
              color: theme.colorScheme.primary,
              minHeight: 3,
            ),
          ),

          // Content
          Expanded(
            child: _downloading
                ? _buildDownloading(theme)
                : _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildError(theme)
                        : _buildContent(theme),
          ),

          // Navigation
          _buildNavBar(theme),
        ],
      ),
    );
  }

  Widget _buildDownloading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Asar yuklanmoqda...', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text('Bu bir marta amalga oshiriladi', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_download_outlined, size: 64,
                color: theme.colorScheme.primary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(_error!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Sinxronlash'),
              onPressed: () async {
                setState(() => _downloading = true);
                final slug = widget.asar.slug ?? '';
                await SyncManager.instance.downloadAsar(slug);
                setState(() => _downloading = false);
                _loadPage(_currentPage);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final pageTitle = _currentPageData?['title'] as String?;
    final content = _currentPageData?['content'] as String? ?? '';
    final quizzes = (_currentPageData?['quizzes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pageTitle != null) ...[
            Text(pageTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            Divider(),
            const SizedBox(height: 16),
          ],
          Text(content, style: theme.textTheme.bodyLarge?.copyWith(height: 1.9)),
          if (quizzes.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildQuizSection(quizzes, theme),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuizSection(List<Map<String, dynamic>> quizzes, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.quiz_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Savol-javob', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...quizzes.asMap().entries.map((entry) {
          final i = entry.key;
          final quiz = entry.value;
          return _QuizCard(
            quizIndex: i,
            quizData: quiz,
            selectedAnswers: _selectedAnswers[i] ?? [],
            result: _quizResults[i],
            onAnswerSelected: (answers) {
              setState(() => _selectedAnswers[i] = answers);
            },
            onSubmit: (answers) {
              final correctAnswers = List<int>.from(quiz['correct_answers'] as List);
              final isCorrect = _listEquals(answers..sort(), correctAnswers..sort());
              setState(() => _quizResults[i] = isCorrect);

              // Save locally
              if (widget.asar.id != null) {
                DatabaseHelper.instance.saveQuizResult(
                  quizId: quiz['id'] as int? ?? 0,
                  asarId: widget.asar.id!,
                  pageNumber: _currentPage,
                  selectedAnswers: answers,
                  isCorrect: isCorrect,
                  pointsEarned: isCorrect ? (quiz['points'] as int? ?? 10) : 0,
                );
              }
            },
          );
        }),
      ],
    );
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Widget _buildNavBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Prev
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
              style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
              child: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          ),
          const SizedBox(width: 12),

          // Page dots / counter
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentPageData?['title'] as String? ?? '$_currentPage-sahifa',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _totalPages.clamp(0, 7),
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: (i + 1 == _currentPage) ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: (i + 1 == _currentPage)
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Next
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
              style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
              child: const Icon(Icons.arrow_forward_ios, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _showPagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sahifaga o\'tish', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _totalPages,
                  itemBuilder: (_, i) {
                    final page = i + 1;
                    final isCurrent = page == _currentPage;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _goToPage(page);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$page',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : theme.colorScheme.onSurface,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Quiz Card ────────────────────────────────────────────────────────────────

class _QuizCard extends StatelessWidget {
  final int quizIndex;
  final Map<String, dynamic> quizData;
  final List<int> selectedAnswers;
  final bool? result;
  final ValueChanged<List<int>> onAnswerSelected;
  final ValueChanged<List<int>> onSubmit;

  const _QuizCard({
    required this.quizIndex,
    required this.quizData,
    required this.selectedAnswers,
    required this.result,
    required this.onAnswerSelected,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = quizData['question'] as String? ?? '';
    final options = List<String>.from(quizData['options'] as List? ?? []);
    final explanation = quizData['explanation'] as String?;
    final isAnswered = result != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAnswered
              ? (result! ? Colors.green : theme.colorScheme.error)
              : theme.dividerColor,
          width: isAnswered ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Savol ${quizIndex + 1}',
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              if (isAnswered)
                Icon(result! ? Icons.check_circle : Icons.cancel,
                    color: result! ? Colors.green : theme.colorScheme.error, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(question, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...options.asMap().entries.map((entry) {
            final i = entry.key;
            final option = entry.value;
            final isSelected = selectedAnswers.contains(i);
            final correctAnswers = List<int>.from(quizData['correct_answers'] as List? ?? []);
            final isCorrectOption = correctAnswers.contains(i);

            Color? bgColor;
            Color? borderColor;
            if (isAnswered) {
              if (isCorrectOption) { bgColor = Colors.green.withOpacity(0.12); borderColor = Colors.green; }
              else if (isSelected && !isCorrectOption) { bgColor = theme.colorScheme.error.withOpacity(0.1); borderColor = theme.colorScheme.error; }
            } else if (isSelected) {
              bgColor = theme.colorScheme.primary.withOpacity(0.12);
              borderColor = theme.colorScheme.primary;
            }

            return GestureDetector(
              onTap: isAnswered ? null : () {
                final newSelected = List<int>.from(selectedAnswers);
                if (newSelected.contains(i)) newSelected.remove(i);
                else newSelected.add(i);
                onAnswerSelected(newSelected);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor ?? theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor ?? theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(option, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            );
          }),

          if (!isAnswered && selectedAnswers.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onSubmit(List.from(selectedAnswers)),
                child: const Text('Tekshirish'),
              ),
            ),
          ],

          if (isAnswered && explanation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(explanation, style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue.shade700))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
