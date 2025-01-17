import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nokulive/searcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:system_tray/system_tray.dart';

import 'nokulog.dart';

/// Simple class that keeps configuration variables and functions.
class Config {
    static const String dataDir = "Nokulive";
    static const String dataFile = "data.json";

    // Could I create a class that contains all of these properties? Yes, but for now, we don't.
    static Map<String, Searcher> streamers = {};
    static Map<String, ValueNotifier<bool>> streamNotifiers = {};
    static Map<String, Stopwatch> streamerWatches = {};
    static Map<String, bool> notified = {};

    static ValueNotifier<Color> appColor = ValueNotifier(Colors.black);
    static ValueNotifier<Brightness> appBrightness = ValueNotifier(Brightness.dark);
    static ValueNotifier<bool> updatedUsers = ValueNotifier(false);

    static bool isShowing = true;
    static bool startHidden = false;
    static bool showNotification = false;

    static Directory? storeDirectory;

    static Future<void> init() async {
        final Directory documents = await getApplicationDocumentsDirectory();
        final String storePath = "${documents.path.replaceAll('\\', '/')}/$dataDir"; // I hate Windows.

        storeDirectory = Directory(storePath);

        await createDirIfNotExists();

        // If no data file is found, we add the default streamers and then save that data as the initial state of the file.
        if (!(await checkFileExists(dataFile))) {
            await addDefault();
            await saveData();
            return;
        }

        if (await loadData()) {
            for (var streamer in Config.streamers.entries) {
                await Config.notifyStream(streamer.value);
            }
            Nokulog.d("Loaded data!");
        }

        if (Config.startHidden) {
            final AppWindow appWindow = AppWindow();
            await appWindow.hide();
        }
    }

    static Future<void> initSystemTray() async {
        // From the demo code for system_tray (https://pub.dev/packages/system_tray)
        String path = Platform.isWindows ? 'assets/logo.ico' : 'assets/logo.png';

        final AppWindow appWindow = AppWindow();
        final SystemTray systemTray = SystemTray();

        await systemTray.initSystemTray(
            title: "Nokulive",
            iconPath: path,
        );

        final Menu menu = Menu();
        await menu.buildFrom([
            MenuItemLabel(label: "Show", onClicked: (menuItem) => appWindow.show()),
            MenuItemLabel(label: "Hide", onClicked: (menuItem) => appWindow.hide()),
            MenuSeparator(),
            MenuItemLabel(label: "Exit", onClicked: (menuItem) => appWindow.close()),
        ]);

        await systemTray.setContextMenu(menu);

        systemTray.registerSystemTrayEventHandler((eventName) {
            Nokulog.d("eventName: $eventName");
            if (eventName == kSystemTrayEventClick) {
                Platform.isWindows ? appWindow.show() : systemTray.popUpContextMenu();
            } else if (eventName == kSystemTrayEventRightClick) {
                Platform.isWindows ? systemTray.popUpContextMenu() : appWindow.show();
            }
        });
    }

    static Future<void> createDirIfNotExists() async {
        if (storeDirectory == null) return;

        Directory dir = storeDirectory!;
        bool exists = await dir.exists();

        if (!exists) {
            await dir.create();
        }
    }

    static Future<bool> checkFileExists(String filename) async {
        await createDirIfNotExists();

        String filepath = "${storeDirectory!.path.replaceAll("\\", "/")}/$filename";
        File file = File(filepath);

        return file.exists();
    }

    // This is a very bodged, not really efficient way to store settings in the long run.
    // However, this is a small project with not that many settings, so we ball it.
    static Future<bool> saveData() async {
        await createDirIfNotExists();
        
        String filepath = "${storeDirectory!.path.replaceAll("\\", "/")}/$dataFile";
        Map<String, dynamic> pack = {
            "startHidden": Config.startHidden,
            "showNotification": Config.showNotification,
            "streamers": {
                for (var streamer in streamers.entries) streamer.key: streamer.value.autoOpen
            }
        };

        try {
            var data = jsonEncode(pack);

            await File(filepath).writeAsString(data);

            return true;
        } catch (e, stackTrace) {
            Nokulog.e("Failed to save data.", error: e, stackTrace: stackTrace);
            return false;
        }
    }

    static Future<bool> loadData() async {
        Future<void> addStreamer(String streamerName, bool autoOpen) async {
            var exists = await Config.addUser(streamerName, autoOpen);

            if (!exists) {
                Nokulog.e("$streamerName not found.");
                return;
            }
        }

        try {
            String filepath = "${storeDirectory!.path.replaceAll("\\", "/")}/$dataFile";

            final File file = File(filepath);
            final bool exists = await file.exists();

            if (!exists) return false;

            final String rawData = await file.readAsString();
            final Map<String, dynamic> data = jsonDecode(rawData);

            // Manually setting data variables is so fun!
            Config.startHidden = data["startHidden"]!;
            Config.showNotification = data["showNotification"]!;

            Map<String, dynamic> storedStreamers = data["streamers"]!;

            List<Future> futures = [];

            for (var streamer in storedStreamers.entries) {
                String streamerName = streamer.key;
                bool autoOpen = streamer.value as bool;

                futures.add(addStreamer(streamerName, autoOpen));
            }

            await Future.wait(futures);

            return true;
        } catch (e, stackTrace) {
            Nokulog.e("Failed to load data.", error: e, stackTrace: stackTrace);
            return false;
        }
    }

    // A few default streamers so that the app doesn't feel so empty first time around.
    static Future<void> addDefault() async {
        var temp = ["nokutokamomiji", "aerin_vt", "a4loveletter", "udon0421"];

        await Future.wait([
            for (var streamer in temp) addUser(streamer)
        ]);

        for (var streamer in Config.streamers.entries) {
            await Config.notifyStream(streamer.value);
        }
    }

    static Future<bool> addUser(String name, [bool autoOpen = false]) async {
        // Don't allow duplicate streamers. Sorry if anyone shares the same name
        // but like... that shouldn't happen, right?
        if (streamers.containsKey(name)) return true;

        final user = Searcher(name);
        final userExists = await user.exists();

        if (!userExists) return false;

        streamers[name] = user;
        streamNotifiers[user.username] = ValueNotifier<bool>(false);
        notified[user.username] = false;
    
        user.autoOpen = autoOpen;

        // It's called reload but in reality we're loading the data for the first time.
        await user.reload();

        updatedUsers.value = !updatedUsers.value;

        // A timer that reloads the streamer data every 5 minutes and notifies the widgets as necessary.
        Timer.periodic(const Duration(minutes: 5), (timer) async {
            Nokulog.d("Reloading \"${user.username}\"...");
            await user.reload();

            await Config.notifyStream(user);

            streamerWatches[user.username]!..reset()..start();

            final notifier = streamNotifiers[user.username]!;
            notifier.value = !notifier.value;
        });

        streamerWatches[user.username] = Stopwatch()..start();

        return true;
    }

    static Future<void> removeUser(String name) async {
        if (!streamers.containsKey(name)) return;

        streamers.remove(name);
        streamNotifiers.remove(name);

        updatedUsers.value = !updatedUsers.value;
    }

    static Future<void> notifyStream(Searcher user) async {
        bool isLive = user.isLive;

        if (!isLive) {
            notified[user.username] = false;
            return;
        }

        if (isLive && !notified[user.username]!) {
            Nokulog.d("Displaying notification.");
            
            notified[user.username] = true;
            return;
        }
    }
}