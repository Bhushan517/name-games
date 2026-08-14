import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = !(prefs.getBool('seen') ?? false);
  runApp(App(first: isFirstLaunch));
}

const bg = Color(0xFF060916);
const cyan = Color(0xFF25F1DF);
const purple = Color(0xFF9A60FF);
const pink = Color(0xFFFF5D9E);
const gold = Color(0xFFFFD45C);

class App extends StatelessWidget {
  const App({super.key, required this.first});
  final bool first;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spell & Shape Quest',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: first ? const Splash() : const Home(),
    );
  }
}

class Space extends StatelessWidget {
  const Space({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1, -1),
              radius: 1.35,
              colors: [Color(0xFF321360), bg, Color(0xFF02040B)],
            ),
          ),
        ),
        const CustomPaint(painter: Stars()),
        SafeArea(child: child),
      ],
    );
  }
}

class Stars extends CustomPainter {
  const Stars();

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    for (var i = 0; i < 95; i++) {
      final offset = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = 0.5 + random.nextDouble() * 1.2;
      final starColor = (i % 9 == 0 ? cyan : Colors.white).withValues(
        alpha: 0.15 + random.nextDouble() * 0.45,
      );
      canvas.drawCircle(offset, radius, Paint()..color = starColor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late final AnimationController spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final AnimationController enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder<void>(
            pageBuilder: (context, anim, secAnim) => const Onboarding(),
            transitionsBuilder: (context, animation, secAnim, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 650),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    spin.dispose();
    enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Space(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: FadeTransition(
              opacity: enter,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(parent: enter, curve: Curves.elasticOut),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RotationTransition(
                      turns: spin,
                      child: Container(
                        width: 128,
                        height: 128,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const SweepGradient(
                            colors: [cyan, purple, pink, cyan],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cyan.withValues(alpha: 0.35),
                              blurRadius: 45,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: bg,
                          ),
                          child: const Icon(
                            Icons.gesture_rounded,
                            color: cyan,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'SPELL & SHAPE',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const Text(
                      'Q U E S T',
                      style: TextStyle(
                        color: cyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 130,
                      child: LinearProgressIndicator(
                        color: cyan,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Slide {
  const Slide(this.icon, this.title, this.text, this.color);
  final IconData icon;
  final String title;
  final String text;
  final Color color;
}

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController pc = PageController();
  int page = 0;

  final List<Slide> slides = const [
    Slide(
      Icons.shuffle_rounded,
      'UNSCRAMBLE WORDS',
      'Use the picture and sentence clue to discover a meaningful word.',
      cyan,
    ),
    Slide(
      Icons.auto_awesome_rounded,
      'REVEAL PATTERNS',
      'Tap letters in order. Every correct word reveals a magical hidden shape.',
      purple,
    ),
    Slide(
      Icons.school_rounded,
      'LEARN & WIN',
      'Improve spelling, learn meanings and collect three stars on every level.',
      pink,
    ),
  ];

  Future<void> finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const Home()),
      );
    }
  }

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Space(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: TextButton(
                  onPressed: finish,
                  child: const Text('SKIP'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pc,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => page = i),
                itemBuilder: (_, i) {
                  final s = slides[i];
                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            key: ValueKey(i),
                            tween: Tween<double>(begin: 0.4, end: 1.0),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.elasticOut,
                            builder: (_, v, child) =>
                                Transform.scale(scale: v, child: child),
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: s.color.withValues(alpha: 0.12),
                                border: Border.all(color: s.color, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: s.color.withValues(alpha: 0.22),
                                    blurRadius: 50,
                                  ),
                                ],
                              ),
                              child: Icon(s.icon, color: s.color, size: 80),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            s.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            s.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: Colors.white.withValues(alpha: 0.68),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.all(4),
                        width: i == page ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == page
                              ? slides[page].color
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: page == slides.length - 1
                          ? finish
                          : () => pc.nextPage(
                                duration: const Duration(milliseconds: 420),
                                curve: Curves.easeOutCubic,
                              ),
                      child: Text(
                        page == slides.length - 1
                            ? 'START THE QUEST'
                            : 'NEXT  →',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late final AnimationController float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Space(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cyan.withValues(alpha: 0.12),
                      border: Border.all(color: cyan),
                    ),
                    child: const Icon(Icons.gesture_rounded, color: cyan),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SPELL & SHAPE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Learn • Connect • Reveal',
                          style: TextStyle(color: cyan, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const Help(),
                    ),
                    icon: const Icon(Icons.help_outline_rounded),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        AnimatedBuilder(
                          animation: float,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, -8 + float.value * 16),
                            child: child,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      purple.withValues(alpha: 0.28),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cyan.withValues(alpha: 0.2),
                                      blurRadius: 70,
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                '✨',
                                style: TextStyle(fontSize: 110),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'WORDS CREATE MAGIC',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Unscramble the word. Reveal the shape.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.055),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stat(Icons.flag_rounded, '5', 'LEVELS'),
                              SizedBox(width: 26),
                              Stat(Icons.favorite_rounded, '3', 'LIVES'),
                              SizedBox(width: 26),
                              Stat(Icons.star_rounded, '15', 'STARS'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const LevelMap(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 30,
                            ),
                            label: const Text(
                              'PLAY NOW',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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
}

class Stat extends StatelessWidget {
  const Stat(this.icon, this.value, this.label, {super.key});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: gold, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white54),
        ),
      ],
    );
  }
}

class Help extends StatelessWidget {
  const Help({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('HOW TO PLAY'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Rule(Icons.image_rounded, 'Read the emoji and fill-in-the-blank clue.'),
            Rule(Icons.touch_app_rounded, 'Tap scrambled letters in spelling order.'),
            Rule(Icons.check_circle_rounded, 'Check the word to reveal its pattern.'),
            Rule(Icons.favorite_rounded, 'A wrong word costs one life.'),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('GOT IT'),
        ),
      ],
    );
  }
}

class Rule extends StatelessWidget {
  const Rule(this.icon, this.text, {super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: cyan, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class WordLevel {
  const WordLevel(
    this.word,
    this.emoji,
    this.clue,
    this.meaning,
    this.shape,
    this.color,
    this.points,
  );
  final String word;
  final String emoji;
  final String clue;
  final String meaning;
  final String shape;
  final Color color;
  final List<Offset> points;
}

const levels = [
  WordLevel(
    'SHINE',
    '✨',
    'The sun can _____ brightly.',
    'To produce or reflect bright light.',
    'STAR',
    cyan,
    [
      Offset(0.49, 0.04),
      Offset(0.61, 0.62),
      Offset(0.08, 0.25),
      Offset(0.90, 0.25),
      Offset(0.37, 0.62),
    ],
  ),
  WordLevel(
    'HOUSE',
    '🏠',
    'We live with our family in a _____.',
    'A building used as a home.',
    'HOUSE',
    purple,
    [
      Offset(0.15, 0.48),
      Offset(0.50, 0.08),
      Offset(0.85, 0.48),
      Offset(0.85, 0.88),
      Offset(0.15, 0.88),
    ],
  ),
  WordLevel(
    'CROWN',
    '👑',
    'A king or queen wears a _____.',
    'A special royal headpiece.',
    'CROWN',
    gold,
    [
      Offset(0.08, 0.80),
      Offset(0.18, 0.20),
      Offset(0.50, 0.62),
      Offset(0.82, 0.20),
      Offset(0.92, 0.80),
    ],
  ),
  WordLevel(
    'HEART',
    '🫀',
    'This organ pumps blood: _____.',
    'The organ that keeps blood moving.',
    'HEART',
    pink,
    [
      Offset(0.50, 0.88),
      Offset(0.08, 0.42),
      Offset(0.28, 0.15),
      Offset(0.50, 0.36),
      Offset(0.72, 0.15),
    ],
  ),
  WordLevel(
    'PLANT',
    '🌱',
    'It grows in soil and has leaves: _____.',
    'A living thing with roots and leaves.',
    'TREE',
    Color(0xFF58E68A),
    [
      Offset(0.50, 0.05),
      Offset(0.50, 0.86),
      Offset(0.08, 0.55),
      Offset(0.50, 0.24),
      Offset(0.92, 0.55),
    ],
  ),
];

class LevelMap extends StatefulWidget {
  const LevelMap({super.key});

  @override
  State<LevelMap> createState() => _LevelMapState();
}

class _LevelMapState extends State<LevelMap> {
  int unlocked = 1;
  final stars = <int, int>{};

  Future<void> open(int i) async {
    if (i >= unlocked) return;
    final r = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => Game(i)),
    );
    if (r != null && mounted) {
      setState(() {
        stars[i] = max(stars[i] ?? 0, r);
        unlocked = min(5, max(unlocked, i + 2));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Space(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR JOURNEY',
                          style: TextStyle(
                            fontSize: 12,
                            color: cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'CHOOSE A LEVEL',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.map_rounded, color: gold),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                itemCount: 5,
                itemBuilder: (_, i) {
                  final l = levels[i];
                  final locked = i >= unlocked;
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 350 + i * 80),
                    curve: Curves.easeOutBack,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: i.isOdd ? 45 : 0,
                        right: i.isEven ? 45 : 0,
                        bottom: 15,
                      ),
                      child: InkWell(
                        onTap: () => open(i),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121A31),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: locked ? Colors.white12 : l.color,
                            ),
                            boxShadow: locked
                                ? null
                                : [
                                    BoxShadow(
                                      color: l.color.withValues(alpha: 0.16),
                                      blurRadius: 20,
                                    ),
                                  ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                locked ? '🔒' : l.emoji,
                                style: const TextStyle(fontSize: 34),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'LEVEL ${i + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: locked
                                            ? Colors.white38
                                            : l.color,
                                      ),
                                    ),
                                    Text(
                                      locked ? 'LOCKED' : l.shape,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: locked
                                            ? Colors.white38
                                            : Colors.white,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        3,
                                        (s) => Icon(
                                          s < (stars[i] ?? 0)
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          size: 16,
                                          color: s < (stars[i] ?? 0)
                                              ? gold
                                              : Colors.white24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.play_circle_fill_rounded,
                                color: locked ? Colors.white12 : l.color,
                                size: 30,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Node {
  Node(this.letter, this.position);
  final String letter;
  final Offset position;
}

class Game extends StatefulWidget {
  const Game(this.index, {super.key});
  final int index;

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> with TickerProviderStateMixin {
  late final WordLevel l = levels[widget.index];
  late List<Node> nodes;
  final selected = <int>[];
  int lives = 3;
  bool done = false;
  bool hinted = false;
  late final AnimationController shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    nodes = List.generate(5, (i) => Node(l.word[i], l.points[i]))
      ..shuffle(Random());
  }

  @override
  void dispose() {
    shake.dispose();
    super.dispose();
  }

  String get attempt => selected.map((i) => nodes[i].letter).join();

  void choose(int i) {
    if (done || selected.contains(i)) return;
    HapticFeedback.selectionClick();
    setState(() => selected.add(i));
  }

  void undo() {
    if (selected.isNotEmpty && !done) {
      setState(() => selected.removeLast());
    }
  }

  Future<void> check() async {
    if (selected.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use all 5 letters first!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (attempt == l.word) {
      HapticFeedback.heavyImpact();
      setState(() => done = true);
      await Future.delayed(const Duration(milliseconds: 650));
      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => Win(
            l,
            hinted ? 2 : (lives == 3 ? 3 : 2),
            () {
              Navigator.pop(context);
              Navigator.pop(context, hinted ? 2 : (lives == 3 ? 3 : 2));
            },
          ),
        );
      }
      return;
    }

    HapticFeedback.vibrate();
    await shake.forward(from: 0);
    setState(() {
      lives--;
      selected.clear();
      nodes.shuffle(Random());
    });

    if (lives == 0 && mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('OUT OF LIVES 💔'),
          content: const Text('Look at the clue and try once more!'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => lives = 3);
              },
              child: const Text('TRY AGAIN'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Space(
        child: AnimatedBuilder(
          animation: shake,
          builder: (_, child) => Transform.translate(
            offset: Offset(sin(shake.value * pi * 6) * 10, 0),
            child: child,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LEVEL ${widget.index + 1} / 5',
                            style: TextStyle(color: l.color, fontSize: 11),
                          ),
                          Text(
                            l.shape,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(
                        3,
                        (i) => AnimatedScale(
                          duration: const Duration(milliseconds: 220),
                          scale: i < lives ? 1 : 0,
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: pink,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.055),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Text(l.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 2),
                      Text(
                        l.clue,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextButton.icon(
                        onPressed: hinted || selected.isNotEmpty
                            ? null
                            : () => setState(() => hinted = true),
                        icon: const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                        ),
                        label: Text(
                          hinted
                              ? 'STARTS WITH ${l.word[0]}'
                              : 'FIRST LETTER HINT',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final has = i < selected.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 36,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: has
                          ? l.color.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: has
                            ? l.color
                            : (hinted && i == 0 ? gold : Colors.white12),
                      ),
                    ),
                    child: Text(
                      has
                          ? nodes[selected[i]].letter
                          : (hinted && i == 0 ? l.word[0] : '•'),
                      style: TextStyle(
                        color: has ? l.color : Colors.white38,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  );
                }),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final areaWidth = constraints.maxWidth;
                    final areaHeight = constraints.maxHeight;
                    const nodeRadius = 27.0;

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: Lines(
                              nodes,
                              selected,
                              Size(areaWidth, areaHeight),
                              l.color,
                              done,
                            ),
                          ),
                        ),
                        ...List.generate(5, (i) {
                          final n = nodes[i];
                          final sel = selected.contains(i);
                          final leftPos = (n.position.dx * areaWidth - nodeRadius)
                              .clamp(4.0, areaWidth - nodeRadius * 2 - 4);
                          final topPos = (n.position.dy * areaHeight - nodeRadius)
                              .clamp(4.0, areaHeight - nodeRadius * 2 - 4);

                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutBack,
                            left: leftPos,
                            top: topPos,
                            child: GestureDetector(
                              onTap: () => choose(i),
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 220),
                                scale: sel ? 1.15 : 1.0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  width: nodeRadius * 2,
                                  height: nodeRadius * 2,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: sel
                                        ? l.color
                                        : const Color(0xFF17223B),
                                    border: Border.all(
                                      color: sel ? Colors.white : l.color,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: l.color.withValues(
                                          alpha: sel ? 0.65 : 0.25,
                                        ),
                                        blurRadius: sel ? 25 : 10,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    n.letter,
                                    style: TextStyle(
                                      color: sel ? bg : Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: undo,
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: const Text('UNDO'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: check,
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: const Text(
                          'CHECK WORD',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Lines extends CustomPainter {
  const Lines(
    this.nodes,
    this.selected,
    this.area,
    this.color,
    this.close,
  );

  final List<Node> nodes;
  final List<int> selected;
  final Size area;
  final Color color;
  final bool close;

  @override
  void paint(Canvas canvas, Size size) {
    if (selected.isEmpty) return;

    final pts = selected
        .map((i) => Offset(
              nodes[i].position.dx * area.width,
              nodes[i].position.dy * area.height,
            ))
        .toList();

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final pt in pts.skip(1)) {
      path.lineTo(pt.dx, pt.dy);
    }
    if (close) {
      path.close();
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant Lines oldDelegate) =>
      oldDelegate.selected.length != selected.length ||
      oldDelegate.close != close ||
      oldDelegate.nodes != nodes;
}

class Win extends StatefulWidget {
  const Win(this.level, this.stars, this.next, {super.key});
  final WordLevel level;
  final int stars;
  final VoidCallback next;

  @override
  State<Win> createState() => _WinState();
}

class _WinState extends State<Win> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.elasticOut),
      child: AlertDialog(
        title: const Text('BRILLIANT! 🎉', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.level.emoji, style: const TextStyle(fontSize: 54)),
            Text(
              widget.level.word,
              style: TextStyle(
                color: widget.level.color,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.level.meaning, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: i < widget.stars ? 1.0 : 0.45,
                  ),
                  duration: Duration(milliseconds: 400 + i * 170),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Icon(
                    i < widget.stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: gold,
                    size: 38,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.next,
              child: const Text('CONTINUE  →'),
            ),
          ),
        ],
      ),
    );
  }
}
