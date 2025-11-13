import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _slides = const [
    _OnboardingSlide(
      title: 'Pair in Seconds',
      description:
          'Generate a code and mirror your other phone instantly with a single tap.',
      icon: Icons.auto_awesome_motion_rounded,
      colors: [Color(0xFF5E5CE6), Color(0xFF8E8CFF)],
    ),
    _OnboardingSlide(
      title: 'Flip Sound Profiles',
      description:
          'Switch between ring, vibrate, and silent remotely with a bold tap.',
      icon: Icons.hearing_rounded,
      colors: [Color(0xFFEF5350), Color(0xFFFF7043)],
    ),
    _OnboardingSlide(
      title: 'Stay in Sync',
      description:
          'Status cards pulse with live updates so you always know the mode you set.',
      icon: Icons.bolt_rounded,
      colors: [Color(0xFF26C6DA), Color(0xFF29B6F6)],
    ),
  ];

  void _next() {
    if (_index == _slides.length - 1) {
      final appState = context.read<AppStateController>();
      appState.completeOnboarding();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  context.read<AppStateController>().completeOnboarding();
                },
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (value) {
                  setState(() {
                    _index = value;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _OnboardingCard(slide: slide);
                },
              ),
            ),
            const SizedBox(height: 24),
            _DotsIndicator(
              count: _slides.length,
              index: _index,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(
                  _index == _slides.length - 1 ? 'Let’s pair up' : 'Next',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: slide.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: Icon(
                slide.icon,
                size: 220,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(
                      slide.icon,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    slide.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    slide.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) {
          final isActive = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            height: 10,
            width: isActive ? 28 : 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.4),
            ),
          );
        },
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
}

