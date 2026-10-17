// Swap to a neutral page and drop SafeSignal from the back stack.
const NEUTRAL_URL = "https://www.google.com";

export function quickExit(): void {
  document.title = "Notes";
  window.location.replace(NEUTRAL_URL);
}
