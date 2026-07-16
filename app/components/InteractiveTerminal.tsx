"use client";

import React, { useState, useEffect, useRef } from "react";

interface LogLine {
  text: string;
  type: "info" | "success" | "error" | "warning" | "input" | "output";
  timestamp: string;
}

export default function InteractiveTerminal() {
  const [history, setHistory] = useState<LogLine[]>([]);
  const [input, setInput] = useState("");
  const [isInjecting, setIsInjecting] = useState(false);
  const [injectionProgress, setInjectionProgress] = useState(0);
  const terminalEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const getTimestamp = () => {
    const now = new Date();
    return now.toTimeString().split(" ")[0];
  };

  const addLine = (text: string, type: LogLine["type"] = "output") => {
    setHistory((prev) => [...prev, { text, type, timestamp: getTimestamp() }]);
  };

  // Simulated Boot Sequence
  useEffect(() => {
    const bootSequence = [
      { text: "INITIALIZING GAG PROTOCOL DEPLOYMENT ENGINE v4.2...", type: "info" as const, delay: 100 },
      { text: "ESTABLISHING SECURE TUNNEL TO NEXUS CENTRAL...", type: "info" as const, delay: 400 },
      { text: "SECURE CONNECTION ESTABLISHED // LATENCY: 14ms", type: "success" as const, delay: 800 },
      { text: "LOADING BYPASS MODULES: [MEM_HOOK, KERNEL_FILTER, HOOK_BYPASS]", type: "info" as const, delay: 1100 },
      { text: "BYPASS ENGINE STATUS: SECURE & ACTIVE", type: "success" as const, delay: 1500 },
      { text: "TYPE 'help' TO VIEW COMMAND GATEWAY DIRECTORY.", type: "warning" as const, delay: 1800 },
    ];

    bootSequence.forEach((line) => {
      setTimeout(() => {
        setHistory((prev) => [...prev, { text: line.text, type: line.type, timestamp: getTimestamp() }]);
      }, line.delay);
    });
  }, []);

  // Auto scroll to bottom of terminal
  useEffect(() => {
    terminalEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [history, isInjecting, injectionProgress]);

  const handleCommandSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const command = input.trim().toLowerCase();
    if (!command) return;

    // Add user command to history
    addLine(`nexus-user@terminal:~$ ${input}`, "input");
    setInput("");

    if (isInjecting) {
      addLine("ERROR: Operation in progress. Please wait for module compilation to finish.", "error");
      return;
    }

    // Process commands
    switch (command) {
      case "help":
        addLine("AVAILABLE NEXUS GATEWAY COMMANDS:", "info");
        addLine("  status     - Query system status, version, and security levels.");
        addLine("  inject     - Compile and inject automation hooks into memory space.");
        addLine("  bypass     - Cycle anti-cheat telemetry filters.");
        addLine("  modules    - List active automation plugins.");
        addLine("  logs       - Fetch kernel hook telemetry stream.");
        addLine("  clear      - Purge terminal logs display cache.");
        break;

      case "status":
        addLine("--- GAG NEXUS DIAGNOSTICS ---", "info");
        addLine("SYSTEM CORE: Active (v4.2.9-Release)");
        addLine("ANTI-CHEAT DEFECTION RATE: 99.86%");
        addLine("ACTIVE PROXIES: 3 (Shadow-Routing Enabled)");
        addLine("KERNEL LEVEL: Driver Loaded & Obfuscated");
        addLine("VULNERABILITY PATCH LEVEL: Verified Secure", "success");
        break;

      case "inject":
        setIsInjecting(true);
        setInjectionProgress(0);
        addLine("STARTING MODULE COMPILATION & INJECTION SEQUENCE...", "warning");
        break;

      case "bypass":
        addLine("INITIATING ANTI-CHEAT FILTER RE-KEYING...", "warning");
        setTimeout(() => {
          addLine("RE-KEYING COMPLETED. ROTATED VIRTUAL HARDWARE ID.", "success");
          addLine("STEALTH SIGNATURE ROTATED // NEW ID: NEXUS-BYP-" + Math.floor(Math.random() * 9000 + 1000), "success");
        }, 1200);
        break;

      case "modules":
        addLine("CURRENT STACK PLUGINS:", "info");
        addLine("  [+] KERNEL_BYPASS.SYS   - [LOADED] - Running in Kernel ring-0", "success");
        addLine("  [+] MEMORY_OBFUSCATOR   - [LOADED] - Obfuscating dynamic memory pages", "success");
        addLine("  [+] TELEMETRY_MUTANT    - [LOADED] - Spoofing client telemetry", "success");
        addLine("  [-] AUTO_KICK_PREVENTER - [STANDBY] - Ready for UI invocation", "warning");
        break;

      case "logs":
        addLine("[LOG] Hooking module base address 0x7FFA89B00000", "info");
        addLine("[LOG] Intercepted heartbeat packet. Modified signature payload.", "success");
        addLine("[LOG] Filtered out callstack traceback query from game engine.", "success");
        addLine("[WARN] Memory page sweep detected. Re-routed pointer references successfully.", "warning");
        addLine("[LOG] Virtual sandbox heartbeat maintained. Latency jitter: 1.2ms", "info");
        break;

      case "clear":
        setHistory([]);
        break;

      default:
        addLine(`nexus-terminal: command not found: '${command}'. Type 'help' for options.`, "error");
        break;
    }
  };

  // Handle injection progress bar
  useEffect(() => {
    if (!isInjecting) return;

    const interval = setInterval(() => {
      setInjectionProgress((prev) => {
        if (prev >= 100) {
          clearInterval(interval);
          setIsInjecting(false);
          addLine("COMPILATION COMPLETED. HOOK INJECTED AT BASE 0x" + Math.random().toString(16).substr(2, 8).toUpperCase(), "success");
          addLine("GAG AUTOMATION CONTROLS INITIALIZED // READY FOR DEPLOYMENT", "success");
          return 100;
        }
        return prev + 10;
      });
    }, 200);

    return () => clearInterval(interval);
  }, [isInjecting]);

  const focusInput = () => {
    inputRef.current?.focus();
  };

  return (
    <section id="terminal" className="py-24 relative overflow-hidden">
      {/* Background neon glows */}
      <div className="absolute top-1/2 left-1/4 -translate-y-1/2 -translate-x-1/2 w-[400px] h-[400px] rounded-full bg-neon-cyan/5 blur-[120px] pointer-events-none" />
      <div className="absolute top-1/3 right-1/4 -translate-y-1/2 translate-x-1/2 w-[400px] h-[400px] rounded-full bg-neon-purple/5 blur-[120px] pointer-events-none" />

      <div className="max-w-4xl mx-auto px-6">
        {/* Section Header */}
        <div className="text-center mb-12">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-neon-purple/30 bg-neon-purple/5 text-xs text-neon-purple font-mono mb-4 shadow-[0_0_10px_rgba(157,78,237,0.1)]">
            <span className="w-1.5 h-1.5 rounded-full bg-neon-purple animate-pulse" />
            NEXUS CORE GATEWAY
          </div>
          <h2 className="text-3xl md:text-4xl font-black text-white tracking-tight">
            INTERACTIVE <span className="text-neon-cyan text-glow-cyan">COMMAND HUB</span>
          </h2>
          <p className="text-zinc-400 mt-4 max-w-lg mx-auto text-sm">
            Interface directly with the Nexus bypass core. Try compilation injections, query status checks, or cycle telemetry filters.
          </p>
        </div>

        {/* Terminal Window */}
        <div
          onClick={focusInput}
          className="relative rounded-lg border border-neon-cyan/20 bg-black/85 shadow-[0_0_40px_rgba(0,242,254,0.06)] overflow-hidden cursor-text group"
        >
          {/* Top Bar */}
          <div className="flex items-center justify-between px-4 py-3 bg-zinc-950 border-b border-zinc-900 font-mono text-[11px] text-zinc-500">
            <div className="flex items-center gap-2">
              <div className="w-2.5 h-2.5 rounded-full bg-red-500/60" />
              <div className="w-2.5 h-2.5 rounded-full bg-yellow-500/60" />
              <div className="w-2.5 h-2.5 rounded-full bg-green-500/60" />
              <span className="ml-2 text-zinc-400 font-bold tracking-wider">NEXUS-SYSTEM-CONSOLE // TTY-1</span>
            </div>
            <div className="flex items-center gap-1.5 text-zinc-500">
              <span className="w-2 h-2 rounded-full bg-neon-cyan animate-pulse" />
              SECURE SHELL (SSH)
            </div>
          </div>

          {/* Screen Content */}
          <div className="relative p-6 h-[380px] overflow-y-auto font-mono text-xs md:text-sm space-y-2.5 select-text">
            {/* Scanline overlay */}
            <div className="absolute inset-0 pointer-events-none bg-[linear-gradient(rgba(18,16,16,0)_50%,rgba(0,0,0,0.25)_50%),linear-gradient(90deg,rgba(255,0,0,0.06),rgba(0,255,0,0.02),rgba(0,0,255,0.06))] bg-[length:100%_4px,3px_100%] opacity-45" />

            {/* History Logs */}
            {history.map((line, i) => (
              <div key={i} className="flex items-start gap-2.5 leading-relaxed">
                <span className="text-zinc-600 shrink-0 text-[10px] md:text-xs select-none">
                  [{line.timestamp}]
                </span>
                <span
                  className={`break-all ${
                    line.type === "info"
                      ? "text-neon-cyan/90"
                      : line.type === "success"
                      ? "text-neon-green/90"
                      : line.type === "error"
                      ? "text-neon-pink font-bold"
                      : line.type === "warning"
                      ? "text-yellow-400"
                      : line.type === "input"
                      ? "text-white font-medium"
                      : "text-zinc-300"
                  }`}
                >
                  {line.text}
                </span>
              </div>
            ))}

            {/* Simulation of Injection Progress */}
            {isInjecting && (
              <div className="flex items-center gap-4 py-2 text-neon-cyan font-semibold">
                <span className="shrink-0">COMPILING:</span>
                <div className="w-full max-w-xs bg-zinc-900 rounded-md border border-neon-cyan/20 h-4 overflow-hidden relative">
                  <div
                    className="h-full bg-gradient-to-r from-neon-cyan to-neon-purple transition-all duration-200 shadow-[0_0_10px_rgba(0,242,254,0.5)]"
                    style={{ width: `${injectionProgress}%` }}
                  />
                  <div className="absolute inset-0 flex items-center justify-center text-[9px] font-bold text-white tracking-widest mix-blend-difference">
                    {injectionProgress}%
                  </div>
                </div>
              </div>
            )}

            <div ref={terminalEndRef} />
          </div>

          {/* Command Input Form */}
          <form
            onSubmit={handleCommandSubmit}
            className="flex items-center border-t border-zinc-900 bg-zinc-950/70 p-4"
          >
            <span className="text-neon-cyan font-mono font-bold mr-2 select-none">
              nexus-user@terminal:~$
            </span>
            <input
              ref={inputRef}
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              disabled={isInjecting}
              className="flex-1 bg-transparent border-none outline-none font-mono text-white text-sm focus:ring-0 placeholder-zinc-700 disabled:opacity-50"
              placeholder={isInjecting ? "Compiling hook modules..." : "Type command (e.g. 'help', 'status', 'inject')..."}
              autoComplete="off"
              autoCorrect="off"
              autoCapitalize="off"
              spellCheck="false"
            />
            {/* Blinking Cursor overlay */}
            <div className="w-2 h-4 bg-neon-cyan animate-pulse shadow-[0_0_8px_rgba(0,242,254,0.8)] shrink-0" />
          </form>
        </div>
      </div>
    </section>
  );
}
