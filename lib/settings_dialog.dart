import 'package:flutter/material.dart';
import 'package:nokulive/config.dart';
import 'package:nokulive/labeled_widget.dart';

import 'padded_widget.dart';

class SettingsDialog extends StatefulWidget {
    const SettingsDialog({super.key});

    @override
    State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
    @override
    Widget build(BuildContext context) {
        return Dialog(
            child: PaddedWidget(
                child: Container(
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(16.0))
                    ),
                    child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minWidth: 320,
                            minHeight: 320,
                            maxWidth: MediaQuery.sizeOf(context).width - 16,
                            maxHeight: MediaQuery.sizeOf(context).height - 16
                        ),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                const PaddedWidget(
                                    child: Text.rich(
                                        TextSpan(
                                            children: [
                                                WidgetSpan(child: Padding(
                                                    padding: EdgeInsets.only(right: 8.0),
                                                    child: Icon(Icons.settings),
                                                )),
                                                TextSpan(text: "Settings"),
                                            ],
                                            style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                            )
                                        )
                                    ),
                                ),
                                PaddedWidget(
                                    child: LabeledWidget(
                                        label: const Text.rich(
                                            TextSpan(
                                                text: "Start hidden"
                                            ),
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                        ), 
                                        child: Switch(
                                            activeColor: const Color.fromARGB(255, 255, 255, 255),
                                            value: Config.startHidden, 
                                            onChanged: (value) {
                                                Config.startHidden = value;
                                                setState(() {
                                                    Future.sync(Config.saveData);
                                                });
                                            }
                                        )
                                    ),
                                ),
                                PaddedWidget(
                                    child: LabeledWidget(
                                        label: const Text.rich(
                                            TextSpan(
                                                text: "Show notification when streamer goes live"
                                            ),
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                        ), 
                                        child: Switch(
                                            activeColor: const Color.fromARGB(255, 255, 255, 255),
                                            value: Config.showNotification, 
                                            onChanged: (value) {
                                                Config.showNotification = value;
                                                setState(() {
                                                    Future.sync(Config.saveData);
                                                });
                                            }
                                        )
                                    ),
                                )
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}