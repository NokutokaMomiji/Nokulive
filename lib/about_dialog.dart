import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nokulive/padded_widget.dart';
import 'package:url_launcher/url_launcher.dart';

// Hey there, scrappers.
const String youtube = "aHR0cHM6Ly95b3V0dWJlLmNvbS9Abm9rdXRva2Ftb21pamk=";
const String twitch = "aHR0cHM6Ly90d2l0Y2gudHYvbm9rdXRva2Ftb21pamk=";
const String discord = "aHR0cHM6Ly9kaXNjb3JkLmdnL3hEZmsyeDh0eHI=";
const String twitter = "aHR0cHM6Ly90d2l0dGVyLmNvbS9ub2t1dG9rYW1vbWlqaV8=";
const String github = "aHR0cHM6Ly9naXRodWIuY29tL25va3V0b2thbW9taWpp";

/// Just a simple widget that returns a custom about dialog box.
class InfoDialog extends StatelessWidget {
    const InfoDialog({super.key});

    @override
    Widget build(BuildContext context) {
        return AboutDialog(
            applicationName: "Nokulive",
            applicationVersion: "1.0.0",
            applicationIcon: PaddedWidget(child: Image.asset("assets/logo.png")),
            children: [
                PaddedWidget(
                    child: Container(
                        decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(16.0))
                        ),
                        child: const Text("A fun little app made by Nokutoka Momiji!"),
                    ),
                ),
                PaddedWidget(
                    child: Wrap(
                        //mainAxisSize: MainAxisSize.min,
                        children: [
                            PaddedWidget(
                                child: IconButton(
                                    onPressed: () {
                                        var text = utf8.decode(base64Decode(youtube));
                                        launchUrl(Uri.parse(text));
                                    },
                                    icon: const FaIcon(FontAwesomeIcons.youtube),
                                    color: Colors.redAccent,
                                ),
                            ),
                            PaddedWidget(
                                child: IconButton(
                                    onPressed: () {
                                        var text = utf8.decode(base64Decode(twitch));
                                        launchUrl(Uri.parse(text));
                                    },
                                    icon: const FaIcon(FontAwesomeIcons.twitch),
                                    color: const Color(0xFFA970FF),
                                ),
                            ),
                            PaddedWidget(
                                child: IconButton(
                                    onPressed: () {
                                        var text = utf8.decode(base64Decode(twitter));
                                        launchUrl(Uri.parse(text));
                                    },
                                    icon: const FaIcon(FontAwesomeIcons.twitter),
                                    color: const Color(0xFF1DA1F2),
                                ),
                            ),
                            PaddedWidget(
                                child: IconButton(
                                    onPressed: () {
                                        var text = utf8.decode(base64Decode(discord));
                                        launchUrl(Uri.parse(text));
                                    },
                                    icon: const FaIcon(FontAwesomeIcons.discord),
                                    color: const Color(0xFF5966F1)
                                ),
                            ),
                            PaddedWidget(
                                child: IconButton(
                                    onPressed: () {
                                        var text = utf8.decode(base64Decode(github));
                                        launchUrl(Uri.parse(text));
                                    },
                                    icon: const FaIcon(FontAwesomeIcons.github),
                                    color: const Color(0xFFF0F6FC),
                                ),
                            ),
                        ],
                    )
                )
            ]
        );
    }
}