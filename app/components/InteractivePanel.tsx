"use client";

import { useState } from "react";

export default function InteractivePanel() {
  const [activeTab, setActiveTab] = useState("home"); // home, gear, wrench, db, cog
  
  // Interactive Toggles states
  const [autoSell, setAutoSell] = useState(true);
  const [gateEsp, setGateEsp] = useState(false);
  const [aimbot, setAimbot] = useState(true);
  const [laserCape, setLaserCape] = useState(false);
  const [webSlinger, setWebSlinger] = useState(true);
  const [destroyTurrets, setDestroyTurrets] = useState(false);
  const [stealBest, setStealBest] = useState(true);
  const [stealNearest, setStealNearest] = useState(false);

  // Custom Dropdowns states
  const [brainrotSell, setBrainrotSell] = useState("Standard Brainrot");
  const [mariticoSell, setMariticoSell] = useState("Level 1 Maritico");
  const [brainrotBuy, setBrainrotBuy] = useState("Elite Pack");
  const [excludePlayers, setExcludePlayers] = useState("None");

  // Dropdown open states
  const [openDropdown, setOpenDropdown] = useState<string | null>(null);

  // Sliders states
  const [generationRange, setGenerationRange] = useState(6);
  const [flingDistance, setFlingDistance] = useState(25);

  const toggleDropdown = (name: string) => {
    setOpenDropdown(openDropdown === name ? null : name);
  };

  const selectOption = (dropdown: string, value: string) => {
    if (dropdown === "brainrotSell") setBrainrotSell(value);
    if (dropdown === "mariticoSell") setMariticoSell(value);
    if (dropdown === "brainrotBuy") setBrainrotBuy(value);
    if (dropdown === "excludePlayers") setExcludePlayers(value);
    setOpenDropdown(null);
  };

  return (
    <div className="w-full max-w-[620px] rounded-lg border border-[#2a2a35]/60 bg-[#0c0c12]/95 shadow-[0_15px_50px_rgba(0,0,0,0.8),0_0_20px_rgba(157,78,237,0.1)] text-zinc-300 font-sans text-xs select-none overflow-hidden backdrop-blur-md relative">
      
      {/* Top Title Bar */}
      <div className="flex items-center justify-between px-4 py-3 bg-[#0a0a0f] border-b border-[#1f1f2a]/60">
        <div className="flex items-center gap-2.5">
          {/* Logo Icon */}
          <div className="w-5 h-5 flex items-center justify-center rounded bg-gradient-to-br from-[#c084fc] to-[#9333ea] shadow-[0_0_8px_rgba(147,51,234,0.4)]">
            <svg className="w-3.5 h-3.5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          </div>
          <div className="flex flex-col">
            <span className="font-extrabold text-white text-[11px] tracking-wide uppercase">HipHub Automation</span>
            <span className="text-[9px] text-[#8a8f98] font-medium leading-none">Features That Makes Your Day Better :)</span>
          </div>
        </div>

        {/* Search & Drag Bar */}
        <div className="flex items-center gap-3">
          <div className="relative flex items-center bg-[#13131c] border border-[#1f1f2a]/80 rounded px-2 py-1 w-32">
            <svg className="w-3 h-3 text-[#5e5e6e] mr-1.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input
              type="text"
              placeholder="Search"
              className="bg-transparent border-none outline-none text-[10px] text-white w-full placeholder-[#5e5e6e]"
              disabled
            />
          </div>
          {/* Resize cross icon */}
          <div className="text-[#5e5e6e] hover:text-[#9333ea] transition-colors cursor-pointer">
            <svg className="w-4.5 h-4.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </div>
        </div>
      </div>

      {/* Main Body */}
      <div className="flex min-h-[420px]">
        
        {/* Left Vertical Navigation Menu */}
        <div className="w-[50px] bg-[#08080c] border-r border-[#1f1f2a]/60 flex flex-col items-center py-4 gap-4">
          <button
            onClick={() => setActiveTab("home")}
            className={`w-8 h-8 rounded-lg flex items-center justify-center transition-all ${
              activeTab === "home"
                ? "bg-[#9333ea]/15 text-[#c084fc] border border-[#9333ea]/45 shadow-[0_0_10px_rgba(147,51,234,0.25)]"
                : "text-[#5e5e6e] hover:text-zinc-400"
            }`}
          >
            <svg className="w-4.5 h-4.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
            </svg>
          </button>

          <button
            onClick={() => setActiveTab("gear")}
            className={`w-8 h-8 rounded-lg flex items-center justify-center transition-all ${
              activeTab === "gear"
                ? "bg-[#9333ea]/15 text-[#c084fc] border border-[#9333ea]/45 shadow-[0_0_10px_rgba(147,51,234,0.25)]"
                : "text-[#5e5e6e] hover:text-zinc-400"
            }`}
          >
            <svg className="w-4.5 h-4.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </button>

          <button
            onClick={() => setActiveTab("wrench")}
            className={`w-8 h-8 rounded-lg flex items-center justify-center transition-all ${
              activeTab === "wrench"
                ? "bg-[#9333ea]/15 text-[#c084fc] border border-[#9333ea]/45 shadow-[0_0_10px_rgba(147,51,234,0.25)]"
                : "text-[#5e5e6e] hover:text-zinc-400"
            }`}
          >
            <svg className="w-4.5 h-4.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.907c.961 0 1.36 1.24.588 1.81l-3.97 2.883a1 1 0 00-.364 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.971-2.883a1 1 0 00-1.175 0l-3.97 2.883c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h4.907a1 1 0 00.95-.69l1.519-4.674z" />
            </svg>
          </button>

          <button
            onClick={() => setActiveTab("db")}
            className={`w-8 h-8 rounded-lg flex items-center justify-center transition-all ${
              activeTab === "db"
                ? "bg-[#9333ea]/15 text-[#c084fc] border border-[#9333ea]/45 shadow-[0_0_10px_rgba(147,51,234,0.25)]"
                : "text-[#5e5e6e] hover:text-zinc-400"
            }`}
          >
            <svg className="w-4.5 h-4.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
          </button>
        </div>

        {/* Dashboard Panels Container */}
        <div className="flex-1 p-5 bg-[#0b0b0f] overflow-y-auto">
          
          {activeTab === "home" && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-5 items-start">
              
              {/* Left Column Controls */}
              <div className="space-y-5">
                
                {/* Base Card */}
                <div className="bg-[#101018]/90 border border-[#1f1f2a]/85 rounded-lg p-4 space-y-4">
                  <div className="flex items-center justify-between border-b border-[#1f1f2a]/60 pb-2 mb-1">
                    <span className="font-extrabold text-white uppercase tracking-wider text-[10px] flex items-center gap-1.5">
                      <span className="w-1.5 h-1.5 rounded-full bg-[#c084fc] shadow-[0_0_6px_rgba(192,132,252,0.6)]" />
                      Base
                    </span>
                    <span className="text-[8px] text-[#5e5e6e] font-mono">STATUS: ACTIVE</span>
                  </div>

                  {/* Dropdown 1: Brainrot Sell */}
                  <div className="space-y-1 relative">
                    <label className="text-[9px] font-bold text-[#8a8f98] tracking-wide uppercase block">Select Brainrot to Sell</label>
                    <button
                      onClick={() => toggleDropdown("brainrotSell")}
                      className="w-full bg-[#161622] border border-[#232332] rounded px-3 py-2 flex items-center justify-between text-left text-zinc-300 hover:border-[#9333ea]/50 transition-colors"
                    >
                      <span className="text-[10px] font-medium">{brainrotSell}</span>
                      <svg className="w-3 h-3 text-[#8a8f98]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M19 9l-7 7-7-7" />
                      </svg>
                    </button>
                    {openDropdown === "brainrotSell" && (
                      <div className="absolute top-full left-0 right-0 z-20 mt-1 bg-[#161622] border border-[#232332] rounded-md shadow-xl overflow-hidden">
                        {["Standard Brainrot", "Rare Brainrot", "Legendary Brainrot", "Mythical Brainrot"].map((opt) => (
                          <div
                            key={opt}
                            onClick={() => selectOption("brainrotSell", opt)}
                            className="px-3 py-2 text-[10px] hover:bg-[#9333ea]/20 hover:text-white cursor-pointer transition-colors"
                          >
                            {opt}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Dropdown 2: Maritico Sell */}
                  <div className="space-y-1 relative">
                    <label className="text-[9px] font-bold text-[#8a8f98] tracking-wide uppercase block">Select Maritico to Sell</label>
                    <button
                      onClick={() => toggleDropdown("mariticoSell")}
                      className="w-full bg-[#161622] border border-[#232332] rounded px-3 py-2 flex items-center justify-between text-left text-zinc-300 hover:border-[#9333ea]/50 transition-colors"
                    >
                      <span className="text-[10px] font-medium">{mariticoSell}</span>
                      <svg className="w-3 h-3 text-[#8a8f98]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M19 9l-7 7-7-7" />
                      </svg>
                    </button>
                    {openDropdown === "mariticoSell" && (
                      <div className="absolute top-full left-0 right-0 z-20 mt-1 bg-[#161622] border border-[#232332] rounded-md shadow-xl overflow-hidden">
                        {["Level 1 Maritico", "Level 2 Maritico", "Level 3 Maritico", "Boss Maritico"].map((opt) => (
                          <div
                            key={opt}
                            onClick={() => selectOption("mariticoSell", opt)}
                            className="px-3 py-2 text-[10px] hover:bg-[#9333ea]/20 hover:text-white cursor-pointer transition-colors"
                          >
                            {opt}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Slider 1: Generation Range */}
                  <div className="space-y-1.5">
                    <div className="flex items-center justify-between text-[9px] font-bold text-[#8a8f98] tracking-wide uppercase">
                      <span>Generation To Sell (Min - Max)</span>
                      <span className="font-mono text-[#c084fc]">{generationRange} / 10</span>
                    </div>
                    <input
                      type="range"
                      min="0"
                      max="10"
                      value={generationRange}
                      onChange={(e) => setGenerationRange(parseInt(e.target.value))}
                      className="w-full accent-[#9333ea] bg-[#161622] rounded h-1 cursor-pointer"
                    />
                  </div>

                  {/* Toggle 1: Auto Sell */}
                  <div className="flex items-center justify-between pt-1">
                    <div className="flex flex-col">
                      <span className="font-semibold text-white text-[10px]">Auto Sell Brainrot</span>
                      <span className="text-[8px] text-[#5e5e6e]">Automates marketplace dispatching</span>
                    </div>
                    <button
                      onClick={() => setAutoSell(!autoSell)}
                      className={`relative w-8 h-4.5 rounded-full transition-all duration-300 ${
                        autoSell ? "bg-[#9333ea]/35 border border-[#9333ea]" : "bg-[#161622] border border-[#232332]"
                      }`}
                    >
                      <div
                        className={`absolute top-[2px] w-2.5 h-2.5 rounded-full transition-all duration-300 ${
                          autoSell ? "right-[2px] bg-[#c084fc] shadow-[0_0_6px_#c084fc]" : "left-[2px] bg-[#5e5e6e]"
                        }`}
                      />
                    </button>
                  </div>

                  {/* Toggle 2: Gate ESP */}
                  <div className="flex items-center justify-between pt-1">
                    <div className="flex flex-col">
                      <span className="font-semibold text-white text-[10px]">Gate ESP</span>
                      <span className="text-[8px] text-[#5e5e6e]">Highlights extraction thresholds</span>
                    </div>
                    <button
                      onClick={() => setGateEsp(!gateEsp)}
                      className={`relative w-8 h-4.5 rounded-full transition-all duration-300 ${
                        gateEsp ? "bg-[#9333ea]/35 border border-[#9333ea]" : "bg-[#161622] border border-[#232332]"
                      }`}
                    >
                      <div
                        className={`absolute top-[2px] w-2.5 h-2.5 rounded-full transition-all duration-300 ${
                          gateEsp ? "right-[2px] bg-[#c084fc] shadow-[0_0_6px_#c084fc]" : "left-[2px] bg-[#5e5e6e]"
                        }`}
                      />
                    </button>
                  </div>
                </div>

                {/* Brainrot Buy Card */}
                <div className="bg-[#101018]/90 border border-[#1f1f2a]/85 rounded-lg p-4 space-y-4">
                  <div className="flex items-center justify-between border-b border-[#1f1f2a]/60 pb-2 mb-1">
                    <span className="font-extrabold text-white uppercase tracking-wider text-[10px] flex items-center gap-1.5">
                      <svg className="w-3.5 h-3.5 text-[#c084fc]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                      </svg>
                      Brainrot Store
                    </span>
                  </div>

                  {/* Dropdown 3: Select Brainrot to Buy */}
                  <div className="space-y-1 relative">
                    <label className="text-[9px] font-bold text-[#8a8f98] tracking-wide uppercase block">Select Brainrot to Buy</label>
                    <button
                      onClick={() => toggleDropdown("brainrotBuy")}
                      className="w-full bg-[#161622] border border-[#232332] rounded px-3 py-2 flex items-center justify-between text-left text-zinc-300 hover:border-[#9333ea]/50 transition-colors"
                    >
                      <span className="text-[10px] font-medium">{brainrotBuy}</span>
                      <svg className="w-3 h-3 text-[#8a8f98]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M19 9l-7 7-7-7" />
                      </svg>
                    </button>
                    {openDropdown === "brainrotBuy" && (
                      <div className="absolute top-full left-0 right-0 z-20 mt-1 bg-[#161622] border border-[#232332] rounded-md shadow-xl overflow-hidden">
                        {["Basic Pack", "Elite Pack", "HipHub Supreme", "Omega Infinite"].map((opt) => (
                          <div
                            key={opt}
                            onClick={() => selectOption("brainrotBuy", opt)}
                            className="px-3 py-2 text-[10px] hover:bg-[#9333ea]/20 hover:text-white cursor-pointer transition-colors"
                          >
                            {opt}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </div>

              </div>

              {/* Right Column Controls */}
              <div className="space-y-5">
                
                {/* Gear Card */}
                <div className="bg-[#101018]/90 border border-[#1f1f2a]/85 rounded-lg p-4 space-y-4">
                  <div className="flex items-center justify-between border-b border-[#1f1f2a]/60 pb-2 mb-1">
                    <span className="font-extrabold text-white uppercase tracking-wider text-[10px] flex items-center gap-1.5">
                      <span className="w-1.5 h-1.5 rounded-full bg-[#c084fc] shadow-[0_0_6px_rgba(192,132,252,0.6)]" />
                      Gear
                    </span>
                    <span className="text-[8px] text-[#5e5e6e] font-mono">BINDINGS AVAILABLE</span>
                  </div>

                  {/* Toggle 3: Aimbot */}
                  <div className="flex items-center justify-between">
                    <div className="flex flex-col">
                      <div className="flex items-center gap-1.5">
                        <span className="font-semibold text-white text-[10px]">Aimbot (Laser/Web)</span>
                        <span className="text-[8px] font-mono px-1 py-0.2 rounded bg-[#1f1f2a] text-[#c084fc] border border-[#2d2d3d]">F7</span>
                      </div>
                      <span className="text-[8px] text-[#5e5e6e]">Automates lock on targeting</span>
                    </div>
                    <button
                      onClick={() => setAimbot(!aimbot)}
                      className={`relative w-8 h-4.5 rounded-full transition-all duration-300 ${
                        aimbot ? "bg-[#9333ea]/35 border border-[#9333ea]" : "bg-[#161622] border border-[#232332]"
                      }`}
                    >
                      <div
                        className={`absolute top-[2px] w-2.5 h-2.5 rounded-full transition-all duration-300 ${
                          aimbot ? "right-[2px] bg-[#c084fc] shadow-[0_0_6px_#c084fc]" : "left-[2px] bg-[#5e5e6e]"
                        }`}
                      />
                    </button>
                  </div>

                  {/* Dropdown 4: Exclude Players */}
                  <div className="space-y-1 relative">
                    <label className="text-[9px] font-bold text-[#8a8f98] tracking-wide uppercase block">Exclude Players (Laser)</label>
                    <button
                      onClick={() => toggleDropdown("excludePlayers")}
                      className="w-full bg-[#161622] border border-[#232332] rounded px-3 py-2 flex items-center justify-between text-left text-zinc-300 hover:border-[#9333ea]/50 transition-colors"
                    >
                      <span className="text-[10px] font-medium">{excludePlayers}</span>
                      <svg className="w-3 h-3 text-[#8a8f98]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M19 9l-7 7-7-7" />
                      </svg>
                    </button>
                    {openDropdown === "excludePlayers" && (
                      <div className="absolute top-full left-0 right-0 z-20 mt-1 bg-[#161622] border border-[#232332] rounded-md shadow-xl overflow-hidden">
                        {["None", "Friends Only", "Guild Members", "All Ranged Players"].map((opt) => (
                          <div
                            key={opt}
                            onClick={() => selectOption("excludePlayers", opt)}
                            className="px-3 py-2 text-[10px] hover:bg-[#9333ea]/20 hover:text-white cursor-pointer transition-colors"
                          >
                            {opt}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Toggle 4: Auto Use Laser Cape */}
                  <div className="flex items-center justify-between pt-1">
                    <div className="flex flex-col">
                      <span className="font-semibold text-white text-[10px]">Auto Use Laser Cape</span>
                      <span className="text-[8px] text-[#5e5e6e]">Deploys defensive shielding</span>
                    </div>
                    <button
                      onClick={() => setLaserCape(!laserCape)}
                      className={`relative w-8 h-4.5 rounded-full transition-all duration-300 ${
                        laserCape ? "bg-[#9333ea]/35 border border-[#9333ea]" : "bg-[#161622] border border-[#232332]"
                      }`}
                    >
                      <div
                        className={`absolute top-[2px] w-2.5 h-2.5 rounded-full transition-all duration-300 ${
                          laserCape ? "right-[2px] bg-[#c084fc] shadow-[0_0_6px_#c084fc]" : "left-[2px] bg-[#5e5e6e]"
                        }`}
                      />
                    </button>
                  </div>

                  {/* Toggle 5: Auto Use Web Slinger */}
                  <div className="flex items-center justify-between pt-1">
                    <div className="flex flex-col">
                      <span className="font-semibold text-white text-[10px]">Auto Use Web Slinger</span>
                      <span className="text-[8px] text-[#5e5e6e]">Automates mobility grapples</span>
                    </div>
                    <button
                      onClick={() => setWebSlinger(!webSlinger)}
                      className={`relative w-8 h-4.5 rounded-full transition-all duration-300 ${
                        webSlinger ? "bg-[#9333ea]/35 border border-[#9333ea]" : "bg-[#161622] border border-[#232332]"
                      }`}
                    >
                      <div
                        className={`absolute top-[2px] w-2.5 h-2.5 rounded-full transition-all duration-300 ${
                          webSlinger ? "right-[2px] bg-[#c084fc] shadow-[0_0_6px_#c084fc]" : "left-[2px] bg-[#5e5e6e]"
                        }`}
                      />
                    </button>
                  </div>

                  {/* Toggle 6: Auto Destroy Turrets */}
                  <div className="flex items-center justify-between pt-1">
                    <div className="flex flex-col">
                      <span className="font-semibold text-white text-[10px]">Auto Destroy Turrets</span>
                      <span className="text-[8px] text-[#5e5e6e]">Fires on hostile fortifications</span>
                    </div>
                    <button
                      onClick={() => setDestroyTurrets(!destroyTurrets)}
                      className={`relative w-8 h-4.5 rounded-full transition-all duration-300 ${
                        destroyTurrets ? "bg-[#9333ea]/35 border border-[#9333ea]" : "bg-[#161622] border border-[#232332]"
                      }`}
                    >
                      <div
                        className={`absolute top-[2px] w-2.5 h-2.5 rounded-full transition-all duration-300 ${
                          destroyTurrets ? "right-[2px] bg-[#c084fc] shadow-[0_0_6px_#c084fc]" : "left-[2px] bg-[#5e5e6e]"
                        }`}
                      />
                    </button>
                  </div>
                </div>

                {/* Steal Utilities Card */}
                <div className="bg-[#101018]/90 border border-[#1f1f2a]/85 rounded-lg p-4 space-y-4">
                  <div className="flex items-center justify-between border-b border-[#1f1f2a]/60 pb-2 mb-1">
                    <span className="font-extrabold text-white uppercase tracking-wider text-[10px] flex items-center gap-1.5">
                      <span className="w-1.5 h-1.5 rounded-full bg-[#c084fc] shadow-[0_0_6px_rgba(192,132,252,0.6)]" />
                      Steal Utilities / Anti Hit
                    </span>
                  </div>

                  {/* Toggle 7: Auto-Steal Best */}
                  <div className="flex items-center justify-between">
                    <div className="flex flex-col">
                      <span className="font-semibold text-white text-[10px]">Auto-Steal Best</span>
                      <span className="text-[8px] text-[#5e5e6e]">Secures high-value relics</span>
                    </div>
                    <button
                      onClick={() => setStealBest(!stealBest)}
                      className={`relative w-8 h-4.5 rounded-full transition-all duration-300 ${
                        stealBest ? "bg-[#9333ea]/35 border border-[#9333ea]" : "bg-[#161622] border border-[#232332]"
                      }`}
                    >
                      <div
                        className={`absolute top-[2px] w-2.5 h-2.5 rounded-full transition-all duration-300 ${
                          stealBest ? "right-[2px] bg-[#c084fc] shadow-[0_0_6px_#c084fc]" : "left-[2px] bg-[#5e5e6e]"
                        }`}
                      />
                    </button>
                  </div>

                  {/* Toggle 8: Auto-Steal Nearest */}
                  <div className="flex items-center justify-between">
                    <div className="flex flex-col">
                      <span className="font-semibold text-white text-[10px]">Auto-Steal Nearest</span>
                      <span className="text-[8px] text-[#5e5e6e]">Secures proximal items</span>
                    </div>
                    <button
                      onClick={() => setStealNearest(!stealNearest)}
                      className={`relative w-8 h-4.5 rounded-full transition-all duration-300 ${
                        stealNearest ? "bg-[#9333ea]/35 border border-[#9333ea]" : "bg-[#161622] border border-[#232332]"
                      }`}
                    >
                      <div
                        className={`absolute top-[2px] w-2.5 h-2.5 rounded-full transition-all duration-300 ${
                          stealNearest ? "right-[2px] bg-[#c084fc] shadow-[0_0_6px_#c084fc]" : "left-[2px] bg-[#5e5e6e]"
                        }`}
                      />
                    </button>
                  </div>

                  {/* Slider 2: Fling Distance */}
                  <div className="space-y-1.5">
                    <div className="flex items-center justify-between text-[9px] font-bold text-[#8a8f98] tracking-wide uppercase">
                      <span>Auto Fling Distance</span>
                      <span className="font-mono text-[#c084fc]">{flingDistance} / 50</span>
                    </div>
                    <input
                      type="range"
                      min="0"
                      max="50"
                      value={flingDistance}
                      onChange={(e) => setFlingDistance(parseInt(e.target.value))}
                      className="w-full accent-[#9333ea] bg-[#161622] rounded h-1 cursor-pointer"
                    />
                  </div>
                </div>

              </div>

            </div>
          )}

          {activeTab !== "home" && (
            <div className="h-[340px] flex flex-col items-center justify-center text-center text-[#5e5e6e] font-mono border border-dashed border-[#1f1f2a] rounded-lg p-6 bg-[#09090d]/50">
              <svg className="w-8 h-8 text-[#9333ea]/40 mb-3 animate-pulse" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              </svg>
              <span className="text-[11px] font-bold text-[#8a8f98] uppercase tracking-wider">Sub-Interface Node Loaded</span>
              <span className="text-[9px] text-[#5e5e6e] mt-1 max-w-[280px]">Configuring secure pipeline bindings for external script injection. Fully operational.</span>
            </div>
          )}

        </div>

      </div>

      {/* Bottom status bar link */}
      <div className="flex items-center justify-center py-2.5 bg-[#07070a] border-t border-[#1f1f2a]/50">
        <a
          href="https://discord.gg/hiphub"
          target="_blank"
          rel="noopener noreferrer"
          className="text-[9px] font-bold tracking-widest text-[#8a8f98] hover:text-[#c084fc] transition-colors flex items-center gap-1.5 font-mono uppercase"
        >
          <span>discord.gg/hiphub</span>
          <svg className="w-2.5 h-2.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3" />
          </svg>
        </a>
      </div>

    </div>
  );
}
