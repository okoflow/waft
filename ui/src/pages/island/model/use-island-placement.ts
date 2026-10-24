import { useEffect, useState } from "react";

import { events, type IslandPlacement } from "@/shared/api";

export const useIslandPlacement = () => {
  const [placement, setPlacement] = useState<IslandPlacement>({ notch: null, topInset: 0 });

  useEffect(() => {
    const listening = events.islandPlacement.listen((event) => setPlacement(event.payload));

    return () => {
      listening.then((stopListening) => stopListening());
    };
  }, []);

  return placement;
};
