import 'dart:math';
import 'dart:ui';

import 'package:bloc_clean_architecture/injection.dart';
import 'package:bloc_clean_architecture/src/domain/entities/chat_message.dart';
import 'package:bloc_clean_architecture/src/domain/entities/chat_session.dart';
import 'package:bloc_clean_architecture/src/domain/entities/speaking_grade.dart';
import 'package:bloc_clean_architecture/src/presentation/bloc/ai_teacher/ai_teacher_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// ─── Color palette — dark glassmorphism ──────────────────────────────
class _C {
  static const bg1 = Color(0xFF0A0E27);
  static const bg2 = Color(0xFF1A0F3D);
  static const bg3 = Color(0xFF050613);

  static const accent1 = Color(0xFF7C3AED); // violet
  static const accent2 = Color(0xFF06B6D4); // cyan
  static const accent3 = Color(0xFFEC4899); // pink
  static const success = Color(0xFF34D399);
  static const danger = Color(0xFFF87171);
  static const warning = Color(0xFFFBBF24);

  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFFA5B4D4);
  static const textMuted = Color(0xFF6B7AA8);

  static Color glass(double a) => Colors.white.withValues(alpha: a);
  static Color border(double a) => Colors.white.withValues(alpha: a);
}

class AiTeacherHomeScreen extends StatelessWidget {
  const AiTeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AiTeacherBloc>(
      create: (_) => locator<AiTeacherBloc>()..add(const AiTeacherStarted()),
      child: const _AiTeacherView(),
    );
  }
}

class _AiTeacherView extends StatefulWidget {
  const _AiTeacherView();

  @override
  State<_AiTeacherView> createState() => _AiTeacherViewState();
}

class _AiTeacherViewState extends State<_AiTeacherView>
    with TickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Speech-to-text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;
  String _recognizedText = '';

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (e) {
          if (!mounted) return;
          setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
      );
      if (!mounted) return;
      setState(() => _speechReady = available);
    } catch (_) {
      if (!mounted) return;
      setState(() => _speechReady = false);
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_recognizedText.trim().isNotEmpty) _handleSend();
      return;
    }
    if (!_speechReady) {
      await _initSpeech();
      if (!_speechReady) {
        _toast('Microphone chưa sẵn sàng. Cấp quyền rồi thử lại.', _C.danger);
        return;
      }
    }
    _recognizedText = '';
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        _recognizedText = result.recognizedWords;
        _inputController.value = TextEditingValue(
          text: _recognizedText,
          selection: TextSelection.collapsed(offset: _recognizedText.length),
        );
      },
      localeId: 'en_US',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  void _handleSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    context.read<AiTeacherBloc>().add(AiTeacherMessageSent(text));
    _inputController.clear();
    _recognizedText = '';
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

  void _toast(String msg, Color color) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: color,
      textColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    _bgController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const _HistoryDrawer(),
      drawerScrimColor: Colors.black.withValues(alpha: 0.6),
      extendBodyBehindAppBar: true,
      backgroundColor: _C.bg1,
      body: BlocConsumer<AiTeacherBloc, AiTeacherState>(
        listener: (context, state) {
          _scrollToBottom();
          if (state.status == AiTeacherStatus.error &&
              state.errorMessage != null) {
            _toast(state.errorMessage!, _C.danger);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Background gradient + animated orbs
              _AnimatedBackground(animation: _bgController),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                      state: state,
                    ),
                    if (state.messages.length <= 1)
                      _TopicSuggestions(
                        onPick: (t) => context
                            .read<AiTeacherBloc>()
                            .add(AiTeacherTopicPicked(t)),
                      ),
                    Expanded(
                      child: _ChatList(
                        scrollController: _scrollController,
                        messages: state.messages,
                        isThinking: state.isSending,
                      ),
                    ),
                    if (state.canGrade && state.grade == null)
                      _GradeCtaPill(
                        isLoading: state.isGrading,
                        onTap: () => context
                            .read<AiTeacherBloc>()
                            .add(const AiTeacherGradeRequested()),
                      ),
                    _ChatInputBar(
                      controller: _inputController,
                      enabled:
                          !state.isSending && state.status != AiTeacherStatus.grading,
                      isListening: _isListening,
                      onSend: _handleSend,
                      onMicTap: _toggleListening,
                    ),
                  ],
                ),
              ),

              // Grade card overlay
              if (state.grade != null)
                _GradeOverlay(
                  grade: state.grade!,
                  onClose: () => context
                      .read<AiTeacherBloc>()
                      .add(const AiTeacherGradeDismissed()),
                ),

              // Grading-in-progress overlay
              if (state.isGrading) const _GradingOverlay(),
            ],
          );
        },
      ),
    );
  }
}

