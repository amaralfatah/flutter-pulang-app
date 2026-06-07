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

  // Authorization scopes only. In google_sign_in v7 authentication (identity)
  // and authorization (API access) are separate steps, so 'email' must NOT be
  // here — mixing it in breaks the "already granted?" check and re-prompts.
  static const List<String> _driveScopes = [
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
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw Exception('Sign in not supported on this platform');
      }

      // 1. Authenticate (establishes identity, persisted for silent restore).
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: _driveScopes,
      );
      _currentUser = account;

      // 2. Authorize the Drive scopes ONCE, interactively. This grant is
      // cached by the platform so future sessions can reuse it silently —
      // this is what stops the app from re-prompting on every restart.
      await account.authorizationClient.authorizeScopes(_driveScopes);
    } catch (e) {
      // ignore: avoid_print
      print('Sign In Error: $e');
      rethrow;
    }
  }

  /// Sign out and fully disconnect the Google account.
  ///
  /// Uses disconnect() (not signOut()) so the authorization grant is revoked
  /// and the account is NOT silently restored by attemptLightweightAuthentication()
  /// on the next launch — otherwise the logout wouldn't "stick".
  ///
  /// Local state (current user + persisted email) is cleared synchronously so
  /// the UI updates immediately, instead of waiting for the asynchronous
  /// authenticationEvents callback (which fires after the caller already
  /// re-read settings, making it look like logout did nothing).
  Future<void> signOut() async {
    if (!_isInitialized) await init();

    try {
      await GoogleSignIn.instance.disconnect();
    } catch (e) {
      // Even if the remote revoke fails (e.g. no network), still clear local
      // state below so the user is logged out from the app's perspective.
      // ignore: avoid_print
      print('Sign Out Error: $e');
    }

    _currentUser = null;
    await _preferencesService.setGoogleAccountEmail(null);
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

    // 6. Retention: keep only the most recent backups, delete the rest.
    await _pruneOldBackups(driveApi);
  }

  /// Maximum number of backup files to retain on Drive.
  static const int maxBackupsToKeep = 10;

  /// Delete backups beyond [maxBackupsToKeep], keeping the newest ones.
  /// Best-effort: a failure here must never fail the backup itself.
  Future<void> _pruneOldBackups(drive.DriveApi driveApi) async {
    try {
      final list = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name contains 'pulang_backup_' and trashed = false",
        orderBy: 'createdTime desc',
        $fields: 'files(id, createdTime)',
      );
      final files = list.files ?? [];
      if (files.length <= maxBackupsToKeep) return;

      for (final file in files.sublist(maxBackupsToKeep)) {
        final id = file.id;
        if (id != null) {
          await driveApi.files.delete(id);
        }
      }
    } catch (_) {
      // Ignore pruning errors; the backup already succeeded.
    }
  }

  /// Delete a single backup file by id (used by the restore dialog UI).
  Future<void> deleteBackup(String fileId) async {
    if (!_isInitialized) await init();
    if (_currentUser == null) throw Exception('Not signed in');

    final client = await _getAuthClient();
    final driveApi = drive.DriveApi(client);
    await driveApi.files.delete(fileId);
  }

  /// Minimum gap between two automatic backups.
  static const Duration autoBackupInterval = Duration(hours: 24);

  /// Run a backup automatically, but ONLY if all conditions are met:
  /// - auto-backup is enabled in settings,
  /// - a Google account is available via silent restore (never prompts),
  /// - Drive authorization can be obtained silently (never prompts),
  /// - at least [autoBackupInterval] has passed since the last backup.
  ///
  /// Returns true if a backup was actually performed. Safe to call on every
  /// app launch — it's a no-op when not due.
  Future<bool> autoBackupIfDue() async {
    // --- Cheap, local checks FIRST: do not touch Google unless truly needed.
    // This is what keeps the Credential Manager UI from flashing on every
    // launch — we only contact Google when a backup is actually due.

    if (!await _preferencesService.isAutoBackupEnabled()) return false;

    // Only proceed if the user has connected an account before. Otherwise
    // there's nothing to restore and no reason to trigger any sign-in UI.
    final email = await _preferencesService.getGoogleAccountEmail();
    if (email == null || email.isEmpty) return false;

    // Skip if we already backed up within the interval window.
    final lastStr = await _preferencesService.getLastBackupDate();
    if (lastStr != null) {
      final last = DateTime.tryParse(lastStr);
      if (last != null &&
          DateTime.now().difference(last) < autoBackupInterval) {
        return false;
      }
    }

    // --- Only now do we touch Google (at most once per interval).
    if (!_isInitialized) await init();

    // Need a restored account; an automatic backup must never show a login UI.
    if (_currentUser == null) return false;

    // Ensure Drive access can be granted silently; bail (no prompt) otherwise.
    final authorization = await _currentUser!.authorizationClient
        .authorizationForScopes(_driveScopes);
    if (authorization == null) return false;

    await backup();
    return true;
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

  /// Helper to get authenticated HTTP client (google_sign_in v7 API).
  Future<AuthClient> _getAuthClient() async {
    final user = _currentUser;
    if (user == null) throw Exception('No user');

    final authClient = user.authorizationClient;

    // 1. SILENT first: reuse a previously-granted authorization. After the
    // user has signed in once, this returns a fresh access token with NO UI,
    // even across app restarts — so no repeated login prompts.
    GoogleSignInClientAuthorization? authorization = await authClient
        .authorizationForScopes(_driveScopes);

    // 2. Fallback: only prompt if the grant is genuinely missing
    // (first run, revoked, or scopes changed).
    authorization ??= await authClient.authorizeScopes(_driveScopes);

    return AuthClient({
      'Authorization': 'Bearer ${authorization.accessToken}',
    });
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
