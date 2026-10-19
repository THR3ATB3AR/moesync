import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../providers/providers.dart';

class OAuthDialog extends ConsumerStatefulWidget {
  final ServiceType service;

  const OAuthDialog({
    super.key,
    required this.service,
  });

  @override
  ConsumerState<OAuthDialog> createState() => _OAuthDialogState();
}

class _OAuthDialogState extends ConsumerState<OAuthDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  String? _authUrl;
  String? _codeVerifier;
  final TextEditingController _codeController = TextEditingController();
  bool _hasOpenedBrowser = false;
  HttpServer? _localServer;

  final TextEditingController _kitsuUser = TextEditingController();
  final TextEditingController _kitsuPass = TextEditingController();
  bool _obscurePassword = true;

  final TextEditingController _muUser = TextEditingController();
  final TextEditingController _muPass = TextEditingController();
  bool _obscureMuPassword = true;

  final TextEditingController _manualTokenController = TextEditingController();
  final TextEditingController _manualUserController = TextEditingController();
  final TextEditingController _customClientId = TextEditingController();
  final TextEditingController _customClientSecret = TextEditingController();

  @override
  void initState() {
    super.initState();
    final creds = ref.read(authProvider).credentials[widget.service];
    if (creds != null) {
      _manualTokenController.text = creds.accessToken ?? '';
      _manualUserController.text = creds.username ?? '';
      _customClientId.text = creds.clientId ?? '';
      _customClientSecret.text = creds.clientSecret ?? '';
      if (widget.service == ServiceType.kitsu && creds.username != null) {
        _kitsuUser.text = creds.username!;
      }
      if (widget.service == ServiceType.mangaupdates && creds.username != null) {
        _muUser.text = creds.username!;
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _kitsuUser.dispose();
    _kitsuPass.dispose();
    _muUser.dispose();
    _muPass.dispose();
    _manualTokenController.dispose();
    _manualUserController.dispose();
    _customClientId.dispose();
    _customClientSecret.dispose();
    _localServer?.close(force: true);
    super.dispose();
  }

  void _onLoopbackCodeReceived(String code) {
    if (!mounted) return;
    setState(() {
      _codeController.text = code;
    });
    _submitOAuth();
  }

  Future<void> _openBrowser() async {
    final oauth = ref.read(oauthServiceProvider);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String url;
      switch (widget.service) {
        case ServiceType.mal:
          final malAuth = oauth.prepareMalAuth();
          url = malAuth.url;
          _codeVerifier = malAuth.codeVerifier;
          break;
        case ServiceType.anilist:
          url = oauth.prepareAnilistAuth();
          break;
        case ServiceType.shikimori:
          url = oauth.prepareShikimoriAuth();
          break;
        case ServiceType.simkl:
          final simklAuth = oauth.prepareSimklAuth();
          url = simklAuth.url;
          _codeVerifier = simklAuth.codeVerifier;
          break;
        case ServiceType.mangabaka:
          final mbAuth = oauth.prepareMangaBakaAuth();
          url = mbAuth.url;
          _codeVerifier = mbAuth.codeVerifier;
          break;
        case ServiceType.kitsu:
        case ServiceType.mangaupdates:
          return;
      }

      _authUrl = url;

      if (widget.service != ServiceType.shikimori && _localServer == null) {
        _localServer = await oauth.tryStartLoopbackServer(_onLoopbackCodeReceived);
      }

      final opened = await oauth.openUrlInBrowser(url);
      if (!opened && mounted) {
        setState(() {
          _errorMessage =
              'Could not open system browser automatically. Please open the URL manually.';
        });
      }

      setState(() {
        _hasOpenedBrowser = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initiate authorization: $e';
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _codeController.text = data.text!.trim();
      });
    }
  }

  Future<void> _submitOAuth() async {
    final rawInput = _codeController.text.trim();
    if (rawInput.isEmpty) {
      setState(() => _errorMessage = 'Please enter or paste the code/URL');
      return;
    }

    final oauth = ref.read(oauthServiceProvider);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      ServiceCredentials creds;
      switch (widget.service) {
        case ServiceType.mal:
          if (_codeVerifier == null) {
            throw Exception('Please click "Open Login Page" first');
          }
          creds = await oauth.exchangeMalToken(
            rawCodeOrUrl: rawInput,
            codeVerifier: _codeVerifier!,
          );
          break;
        case ServiceType.anilist:
          creds = await oauth.exchangeAnilistToken(rawCodeOrUrl: rawInput);
          break;
        case ServiceType.shikimori:
          creds = await oauth.exchangeShikimoriToken(rawCodeOrUrl: rawInput);
          break;
        case ServiceType.simkl:
          if (_codeVerifier == null) {
            throw Exception('Please click "Open Login Page" first');
          }
          creds = await oauth.exchangeSimklToken(
            rawCodeOrUrl: rawInput,
            codeVerifier: _codeVerifier!,
          );
          break;
        case ServiceType.mangabaka:
          if (_codeVerifier == null) {
            throw Exception('Please click "Open Login Page" first');
          }
          creds = await oauth.exchangeMangaBakaToken(
            rawCodeOrUrl: rawInput,
            codeVerifier: _codeVerifier!,
          );
          break;
        case ServiceType.kitsu:
        case ServiceType.mangaupdates:
          return;
      }

      await _finishLogin(creds);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _submitKitsu() async {
    final username = _kitsuUser.text.trim();
    final password = _kitsuPass.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email/username and password');
      return;
    }

    final oauth = ref.read(oauthServiceProvider);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final creds = await oauth.loginKitsu(
        usernameOrEmail: username,
        password: password,
      );
      await _finishLogin(creds);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _submitMangaUpdates() async {
    final username = _muUser.text.trim();
    final password = _muPass.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both username and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final creds = await ref.read(mangaupdatesServiceProvider).login(
            username: username,
            password: password,
          );
      await _finishLogin(creds);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }



  Future<void> _saveCustomAppCredentials() async {
    final customCId = _customClientId.text.trim();
    final customCSecret = _customClientSecret.text.trim();
    final currentCreds = ref.read(authProvider).credentials[widget.service] ??
        const ServiceCredentials();
    final newCreds = currentCreds.copyWith(
      clientId: customCId.isNotEmpty ? customCId : null,
      clientSecret: customCSecret.isNotEmpty ? customCSecret : null,
    );
    await ref.read(authProvider.notifier).saveCredentials(widget.service, newCreds);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved developer credentials for ${widget.service.displayName}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitManual() async {
    final token = _manualTokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _errorMessage = 'Token cannot be empty');
      return;
    }

    final currentCreds = ref.read(authProvider).credentials[widget.service] ??
        const ServiceCredentials();
    final customCId = _customClientId.text.trim();
    final customCSecret = _customClientSecret.text.trim();
    final newCreds = currentCreds.copyWith(
      accessToken: token,
      username: _manualUserController.text.trim().isNotEmpty
          ? _manualUserController.text.trim()
          : currentCreds.username,
      clientId: customCId.isNotEmpty ? customCId : currentCreds.clientId,
      clientSecret:
          customCSecret.isNotEmpty ? customCSecret : currentCreds.clientSecret,
      isConnected: true,
    );

    await _finishLogin(newCreds);
  }

  Future<void> _finishLogin(ServiceCredentials creds) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    await ref.read(authProvider.notifier).saveCredentials(widget.service, creds);

    ref.read(mediaLibraryProvider.notifier).loadItems();
    ref.read(syncProvider.notifier).scanDiffs();

    if (mounted) {
      final userText = creds.username != null && creds.username!.isNotEmpty
          ? ' as ${creds.username}'
          : '';
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '✓ Successfully connected to ${widget.service.displayName}$userText!',
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final isConnected = auth.isConnected(widget.service);
    final currentCreds = auth.credentials[widget.service];

    final serviceErrors = ref.watch(serviceErrorsProvider);
    final hasError = isConnected && serviceErrors.containsKey(widget.service);
    final serviceError = serviceErrors[widget.service];
    final displayedError = _errorMessage ?? (hasError ? serviceError : null);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: hasError
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.primaryContainer,
                    child: Icon(
                      hasError
                          ? Icons.error_outline_rounded
                          : Icons.account_circle_rounded,
                      color: hasError
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect ${widget.service.displayName}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          hasError
                              ? 'Connection error: $serviceError'
                              : (isConnected
                                  ? 'Connected as ${currentCreds?.username ?? "User"}'
                                  : 'Log in to sync your anime & manga lists'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasError
                                ? theme.colorScheme.error
                                : (isConnected
                                    ? Colors.green.shade700
                                    : theme.colorScheme.onSurfaceVariant),
                            fontWeight: (isConnected || hasError)
                                ? FontWeight.w600
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              if (displayedError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          displayedError,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (widget.service == ServiceType.kitsu)
                _buildKitsuContent(theme)
              else if (widget.service == ServiceType.mangaupdates)
                _buildMangaUpdatesContent(theme)
              else
                _buildOAuthContent(theme),

              const SizedBox(height: 16),

              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Advanced Configuration & Manual Entry',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  children: [
                    if (widget.service != ServiceType.kitsu &&
                        widget.service != ServiceType.mangaupdates) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customClientId,
                        decoration: const InputDecoration(
                          labelText: 'Custom Client ID (Optional override)',
                          hintText: 'Configured in .env by default',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customClientSecret,
                        decoration: const InputDecoration(
                          labelText: 'Custom Client Secret (Optional override)',
                          hintText: 'Configured in .env by default',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: _saveCustomAppCredentials,
                          child: const Text('Save Custom Client ID/Secret'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _manualTokenController,
                      decoration: const InputDecoration(
                        labelText: 'Access Token / Bearer Token',
                        hintText: 'Paste token here',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _manualUserController,
                      decoration: const InputDecoration(
                        labelText: 'Username (Optional)',
                        hintText: 'e.g. username',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _isLoading ? null : _submitManual,
                      child: const Text('Save Manual Token'),
                    ),
                  ],
                ),
              ),

              if (isConnected) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final nav = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          await ref
                              .read(authProvider.notifier)
                              .disconnect(widget.service);
                          ref.read(mediaLibraryProvider.notifier).loadItems();
                          ref.read(syncProvider.notifier).scanDiffs();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Logged out from ${widget.service.displayName}',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            nav.pop();
                          }
                        },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text('Logout (${widget.service.displayName})'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOAuthContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _isLoading ? null : _openBrowser,
          icon: _isLoading && !_hasOpenedBrowser
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.open_in_browser_rounded),
          label: Text(
            _hasOpenedBrowser
                ? 'Re-open ${widget.service.displayName} in Browser'
                : '1. Open Login Page in Browser',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (_hasOpenedBrowser && _authUrl != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: _authUrl!));
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Copied authorization link to clipboard!'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: const Text('Copy Auth Link', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to connect:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              if (widget.service == ServiceType.shikimori) ...[
                _buildInstructionRow('1', 'Click above to log in on Shikimori.'),
                _buildInstructionRow('2', 'Click "Allow" on the authorization page.'),
                _buildInstructionRow(
                    '3', 'Shikimori will display your code. Copy & paste it below.'),
              ] else ...[
                _buildInstructionRow(
                    '1', 'Click above to log in and approve access in your browser.'),
                _buildInstructionRow('2',
                    'You will be redirected to localhost (the page might say "Cannot connect", that is expected).'),
                _buildInstructionRow('3',
                    'Copy the entire URL from your browser address bar (or just the code) and paste below.'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          '2. Paste Authorization Code or Redirect URL:',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          decoration: InputDecoration(
            hintText: widget.service == ServiceType.shikimori
                ? 'e.g. 783ab29... or code'
                : 'http://localhost/?code=... or raw code',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_codeController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _codeController.clear()),
                  ),
                IconButton(
                  tooltip: 'Paste from clipboard',
                  icon: const Icon(Icons.paste_rounded, size: 20),
                  onPressed: _pasteFromClipboard,
                ),
              ],
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: (_isLoading || _codeController.text.trim().isEmpty)
              ? null
              : _submitOAuth,
          icon: _isLoading && _hasOpenedBrowser
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_rounded),
          label: const Text(
            'Complete Connection',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildKitsuContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Log in with your Kitsu email / username and password:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _kitsuUser,
          decoration: InputDecoration(
            labelText: 'Email or Username',
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _kitsuPass,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _isLoading ? null : _submitKitsu,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.login_rounded),
          label: const Text(
            'Log In to Kitsu',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildMangaUpdatesContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Log in with your MangaUpdates username and password:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _muUser,
          decoration: InputDecoration(
            labelText: 'Username',
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _muPass,
          obscureText: _obscureMuPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureMuPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureMuPassword = !_obscureMuPassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _isLoading ? null : _submitMangaUpdates,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.login_rounded),
          label: const Text(
            'Log In to MangaUpdates',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }



  Widget _buildInstructionRow(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            ),
            child: Text(
              step,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
