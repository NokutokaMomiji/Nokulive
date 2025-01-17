import 'package:flutter/material.dart';
import 'package:nokulive/config.dart';
import 'package:nokulive/live_style.dart';
import 'package:nokulive/padded_widget.dart';

// Bool to mark that we're currently in the process of fetching the streamer data.
bool inProgress = false;

class AddStreamerDialog extends StatefulWidget {
    const AddStreamerDialog({super.key});

    @override
    State<AddStreamerDialog> createState() => _AddStreamerDialogState();
}

class _AddStreamerDialogState extends State<AddStreamerDialog> {
    SearchState? state;
    SearchController searchController = SearchController();

    @override
    void initState() {
        super.initState();

        inProgress = false;
    }

    @override
    Widget build(BuildContext context) {
        return Dialog(
            insetPadding: const EdgeInsets.all(8.0),
            child: TapRegion(
                onTapOutside: (event) {
                    // We use the inProgress bool to avoid allowing the user to click off the dialog
                    // whilst fetching the streamer data.
                    if (inProgress) return;

                    Navigator.of(context, rootNavigator: true).pop();
                },
                child: PaddedWidget(
                    child: Container(
                        decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(16.0))
                        ),
                        child: SizedBox(
                            width: 640,
                            height: 320,
                            child: Column(
                                children: [
                                    PaddedWidget(
                                        child: RichText(
                                            text: const TextSpan(
                                                children: [
                                                    WidgetSpan(child: Padding(
                                                        padding: EdgeInsets.only(right: 8.0),
                                                        child: Icon(Icons.search),
                                                    )),
                                                    TextSpan(text: "Search"),
                                                ],
                                                style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                )
                                            ) 
                                        ),
                                    ),
                                    PaddedWidget(
                                        child: SearchAnchor(
                                            searchController: searchController,
                                            suggestionsBuilder: (context, controller) => const [],
                                            builder: (context, controller) {
                                                return SearchBar(
                                                    onSubmitted: (text) {
                                                        final searchFuture = Config.addUser(text);
                
                                                        setState(() {
                                                            state = SearchState(
                                                                searchFuture: searchFuture, 
                                                                searchQuery: text
                                                            );
                                                            inProgress = true;
                                                        });
                                                    },
                                                    leading: const PaddedWidget(child: Icon(Icons.search)),
                                                );
                                            },
                                        ),
                                    ),
                                    if (state != null) state!
                                ],
                            ),
                        ),
                    )
                ),
            ),
        );
    }
}

// This is the widget that displays the loading circle and an error if the streamer was not found.
class SearchState extends StatelessWidget {
    final Future<bool> searchFuture;
    final String searchQuery;

    const SearchState({required this.searchFuture, required this.searchQuery, super.key});

    @override
    Widget build(BuildContext context) {
        return PaddedWidget(
            child: FutureBuilder(
                future: searchFuture, 
                builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                        var data = snapshot.data!;
            
                        if (!data) {
                            inProgress = false;
                            return Container(
                                decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                    color: LiveStyle.errorBackground
                                ),
                                child: PaddedWidget(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            const PaddedWidget(child: Icon(Icons.error, color: LiveStyle.errorText)),
                                            PaddedWidget(
                                                child: Text.rich(
                                                    TextSpan(
                                                        text: "Could not find streamer \"$searchQuery\""
                                                    ),
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16,
                                                        color: LiveStyle.errorText
                                                    ),
                                                ),
                                            )
                                        ],
                                    ),
                                ),
                            );
                        }
            
                        // We save the streamer list since we have a new one.
                        Future.sync(Config.saveData);

                        // We remove the dialog.
                        Navigator.of(context, rootNavigator: true).pop<bool>(data);
                    }
            
                    return const Center(child: CircularProgressIndicator());
                },
            ),
        );
    }
}