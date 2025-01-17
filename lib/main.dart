import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:nokulive/about_dialog.dart';
import 'package:nokulive/add_dialog.dart';
import 'package:nokulive/config.dart';
import 'package:nokulive/live_style.dart';
import 'package:nokulive/padded_widget.dart';
import 'package:nokulive/settings_dialog.dart';
import 'package:nokulive/streamer_box.dart';
import 'package:smooth_scroll_multiplatform/smooth_scroll_multiplatform.dart';

late Future initializing;

void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Config.initSystemTray();

    initializing = Config.init();
    runApp(const MainApp());

    doWhenWindowReady(() {
        final win = appWindow;
        const initialSize = Size(1280, 720);

        win.minSize = const Size(600, 450);
        win.size = initialSize;
        win.alignment = Alignment.center;
        win.title = "Nokulive";
        
        win.show();
    });
}

class MainApp extends StatelessWidget {
    const MainApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            theme: ThemeData.from(
                colorScheme: const ColorScheme.light(
                    primary: Color(0xfffcfcfc),
                    secondary: Color(0xffdadada),
                    error: Color(0xffcf6679),
                    surface: Color(0xff121212),
                )
            ),
            darkTheme: ThemeData.from(
                colorScheme: const ColorScheme.dark(
                    primary: Color(0xfffcfcfc),
                    secondary: Color(0xffdadada),
                    error: Color(0xffcf6679),
                    surface: Color(0xff121212),
                )
            ),
            home: Scaffold(
                body: FutureBuilder(
                    future: initializing,
                    builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                            return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    WindowTitleBarBox(
                                        child: const ActualAppButtons()
                                    ),
                                    const Expanded(child: ActualAppView())
                                ],
                            );
                        }
                
                        return const Center(
                            child: CircularProgressIndicator(),
                        );
                    },
                ),
            ),
            debugShowCheckedModeBanner: false,
        );
    }
}

var buttonColor = WindowButtonColors(iconNormal: LiveStyle.offlineRing);

class ActualAppButtons extends StatelessWidget {
    const ActualAppButtons({super.key});

    @override
    Widget build(BuildContext context) {
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
                Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                            child: Image.asset("assets/logo.png", scale: 2)
                        ),
                        Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: WindowButton(
                                onPressed: () async {
                                    showDialog(
                                        context: context, 
                                        barrierDismissible: false,
                                        builder: (context) => const AddStreamerDialog(),
                                    );
                                },
                                iconBuilder: (_) => const Center(
                                    child: Icon(
                                        Icons.add,
                                        size: 16,
                                    ),
                                )
                            ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: WindowButton(
                                onPressed: () async {
                                    showDialog(
                                        context: context,
                                        builder: (context) => const SettingsDialog(),
                                    );
                                },
                                iconBuilder: (_) => const Center(
                                    child: Icon(
                                        Icons.settings,
                                        size: 16,
                                    ),
                                )
                            ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: WindowButton(
                                onPressed: () async {
                                    showDialog(
                                        context: context, 
                                        barrierDismissible: false,
                                        builder: (context) => const InfoDialog(),
                                    );
                                },
                                iconBuilder: (_) => const Center(
                                    child: Icon(
                                        Icons.info,
                                        size: 16,
                                    ),
                                )
                            ),
                        )
                    ],
                ),
                Expanded(child: MoveWindow()),
                Row(
                    children: [
                        MinimizeWindowButton(colors: buttonColor),
                        MaximizeWindowButton(colors: buttonColor),
                        CloseWindowButton(colors: buttonColor),
                    ],
                )
            ],
        );
    }
}

class ActualAppView extends StatelessWidget {
    const ActualAppView({super.key});

    @override
    Widget build(BuildContext context) {
        return Center(
            child: ValueListenableBuilder(
                valueListenable: Config.updatedUsers,
                builder: (context, value, child) {
                    var streamers = Config.streamers.values.toList();

                    return DynMouseScroll(
                        builder: (context, controller, physics) => ListView.builder(
                            controller: controller,
                            physics: physics,
                            itemCount: Config.streamers.length,
                            itemBuilder: (context, index) {
                                var streamer = streamers[index];
                                                
                                return PaddedWidget(
                                    child: StreamerBox(
                                        streamer: streamer, 
                                        notifier: Config.streamNotifiers[streamer.username]!
                                    ),
                                );
                            },
                        ),
                    );
                },
            ),
        );
    }
}