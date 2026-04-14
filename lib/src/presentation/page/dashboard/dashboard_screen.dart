import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  late AnimationController _fadeController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(),

          // Particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _DashboardParticlePainter(
                  progress: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomePage(),
                  _buildPracticePage(),
                  _buildProgressPage(),
                  _buildProfilePage(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0A2E),
            Color(0xFF0D1230),
            Color(0xFF050515),
          ],
        ),
      ),
    );
  }

  // ─── HOME PAGE ────────────────────────────────────────────────────
  Widget _buildHomePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildGreetingHeader(),
            const SizedBox(height: 24),
            _buildBandScoreCard(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 28),
            _buildSectionTitle('IELTS Speaking Parts', 'Practice now'),
            const SizedBox(height: 14),
            _buildSpeakingParts(),
            const SizedBox(height: 28),
            _buildSectionTitle('Recent Sessions', 'View all'),
            const SizedBox(height: 14),
            _buildRecentSessions(),
            const SizedBox(height: 28),
            _buildDailyTip(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Learner 👋',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Let's practice speaking today!",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF8DA4EF),
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF4A6CF7), Color(0xFF00C6FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A6CF7).withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 26),
        ),
      ],
    );
  }

  Widget _buildBandScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B5FD9),
            Color(0xFF2563EB),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Band Score',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '6.5',
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 6),
                        child: Text(
                          '/ 9.0',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white60,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Target badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        color: Color(0xFFFBBF24), size: 16,),
                    const SizedBox(width: 6),
                    Text(
                      'Target: 7.5',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Score breakdown
          Row(
            children: [
              _buildScoreItem('Fluency', 6.5, const Color(0xFF34D399)),
              const SizedBox(width: 10),
              _buildScoreItem('Vocab', 7, const Color(0xFF60A5FA)),
              const SizedBox(width: 10),
              _buildScoreItem('Grammar', 6, const Color(0xFFFBBF24)),
              const SizedBox(width: 10),
              _buildScoreItem('Pronun.', 6.5, const Color(0xFFF472B6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, double score, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              score.toString(),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white60,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionCard(
          icon: Icons.mic_rounded,
          label: 'New\nSession',
          gradient: const [Color(0xFF4A6CF7), Color(0xFF2A8AF6)],
          onTap: () {},
        ),
        const SizedBox(width: 12),
        _buildActionCard(
          icon: Icons.auto_stories_rounded,
          label: 'Topic\nBank',
          gradient: const [Color(0xFF7C3AED), Color(0xFF9F67FF)],
          onTap: () {},
        ),
        const SizedBox(width: 12),
        _buildActionCard(
          icon: Icons.analytics_rounded,
          label: 'AI\nFeedback',
          gradient: const [Color(0xFF059669), Color(0xFF34D399)],
          onTap: () {},
        ),
        const SizedBox(width: 12),
        _buildActionCard(
          icon: Icons.school_rounded,
          label: 'Mock\nTest',
          gradient: const [Color(0xFFDB4437), Color(0xFFF472B6)],
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradient[0].withValues(alpha: 0.2),
                gradient[1].withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(
              color: gradient[0].withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradient),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            action,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF4A6CF7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakingParts() {
    final parts = [
      {
        'title': 'Part 1: Introduction',
        'desc': 'Familiar topics & personal questions',
        'duration': '4-5 min',
        'icon': Icons.record_voice_over_rounded,
        'color': const Color(0xFF4A6CF7),
        'topics': '25 topics',
      },
      {
        'title': 'Part 2: Long Turn',
        'desc': 'Describe a topic with cue card',
        'duration': '3-4 min',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF7C3AED),
        'topics': '30 topics',
      },
      {
        'title': 'Part 3: Discussion',
        'desc': 'In-depth discussion & abstract ideas',
        'duration': '4-5 min',
        'icon': Icons.forum_rounded,
        'color': const Color(0xFF059669),
        'topics': '20 topics',
      },
    ];

    return Column(
      children: parts.map((part) {
        final color = part['color']! as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              end: Alignment.centerRight,
              colors: [
                color.withValues(alpha: 0.15),
                const Color(0xFF0F1835).withValues(alpha: 0.6),
              ],
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.6)],
                  ),
                ),
                child: Icon(part['icon']! as IconData,
                    color: Colors.white, size: 24,),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part['title']! as String,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      part['desc']! as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF8DA4EF),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      part['topics']! as String,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    part['duration']! as String,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentSessions() {
    final sessions = [
      {
        'topic': 'Describe a place you visited',
        'part': 'Part 2',
        'score': '7.0',
        'time': '2h ago',
        'color': const Color(0xFF7C3AED),
      },
      {
        'topic': 'Hobbies and Leisure',
        'part': 'Part 1',
        'score': '6.5',
        'time': 'Yesterday',
        'color': const Color(0xFF4A6CF7),
      },
      {
        'topic': 'Education & Technology',
        'part': 'Part 3',
        'score': '6.0',
        'time': '2 days ago',
        'color': const Color(0xFF059669),
      },
    ];

    return Column(
      children: sessions.map((session) {
        final color = session['color']! as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF0F1835).withValues(alpha: 0.8),
            border: Border.all(
              color: const Color(0xFF2A3A6A).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    session['score']! as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['topic']! as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2,),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            session['part']! as String,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          session['time']! as String,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white24, size: 24,),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDailyTip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFBBF24).withValues(alpha: 0.12),
            const Color(0xFFF59E0B).withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.lightbulb_rounded,
                color: Color(0xFFFBBF24), size: 24,),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Speaking Tip',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFBBF24),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use linking words like "moreover", "however" to boost your Coherence score.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF8DA4EF),
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PRACTICE PAGE ────────────────────────────────────────────────
  Widget _buildPracticePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4A6CF7), Color(0xFF00C6FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A6CF7).withValues(alpha: 0.4),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Tap to Start Speaking',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI will analyze your pronunciation,\nfluency and grammar in real-time',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF8DA4EF),
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROGRESS PAGE ────────────────────────────────────────────────
  Widget _buildProgressPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Your Progress',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Stats row
            Row(
              children: [
                _buildStatCard('Sessions', '24', Icons.mic_rounded,
                    const Color(0xFF4A6CF7),),
                const SizedBox(width: 12),
                _buildStatCard('Hours', '12.5', Icons.access_time_rounded,
                    const Color(0xFF7C3AED),),
                const SizedBox(width: 12),
                _buildStatCard('Streak', '7 🔥', Icons.local_fire_department,
                    const Color(0xFFF59E0B),),
              ],
            ),
            const SizedBox(height: 24),
            // Weekly chart placeholder
            _buildWeeklyChart(),
            const SizedBox(height: 24),
            // Skills breakdown
            _buildSkillsBreakdown(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color,) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = [0.4, 0.7, 0.5, 0.9, 0.6, 0.3, 0.8];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0F1835).withValues(alpha: 0.8),
        border: Border.all(
            color: const Color(0xFF2A3A6A).withValues(alpha: 0.4),),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 28,
                      height: 90 * values[i],
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF4A6CF7),
                            const Color(0xFF4A6CF7).withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[i],
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsBreakdown() {
    final skills = [
      {'name': 'Fluency & Coherence', 'score': 0.72, 'color': const Color(0xFF34D399)},
      {'name': 'Lexical Resource', 'score': 0.78, 'color': const Color(0xFF60A5FA)},
      {'name': 'Grammar Range', 'score': 0.65, 'color': const Color(0xFFFBBF24)},
      {'name': 'Pronunciation', 'score': 0.70, 'color': const Color(0xFFF472B6)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0F1835).withValues(alpha: 0.8),
        border: Border.all(
            color: const Color(0xFF2A3A6A).withValues(alpha: 0.4),),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          ...skills.map((skill) {
            final score = skill['score']! as double;
            final color = skill['color']! as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        skill['name']! as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${(score * 100).toInt()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: score,
                      minHeight: 8,
                      backgroundColor:
                          const Color(0xFF2A3A6A).withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── PROFILE PAGE ─────────────────────────────────────────────────
  Widget _buildProfilePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A6CF7), Color(0xFF00C6FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A6CF7).withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child:
                  const Icon(Icons.person, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 16),
            Text(
              'Learner',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'learner@email.com',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF8DA4EF),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFBBF24).withValues(alpha: 0.15),
                    const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '⭐ Premium Member',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFFFBBF24),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Menu items
            _buildMenuItem(
                Icons.settings_outlined, 'Settings', Colors.white60,),
            _buildMenuItem(Icons.notifications_outlined, 'Notifications',
                Colors.white60,),
            _buildMenuItem(
                Icons.language_rounded, 'Language', Colors.white60,),
            _buildMenuItem(
                Icons.help_outline_rounded, 'Help & Support', Colors.white60,),
            _buildMenuItem(
                Icons.info_outline_rounded, 'About', Colors.white60,),
            const SizedBox(height: 16),
            _buildMenuItem(
                Icons.logout_rounded, 'Log Out', const Color(0xFFFF6B6B),),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0F1835).withValues(alpha: 0.6),
        border: Border.all(
          color: const Color(0xFF2A3A6A).withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: Colors.white24, size: 22,),
        onTap: () {},
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ─── BOTTOM NAVIGATION BAR ────────────────────────────────────────
  Widget _buildBottomNavBar() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E24),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF2A3A6A).withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.mic_rounded, 'Practice'),
              _buildNavItem(2, Icons.bar_chart_rounded, 'Progress'),
              _buildNavItem(3, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? const Color(0xFF4A6CF7).withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected ? const Color(0xFF4A6CF7) : const Color(0xFF4A5580),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF4A6CF7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Particle Painter for dashboard
class _DashboardParticlePainter extends CustomPainter {

  _DashboardParticlePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(55);

    for (var i = 0; i < 12; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.15 + random.nextDouble() * 0.3;
      final particleSize = 1.0 + random.nextDouble() * 1.5;

      final animatedY = (baseY - progress * size.height * speed) % size.height;
      final animatedX = baseX + sin((progress * 2 * pi) + i) * 10;

      final distFromCenter = (animatedY / size.height - 0.5).abs();
      final opacity = (1.0 - distFromCenter * 2).clamp(0.0, 0.25);

      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFF4A6CF7),
          const Color(0xFF00D2FF),
          random.nextDouble(),
        )!
            .withValues(alpha: opacity * 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(animatedX, animatedY), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}