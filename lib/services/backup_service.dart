import 'dart:convert';
import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
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

  /// Initialize the Google Sign-In singleton and event listeners.
  ///
  /// Deliberately does NOT call attemptLightweightAuthentication(): on Android
  /// that goes through Credential Manager, which briefly flashes its own
  /// bottom sheet even for a "silent" restore. We never need authentication at
  /// startup — Drive access only needs an authorization token, which
  /// [_getAuthClient] obtains silently without any Credential Manager UI.
  /// Interactive authentication happens only in [signIn] (user-initiated).
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);

      GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
          _preferencesService.setGoogleAccountEmail(event.user.email);
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
          _preferencesService.setGoogleAccountEmail(null);
        }
      });
    } catch (e) {
      debugPrint('BackupService Init Error: $e');
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

      // Persist the email synchronously — the authenticationEvents listener
      // also does this, but asynchronously, and callers (e.g. sign-in +
      // restore flow) may check the signed-in state immediately after.
      await _preferencesService.setGoogleAccountEmail(account.email);

      // 2. Authorize the Drive scopes ONCE, interactively. This grant is
      // cached by the platform so future sessions can reuse it silently —
      // this is what stops the app from re-prompting on every restart.
      await account.authorizationClient.authorizeScopes(_driveScopes);
    } catch (e) {
      debugPrint('Sign In Error: $e');
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
      debugPrint('Sign Out Error: $e');
    }

    _currentUser = null;
    await _preferencesService.setGoogleAccountEmail(null);
  }

  /// Get current user
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Whether a Google account has been connected before. This is the
  /// "signed in" gate for Drive operations: identity comes from the stored
  /// email, and API access from the platform-cached authorization grant —
  /// neither requires re-authenticating (and thus no Credential Manager UI).
  Future<bool> _hasConnectedAccount() async {
    if (_currentUser != null) return true;
    final email = await _preferencesService.getGoogleAccountEmail();
    return email != null && email.isNotEmpty;
  }

  Future<void> _ensureSignedIn() async {
    if (!_isInitialized) await init();
    if (!await _hasConnectedAccount()) throw Exception('Not signed in');
  }

  /// Perform Backup (interactive context: may prompt to re-authorize if the
  /// cached grant was revoked).
  Future<void> backup() async {
    await _ensureSignedIn();
    await _performBackup(await _requireAuthClient());
  }

  /// Upload a backup using an already-authorized [client].
  Future<void> _performBackup(AuthClient client) async {
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
    await _ensureSignedIn();
    final client = await _requireAuthClient();
    final driveApi = drive.DriveApi(client);
    await driveApi.files.delete(fileId);
  }

  /// Minimum gap between two automatic backups.
  static const Duration autoBackupInterval = Duration(hours: 24);

  /// Run a backup automatically, but ONLY if all conditions are met:
  /// - auto-backup is enabled in settings,
  /// - a Google account was connected before (stored email),
  /// - Drive authorization can be obtained silently (never prompts, no UI),
  /// - at least [autoBackupInterval] has passed since the last backup.
  ///
  /// Returns true if a backup was actually performed. Safe to call on every
  /// app launch or from a background alarm — it never shows any UI.
  Future<bool> autoBackupIfDue() async {
    // --- Cheap, local checks FIRST: do not touch Google unless truly needed.

    if (!await _preferencesService.isAutoBackupEnabled()) return false;

    // Only proceed if the user has connected an account before.
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

    // Silent authorization ONLY — this is a pure token fetch through the
    // platform's Authorization API, NOT Credential Manager authentication,
    // so no bottom sheet can appear. Bail out quietly if the grant is gone.
    final client = await _getAuthClient(allowInteraction: false);
    if (client == null) return false;

    await _performBackup(client);
    return true;
  }

  /// Alarm id for the daily background auto-backup
  /// (prayer alarms use 1-5, the test notification uses 99).
  static const int autoBackupAlarmId = 90;

  /// Schedule the daily background auto-backup, WhatsApp-style: it runs via
  /// AlarmManager even when the app is not open. Inexact + no wakeup so the
  /// system batches it cheaply; [autoBackupIfDue] re-checks all conditions
  /// (and the 24h window) inside the callback, so firing is always safe.
  static Future<void> scheduleDailyAutoBackup() async {
    if (!Platform.isAndroid) return;
    try {
      await AndroidAlarmManager.periodic(
        autoBackupInterval,
        autoBackupAlarmId,
        _backgroundBackupCallback,
        exact: false,
        wakeup: false,
        rescheduleOnReboot: true,
      );
    } catch (e) {
      debugPrint('Auto-backup scheduling error: $e');
    }
  }

  /// Entry point invoked by AlarmManager in a background isolate. Must build
  /// its own service instances — nothing from the UI isolate is available.
  @pragma('vm:entry-point')
  static Future<void> _backgroundBackupCallback() async {
    try {
      final service = BackupService(
        databaseService: DatabaseService(),
        preferencesService: PreferencesService(),
      );
      await service.autoBackupIfDue();
    } catch (e) {
      // A background backup must never crash the isolate; just log and retry
      // on the next alarm.
      debugPrint('Background backup error: $e');
    }
  }

  /// List available backups
  Future<List<drive.File>> listBackups() async {
    await _ensureSignedIn();
    final client = await _requireAuthClient();
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
    await _ensureSignedIn();
    final client = await _requireAuthClient();
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

  /// Get an authorized HTTP client for the Drive API.
  ///
  /// This is authorization-only (a token fetch), NOT authentication — it never
  /// goes through Credential Manager, so the silent path shows zero UI.
  /// Works even when [_currentUser] is null: the account-less
  /// [GoogleSignIn.authorizationClient] resolves the previously-authorized
  /// account from the platform-cached grant, which is how a backup can run
  /// silently after an app restart (or in a background isolate) without ever
  /// re-authenticating.
  ///
  /// With [allowInteraction] false, returns null when no cached grant exists
  /// instead of prompting — required for automatic/background backups.
  Future<AuthClient?> _getAuthClient({bool allowInteraction = true}) async {
    if (!_isInitialized) await init();

    // Prefer the account-bound client right after an interactive sign-in;
    // fall back to the account-less one for restored sessions.
    final authClient =
        _currentUser?.authorizationClient ??
        GoogleSignIn.instance.authorizationClient;

    // 1. SILENT first: reuse the previously-granted authorization. After the
    // user has signed in once, this returns a fresh access token with NO UI,
    // even across app restarts.
    GoogleSignInClientAuthorization? authorization = await authClient
        .authorizationForScopes(_driveScopes);

    // 2. Fallback: only prompt if the grant is genuinely missing (revoked or
    // scopes changed) — and only in user-initiated (interactive) contexts.
    if (authorization == null && allowInteraction) {
      authorization = await authClient.authorizeScopes(_driveScopes);
    }
    if (authorization == null) return null;

    return AuthClient({'Authorization': 'Bearer ${authorization.accessToken}'});
  }

  /// Interactive variant of [_getAuthClient] for user-initiated operations,
  /// where a missing grant is an error rather than a silent no-op.
  Future<AuthClient> _requireAuthClient() async {
    final client = await _getAuthClient();
    if (client == null) {
      throw Exception('Gagal mendapat izin akses Google Drive');
    }
    return client;
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
