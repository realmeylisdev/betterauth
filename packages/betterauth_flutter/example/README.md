# betterauth_flutter example

A small app demonstrating `betterauth_flutter`:

- `BetterAuth.initialize` at startup with secure-storage persistence
- an `AuthCubit` driving the UI via `BlocBuilder`
- email/password sign-in and sign-up
- a two-factor (TOTP) challenge screen
- native Google / Apple sign-in
- passkey sign-in + registration
- anonymous ("continue as guest") sign-in
- sign-out

The organization API is also available via
`BetterAuth.instance.client.organization`.

## Running

1. Set `kBaseUrl` in `lib/main.dart` to your better-auth server's auth base URL
   (for example `https://api.example.com/api/auth`). The server must have the
   `bearer` plugin enabled, plus whichever plugins you exercise.
2. `flutter run`

The iOS/Android runners are generated; the auth plugins need a little native
configuration (placeholders are already wired with the `betterauthexample`
callback scheme):

| Plugin | iOS | Android |
|---|---|---|
| Social redirect (`flutter_web_auth_2`) | callback scheme in `Info.plist` (done) | `CallbackActivity` in `AndroidManifest.xml` (done) |
| Google (`google_sign_in`) | replace `GIDClientID` + reversed-client-ID `CFBundleURLSchemes` placeholders in `Info.plist` | register your signing SHA-1 + OAuth client in Google Cloud |
| Apple (`sign_in_with_apple`) | add the "Sign in with Apple" capability in Xcode (wires `Runner.entitlements`) | uses the web flow + `SignInWithAppleCallback` (done) |
| Passkey (`passkeys`) | Associated Domains (`webcredentials:yourdomain`) + host `apple-app-site-association` | host `assetlinks.json` with your signing SHA-256 |

Replace every `PLACEHOLDER_…` value with your own credentials before using the
corresponding provider.
