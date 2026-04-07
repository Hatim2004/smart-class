import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/transcript.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import 'summary_screen.dart';

class RecorderScreen extends StatefulWidget {
  final String apiKey;
  const RecorderScreen({super.key, required this.apiKey});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _stt = SpeechToText();
  final StorageService _storage = StorageService();
  late AiService _ai;

  bool _isListening = false;
  bool _isAvailable = false;
  bool _isSummarizing = false;
  String _currentWords = '';
  String _fullTranscript = '';
  Timer? _durationTimer;
  Duration _recordDuration = Duration.zero;
  late AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ai = AiService(apiKey: widget.apiKey);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await Permission.microphone.request();
    _isAvailable = await _stt.initialize(
      onError: (e) => _showSnack('Speech error: ${e.errorMsg}'),
      onStatus: (s) {
        if (s == 'done' && _isListening) _restartListening();
      },
    );
    setState(() {});
  }

  Future<void> _restartListening() async {
    if (!_isListening) return;
    await Future.delayed(const Duration(milliseconds: 200));
    if (_isListening) _startListening();
  }

  void _startListening() {
    _stt.listen(
      onResult: _onSpeechResult,
      listenMode: ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _currentWords = result.recognizedWords;
      if (result.finalResult) {
        if (_currentWords.trim().isNotEmpty) {
          _fullTranscript += ' ${_currentWords.trim()}';
        }
        _currentWords = '';
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleRecording() async {
    HapticFeedback.mediumImpact();
    if (!_isAvailable) {
      _showSnack('Microphone not available');
      return;
    }
    if (_isListening) {
      await _stt.stop();
      _durationTimer?.cancel();
      _pulseController.stop();
      setState(() {
        _isListening = false;
        if (_currentWords.trim().isNotEmpty) {
          _fullTranscript += ' ${_currentWords.trim()}';
          _currentWords = '';
        }
      });
    } else {
      setState(() {
        _isListening = true;
        _recordDuration = Duration.zero;
      });
      _pulseController.repeat(reverse: true);
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _recordDuration += const Duration(seconds: 1));
      });
      _startListening();
    }
  }

  Future<void> _summarizeAndSave() async {
    final fullText = '$_fullTranscript $_currentWords'.trim();
    if (fullText.isEmpty) {
      _showSnack('No transcript to summarize yet');
      return;
    }

    setState(() => _isSummarizing = true);

    try {
      final title = await _ai.generateTitle(fullText);
      final summary = await _ai.summarize(fullText);

      final transcript = Transcript(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        text: fullText,
        summary: summary,
        createdAt: DateTime.now(),
        duration: _recordDuration,
      );

      await _storage.save(transcript);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SummaryScreen(transcript: transcript),
          ),
        );
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _isSummarizing = false);
    }
  }

  void _clearTranscript() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear Transcript?',
            style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        content: Text('This will erase all recorded text.',
            style: GoogleFonts.inter(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _fullTranscript = '';
                _currentWords = '';
                _recordDuration = Duration.zero;
              });
            },
            child: Text('Clear',
                style: GoogleFonts.inter(color: const Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF252547),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String get _formattedTime {
    final m = _recordDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _recordDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _stt.stop();
    _durationTimer?.cancel();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _fullTranscript.trim().isNotEmpty || _currentWords.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTranscriptArea(),
            _buildControls(hasContent),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ClassRecord',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'AI-Powered Lecture Recorder',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6C6C8A),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_isListening)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFFFF4444).withOpacity(0.15),
                    const Color(0xFFFF4444).withOpacity(0.3),
                    _pulseController.value,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF4444), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4444).withOpacity(0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formattedTime,
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFFFF4444),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildTranscriptArea() {
    final displayText = _fullTranscript.trim();
    final liveText = _currentWords.trim();

    return Expanded(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF111128),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isListening
                ? const Color(0xFF4A4AFF).withOpacity(0.4)
                : const Color(0xFF252547),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    'TRANSCRIPT',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: const Color(0xFF4A4AFF),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (displayText.isNotEmpty)
                    Text(
                      '${displayText.split(' ').length} words',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6C6C8A),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF252547), height: 1),
            Expanded(
              child: displayText.isEmpty && liveText.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: displayText,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                height: 1.8,
                                color: Colors.white.withOpacity(0.88),
                              ),
                            ),
                            if (liveText.isNotEmpty)
                              TextSpan(
                                text: displayText.isEmpty ? liveText : ' $liveText',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  height: 1.8,
                                  color: const Color(0xFF7B7BFF),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none_rounded,
            size: 52,
            color: const Color(0xFF252547),
          ),
          const SizedBox(height: 16),
          Text(
            _isAvailable ? 'Tap record to start' : 'Initializing microphone...',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF3A3A5C),
            ),
          ),
          if (_isAvailable) ...[
            const SizedBox(height: 8),
            Text(
              'Speech will appear here in real-time',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF2A2A4A),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls(bool hasContent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          // Main record button
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isListening
                      ? [const Color(0xFFFF4444), const Color(0xFFCC2222)]
                      : [const Color(0xFF4A4AFF), const Color(0xFF7B2FFF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening
                            ? const Color(0xFFFF4444)
                            : const Color(0xFF4A4AFF))
                        .withOpacity(0.5),
                    blurRadius: _isListening ? 30 : 20,
                    spreadRadius: _isListening ? 4 : 0,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ).animate().scale(delay: 300.ms),
          const SizedBox(height: 8),
          Text(
            _isListening ? 'Tap to stop' : 'Tap to record',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6C6C8A),
            ),
          ),
          const SizedBox(height: 20),

          // Secondary buttons
          Row(
            children: [
              if (hasContent) ...[
                Expanded(
                  child: _SecondaryButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Clear',
                    color: const Color(0xFFFF6B6B),
                    onTap: _clearTranscript,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: hasContent ? 2 : 1,
                child: _isSummarizing
                    ? Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF252547), Color(0xFF1A1A3A)],
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: const Color(0xFF7B7BFF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Summarizing with AI...',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF7B7BFF),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: hasContent ? _summarizeAndSave : null,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: hasContent
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF4A4AFF),
                                      Color(0xFF7B2FFF)
                                    ],
                                  )
                                : null,
                            color: hasContent ? null : const Color(0xFF1A1A2E),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: hasContent
                                      ? Colors.white
                                      : const Color(0xFF3A3A5C),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Summarize with AI',
                                  style: GoogleFonts.inter(
                                    color: hasContent
                                        ? Colors.white
                                        : const Color(0xFF3A3A5C),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
