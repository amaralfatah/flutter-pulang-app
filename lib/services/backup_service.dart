import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'database_service.dart';
import 'preferences_service.dart';

/// Service for handling Google Drive Backup & Restore
class BackupService {
  final DatabaseService _databaseService;
  final PreferencesService _preferencesService;

  BackupService({
    required DatabaseService databaseService,
    required PreferencesService preferencesService,
  }) : _databaseService = databaseService,
       _preferencesService = preferencesService;

  static const List<String> _driveScopes = [
    'email', // Required for sign in
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  // Server Client ID from Google Cloud Console (Web application type)
  static const String _serverClientId =
      '407290386438-orjbo225jeco7cknlq5l2ov43iurthpq.apps.googleusercontent.com';

  GoogleSignInAccount? _currentUser;
  bool _isInitialized = false;

  /// Initialize and check persistent auth
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Singleton
      await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);

      // 2. Listen for auth events
      GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
          _preferencesService.setGoogleAccountEmail(event.user.email);
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
          _preferencesService.setGoogleAccountEmail(null);
        }
      });

      // 3. Try silent sign-in (now attemptLightweightAuthentication)
      final result = await GoogleSignIn.instance
          .attemptLightweightAuthentication();

      if (result != null) {
        _currentUser = result;
        await _preferencesService.setGoogleAccountEmail(result.email);
      }
    } catch (e) {
      // ignore: avoid_print
      print('BackupService Init Error: $e');
    }
    _isInitialized = true;
  }

  /// Sign in with Google (Interactive)
  Future<void> signIn() async {
    // Ensure initialized
    if (!_isInitialized) {
      await init();
    }

    try {
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        await GoogleSignIn.instance.authenticate(scopeHint: _driveScopes);
      } else {
        throw Exception('Sign in not supported on this platform');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Sign In Error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
  }

  /// Get current user
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Perform Backup
  Future<void> backup() async {
    if (!_isInitialized) await init();

    if (_currentUser == null) throw Exception('Not signed in');

    // 1. Get Auth Client
    final client = await _getAuthClient();
    final driveApi = drive.DriveApi(client);

    // 2. Prepare Data
    final prayers = await _databaseService.getAllPrayers();
    final settings = await _preferencesService.getAllSettings();

    final backupData = {
      'version': 1,
      'date': DateTime.now().toIso8601String(),
      'device': Platform.operatingSystem,
      'settings': settings,
      'prayers': prayers.map((p) => p.toMap()).toList(),
    };

    final jsonString = jsonEncode(backupData);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'pulang_backup_$timestamp.json';

    // 3. Create File Metadata
    final driveFile = drive.File()
      ..name = fileName
      ..parents =
          ['appDataFolder'] // Hidden app specific folder
      ..mimeType = 'application/json';

    final media = drive.Media(
      Stream.value(jsonString.codeUnits),
      jsonString.length,
    );

    // 4. Upload
    await driveApi.files.create(driveFile, uploadMedia: media);

    // 5. Update local record
    final nowStr = DateTime.now().toString().split('.')[0]; // Simple format
    await _preferencesService.setLastBackupDate(nowStr);
  }

  /// List available backups
  Future<List<drive.File>> listBackups() async {
    if (!_isInitialized) await init();

    if (_currentUser == null) throw Exception('Not signed in');

    final client = await _getAuthClient();
    final driveApi = drive.DriveApi(client);

    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name contains 'pulang_backup_' and trashed = false",
      orderBy: 'createdTime desc',
      $fields: 'files(id, name, createdTime)',
    );

    return fileList.files ?? [];
  }

  /// Restore from a specific file
  Future<void> restore(String fileId) async {
    if (!_isInitialized) await init();

    if (_currentUser == null) throw Exception('Not signed in');

    final client = await _getAuthClient();
    final driveApi = drive.DriveApi(client);

    // 1. Download file
    final drive.Media file =
        await driveApi.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final stream = file.stream;
    final content = await utf8.decodeStream(stream);
    final data = jsonDecode(content) as Map<String, dynamic>;

    // 2. Clear existing data (Replace strategy)
    await _databaseService.deleteAllData();

    // 3. Import Settings
    if (data['settings'] != null) {
      await _preferencesService.restoreSettings(data['settings']);
    }

    // 4. Import Prayers
    if (data['prayers'] != null) {
      final List<dynamic> prayersList = data['prayers'];
      final prayers = prayersList.map((map) => Prayer.fromMap(map)).toList();
      await _databaseService.importPrayers(prayers);
    }
  }

  /// Helper to get authenticated HTTP client (New v7.2.0 API)
  Future<AuthClient> _getAuthClient() async {
    if (_currentUser == null) throw Exception('No user');

    // Retrieve the authorization tokens from the current user using AuthorizationClient
    final authClient = _currentUser!.authorizationClient;

    // DEBUG LOGGING
    print('DEBUG: Requesting headers for scopes: $_driveScopes');
    print('DEBUG: Current User ID: ${_currentUser!.id}');
    print('DEBUG: Current User Email: ${_currentUser!.email}');

    // Try to get headers, prompting if necessary (IMPORTANT for new users)
    // We explicitly set promptIfNecessary: true to handle cases where
    // scopeHint in authenticate() wasn't enough.
    Map<String, String>? headers = await authClient.authorizationHeaders(
      _driveScopes,
      promptIfNecessary: true,
    );

    // If still null, try one last force authorization
    if (headers == null) {
      print('DEBUG: Headers null, attempting explicit authorizeScopes...');
      try {
        await authClient.authorizeScopes(_driveScopes);
        headers = await authClient.authorizationHeaders(_driveScopes);
      } catch (e) {
        print('DEBUG: Explicit authorization failed: $e');
      }
    }

    if (headers == null) {
      print('DEBUG: Authorization headers returned NULL.');
      // This often happens if the SHA-1 is missing in Console or scopes were rejected.
      throw Exception(
        'Failed to get authorization headers. Check SHA-1/Scopes.',
      );
    } else {
      print('DEBUG: Headers obtained successfully: ${headers.keys}');
    }

    return AuthClient(headers);
  }
}

class AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
