import 'dart:io';
import 'package:moesync/l10n/gen/app_localizations.dart';
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
          _errorMessage = AppLocalizations.of(context).openBrowserManually;
        });
      }

      setState(() {
        _hasOpenedBrowser = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(
          context,
        ).failedToInitiateAuthorization(e.toString());
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
      setState(
        () => _errorMessage = AppLocalizations.of(context).enterCodeOrUrl,
      );
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
            throw Exception(AppLocalizations.of(context).openLoginPageFirst);
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
            throw Exception(AppLocalizations.of(context).openLoginPageFirst);
          }
          creds = await oauth.exchangeSimklToken(
            rawCodeOrUrl: rawInput,
            codeVerifier: _codeVerifier!,
          );
          break;
        case ServiceType.mangabaka:
          if (_codeVerifier == null) {
            throw Exception(AppLocalizations.of(context).openLoginPageFirst);
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
      setState(
        () => _errorMessage = AppLocalizations.of(
          context,
        ).enterEmailUsernamePassword,
      );
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
      setState(
        () => _errorMessage = AppLocalizations.of(
          context,
        ).enterUsernamePassword,
      );
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
    final l = AppLocalizations.of(context);
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
            l.savedDeveloperCredentials(widget.service.displayName),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitManual() async {
    final token = _manualTokenController.text.trim();
    if (token.isEmpty) {
      setState(
        () => _errorMessage = AppLocalizations.of(context).tokenCannotBeEmpty,
      );
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
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    await ref.read(authProvider.notifier).saveCredentials(widget.service, creds);

    ref.read(mediaLibraryProvider.notifier).loadItems();
    ref.read(syncProvider.notifier).scanDiffs();

    if (mounted) {
      final message = creds.username != null && creds.username!.isNotEmpty
          ? l.successfullyConnectedToServiceAs(
              widget.service.displayName,
              creds.username!,
            )
          : l.successfullyConnectedToService(widget.service.displayName);
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
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
    final l = AppLocalizations.of(context);
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
                          l.connectService(widget.service.displayName),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          hasError
                              ? l.connectionError(serviceError ?? '')
                              : (isConnected
                                  ? l.connectedAsUser(
                                      currentCreds?.username ?? l.user,
                                    )
                                  : l.loginToSyncLists),
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
                    l.advancedConfigurationManualEntry,
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
                        decoration: InputDecoration(
                          labelText: l.customClientIdOptional,
                          hintText: l.configuredInEnvByDefault,
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customClientSecret,
                        decoration: InputDecoration(
                          labelText: l.customClientSecretOptional,
                          hintText: l.configuredInEnvByDefault,
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
                          child: Text(l.saveCustomClientCredentials),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _manualTokenController,
                      decoration: InputDecoration(
                        labelText: 'Access Token / Bearer Token',
                        hintText: l.pasteToken,
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ).copyWith(labelText: l.accessToken),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _manualUserController,
                      decoration: InputDecoration(
                        labelText: l.usernameOptional,
                        hintText: l.exampleUsername,
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _isLoading ? null : _submitManual,
                      child: Text(l.saveManualToken),
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
                                  l.loggedOutFromService(
                                    widget.service.displayName,
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            nav.pop();
                          }
                        },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    AppLocalizations.of(context).logoutService(
                      widget.service.displayName,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOAuthContent(ThemeData theme) {
    final l = AppLocalizations.of(context);
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
                ? l.reopenServiceInBrowser(widget.service.displayName)
                : l.openLoginPageInBrowser,
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
                  SnackBar(
                    content: Text(l.copiedAuthorizationLink),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: Text(
                l.copyAuthLink,
                style: const TextStyle(fontSize: 12),
              ),
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
                l.howToConnect,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              if (widget.service == ServiceType.shikimori) ...[
                _buildInstructionRow('1', l.clickToLoginOnShikimori),
                _buildInstructionRow('2', l.allowOnAuthorizationPage),
                _buildInstructionRow(
                  '3',
                  l.shikimoriDisplayCode,
                ),
              ] else ...[
                _buildInstructionRow(
                  '1',
                  l.clickLoginApproveBrowser,
                ),
                _buildInstructionRow('2', l.redirectLocalhostExpected),
                _buildInstructionRow('3', l.copyEntireUrlOrCode),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          l.pasteAuthorizationCodeOrRedirectUrl,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          decoration: InputDecoration(
            hintText: widget.service == ServiceType.shikimori
                ? l.exampleAuthorizationCode
                : l.localhostCodeExample,
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
                  tooltip: l.pasteFromClipboard,
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
          label: Text(
            l.completeConnection,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildKitsuContent(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.loginWithKitsuCredentials,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _kitsuUser,
          decoration: InputDecoration(
            labelText: l.emailOrUsername,
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _kitsuPass,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: l.password,
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
          label: Text(
            l.loginToKitsu,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildMangaUpdatesContent(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.loginWithMangaUpdatesCredentials,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _muUser,
          decoration: InputDecoration(
            labelText: l.username,
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _muPass,
          obscureText: _obscureMuPassword,
          decoration: InputDecoration(
            labelText: l.password,
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
          label: Text(
            l.loginToMangaUpdates,
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
