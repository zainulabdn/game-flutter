import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rive/rive.dart';
import 'package:audioplayers/audioplayers.dart';

class RacingCarGameScreen extends StatefulWidget {
  const RacingCarGameScreen({super.key});

  @override
  _RacingCarGameScreenState createState() => _RacingCarGameScreenState();
}

class _RacingCarGameScreenState extends State<RacingCarGameScreen> {
  double carPosition = 0.5;
  double carWidth = 0.1;
  double carHeight = 0.2;

  List<Obstacle> obstacles = [];
  bool gameOver = false;
  int score = 0;

  late RiveAnimation asset;
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    asset = RiveAnimation.asset(
      'assets/new_file.riv',
      fit: BoxFit.cover,
    );
    startGameLoop();
  }

  void startGameLoop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!gameOver && mounted) {
        setState(() {
          updateObstacles();
          checkCollision();
          startGameLoop();
        });
      }
    });
  }

  void updateObstacles() {
    // Update existing obstacles and score
    for (var obstacle in obstacles) {
      obstacle.position += obstacle.speed;
      obstacle.top = obstacle.position;
    }
    // Remove obstacles out of the screen
    obstacles.removeWhere((obstacle) =>
        obstacle.position > 1.0 + obstacle.height / MediaQuery.of(context).size.height);

    // Add new obstacles if needed
    double minDistance = 0.5 * MediaQuery.of(context).size.height;
    if (obstacles.isEmpty || obstacles.last.position > minDistance) {
      obstacles.add(Obstacle());
      score += 10;  // Increase score for each new obstacle
    }
  }

  void checkCollision() {
    // Check for collision with obstacles
    for (Obstacle obstacle in obstacles) {
      if (checkCarCollision(obstacle)) {
        setState(() {
          gameOver = true;
          playCrashSound();
        });
      }
    }
  }

  bool checkCarCollision(Obstacle obstacle) {
    double carLeft = carPosition * MediaQuery.of(context).size.width - carWidth * MediaQuery.of(context).size.width / 2;
    double carRight = carPosition * MediaQuery.of(context).size.width + carWidth * MediaQuery.of(context).size.width / 2;
    double carTop = MediaQuery.of(context).size.height * 0.8;
    double carBottom = carTop + carHeight * MediaQuery.of(context).size.height;

    double obstacleLeft = obstacle.left * MediaQuery.of(context).size.width;
    double obstacleRight = obstacleLeft + obstacle.width * MediaQuery.of(context).size.width;
    double obstacleTop = obstacle.top * MediaQuery.of(context).size.height;
    double obstacleBottom = obstacleTop + obstacle.height * MediaQuery.of(context).size.height;

    return carLeft < obstacleRight && carRight > obstacleLeft && carTop < obstacleBottom && carBottom > obstacleTop;
  }

  void playCrashSound() async {
    await player.play(AssetSource('audio/crash_sound.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          asset,
          Positioned(
            top: 40,
            right: 20,
            child: Text(
              'Score: $score',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              updateCarPosition(details);
            },
            child: buildGameLayer(),
          ),
        ],
      ),
    );
  }

  void updateCarPosition(DragUpdateDetails details) {
    double newCarPosition = carPosition + details.primaryDelta! / MediaQuery.of(context).size.width;
    carPosition = newCarPosition.clamp(0.0, 1.0);
  }

  Stack buildGameLayer() {
    return Stack(
      children: [
        Positioned(
          bottom: 40,
          left: carPosition * MediaQuery.of(context).size.width - carWidth * MediaQuery.of(context).size.width / 2,
          child: Image.asset('assets/car.png', height: 80, width: 80),
        ),
        ...obstacles.map((obstacle) => Positioned(
          top: obstacle.top * MediaQuery.of(context).size.height,
          left: obstacle.left * MediaQuery.of(context).size.width,
          child: Image.asset('assets/bus3.png', width: obstacle.width * MediaQuery.of(context).size.width, height: obstacle.height * MediaQuery.of(context).size.height),
        )),
        if (gameOver) buildGameOverScreen(),
      ],
    );
  }

  Center buildGameOverScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Game Over!', style: TextStyle(fontSize: 24, color: Colors.white)),
          SizedBox(height: 16),
          OutlinedButton(
            onPressed: resetGame,
            child: Text('Restart Game', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void resetGame() {
    setState(() {
      obstacles.clear();
      gameOver = false;
      score = 0;
    });
    startGameLoop();
  }
}

class Obstacle {
  double position = 0.0;
  double speed = 0.01;
  double width = 0.1;
  double height = 0.1;
  double left = Random().nextDouble();
  double top = 0.0;
}
