import { commands } from "@/shared/api";
import { Button } from "@/shared/ui";

const showIsland = () => commands.showIsland();
const hideIsland = () => commands.hideIsland();

export const HomePage = () => (
  <main className="flex h-screen flex-col items-center justify-center gap-6">
    <h1 className="font-semibold text-[22px]">Waft</h1>

    <div className="flex gap-2">
      <Button onClick={showIsland}>Show island</Button>

      <Button onClick={hideIsland} variant="secondary">
        Hide island
      </Button>
    </div>
  </main>
);
