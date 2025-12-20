import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Simple test screen for Google Drive connection
class GoogleDriveTestScreen extends StatefulWidget {
  const GoogleDriveTestScreen({super.key});

  @override
  State<GoogleDriveTestScreen> createState() => _GoogleDriveTestScreenState();
}

class _GoogleDriveTestScreenState extends State<GoogleDriveTestScreen> {
  String _status = 'Not connected';
  String _email = '';
  bool _isLoading = false;
  List<String> _files = [];
  GoogleSignInAccount? _currentUser;

  static const List<String> _driveScopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  // Server Client ID from Google Cloud Console (Web application type)
  static const String _serverClientId =
      '407290386438-orjbo225jeco7cknlq5l2ov43iurthpq.apps.googleusercontent.com';

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      // Initialize the singleton with Web application serverClientId
      await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);

      // Listen for authentication events
      GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          setState(() {
            _currentUser = event.user;
            _status = '✅ Signed in!';
            _email = event.user.email;
          });
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          setState(() {
            _currentUser = null;
            _status = 'Signed out';
            _email = '';
            _files = [];
          });
        }
      });

      // Try lightweight authentication (silent sign in)
      final result = await GoogleSignIn.instance
          .attemptLightweightAuthentication();
      if (result != null) {
        setState(() {
          _currentUser = result;
          _status = 'Already signed in';
          _email = result.email;
        });
      }
    } catch (e) {
      setState(() => _status = 'Init error: $e');
    }
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    try {
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        await GoogleSignIn.instance.authenticate(scopeHint: _driveScopes);
      } else {
        setState(() => _status = '❌ Sign in not supported on this platform');
      }
    } on GoogleSignInException catch (e) {
      // Handle specific Google Sign-In errors
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          setState(() => _status = '⚠️ Sign in cancelled');
          break;
        case GoogleSignInExceptionCode.clientConfigurationError:
          setState(() => _status = '❌ Configuration error: ${e.description}');
          break;
        default:
          setState(
            () => _status = '❌ Sign In Error: ${e.code} - ${e.description}',
          );
      }
    } catch (e) {
      setState(() => _status = '❌ Sign In Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestDriveScope() async {
    if (_currentUser == null) {
      setState(() => _status = '❌ Please sign in first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Try to get authorization for scopes
      final authorization = await _currentUser!.authorizationClient
          .authorizeScopes(_driveScopes);

      setState(
        () => _status =
            '✅ Drive access granted! Token: ${authorization.accessToken.substring(0, 20)}...',
      );
      await _testDriveAccess(authorization.accessToken);
    } catch (e) {
      setState(() => _status = '⚠️ Authorization error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testDriveAccess(String accessToken) async {
    try {
      final client = GoogleAuthClient(accessToken);
      final driveApi = drive.DriveApi(client);

      // List files in app's folder
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        pageSize: 10,
      );

      setState(() {
        _files = fileList.files?.map((f) => f.name ?? 'Unknown').toList() ?? [];
        _status =
            '✅ Drive access verified! Found ${_files.length} backup files.';
      });
    } catch (e) {
      setState(() => _status = '⚠️ Drive API error: $e');
    }
  }

  Future<void> _createTestFile() async {
    if (_currentUser == null) {
      setState(() => _status = '❌ Please sign in first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get authorization for Drive access
      final authorization = await _currentUser!.authorizationClient
          .authorizeScopes(_driveScopes);

      final client = GoogleAuthClient(authorization.accessToken);
      final driveApi = drive.DriveApi(client);

      // Create a test backup file
      final testData =
          '''
{
  "backup_date": "${DateTime.now().toIso8601String()}",
  "test": true,
  "message": "Pulang backup test"
}
''';

      final media = drive.Media(
        Stream.value(testData.codeUnits),
        testData.length,
      );

      final driveFile = drive.File()
        ..name =
            'pulang_test_backup_${DateTime.now().millisecondsSinceEpoch}.json'
        ..parents = ['appDataFolder'];

      await driveApi.files.create(driveFile, uploadMedia: media);

      setState(() => _status = '✅ Test backup file created successfully!');
      await _testDriveAccess(authorization.accessToken);
    } catch (e) {
      setState(() => _status = '❌ Create file error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await GoogleSignIn.instance.signOut();
    setState(() {
      _currentUser = null;
      _status = 'Signed out';
      _email = '';
      _files = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Drive Test')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: $_status',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_email.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Email: $_email'),
                      ],
                      if (_files.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Backup files:'),
                        ..._files.map((f) => Text('  • $f')),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton.icon(
                  onPressed: _currentUser == null ? _signIn : null,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _currentUser != null ? _requestDriveScope : null,
                  icon: const Icon(Icons.security),
                  label: const Text('Request Drive Permission'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _currentUser != null ? _createTestFile : null,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Create Test Backup'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _currentUser != null ? _signOut : null,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Setup Required:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Go to Google Cloud Console\n'
                        '2. Create OAuth 2.0 Client ID (Android type)\n'
                        '3. Use package: com.amar.pulang\n'
                        '4. Add SHA-1 fingerprint from your keystore\n'
                        '5. Enable Drive API in the project',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// HTTP client that adds Google auth token to requests
class GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }
}
