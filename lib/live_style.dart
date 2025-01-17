// Because sometimes dealing with Flutter's ThemeData is a nightmare.
import 'package:flutter/material.dart';

/// Class that contains static colors because working with Flutter's ThemeData is sometimes a nightmare.
class LiveStyle {
    static const Color offlineRing = Color(0xffdadada);
    static List<Color> offlineColors = [];
    
    static const Color liveRing = Color(0xffdd0000);
    static List<Color> liveColors = [Colors.red.shade400, Colors.redAccent[100]!];
    static Gradient liveGradient = LinearGradient(colors: liveColors);

    static const Color errorBackground = Color(0xff880000);
    static const Color errorText = Color(0xffffaaaa);
}