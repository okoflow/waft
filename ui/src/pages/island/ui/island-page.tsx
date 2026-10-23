import { Mic } from "lucide-react";

import { useIslandPlacement } from "../model/use-island-placement";

const wingWidth = 62;
const menuBarGap = 8;

const capsuleStyle = (notch: { width: number; height: number } | null | undefined, topInset: number) => {
  if (!notch) {
    return { marginTop: topInset + menuBarGap };
  }

  return { minHeight: notch.height, minWidth: notch.width + 2 * wingWidth };
};

export const IslandPage = () => {
  const { notch, topInset } = useIslandPlacement();

  return (
    <main className="flex h-screen items-start justify-center">
      <div
        className="flex min-h-12 items-center justify-between gap-3 rounded-full bg-[#1c1b20] px-5 font-semibold text-[15px] text-white ring-1 ring-white/12 data-[notch=true]:rounded-t-none data-[notch=true]:rounded-b-3xl data-[notch=true]:bg-black data-[notch=true]:ring-0"
        data-notch={Boolean(notch)}
        style={capsuleStyle(notch, topInset)}
      >
        <Mic className="size-5 text-[#f4646b]" />

        <span className="text-[12px] text-white/55">Clean</span>
      </div>
    </main>
  );
};
