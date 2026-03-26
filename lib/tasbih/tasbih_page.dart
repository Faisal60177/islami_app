import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

enum ClickMode { sound, vibrate, mute }

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage>
    with SingleTickerProviderStateMixin {
  int num = 0;
  int target = 33; // Default target
  late AnimationController _controller;
  late Animation<double> _animation;

  ClickMode _mode = ClickMode.sound;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _targetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _audioPlayer.setSource(AssetSource('assets/sounds/tasbih_sound.mp3'));
    _targetController.text = target.toString();
  }

  void _increment() {
    if (num < target) {
      num++;
      _animateCircle();
      _playEffect(short: true);

      // Vibrate long when reaching target
      if (num == target && _mode == ClickMode.vibrate) {
        Vibration.hasVibrator().then((hasVibrator) {
          if (hasVibrator ?? false) Vibration.vibrate(duration: 500);
        });
      }
    }
  }

  void _reset() {
    num = 0;
    _animateCircle();
  }

  void _animateCircle() {
    _animation = Tween<double>(
      begin: _animation.value,
      end: num / target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller
      ..reset()
      ..forward();
  }

  void _playEffect({bool short = false}) {
    switch (_mode) {
      case ClickMode.sound:
        _audioPlayer.resume();
        break;
      case ClickMode.vibrate:
        if (short) {
          Vibration.hasVibrator().then((hasVibrator) {
            if (hasVibrator ?? false) Vibration.vibrate(duration: 50);
          });
        }
        break;
      case ClickMode.mute:
        break;
    }
  }

  void _updateTarget() {
    final int? newTarget = int.tryParse(_targetController.text);
    if (newTarget != null && newTarget > 0) {
      setState(() {
        target = newTarget;
        num = 0;
        _animateCircle();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[100],
      appBar: AppBar(
        title: const Text("Tasbih Counter"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Progress Circle with gradient
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: GestureDetector(
                    onTap: _increment,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            value: _animation.value,
                            strokeWidth: 14,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.blueAccent),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "$num",
                              style: const TextStyle(
                                  fontSize: 42, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "of $target",
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Reset & Add Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reset"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _increment,
                    icon: const Icon(Icons.add),
                    label: const Text("Add"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent[700],
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20)),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Mode Selection with icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: const Icon(Icons.volume_up),
                    selected: _mode == ClickMode.sound,
                    selectedColor: Colors.blueAccent,
                    onSelected: (_) => setState(() => _mode = ClickMode.sound),
                  ),
                  ChoiceChip(
                    label: const Icon(Icons.vibration),
                    selected: _mode == ClickMode.vibrate,
                    selectedColor: Colors.blueAccent,
                    onSelected: (_) =>
                        setState(() => _mode = ClickMode.vibrate),
                  ),
                  ChoiceChip(
                    label: const Icon(Icons.volume_off),
                    selected: _mode == ClickMode.mute,
                    selectedColor: Colors.blueAccent,
                    onSelected: (_) => setState(() => _mode = ClickMode.mute),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Target input
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 15.0, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _targetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Target",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      IconButton(
                        onPressed: _updateTarget,
                        icon: const Icon(Icons.check_circle,
                            color: Colors.green, size: 32),
                      )
                    ],
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