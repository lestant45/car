"use client";

import { useState, useEffect } from "react";

export default function BentoGrid() {
  // States for live metrics
  const [ping, setPing] = useState(14);
  const [jitter, setJitter] = useState(1.1);
  const [stealthEnabled, setStealthEnabled] = useState(true);
  const [systemIntegrity, setSystemIntegrity] = useState(98.4);
  
  // Modules State
  const [modules, setModules] = useState([
    { id: "mod-1", name: "MEMORY_PROTECT.SYS", active: true, desc: "Prevents memory page scans" },
    { id: "mod-2", name: "D3D_INTEGRATION", active: true, desc: "Stealth overlay draw system" },
    { id: "mod-3", name: "INPUT_INJECTOR", active: false, desc: "Kernel-level input driver hook" },
    { id: "mod-4", name: "AUTO_KICK_BLOCK", active: false, desc: "Intercepts kicked/banned sockets" },
  ]);

  // Ping jitter simulator
  useEffect(() => {
    const interval = setInterval(() => {
      setPing((p) => {
        const delta = Math.random() > 0.5 ? 1 : -1;
        const next = p + delta;
        return next < 10 ? 10 : next > 25 ? 25 : next;
      });
      setJitter((j) => {
        const delta = (Math.random() - 0.5) * 0.4;
        const next = parseFloat((j + delta).toFixed(2));
        return next < 0.2 ? 0.2 : next > 2.5 ? 2.5 : next;
      });
      setSystemIntegrity((i) => {
        const delta = (Math.random() - 0.5) * 0.2;
        const next = parseFloat((i + delta).toFixed(2));
        return next < 95 ? 95 : next > 100 ? 100 : next;
      });
    }, 1500);

    return () => clearInterval(interval);
  }, []);

  const toggleModule = (id: string) => {
    setModules((prev) =>
      prev.map((mod) =>
        mod.id === id ? { ...mod, active: !mod.active } : mod
      )
    );
  };

  return (
    <section id="features" className="py-24 relative">
      {/* Visual neon light leak */}
      <div className="absolute top-1/4 right-1/4 w-[500px] h-[500px] rounded-full bg-neon-pink/5 blur-[150px] pointer-events-none" />

      <div className="max-w-7xl mx-auto px-6">
        {/* Section Header */}
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-neon-cyan/30 bg-neon-cyan/5 text-xs text-neon-cyan font-mono mb-4 shadow-[0_0_10px_rgba(0,242,254,0.1)]">
            <span className="w-1.5 h-1.5 rounded-full bg-neon-cyan animate-pulse" />
            TELEMETRY & CAPABILITIES
          </div>
          <h2 className="text-3xl md:text-5xl font-black text-white tracking-tight">
            THE BENTO <span className="text-neon-purple text-glow-purple">CONTROL DECK</span>
          </h2>
          <p className="text-zinc-400 mt-4 max-w-xl mx-auto text-sm md:text-base">
            Configure system processes, spoof anti-cheat registries, and monitor secure telemetry feeds in real-time.
          </p>
        </div>

        {/* Bento Box Layout Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 auto-rows-[240px]">
          {/* Card 1: Live Ping & Telemetry (Medium Card) */}
          <div className="md:col-span-2 row-span-1 rounded-xl border border-white/5 bg-zinc-950/40 backdrop-blur-md p-6 flex flex-col justify-between relative overflow-hidden group hover:border-neon-cyan/30 transition-all duration-300 shadow-inner">
            <div className="absolute inset-0 bg-gradient-to-br from-neon-cyan/5 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
            
            <div className="flex items-center justify-between relative z-10">
              <div>
                <span className="text-[11px] font-mono text-neon-cyan tracking-wider block font-bold">REAL-TIME TELEMETRY</span>
                <h3 className="text-lg font-bold text-white mt-1">Network Latency Jitter</h3>
              </div>
              <div className="text-right font-mono">
                <span className="text-2xl font-black text-white">{ping}ms</span>
                <span className="text-zinc-500 text-xs block">Jitter: {jitter}ms</span>
              </div>
            </div>

            {/* Dynamic Waveform Simulation */}
            <div className="h-20 w-full mt-4 flex items-end gap-1 relative z-10">
              {Array.from({ length: 24 }).map((_, idx) => {
                // Generate simulated heights
                const height = Math.floor(Math.sin((idx + ping) * 0.5) * 30 + 45) + (idx % 3) * 8;
                return (
                  <div
                    key={idx}
                    className="flex-1 rounded-sm bg-gradient-to-t from-neon-cyan/20 to-neon-cyan shadow-[0_0_8px_rgba(0,242,254,0.3)] transition-all duration-300"
                    style={{ height: `${Math.max(15, Math.min(100, height))}%` }}
                  />
                );
              })}
            </div>

            <div className="flex items-center justify-between text-xs text-zinc-500 font-mono mt-2 relative z-10">
              <span>TUNNEL SERVER: DE-FRANKFURT-1</span>
              <span className="text-neon-cyan animate-pulse">● LIVE TELEMETRY STREAM</span>
            </div>
          </div>

          {/* Card 2: Stealth Mode Toggle (Square Card) */}
          <div className="md:col-span-1 row-span-1 rounded-xl border border-white/5 bg-zinc-950/40 backdrop-blur-md p-6 flex flex-col justify-between relative overflow-hidden group hover:border-neon-purple/30 transition-all duration-300">
            <div className="absolute inset-0 bg-gradient-to-br from-neon-purple/5 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
            
            <div className="relative z-10">
              <span className="text-[11px] font-mono text-neon-purple tracking-wider block font-bold">SECURITY OVERRIDE</span>
              <h3 className="text-lg font-bold text-white mt-1">Stealth Cloaking</h3>
            </div>

            <div className="my-4 flex flex-col items-center justify-center relative z-10">
              <button
                onClick={() => setStealthEnabled(!stealthEnabled)}
                className={`relative w-20 h-10 rounded-full transition-all duration-300 ${
                  stealthEnabled 
                    ? "bg-neon-purple/20 border border-neon-purple shadow-[0_0_15px_rgba(157,78,237,0.3)]" 
                    : "bg-zinc-900 border border-zinc-700"
                }`}
              >
                <div
                  className={`absolute top-1 w-7 h-7 rounded-full transition-all duration-300 ${
                    stealthEnabled 
                      ? "right-1 bg-neon-purple shadow-[0_0_10px_rgba(157,78,237,0.8)]" 
                      : "left-1 bg-zinc-600"
                  }`}
                />
              </button>
              <span className="text-[11px] font-mono mt-3 uppercase tracking-wider text-zinc-400">
                STATUS:{" "}
                <span className={stealthEnabled ? "text-neon-purple font-bold text-glow-purple" : "text-zinc-500"}>
                  {stealthEnabled ? "CLOAKING ENGAGED" : "UNSHIELDED"}
                </span>
              </span>
            </div>

            <div className="text-[10px] font-mono text-zinc-500 text-center relative z-10 leading-relaxed">
              Virtual HwID & MAC spoofing automated rotation engine.
            </div>
          </div>

          {/* Card 3: Global Nodes (Square Card) */}
          <div className="md:col-span-1 row-span-1 rounded-xl border border-white/5 bg-zinc-950/40 backdrop-blur-md p-6 flex flex-col justify-between relative overflow-hidden group hover:border-neon-pink/30 transition-all duration-300">
            <div className="absolute inset-0 bg-gradient-to-br from-neon-pink/5 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
            
            <div className="relative z-10">
              <span className="text-[11px] font-mono text-neon-pink tracking-wider block font-bold">EDGE NETWORK</span>
              <h3 className="text-lg font-bold text-white mt-1">Bypass Node Relays</h3>
            </div>

            <div className="space-y-2 font-mono text-xs mt-3 relative z-10">
              <div className="flex items-center justify-between px-2.5 py-1.5 rounded bg-black/40 border border-white/5">
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-neon-green animate-pulse" />
                  <span>EU-WEST (Frankfurt)</span>
                </div>
                <span className="text-zinc-500">100%</span>
              </div>
              <div className="flex items-center justify-between px-2.5 py-1.5 rounded bg-black/40 border border-white/5">
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-neon-green animate-pulse" />
                  <span>US-EAST (Virginia)</span>
                </div>
                <span className="text-zinc-500">99.8%</span>
              </div>
              <div className="flex items-center justify-between px-2.5 py-1.5 rounded bg-black/40 border border-white/5">
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-yellow-500 animate-pulse" />
                  <span>AS-EAST (Singapore)</span>
                </div>
                <span className="text-zinc-500">92.4%</span>
              </div>
            </div>

            <span className="text-[10px] font-mono text-zinc-500 mt-2 block text-center relative z-10">
              Dynamic load balancing routing.
            </span>
          </div>

          {/* Card 4: Interactive Module Manager (Medium Card) */}
          <div className="md:col-span-2 row-span-2 rounded-xl border border-white/5 bg-zinc-950/40 backdrop-blur-md p-6 flex flex-col justify-between relative overflow-hidden group hover:border-neon-cyan/30 transition-all duration-300">
            <div className="absolute inset-0 bg-gradient-to-br from-neon-cyan/5 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
            
            <div className="relative z-10">
              <span className="text-[11px] font-mono text-neon-cyan tracking-wider block font-bold">CORE PLUGINS</span>
              <h3 className="text-lg font-bold text-white mt-1">Hook Module Integrations</h3>
              <p className="text-xs text-zinc-400 mt-1">Activate or stand by kernel automation routines directly.</p>
            </div>

            <div className="my-6 space-y-3 font-mono relative z-10 flex-1 overflow-y-auto">
              {modules.map((mod) => (
                <div
                  key={mod.id}
                  className={`flex items-center justify-between p-3 rounded-lg border transition-all duration-300 ${
                    mod.active
                      ? "bg-neon-cyan/5 border-neon-cyan/20 shadow-[0_0_10px_rgba(0,242,254,0.04)]"
                      : "bg-black/30 border-white/5 hover:border-zinc-800"
                  }`}
                >
                  <div>
                    <span className={`text-xs font-bold ${mod.active ? "text-neon-cyan" : "text-zinc-400"}`}>
                      {mod.name}
                    </span>
                    <span className="text-[10px] text-zinc-500 block mt-0.5">{mod.desc}</span>
                  </div>

                  <div className="flex items-center gap-3">
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                      mod.active
                        ? "bg-neon-cyan/20 text-neon-cyan shadow-[0_0_5px_rgba(0,242,254,0.3)]"
                        : "bg-zinc-900 text-zinc-600 border border-zinc-800"
                    }`}>
                      {mod.active ? "ACTIVE" : "STANDBY"}
                    </span>
                    <button
                      onClick={() => toggleModule(mod.id)}
                      className={`text-[10px] font-bold py-1 px-3.5 rounded-md border transition-all duration-200 ${
                        mod.active
                          ? "border-neon-pink text-neon-pink bg-neon-pink/10 hover:bg-neon-pink hover:text-white"
                          : "border-neon-cyan text-neon-cyan bg-neon-cyan/10 hover:bg-neon-cyan hover:text-black"
                      }`}
                    >
                      {mod.active ? "HALT" : "LOAD"}
                    </button>
                  </div>
                </div>
              ))}
            </div>

            <div className="text-xs text-zinc-500 font-mono flex items-center justify-between border-t border-white/5 pt-3 relative z-10">
              <span>MODULE DRIVERS CAPABLE: RING-0 RING-3</span>
              <span className="text-neon-cyan font-bold">VERIFIED SIGNATURES</span>
            </div>
          </div>

          {/* Card 5: Core Health Monitor (Square Card) */}
          <div className="md:col-span-1 row-span-1 rounded-xl border border-white/5 bg-zinc-950/40 backdrop-blur-md p-6 flex flex-col justify-between relative overflow-hidden group hover:border-neon-purple/30 transition-all duration-300">
            <div className="absolute inset-0 bg-gradient-to-br from-neon-purple/5 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
            
            <div className="relative z-10">
              <span className="text-[11px] font-mono text-neon-purple tracking-wider block font-bold">SYSTEM STATS</span>
              <h3 className="text-lg font-bold text-white mt-1">Bypass Integrity</h3>
            </div>

            <div className="flex flex-col items-center justify-center my-3 relative z-10">
              {/* Cool radial gauge using SVG */}
              <div className="relative w-28 h-28 flex items-center justify-center">
                <svg className="w-full h-full transform -rotate-95" viewBox="0 0 100 100">
                  <circle
                    className="text-zinc-900"
                    strokeWidth="8"
                    stroke="currentColor"
                    fill="transparent"
                    r="38"
                    cx="50"
                    cy="50"
                  />
                  <circle
                    className="text-neon-purple transition-all duration-500 shadow-[0_0_10px_rgba(157,78,237,0.5)]"
                    strokeWidth="8"
                    strokeDasharray={2 * Math.PI * 38}
                    strokeDashoffset={2 * Math.PI * 38 * (1 - systemIntegrity / 100)}
                    strokeLinecap="round"
                    stroke="currentColor"
                    fill="transparent"
                    r="38"
                    cx="50"
                    cy="50"
                  />
                </svg>
                <div className="absolute flex flex-col items-center justify-center font-mono">
                  <span className="text-lg font-black text-white">{systemIntegrity}%</span>
                  <span className="text-[9px] text-zinc-500 uppercase tracking-widest">STABLE</span>
                </div>
              </div>
            </div>

            <div className="text-[10px] font-mono text-zinc-500 text-center relative z-10">
              Real-time heuristic evasion metrics feedback.
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
