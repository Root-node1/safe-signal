import Shell from './components/Shell'

// Placeholder: confirms Tailwind + Shell work. Screens get wired in next commits.
function App() {
  return (
    <Shell>
      <h1 className="text-[28px] font-bold leading-[34px]">
        Feeling unsafe on your ride?
      </h1>
      <p className="mt-3 text-[18px] leading-[26px] text-[#4A5259]">
        Get discreet support. You decide what happens next.
      </p>
      <button
        type="button"
        className="mt-10 min-h-[72px] w-full rounded-2xl bg-[#0F5C5C] px-6 text-[22px] font-semibold leading-7 text-white"
      >
        I feel unsafe now
      </button>
    </Shell>
  )
}

export default App
