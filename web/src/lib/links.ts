export const GITHUB_URL =
  "https://github.com/alirezamohammadpoor/deploymentbar";

/**
 * Stable download URL. GitHub redirects `releases/latest/download/<asset>` to
 * the newest (non-prerelease) release's asset of that EXACT name — so every
 * release must attach an asset named exactly `Deploymentbar.dmg`. No website
 * edits are ever needed per release.
 */
export const DOWNLOAD_URL = `${GITHUB_URL}/releases/latest/download/Deploymentbar.dmg`;
