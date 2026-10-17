import { useEffect } from "react";
import { quickExit } from "../lib/quickExit";
import { PROTOTYPE } from "../lib/prototype";

export default function SafeHeader() {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") quickExit();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  return (
    <header className="sticky top-0 z-10 bg-[#F7F5F2]">
      <div className="mx-auto flex w-full max-w-[390px] items-center justify-between px-5 py-3 md:max-w-[560px] lg:max-w-[640px]">
        <span className="text-[15px] font-semibold leading-5">
          SafeSignal
          {PROTOTYPE && (
            <span className="ml-2 rounded-full border border-[#4A5259] px-2 py-0.5 text-[12px] font-medium text-[#4A5259]">
              Prototype
            </span>
          )}
        </span>
        <button
          type="button"
          onClick={quickExit}
          aria-label="Quick exit to a neutral page"
          className="min-h-[44px] min-w-[44px] rounded-full bg-[#1B1F23] px-5 text-[15px] font-semibold leading-5 text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#1B1F23] focus-visible:ring-offset-2"
        >
          Exit
        </button>
      </div>
    </header>
  );
}