// ─── Background ───────────────────────────────────────────────────────
class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.bg1, _C.bg2, _C.bg3],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SizedBox.expand(),
        ),
        // Animated orbs
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _OrbPainter(animation.value),
            );
          },
        ),
      ],
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = <_Orb>[
      _Orb(_C.accent1, 0.0, 220),
      _Orb(_C.accent2, 0.33, 260),
      _Orb(_C.accent3, 0.66, 180),
    ];
    for (final orb in orbs) {
      final p = (t + orb.phase) % 1.0;
      final cx = size.width * (0.2 + 0.6 * sin(p * 2 * pi));
      final cy = size.height * (0.15 + 0.6 * cos(p * 2 * pi * 0.7));
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withValues(alpha: 0.28),
            orb.color.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: orb.r),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(Offset(cx, cy), orb.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => oldDelegate.t != t;
}

class _Orb {
  const _Orb(this.color, this.phase, this.r);
  final Color color;
  final double phase;
  final double r;
}

// ─── Reusable glass card ──────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.borderOpacity = 0.14,
    this.fillOpacity = 0.06,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double borderOpacity;
  final double fillOpacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _C.glass(fillOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: _C.border(borderOpacity), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onMenu, required this.state});

  final VoidCallback onMenu;
  final AiTeacherState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AiTeacherBloc>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: _GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        radius: 22,
        child: Row(
          children: [
            _TopBarIconButton(icon: Icons.menu_rounded, onTap: onMenu),
            const SizedBox(width: 6),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_C.accent1, _C.accent2],
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: _C.accent1.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coach Lumi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _C.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: _C.success, blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          state.isSending
                              ? 'thinking…'
                              : state.isGrading
                                  ? 'grading…'
                                  : '${state.level.label} • online',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _C.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _LevelChip(level: state.level),
            const SizedBox(width: 6),
            _TopBarIconButton(
              icon: state.ttsEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              accent: state.ttsEnabled,
              onTap: () => bloc.add(const AiTeacherTtsToggled()),
            ),
            const SizedBox(width: 4),
            _TopBarIconButton(
              icon: Icons.refresh_rounded,
              onTap: () => bloc.add(const AiTeacherCleared()),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.onTap,
    this.accent = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: accent
              ? _C.accent2.withValues(alpha: 0.18)
              : _C.glass(0.05),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: accent ? _C.accent2.withValues(alpha: 0.4) : _C.border(0.12),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: accent ? _C.accent2 : _C.textPrimary,
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});
  final LearnerLevel level;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LearnerLevel>(
      tooltip: 'Change level',
      offset: const Offset(0, 44),
      color: _C.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (l) => context
          .read<AiTeacherBloc>()
          .add(AiTeacherLevelChanged(l)),
      itemBuilder: (context) => LearnerLevel.values.map((l) {
        return PopupMenuItem<LearnerLevel>(
          value: l,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                l.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: level == l ? FontWeight.w700 : FontWeight.w500,
                  color: level == l ? _C.accent2 : _C.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _C.accent1.withValues(alpha: 0.25),
              _C.accent2.withValues(alpha: 0.18),
            ],
          ),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: _C.accent2.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(level.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: _C.textPrimary),
          ],
        ),
      ),
    );
  }
}

