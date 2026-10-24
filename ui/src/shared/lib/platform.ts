export type Platform = "macos" | "windows";

export const currentPlatform = (): Platform => {
  if (navigator.userAgent.includes("Windows")) {
    return "windows";
  }

  return "macos";
};
