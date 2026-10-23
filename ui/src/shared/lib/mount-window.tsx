import { type ReactNode, StrictMode } from "react";
import { createRoot } from "react-dom/client";

import { currentPlatform } from "./platform";

export const mountWindow = (content: ReactNode) => {
  const root = document.getElementById("root");

  if (!root) {
    return;
  }

  document.documentElement.setAttribute("data-platform", currentPlatform());

  createRoot(root).render(<StrictMode>{content}</StrictMode>);
};