// ─── Topic suggestions ────────────────────────────────────────────────
class _TopicSuggestions extends StatelessWidget {
  const _TopicSuggestions({required this.onPick});
  final ValueChanged<String> onPick;

  static const _topics = <Map<String, dynamic>>[
    {'label': 'Daily Life', 'emoji': '☀️', 'color': _C.warning},
    {'label': 'Travel', 'emoji': '✈️', 'color': _C.accent2},
    {'label': 'Hobbies', 'emoji': '🎨', 'color': _C.accent3},
    {'label': 'Food', 'emoji': '🍜', 'color': _C.danger},
    {'label': 'Job Interview', 'emoji': '💼', 'color': _C.accent1},
    {'label': 'Technology', 'emoji': '📱', 'color': _C.success},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_C.accent1, _C.accent2],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'PICK A TOPIC',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _C.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: _topics.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final t = _topics[i];
                return _TopicCard(
                  label: t['label'] as String,
                  emoji: t['emoji'] as String,
                  color: t['color'] as Color,
                  onTap: () => onPick(t['label'] as String),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 112,
        child: _GlassCard(
          padding: const EdgeInsets.all(10),
          radius: 18,
          borderOpacity: 0.16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.35),
                      color.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chat list ────────────────────────────────────────────────────────
class _ChatList extends StatelessWidget {
  const _ChatList({
    required this.scrollController,
    required this.messages,
    required this.isThinking,
  });

  final ScrollController scrollController;
  final List<ChatMessage> messages;
  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    final visible =
        messages.where((m) => m.role != MessageRole.system).toList();
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      itemCount: visible.length + (isThinking ? 1 : 0),
      itemBuilder: (context, index) {
        if (isThinking && index == visible.length) {
          return const _TypingBubble();
        }
        final msg = visible[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ChatBubble(message: msg),
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final maxW = MediaQuery.of(context).size.width * 0.78;

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) const _AvatarOwl(),
        if (!isUser) const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [_C.accent1, _C.accent2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [_C.glass(0.10), _C.glass(0.04)],
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 20),
                    ),
                    border: Border.all(
                      color: isUser
                          ? _C.accent2.withValues(alpha: 0.4)
                          : _C.border(0.14),
                      width: 1,
                    ),
                    boxShadow: isUser
                        ? [
                            BoxShadow(
                              color: _C.accent1.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: SelectableText(
                    message.content,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isUser ? Colors.white : _C.textPrimary,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isUser) const SizedBox(width: 8),
        if (isUser) const _AvatarUser(),
      ],
    );
  }
}

class _AvatarOwl extends StatelessWidget {
  const _AvatarOwl();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.accent1, _C.accent2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: _C.accent1.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
    );
  }
}

class _AvatarUser extends StatelessWidget {
  const _AvatarUser();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _C.glass(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border(0.2), width: 1),
      ),
      child: const Icon(Icons.person_rounded, color: _C.textPrimary, size: 18),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const _AvatarOwl(),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(20),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _C.glass(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: _C.border(0.14), width: 1),
                ),
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final t = (_ctrl.value + i * 0.2) % 1.0;
                        final y = -3.0 * (0.5 - (t - 0.5).abs()) * 2;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
                          child: Transform.translate(
                            offset: Offset(0, y),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: _C.accent2,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grade CTA pill ───────────────────────────────────────────────────
class _GradeCtaPill extends StatelessWidget {
  const _GradeCtaPill({required this.onTap, required this.isLoading});
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.accent3.withValues(alpha: 0.25),
                    _C.accent1.withValues(alpha: 0.20),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _C.accent3.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_C.accent3, _C.accent1],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Grade my speaking',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _C.textPrimary,
                          ),
                        ),
                        Text(
                          'Let Coach Lumi score your performance',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _C.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _C.accent3,
                      ),
                    )
                  else
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: _C.textPrimary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Grading-in-progress overlay ──────────────────────────────────────
class _GradingOverlay extends StatelessWidget {
  const _GradingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: _GlassCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 28),
              radius: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(_C.accent3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Grading your speaking…',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Coach Lumi is reading every word ✍️',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _C.textSecondary,
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
}

