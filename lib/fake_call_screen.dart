import 'dart:async';
import 'package:flutter/material.dart';

class FakeCallScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;

  const FakeCallScreen({
    super.key,
    this.callerName = 'Maa',
    this.callerNumber = '+91 98765 43210',
  });

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen>
    with TickerProviderStateMixin {
  bool _isAnswered = false;
  int _callSeconds = 0;
  Timer? _callTimer;

  late AnimationController _ringController;
  late Animation<double> _ring1;
  late Animation<double> _ring2;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _ring1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    _ring2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _ringController.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  void _answerCall() {
    setState(() => _isAnswered = true);
    _ringController.stop();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _callSeconds++);
    });
  }

  void _endCall() {
    _callTimer?.cancel();
    Navigator.pop(context);
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: _isAnswered ? _buildActiveCall() : _buildIncomingCall(),
      ),
    );
  }

  Widget _buildIncomingCall() {
    return Column(
      children: [
        const Spacer(),
        AnimatedBuilder(
          animation: _ringController,
          builder: (context, child) {
            return SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: (1 - _ring1.value).clamp(0.0, 1.0),
                    child: Container(
                      width: 220 * _ring1.value,
                      height: 220 * _ring1.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: (1 - _ring2.value).clamp(0.0, 1.0),
                    child: Container(
                      width: 220 * _ring2.value,
                      height: 220 * _ring2.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade700,
                          Colors.grey.shade900,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.callerName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          widget.callerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.callerNumber,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.08),
          ),
          child: const Text(
            'Mobile • India',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCallOption(Icons.message_outlined, 'Message',
                  Colors.grey.shade800, Colors.white70),
              _buildCallOption(Icons.volume_up_outlined, 'Remind me',
                  Colors.grey.shade800, Colors.white70),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _endCall,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF3B30),
                  ),
                  child: const Icon(Icons.call_end,
                      color: Colors.white, size: 32),
                ),
              ),
              GestureDetector(
                onTap: _answerCall,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF34C759),
                  ),
                  child: const Icon(Icons.call,
                      color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildActiveCall() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.grey.shade700, Colors.grey.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              widget.callerName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.callerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatTime(_callSeconds),
          style: const TextStyle(
            color: Color(0xFF34C759),
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildCallOption(Icons.mic_off_outlined, 'mute',
                  Colors.white.withOpacity(0.15), Colors.white),
              _buildCallOption(Icons.dialpad, 'keypad',
                  Colors.white.withOpacity(0.15), Colors.white),
              _buildCallOption(Icons.volume_up_outlined, 'audio',
                  Colors.white.withOpacity(0.15), Colors.white),
              _buildCallOption(Icons.videocam_off_outlined, 'video',
                  Colors.white.withOpacity(0.15), Colors.white),
              _buildCallOption(Icons.person_add_outlined, 'add',
                  Colors.white.withOpacity(0.15), Colors.white),
              _buildCallOption(Icons.pause_outlined, 'hold',
                  Colors.white.withOpacity(0.15), Colors.white),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _endCall,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF3B30),
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildCallOption(
      IconData icon, String label, Color bg, Color iconColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}