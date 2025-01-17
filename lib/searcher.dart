import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:nokulive/time.dart';
import 'package:url_launcher/url_launcher.dart';
import 'nokulog.dart';

typedef Searcher = TwitchSearcher; // This is temporary.

/// Class that works as an interface with some of the decapi API for Twitch.
class TwitchSearcher {
    static const String _baseUrl = "https://decapi.me/twitch";

    final String username;
    late final Uri website;

    final Dio _client = Dio()..httpClientAdapter = Http2Adapter(ConnectionManager(idleTimeout: const Duration(seconds: 15)));
    final _timeRegex = RegExp(
        r'(?:(\d+)\s*hours?)?(?:,\s*)?\s*(?:(\d+)\s*minutes?)?(?:,\s*)?\s*(?:(\d+)\s*seconds?)?',
        caseSensitive: false,
    );

    bool autoOpen = false;
    bool _autoopened = false;

    int _followers = -1;
    int _viewers = -1;
    String? _avatarURL;

    bool _isLive = false;
    String? _streamTitle;
    String? _streamGame;
    Time _streamTime = Time.zero;

    Completer<bool> _reloading = Completer<bool>();

    TwitchSearcher(this.username) {
        website = Uri.parse("https://twitch.tv/$username");
    }

    Future<bool> exists() async {
        try {
            Response<String> response = await _client.get<String>("$_baseUrl/id/$username");

            if (response.data == null) return false;

            return !response.data!.contains("User not found");
        } catch (e, stackTrace) {
            Nokulog.e("Failed to fetch ID of \"$username\" to check if it exists.", error: e, stackTrace: stackTrace);
            return false;
        }
    }

    Future<bool> reload() async {
        _resetDefaults();

        var live = await _getLive();

        _followers = await _getFollowers();
        _avatarURL = await _getAvatar();

        _streamTitle = await _getStreamTitle();
        _streamGame = await _getStreamGame();

        if (live == null) {
            _isLive = false;
            _autoopened = false;
            _reloading.complete(true);
            return _isLive;
        }

        _isLive = true;

        _streamTime = await _getStreamTime(timeString: live);
        _viewers = await _getStreamViewers();

        _reloading.complete(true);

        if (autoOpen && !_autoopened) {
            launchUrl(website);
            _autoopened = true;
        }
        return _isLive;
    }

    Future<String?> _getLive() async {
        try {
            Response<String> status = await _client.get<String>("$_baseUrl/uptime/$username");

            final result = status.data ?? "offline";

            return (result.contains("offline") ? null : result);
        }
        catch (e, stackTrace) {
            Nokulog.e("Failed to fetch live status for \"$username\"", error: e, stackTrace: stackTrace);
            return null;
        }
    }

    Future<int> _getFollowers() async {
        try {
            Response<String> response = await _client.get<String>("$_baseUrl/followcount/$username");
            
            return int.tryParse(response.data ?? "") ?? _followers;
        } catch (e, stackTrace) {
            Nokulog.e("Failed to fetch follower count for \"$username\".", error: e, stackTrace: stackTrace);
            return _followers;
        }
    }

    Future<String?> _getAvatar() async {
        try {
            Response<String> response = await _client.get<String>("$_baseUrl/avatar/$username");
            return response.data ?? _avatarURL;
        } catch (e, stackTrace) {
            Nokulog.e("Failed to fetch avatar URL for \"$username\".", error: e, stackTrace: stackTrace);
            return _avatarURL;
        }
    }

    Future<String?> _getStreamTitle() async {
        try {
            Response<String> response = await _client.get<String>("$_baseUrl/title/$username");
            return response.data ?? _streamTitle;
        } catch (e, stackTrace) {
            Nokulog.e("Failed to fetch stream title for \"$username\".", error: e, stackTrace: stackTrace);
            return _streamTitle;
        }
    }

    Future<String?> _getStreamGame() async {
        try {
            Response<String> response = await _client.get<String>("$_baseUrl/game/$username");
            return response.data ?? _streamGame;
        } catch (e, stackTrace) {
            Nokulog.e("Failed to fetch game title for \"$username\".", error: e, stackTrace: stackTrace);
            return _streamGame;
        }
    }

    Future<Time> _getStreamTime({String? timeString}) async {
        if (timeString == null) {
            try {
                Response<String> timeResponse = await _client.get<String>("$_baseUrl/uptime/$username");
                timeString = timeResponse.data ?? "offline";
            } catch (e, stackTrace) {
                Nokulog.e("Failed to fetch stream time for \"$username\".", error: e, stackTrace: stackTrace);
                timeString = "offline";
            }
        }

        if (timeString.contains("offline")) return Time.zero;

        var possibleMatch = _timeRegex.firstMatch(timeString);

        if (possibleMatch == null) return _streamTime;

        final hours = int.tryParse(possibleMatch.group(1) ?? "");
        final minutes = int.tryParse(possibleMatch.group(2) ?? "");
        final seconds = int.tryParse(possibleMatch.group(3) ?? "");
    
        return Time(hours: hours ?? 0, minutes: minutes ?? 0, seconds: seconds ?? 0);
    }

    Future<int> _getStreamViewers() async {
        try {
            Response<String> response = await _client.get("$_baseUrl/viewercount/$username");

            return int.tryParse(response.data ?? "") ?? _viewers;
        } catch (e, stackTrace) {
            Nokulog.e("Failed to fetch number of viewers on stream for \"$username\".", error: e, stackTrace: stackTrace);
            return _viewers;
        }
    }

    void _resetDefaults() {
        _reloading = Completer<bool>();
        _followers = -1;
        _viewers = -1;
        _avatarURL = null;
        _isLive = false;
        _streamTitle = null;
        _streamGame = null;
        _streamTime = Time.zero;
    }

    int get followers {
        return _followers;
    }

    String get avatarURL {
        return _avatarURL ?? "";
    }

    bool get isLive => _isLive;

    String get streamTitle {
        return _streamTitle ?? "";
    }

    String get streamGame {
        return _streamGame ?? "";
    }

    Time get streamTime {
        return _streamTime;
    }

    int get streamViewers {
        return _viewers;
    }

    Future<bool> get reloading => _reloading.future;
}