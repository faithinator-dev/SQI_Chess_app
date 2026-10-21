# Google Sign-In with Supabase

This guide explains how to add Google sign-up/sign-in to SQI Checkmate Arena.
Supabase uses one OAuth flow for both actions:

- A new Google account creates a Supabase user.
- An existing Google account signs the user in.

The login screen now starts the Google OAuth flow. Complete the provider and
mobile redirect configuration below before testing the button.

## 1. Create Google OAuth credentials

1. Open the [Google Cloud Console](https://console.cloud.google.com/).
2. Select the Google Cloud project used by this app, or create one.
3. Open **APIs & Services > OAuth consent screen**.
4. Configure the consent screen:
   - Choose **External** unless the app is restricted to a Google Workspace
     organization.
   - Add the app name, support email, and developer contact email.
   - Add the scopes `openid`, `email`, and `profile`.
   - Add test users while the consent screen is in testing mode.
5. Open **APIs & Services > Credentials** and create an **OAuth client ID**.
6. Choose **Web application** as the application type.
7. Keep the generated client ID and client secret available for the Supabase
   provider configuration. Never put the client secret in Flutter code or in
   `assets/.env`.

The web client is used by Supabase as the OAuth client. A separate Android
client ID is not required for the Supabase browser OAuth flow described here.

## 2. Configure Google in Supabase

1. Open the Supabase project dashboard.
2. Go to **Authentication > Providers > Google**.
3. Enable Google.
4. Paste the Google **Web client ID** and **Web client secret**.
5. Save the provider.

In the Google OAuth client's **Authorized redirect URIs**, add the callback
URL shown by Supabase in the Google provider panel. It normally has this form:

```text
https://<project-ref>.supabase.co/auth/v1/callback
```

Use the exact URL displayed by Supabase rather than manually changing it.

## 3. Add the mobile redirect URL in Supabase

Choose one redirect URI for this app. This guide uses:

```text
sqi-chess-club://login-callback
```

In Supabase, open **Authentication > URL Configuration** and add the URI to
**Redirect URLs**:

```text
sqi-chess-club://login-callback
```

The redirect URI passed in Flutter must exactly match a URI in this allowlist.
The Supabase callback URL from the previous section is different: it is for
Google to return to Supabase, while `sqi-chess-club://login-callback` is for
Supabase to return to the installed app.

For local web testing, add the web URL separately, for example:

```text
http://localhost:3000/
```

Only add URLs that are controlled by the project. Do not use a broad wildcard
in production.

## 4. Register the Android deep link

Edit
[`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml)
and add this intent filter inside the existing `MainActivity` element:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="sqi-chess-club"
        android:host="login-callback" />
</intent-filter>
```

The scheme and host must match the redirect URI:

```text
sqi-chess-club://login-callback
```

If a different scheme is selected, update all three locations:

1. Supabase **Redirect URLs**.
2. The Flutter `redirectTo` value.
3. The Android manifest intent filter.

## 5. Add a deep-link package

The app must receive the callback URI when Android returns from the browser.
Add `app_links` to `pubspec.yaml`:

```yaml
dependencies:
  app_links: ^6.4.1
```

Then run:

```bash
flutter pub get
```

Use the current compatible version if Pub recommends a newer release.

## 6. Start Google OAuth from the login screen

Add these imports to
[`lib/features/auth/login_screen.dart`](../lib/features/auth/login_screen.dart):

```dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
```

Add a method to `_LoginScreenState`:

```dart
Future<void> _signInWithGoogle() async {
  FocusScope.of(context).unfocus();

  setState(() {
    _errorMessage = null;
    _isLoading = true;
  });

  try {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'sqi-chess-club://login-callback',
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  } on AuthException catch (error) {
    if (!mounted) return;
    setState(() {
      _errorMessage = _friendlyAuthError(error);
      _isLoading = false;
    });
  } catch (_) {
    if (!mounted) return;
    setState(() {
      _errorMessage = 'Unable to start Google sign-in. Please try again.';
      _isLoading = false;
    });
  }
}
```

The exact `authScreenLaunchMode` API can vary by the installed
`supabase_flutter` version. If the analyzer reports that parameter as
unsupported, remove that parameter and keep `redirectTo`.

Connect the existing button to the method:

```dart
onPressed: _isLoading ? null : _signInWithGoogle,
```

Do not manually navigate to the dashboard after starting OAuth. The
`AuthGate` already listens for Supabase auth state changes and should perform
the authenticated transition.

## 7. Handle the callback in Flutter

Initialize a deep-link subscription near the app root, after Supabase has been
initialized. A small service or the root app state can own this subscription:

```dart
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthDeepLinkHandler {
  AuthDeepLinkHandler(this._supabase);

  final SupabaseClient _supabase;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  Future<void> start() async {
    final initialUri = await _appLinks.getInitialLink();
    await _handle(initialUri);

    _subscription = _appLinks.uriLinkStream.listen(_handle);
  }

  Future<void> _handle(Uri? uri) async {
    if (uri == null || uri.scheme != 'sqi-chess-club') return;
    await _supabase.auth.getSessionFromUrl(uri);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
```

Create one handler for the application lifetime. Do not create a new
subscription every time the login screen is rebuilt. Dispose the subscription
when the app root is disposed.

If the installed `supabase_flutter` version automatically consumes the
callback, calling `getSessionFromUrl` a second time can produce an
already-consumed or invalid-token error. In that case, keep the deep-link
listener only if it is required by the package version, and rely on the
Supabase auth state listener for navigation.

## 8. Store a profile for Google users

Google supplies profile claims such as `name`, `full_name`, `email`, and
`avatar_url` in the Supabase user metadata. The app should create or update
its application profile from the authenticated user rather than trusting
client-provided profile rows.

Example metadata lookup:

```dart
final user = Supabase.instance.client.auth.currentUser;
final metadata = user?.userMetadata ?? <String, dynamic>{};
final displayName =
    (metadata['full_name'] ?? metadata['name'] ?? '').toString().trim();
final avatarUrl = (metadata['avatar_url'] ?? '').toString().trim();
```

Use the existing profile repository and database policies when persisting the
profile. Do not store the Google client secret or service-role key in the
Flutter application.

## 9. Test the complete flow

Test on a physical Android device or emulator:

1. Uninstall the previous app build if an old redirect configuration is
   cached.
2. Start the app with the normal Supabase URL and publishable key.
3. Tap **Continue with Google**.
4. Select a Google account.
5. Confirm the browser returns to the app.
6. Confirm the app reaches the authenticated dashboard.
7. Sign out and repeat with the same account.
8. Confirm the same Supabase user is reused rather than creating duplicates.
9. Test cancellation and a failed login to confirm the loading state resets.

Run the project checks:

```bash
flutter analyze
flutter test
```

## Troubleshooting

### `Unsupported provider: google`

Google is not enabled under **Authentication > Providers** in Supabase, or
the provider credentials were not saved.

### `redirect_uri_mismatch`

The Google client does not contain the exact Supabase callback URL. Copy the
callback URL from the Supabase Google provider panel into **Authorized
redirect URIs** in Google Cloud.

### The browser signs in but does not return to the app

Check all of the following:

- `sqi-chess-club://login-callback` is in Supabase **Redirect URLs**.
- The Android intent filter is inside `MainActivity`.
- The scheme, host, and path match exactly.
- The Flutter `redirectTo` value matches the allowlisted URL.
- The `app_links` listener is started once after Supabase initialization.

### The app opens but the user is still logged out

Check that the callback URI is passed to `getSessionFromUrl` when required by
the installed `supabase_flutter` version, and that `AuthGate` remains mounted
while the auth state event is delivered.

### Google says the app is unverified

The OAuth consent screen is still in testing or requests sensitive scopes.
Keep the scopes limited to `openid`, `email`, and `profile`, add test users,
and submit the consent screen for verification before production release.

## Official references

- [Supabase Flutter `signInWithOAuth`](https://supabase.com/docs/reference/dart/auth-signinwithoauth)
- [Supabase mobile deep linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)
- [Supabase redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls)
- [Google OAuth client documentation](https://support.google.com/cloud/answer/15549257)
