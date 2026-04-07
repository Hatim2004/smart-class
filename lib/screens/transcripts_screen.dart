import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/transcript.dart';
import '../services/storage_service.dart';
import 'summary_screen.dart';

class TranscriptsScreen extends StatefulWidget {
  const TranscriptsScreen({super.key});

  @override
  State<TranscriptsScreen> createState() => _TranscriptsScreenState();
}

class _TranscriptsScreenState extends State<TranscriptsScreen> {
  final StorageService _storage = StorageService();
  List<Transcript> _transcripts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _storage.loadAll();
    setState(() {
      _transcripts = data;
      _loading = false;
    });
  }

  Future<void> _delete(String id) async {
    await _storage.delete(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved Classes',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${_transcripts.length} lecture${_transcripts.length == 1 ? '' : 's'} recorded',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6C6C8A),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4A4AFF),
                      ),
                    )
                  : _transcripts.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: const Color(0xFF4A4AFF),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _transcripts.length,
                            itemBuilder: (ctx, i) => _buildCard(
                              _transcripts[i],
                              i,
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: const Color(0xFF252547)),
          const SizedBox(height: 16),
          Text(
            'No recordings yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3A5C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start recording a class to see\nyour transcripts here',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF2A2A4A),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Transcript t, int index) {
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(t.createdAt);
    final hasSummary = t.summary != null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SummaryScreen(transcript: t)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111128),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF252547)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A4AFF), Color(0xFF7B2FFF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6C6C8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _confirmDelete(t.id),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFFF6B6B),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                t.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6C6C8A),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Chip(
                    icon: Icons.access_time_rounded,
                    label: t.formattedDuration,
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    icon: Icons.text_fields_rounded,
                    label: '${t.text.split(' ').length} words',
                  ),
                  const Spacer(),
                  if (hasSummary)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A4AFF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 12, color: Color(0xFF7B7BFF)),
                          const SizedBox(width: 4),
                          Text(
                            'AI Summary',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF7B7BFF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 50 * index))
          .fadeIn()
          .slideY(begin: 0.1),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Recording?',
            style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        content: Text('This cannot be undone.',
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
              _delete(id);
            },
            child: Text('Delete',
                style: GoogleFonts.inter(color: const Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF4A4A6A)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF4A4A6A),
            ),
          ),
        ],
      ),
    );
  }
}
