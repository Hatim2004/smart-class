import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transcript.dart';

class SummaryScreen extends StatefulWidget {
  final Transcript transcript;
  const SummaryScreen({super.key, required this.transcript});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int _selectedTab = 0;

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard', style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF252547),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: _selectedTab == 0
                  ? _buildSummaryTab()
                  : _buildTranscriptTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _copyToClipboard(
                  _selectedTab == 0
                      ? (widget.transcript.summary ?? '')
                      : widget.transcript.text,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252547),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.copy_rounded,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text('Copy',
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF4A4AFF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '✨ AI SUMMARY',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: const Color(0xFF7B7BFF),
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.transcript.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoChip(
                icon: Icons.access_time_rounded,
                label: widget.transcript.formattedDuration,
              ),
              const SizedBox(width: 10),
              _InfoChip(
                icon: Icons.text_fields_rounded,
                label:
                    '${widget.transcript.text.split(' ').length} words',
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111128),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF252547)),
        ),
        child: Row(
          children: [
            _TabButton(
              label: 'Summary',
              icon: Icons.auto_awesome_rounded,
              selected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            _TabButton(
              label: 'Full Transcript',
              icon: Icons.subject_rounded,
              selected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildSummaryTab() {
    final summary = widget.transcript.summary ?? 'No summary available.';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111128),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF252547)),
        ),
        padding: const EdgeInsets.all(20),
        child: Text(
          summary,
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.8,
            color: Colors.white.withOpacity(0.88),
          ),
        ),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildTranscriptTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111128),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF252547)),
        ),
        padding: const EdgeInsets.all(20),
        child: Text(
          widget.transcript.text,
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.9,
            color: Colors.white.withOpacity(0.80),
          ),
        ),
      ).animate().fadeIn(delay: 200.ms),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF6C6C8A)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6C6C8A),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF252547) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color:
                      selected ? const Color(0xFF7B7BFF) : Colors.white38),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? Colors.white : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
