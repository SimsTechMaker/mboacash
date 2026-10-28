/// OAuth client ID of type "Web application" from the Google Cloud project
/// that has the Drive API enabled (see docs/google-drive-setup.md).
///
/// On Android, Google Sign-In needs this web client ID as `serverClientId`,
/// plus an "Android" client ID registered with the app's package name
/// (com.ndi.carnet237) and the SHA-1 of the signing key. Leave it empty and
/// the backup screen explains that the feature is not configured yet.
const googleServerClientId = '1050417282744-oalrntq85d5q7p5ph0df6nl0dtk65kka.apps.googleusercontent.com';
