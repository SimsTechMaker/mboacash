/// OAuth client ID of type "Web application" from the Google Cloud project
/// that has the Drive API enabled (see docs/google-drive-setup.md).
///
/// On Android, Google Sign-In needs this web client ID as `serverClientId`,
/// plus an "Android" client ID registered with the app's package name
/// (com.ndi.carnet237) and the SHA-1 of the signing key. Leave it empty and
/// the backup screen explains that the feature is not configured yet.
// Web client. The Android client (1050417282744-oalrntq85d5…) must not be
// used here: Google then answers "[28444] Developer console is not set up
// correctly".
const googleServerClientId = '1050417282744-rqkglih3psumsu73lgtimqq8cg3o3i26.apps.googleusercontent.com';