// ─── Grade overlay (full sheet) ───────────────────────────────────────
class _GradeOverlay extends StatelessWidget {
  const _GradeOverlay({required this.grade, required this.onClose});
  final SpeakingGrade grade;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.55),
            child: SafeArea(
              child: GestureDetector(
                onTap: () {},
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: _GradeCard(grade: grade, onClose: onClose),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.grade, required this.onClose});
  final SpeakingGrade grade;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      radius: 24,
      fillOpacity: 0.10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_C.accent3, _C.accent1]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Speaking report',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary,
                      ),
                    ),
                    Text(
                      'by Coach Lumi',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: _C.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _C.glass(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.border(0.2)),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: _C.textPrimary, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overall score circle
          Center(
            child: _ScoreCircle(score: grade.overall, letter: grade.letterGrade),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Overall',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _C.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
          ),

          if (grade.summary.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              grade.summary,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _C.textPrimary,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 20),
          _CriteriaBar(label: 'Grammar', value: grade.grammar),
          const SizedBox(height: 10),
          _CriteriaBar(label: 'Vocabulary', value: grade.vocabulary),
          const SizedBox(height: 10),
          _CriteriaBar(label: 'Fluency', value: grade.fluency),
          const SizedBox(height: 10),
          _CriteriaBar(label: 'Content', value: grade.content),

          if (grade.strengths.isNotEmpty) ...[
            const SizedBox(height: 20),
            _BulletSection(
              title: 'Strengths',
              icon: Icons.thumb_up_rounded,
              color: _C.success,
              items: grade.strengths,
            ),
          ],
          if (grade.improvements.isNotEmpty) ...[
            const SizedBox(height: 16),
            _BulletSection(
              title: 'Improve',
              icon: Icons.trending_up_rounded,
              color: _C.warning,
              items: grade.improvements,
            ),
          ],
          if (grade.corrections.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CorrectionsSection(corrections: grade.corrections),
          ],
        ],
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  const _ScoreCircle({required this.score, required this.letter});
  final double score;
  final String letter;

  @override
  Widget build(BuildContext context) {
    final pct = (score / 10).clamp(0.0, 1.0);
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: 10,
              backgroundColor: _C.glass(0.08),
              valueColor: AlwaysStoppedAnimation(
                  score >= 7 ? _C.success
                      : score >= 5 ? _C.warning
                      : _C.danger),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '/ 10  •  $letter',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _C.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CriteriaBar extends StatelessWidget {
  const _CriteriaBar({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final pct = (value / 10).clamp(0.0, 1.0);
    final color = value >= 7
        ? _C.success
        : value >= 5
            ? _C.warning
            : _C.danger;
    return Row(
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _C.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 8,
              color: _C.glass(0.08),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.8), color],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _C.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: _C.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CorrectionsSection extends StatelessWidget {
  const _CorrectionsSection({required this.corrections});
  final List<GradeCorrection> corrections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_fix_high_rounded,
                size: 16, color: _C.accent2),
            const SizedBox(width: 6),
            Text(
              'CORRECTIONS',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _C.accent2,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...corrections.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.glass(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“${c.original}”',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: _C.danger,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '→ ${c.suggested}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _C.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (c.why.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    c.why,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: _C.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Chat input bar ───────────────────────────────────────────────────
class _ChatInputBar extends StatefulWidget {
  const _ChatInputBar({
    required this.controller,
    required this.enabled,
    required this.isListening,
    required this.onSend,
    required this.onMicTap,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isListening;
  final VoidCallback onSend;
  final VoidCallback onMicTap;

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: _GlassCard(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        radius: 22,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [LengthLimitingTextInputFormatter(500)],
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => widget.onSend(),
                  cursorColor: _C.accent2,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _C.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: !widget.enabled
                        ? 'Coach Lumi is busy…'
                        : widget.isListening
                            ? 'Listening… speak in English 🎙️'
                            : 'Say or type in English…',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: widget.isListening
                          ? _C.accent3
                          : _C.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            _PrimaryActionButton(
              hasText: _hasText,
              enabled: widget.enabled,
              isListening: widget.isListening,
              onSend: widget.onSend,
              onMic: widget.onMicTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatefulWidget {
  const _PrimaryActionButton({
    required this.hasText,
    required this.enabled,
    required this.isListening,
    required this.onSend,
    required this.onMic,
  });

  final bool hasText;
  final bool enabled;
  final bool isListening;
  final VoidCallback onSend;
  final VoidCallback onMic;

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.isListening) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PrimaryActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isListening && _pulseCtrl.isAnimating) {
      _pulseCtrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.isListening;
    final isSend = widget.hasText && !isListening;

    final Gradient gradient;
    final IconData icon;
    final VoidCallback? onTap;
    final Color glow;

    if (isListening) {
      gradient = const LinearGradient(colors: [_C.accent3, _C.danger]);
      glow = _C.accent3;
      icon = Icons.stop_rounded;
      onTap = widget.onMic;
    } else if (isSend) {
      gradient = const LinearGradient(colors: [_C.accent1, _C.accent2]);
      glow = _C.accent2;
      icon = Icons.send_rounded;
      onTap = widget.enabled ? widget.onSend : null;
    } else {
      gradient = const LinearGradient(colors: [_C.accent2, _C.accent1]);
      glow = _C.accent2;
      icon = Icons.mic_rounded;
      onTap = widget.enabled ? widget.onMic : null;
    }

    return Opacity(
      opacity: widget.enabled || isListening ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final scale = isListening ? 1.0 + _pulseCtrl.value * 0.10 : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: isListening ? 0.6 : 0.4),
                  blurRadius: isListening ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

// ─── History drawer ───────────────────────────────────────────────────
class _HistoryDrawer extends StatelessWidget {
  const _HistoryDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.82,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _C.bg1.withValues(alpha: 0.95),
                  _C.bg2.withValues(alpha: 0.95),
                ],
              ),
              border: Border.all(color: _C.border(0.12)),
            ),
            child: SafeArea(
              child: BlocBuilder<AiTeacherBloc, AiTeacherState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_C.accent1, _C.accent2],
                                ),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.history_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Chat history',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _C.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${state.sessions.length} saved sessions',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: _C.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                context
                                    .read<AiTeacherBloc>()
                                    .add(const AiTeacherCleared());
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_C.accent1, _C.accent2],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_rounded,
                                        color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'New',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                          color: Colors.white24,
                          height: 16,
                          indent: 18,
                          endIndent: 18),
                      Expanded(
                        child: state.sessions.isEmpty
                            ? _EmptyHistory()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                itemCount: state.sessions.length,
                                itemBuilder: (context, i) {
                                  final s = state.sessions[i];
                                  final selected = s.id == state.sessionId;
                                  return _SessionTile(
                                    session: s,
                                    selected: selected,
                                    onOpen: () {
                                      Navigator.pop(context);
                                      context
                                          .read<AiTeacherBloc>()
                                          .add(AiTeacherSessionOpened(s));
                                    },
                                    onDelete: () => context
                                        .read<AiTeacherBloc>()
                                        .add(AiTeacherSessionDeleted(s.id)),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _C.glass(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: _C.border(0.12)),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: _C.textSecondary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'No chats yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your speaking sessions appear here',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _C.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.selected,
    required this.onOpen,
    required this.onDelete,
  });
  final ChatSession session;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      _C.accent1.withValues(alpha: 0.30),
                      _C.accent2.withValues(alpha: 0.20),
                    ],
                  )
                : null,
            color: selected ? null : _C.glass(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? _C.accent2.withValues(alpha: 0.45)
                  : _C.border(0.10),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.level.emoji,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 11, color: _C.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          _timeAgo(session.updatedAt),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _C.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 11, color: _C.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          '${session.messages.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _C.textMuted,
                          ),
                        ),
                        if (session.grade != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: _C.accent3.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${session.grade!.overall.toStringAsFixed(1)}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: _C.accent3,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 18, color: _C.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
