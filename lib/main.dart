import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/line.dart';
import 'package:flutter_application_1/painter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.white, systemNavigationBarColor: Colors.white));
    return const MaterialApp(
      title: 'SketchIt',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  List<Line?> lines = [];
  Color selectedColor = Colors.yellow;
  int thickness = 20;
  final audioPlayer = AudioPlayer();
  bool showThicknessGuide = false;
  final _globalKey = GlobalKey();
  late AnimationController volumeController;
  late AnimationController buttonController;
  late AnimationController scanController;
  late AnimationController scaleController;

  @override
  void initState() {
    super.initState();
    audioPlayer
        .setAudioSource(AudioSource.uri(Uri.parse("asset:///audio/music.wav")));

    volumeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            audioPlayer.setVolume(volumeController.value);
          });

    buttonController = AnimationController(
        lowerBound: 0,
        upperBound: 80,
        vsync: this,
        duration: const Duration(milliseconds: 200))
      ..addListener(() {
        setState(() {});
      });

    scanController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..addListener(() {
            setState(() {});
          });

    scaleController = AnimationController(
        vsync: this,
        upperBound: 0.1,
        lowerBound: 0.0,
        duration: const Duration(milliseconds: 200))
      ..addListener(() {
        setState(() {});
      });
  }

  void _onPanStart(DragStartDetails _) {
    audioPlayer.play();
    volumeController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    AnimationController controller =
        AnimationController(duration: const Duration(seconds: 2), vsync: this)
          ..addListener(() {
            setState(() {});
          })
          ..forward();

    final Line line = Line(
        color: selectedColor,
        offset: details.globalPosition,
        width: thickness,
        controller: controller);
    lines.add(line);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails _) {
    lines.add(null);
    volumeController.reverse().whenComplete(() => audioPlayer.pause());
  }

  void _undo() {
    bool skip = false;
    final List<Line?> newLines = lines.reversed.toList();
    for (final Line? line in newLines) {
      if (line == null) {
        if (skip) {
          return;
        } else {
          skip = true;
          setState(() {});
        }
      }
      lines.removeLast();
    }
    setState(() {});
  }

  void _clearCanvas() {
    if (lines.isEmpty) {
      return;
    }
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Warning"),
        content: const Text("Are you sure you want to clear the canvas?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("Yes"),
            onPressed: () {
              lines.clear();
              setState(() {});
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            child: const Text("No"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    await buttonController.forward();
    await scaleController.forward();
    await scanController.forward();
    try {
      final boundary = _globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      await ImageGallerySaver.saveImage(
        pngBytes!,
        quality: 100,
        name: DateTime.now().toIso8601String() + ".png",
        isReturnImagePathOfIOS: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sketch saved inside gallery")));
    } catch (e) {
      // print(e);
    }

    scanController.reverse();
    await scaleController.reverse();
    await buttonController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildOptions() {
      return Positioned(
        right: -70 - buttonController.value,
        child: Column(
          children: [
            FloatingActionButton.small(
              elevation: 4,
              backgroundColor: Colors.black,
              onPressed: _save,
              child: const Icon(
                Icons.save_alt,
                size: 12,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            FloatingActionButton.small(
              elevation: 4,
              backgroundColor: Colors.black,
              onPressed: _clearCanvas,
              child: const Icon(
                Icons.clear,
                size: 12,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            FloatingActionButton.small(
              elevation: 4,
              backgroundColor: Colors.black,
              onPressed: _undo,
              child: const Icon(
                Icons.replay,
                size: 12,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            FloatingActionButton.small(
              elevation: 4,
              backgroundColor: selectedColor,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    // title: const Text('Pick a color!'),
                    content: SizedBox(
                      height: 460,
                      width: 400,
                      child: PageView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          BlockPicker(
                            pickerColor: selectedColor,
                            // onPrimaryChanged: (e) {
                            //   selectedColor = e;
                            //   setState(() {});
                            // },
                            onColorChanged: (e) {
                              selectedColor = e;
                              setState(() {});
                            },
                          ),
                          ColorPicker(
                            pickerColor: selectedColor,
                            // onPrimaryChanged: (e) {
                            //   selectedColor = e;
                            //   setState(() {});
                            // },
                            onColorChanged: (e) {
                              selectedColor = e;
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        child: const Text('Got it'),
                        onPressed: () {
                          // setState(() => currentColor = pickerColor);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
              child: const SizedBox(),
            ),
            const SizedBox(
              height: 150,
            ),
            _thicknessButton(),
          ],
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onPanStart: _onPanStart,
          onPanEnd: _onPanEnd,
          onPanUpdate: _onPanUpdate,
          child: Transform.scale(
            scale: 1.0 - scaleController.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildCanvas(),
                Visibility(
                  visible: scanController.status == AnimationStatus.forward,
                  child: Lottie.asset("assets/scan.json",
                      controller: scanController,
                      frameRate: FrameRate.max,
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover),
                ),
                _buildOptions(),
                _buildThicknessGuide(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThicknessGuide() {
    return Positioned(
      child: Visibility(
        visible: showThicknessGuide,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
              height: thickness.toDouble(),
              width: thickness.toDouble(),
              decoration:
                  BoxDecoration(color: selectedColor, shape: BoxShape.circle)),
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return RepaintBoundary(
      key: _globalKey,
      child: CustomPaint(
        size: Size.infinite,
        painter: MyPainter(lines: lines),
        isComplex: true,
        willChange: true,
      ),
    );
  }

  Widget _thicknessButton() {
    return Transform.rotate(
      angle: pi / 2,
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)
          ],
          color: Colors.black,
          borderRadius: BorderRadius.circular(40),
        ),
        child: SizedBox(
          width: 200,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.white10,
              inactiveTrackColor: Colors.white10,
              thumbColor: selectedColor,
            ),
            child: Slider(
              value: thickness.toDouble(),
              min: 10,
              max: 100,
              onChanged: (e) {
                thickness = e.toInt();
                setState(() {});
              },
              onChangeStart: (_) {
                showThicknessGuide = true;
                setState(() {});
              },
              onChangeEnd: (_) {
                showThicknessGuide = false;
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }
}
