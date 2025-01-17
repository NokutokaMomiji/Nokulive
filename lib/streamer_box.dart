import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nokulive/config.dart';
import 'package:nokulive/live_style.dart';
import 'package:nokulive/padded_widget.dart';
import 'package:nokulive/searcher.dart';
import 'package:url_launcher/url_launcher.dart';

class StreamerBox extends StatelessWidget {
    final Searcher streamer;
    final ValueNotifier<bool> notifier;

    const StreamerBox({super.key, required this.streamer, required this.notifier});

    void reload() async {
        notifier.value = !notifier.value;
        await streamer.reload();
        notifier.value = !notifier.value;
    }

    @override
    Widget build(BuildContext context) {
        return PaddedWidget(
            child: ValueListenableBuilder(
                valueListenable: notifier,
                builder: (context, value, child) {
                    return Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                            color: Theme.of(context).cardColor,
                            gradient: (streamer.isLive) ? LiveStyle.liveGradient : null,
                            boxShadow: const [
                                BoxShadow(
                                    offset: Offset(4, 4),
                                    blurRadius: 14
                                )
                            ]
                        ),
                        child: FutureBuilder(
                            future: streamer.reloading,
                            builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.done) {
                                    return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            Expanded(
                                                child: StreamerInfo(
                                                    streamer: streamer
                                                ),
                                            ),
                                            StreamerOptions(
                                                streamer: streamer,
                                                parent: this
                                            )
                                        ],
                                    );
                                }

                                return const Center(child: CircularProgressIndicator());
                            },
                        ),
                    );
                },
            ),
        );
    }
}

class StreamerInfo extends StatelessWidget {
    final Searcher streamer;

    const StreamerInfo({super.key, required this.streamer});

    @override
    Widget build(BuildContext context) {
        var infoChildren = [
            const WidgetSpan(child: Icon(Icons.star)),
            TextSpan(text: " ${streamer.followers} "),
        ];

        if (streamer.isLive) {
            infoChildren.addAll([
                const WidgetSpan(
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.remove_red_eye),
                    )
                ),
                TextSpan(text: "${streamer.streamViewers}"),
                const WidgetSpan(
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.gamepad),
                    )
                ),
                TextSpan(text: streamer.streamGame),
                const WidgetSpan(
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.remove_red_eye),
                    )
                ),
                TextSpan(text: streamer.streamTime.formatted)
            ]);
        }

        return Wrap(
            //mainAxisAlignment: MainAxisAlignment.start,
            //crossAxisAlignment: CrossAxisAlignment.center,
            //mainAxisSize: MainAxisSize.min,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
                PaddedWidget(
                    child: CircleAvatar(
                        backgroundColor: (streamer.isLive) ? LiveStyle.liveRing : LiveStyle.offlineRing,
                        radius: 32 + 3,
                        child: CircleAvatar(
                            radius: 32,
                            foregroundImage: Image.network(streamer.avatarURL).image,
                        ),
                    )
                ),
                PaddedWidget(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            Flexible(
                                fit: FlexFit.loose,
                                child: PaddedWidget(
                                    padding: const EdgeInsets.only(right: 2.0, top: 2.0, bottom: 4.0),
                                    child: RichText(
                                        overflow: TextOverflow.fade,
                                        text: TextSpan(
                                            children: [
                                                TextSpan(text: streamer.username),
                                                if (streamer.isLive) TextSpan(
                                                    text: "\n${streamer.streamTitle}",
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w300
                                                    )
                                                )
                                            ],
                                            style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold
                                            )
                                        ),
                                    ),
                                ),
                            ),
                            //const Padding(padding: EdgeInsets.all(4.0)),
                            PaddedWidget(
                                padding: const EdgeInsets.only(right: 2.0, top: 6.0, bottom: 2.0),
                                child: RichText(
                                    text: TextSpan(
                                        children: infoChildren
                                    ),
                                ),
                            )
                        ],
                    ),
                )
            ],
        );
    }
}

class StreamerOptions extends StatefulWidget {
    final Searcher streamer;
    final StreamerBox parent;

    const StreamerOptions({required this.streamer, required this.parent, super.key});

    @override
    State<StreamerOptions> createState() => _StreamerOptionsState();
}

class _StreamerOptionsState extends State<StreamerOptions> {
    late Stopwatch watch;
    late Timer timer;

    @override
    void initState() {
        super.initState();
    
        watch = Config.streamerWatches[widget.streamer.username]!;
        timer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) {
                setState((){});
            }
        });
    }

    @override
    Widget build(BuildContext context) {
        var buttons = [
            Tooltip(
                message: "Open stream automatically when streamer goes live",
                child: AutoopenSwitch(streamer: widget.streamer),
            ),
            Tooltip(
                message: "Open in Browser",
                child: IconButton(
                    onPressed: () => launchUrl(widget.streamer.website),
                    icon: const Icon(Icons.open_in_browser)
                ),
            ),
            Tooltip(
                message: "Reload Data",
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                        CircularProgressIndicator(
                            strokeWidth: 2,
                            value: (watch.elapsed.inSeconds / 300),
                        ),
                        IconButton(
                            onPressed: widget.parent.reload, 
                            icon: const Icon(Icons.refresh)
                        ),
                    ],
                ),
            ),
            Tooltip(
                message: "Remove",
                child: IconButton(
                    onPressed: () => Config.removeUser(widget.streamer.username), 
                    icon: const Icon(Icons.remove_circle_outline)
                ),
            )
        ].map(
            (e) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: e)
        ).toList();

        return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            children: [
                PaddedWidget(
                    child: RichText(
                        text: TextSpan(
                            text: (widget.streamer.isLive) ? "Live" : "Offline",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: (widget.streamer.isLive) ? LiveStyle.liveRing : LiveStyle.offlineRing
                            )
                        )
                    ),
                ),
                PaddedWidget(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: buttons,
                    )
                )
            ],
        );
    }
}

class AutoopenSwitch extends StatefulWidget {
    final Searcher streamer;

    const AutoopenSwitch({required this.streamer, super.key});

    @override
    State<AutoopenSwitch> createState() => _AutoopenSwitchState();
}

class _AutoopenSwitchState extends State<AutoopenSwitch> {
    @override
    Widget build(BuildContext context) {
        return Switch(
            activeColor: (widget.streamer.isLive) ? LiveStyle.liveRing : LiveStyle.offlineRing,
            value: widget.streamer.autoOpen,
            onChanged: (value) {
                setState(() {
                    widget.streamer.autoOpen = value;
                    Future.sync(Config.saveData);
                });
            }
        );
    }
}