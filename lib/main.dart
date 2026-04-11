import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'contacts_screen.dart';
import 'fake_call_screen.dart';
import 'api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeHer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  bool _isAlertActive = false;
  bool _isCountingDown = false;
  int _countdown = 3;
  int _alertSeconds = 0;
  int _selectedTab = 0;
  bool _shakeEnabled = true;

  Timer? _countdownTimer;
  Timer? _alertTimer;
  StreamSubscription? _shakeSubscription;

  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ripple1;
  late Animation<double> _ripple2;
  late Animation<double> _ripple3;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _ripple1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _ripple2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
      ),
    );
    _ripple3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _initShakeDetection();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _countdownTimer?.cancel();
    _alertTimer?.cancel();
    _shakeSubscription?.cancel();
    super.dispose();
  }

  void _initShakeDetection() {
    _shakeSubscription = accelerometerEventStream().listen((event) {
      if (!_shakeEnabled) return;
      if (_isAlertActive || _isCountingDown) return;
      final double force =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (force > 25) {
        _startCountdown();
      }
    });
  }

  void _onSOSPressed() {
    if (_isAlertActive) {
      _cancelAlert();
      return;
    }
    if (_isCountingDown) {
      _abortCountdown();
      return;
    }
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _countdown = 3;
    });
    Vibration.vibrate(duration: 100);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 1) {
        t.cancel();
        _activateAlert();
      } else {
        setState(() => _countdown--);
        Vibration.vibrate(duration: 100);
      }
    });
  }

  void _abortCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountingDown = false;
      _countdown = 3;
    });
  }

  void _activateAlert() async {
    setState(() {
      _isCountingDown = false;
      _isAlertActive = true;
      _alertSeconds = 0;
    });
    _rippleController.repeat();
    Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
    _alertTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _alertSeconds++);
    });

    final result = await ApiService.triggerEmergency(
      phone: '7387669396',
      lat: 18.5204,
      lng: 73.8567,
    );

    if (result['status'] == 'alert_saved') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert #${result['alert_id']} saved to server!'),
          backgroundColor: const Color(0xFF1A4A3A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _cancelAlert() {
    _alertTimer?.cancel();
    _rippleController.stop();
    _rippleController.reset();
    Vibration.vibrate(duration: 200);
    setState(() {
      _isAlertActive = false;
      _alertSeconds = 0;
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStatusCard(),
            Expanded(child: _buildSOSSection()),
            _buildQuickActions(),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SafeHer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Stay protected, always',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _shakeEnabled = !_shakeEnabled);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _shakeEnabled
                            ? 'Shake detection ON'
                            : 'Shake detection OFF',
                      ),
                      backgroundColor: _shakeEnabled
                          ? const Color(0xFF1A4A3A)
                          : const Color(0xFF3A2010),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _shakeEnabled
                        ? const Color(0xFF1A4A3A)
                        : Colors.white.withOpacity(0.06),
                    border: Border.all(
                      color: _shakeEnabled
                          ? const Color(0xFF1D9E75)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.vibration,
                    color: _shakeEnabled
                        ? const Color(0xFF1D9E75)
                        : Colors.white38,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                  ),
                ),
                child: const Center(
                  child: Text(
                    'YK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  Widget _buildStatusCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _isAlertActive
            ? const Color(0xFFFF416C).withOpacity(0.12)
            : _isCountingDown
                ? Colors.orange.withOpacity(0.12)
                : Colors.white.withOpacity(0.04),
        border: Border.all(
          color: _isAlertActive
              ? const Color(0xFFFF416C).withOpacity(0.4)
              : _isCountingDown
                  ? Colors.orange.withOpacity(0.4)
                  : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isAlertActive
                  ? const Color(0xFFFF416C)
                  : _isCountingDown
                      ? Colors.orange
                      : const Color(0xFF00E676),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _isAlertActive
                ? 'ALERT ACTIVE — ${_formatTime(_alertSeconds)}'
                : _isCountingDown
                    ? 'Sending alert in $_countdown seconds...'
                    : 'You are safe',
            style: TextStyle(
              color: _isAlertActive
                  ? const Color(0xFFFF416C)
                  : _isCountingDown
                      ? Colors.orange
                      : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          if (_isAlertActive)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFFFF416C).withOpacity(0.2),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Color(0xFFFF416C),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSOSSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _isAlertActive
                  ? 'TAP TO CANCEL'
                  : _isCountingDown
                      ? 'TAP TO ABORT'
                      : 'TAP TO ACTIVATE',
              key: ValueKey(
                  _isAlertActive.toString() + _isCountingDown.toString()),
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: _onSOSPressed,
            child: AnimatedBuilder(
              animation: Listenable.merge(
                  [_pulseController, _rippleController]),
              builder: (context, child) {
                return SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isAlertActive) ...[
                        _buildRipple(_ripple1),
                        _buildRipple(_ripple2),
                        _buildRipple(_ripple3),
                      ],
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (_isAlertActive
                                    ? const Color(0xFFFF416C)
                                    : _isCountingDown
                                        ? Colors.orange
                                        : Colors.white)
                                .withOpacity(0.07),
                          ),
                        ),
                      ),
                      Container(
                        width: 188,
                        height: 188,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (_isAlertActive
                                    ? const Color(0xFFFF416C)
                                    : _isCountingDown
                                        ? Colors.orange
                                        : Colors.white)
                                .withOpacity(0.12),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: _isAlertActive
                            ? _pulseAnimation.value
                            : 1.0,
                        child: Container(
                          width: 158,
                          height: 158,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: _isAlertActive
                                  ? [
                                      const Color(0xFFFF416C),
                                      const Color(0xFFCC0000),
                                      const Color(0xFF7A0000),
                                    ]
                                  : _isCountingDown
                                      ? [
                                          Colors.orange.shade300,
                                          Colors.orange.shade700,
                                          Colors.orange.shade900,
                                        ]
                                      : [
                                          const Color(0xFFFF6B8A),
                                          const Color(0xFFFF416C),
                                          const Color(0xFFE8193C),
                                        ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isCountingDown
                                        ? Colors.orange
                                        : const Color(0xFFFF416C))
                                    .withOpacity(
                                        _isAlertActive ? 0.75 : 0.4),
                                blurRadius: _isAlertActive ? 60 : 30,
                                spreadRadius: _isAlertActive ? 10 : 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isCountingDown)
                                Text(
                                  '$_countdown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              else ...[
                                Icon(
                                  _isAlertActive
                                      ? Icons.shield
                                      : Icons.shield_outlined,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 6,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isAlertActive
                  ? 'Alert sent to 3 contacts • ${_formatTime(_alertSeconds)}'
                  : _isCountingDown
                      ? 'Tap again to abort'
                      : 'Hold for instant emergency alert',
              key: ValueKey(
                  _isAlertActive.toString() + _isCountingDown.toString()),
              style: TextStyle(
                color: _isAlertActive
                    ? const Color(0xFFFF416C)
                    : _isCountingDown
                        ? Colors.orange
                        : Colors.white30,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRipple(Animation<double> anim) {
    return Opacity(
      opacity: (1 - anim.value).clamp(0.0, 1.0),
      child: Container(
        width: 260 * anim.value,
        height: 260 * anim.value,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFF416C),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildActionCard(Icons.phone_in_talk_outlined, 'Fake\nCall',
              const Color(0xFF7B2FBE)),
          const SizedBox(width: 10),
          _buildActionCard(Icons.location_on_outlined, 'Share\nLocation',
              const Color(0xFF0F3460)),
          const SizedBox(width: 10),
          _buildActionCard(Icons.mic_outlined, 'Record\nAudio',
              const Color(0xFF1A4A3A)),
          const SizedBox(width: 10),
          _buildActionCard(Icons.people_outline, 'Contacts',
              const Color(0xFF3A2010)),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color bgColor) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (label == 'Contacts') {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ContactsScreen()));
          } else if (label == 'Fake\nCall') {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FakeCallScreen()));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: bgColor.withOpacity(0.55),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white70, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
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

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.shield_outlined, Icons.shield, 'Home', 0),
          _buildNavItem(
              Icons.people_outline, Icons.people, 'Contacts', 1),
          _buildNavItem(Icons.map_outlined, Icons.map, 'Map', 2),
          _buildNavItem(
              Icons.person_outline, Icons.person, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ContactsScreen()));
        } else {
          setState(() => _selectedTab = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? const Color(0xFFFF416C) : Colors.white30,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color:
                  isActive ? const Color(0xFFFF416C) : Colors.white30,
              fontSize: 10,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}