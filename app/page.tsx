"use client";

import { useState, useEffect } from "react";
import Image from "next/image";
import Navbar from "./components/Navbar";
import InteractivePanel from "./components/InteractivePanel";

export default function Home() {
  const [validated, setValidated] = useState(false);
  const [licenseKey, setLicenseKey] = useState("");
  const [validating, setValidating] = useState(false);
  const [validationMsg, setValidationMsg] = useState("");
  const [detectedKey, setDetectedKey] = useState<string>("");

  useEffect(() => {
    const saved = localStorage.getItem("hiphub_key_data");
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        if (parsed.expiresAt > Date.now()) {
          setTimeout(() => {
            setDetectedKey(parsed.key);
            setLicenseKey(parsed.key);
          }, 0);
        }
      } catch {
        // ignore
      }
    }
  }, []);

  const handleValidate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!licenseKey.trim()) return;

    setValidating(true);
    setValidationMsg("INITIALIZING KEY CHECK...");

    setTimeout(() => {
      setValidationMsg("CONNECTING TO AUTH SERVER...");
      setTimeout(async () => {
        try {
          const res = await fetch("/api/keys/validate", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ key: licenseKey }),
          });

          const data = await res.json();
          setValidating(false);

          if (res.ok && data.success) {
            setValidated(true);
            setValidationMsg("AUTHENTICATION MATCHED! LOADING LAUNCHER GATEWAY...");
          } else {
            setValidated(false);
            setValidationMsg("ERROR: " + (data.error || "Authentication rejected."));
          }
        } catch (err) {
          console.error("Key validation failed:", err);
          setValidating(false);
          setValidated(false);
          setValidationMsg("ERROR: Failed to connect to authentication gateway.");
        }
      }, 800);
    }, 800);
  };

  // Supported Roblox games mock data
  const featuredGames = [
    {
      id: 1,
      title: "Anime Fighting",
      image: "/game_anime_sword.png",
      status: "UPDATED",
    },
    {
      id: 2,
      title: "Stealth Sniper",
      image: "/game_cyber_sniper.png",
      status: "UPDATED",
    },
    {
      id: 3,
      title: "Forest Tycoon",
      image: "/game_neon_clown.png",
      status: "UPDATED",
    },
    {
      id: 4,
      title: "Carnival Chest",
      image: "/game_neon_clown.png", // reusing clown carnival asset
      status: "UPDATED",
    },
    {
      id: 5,
      title: "Arena Simulator",
      image: "/game_cyber_giant.png",
      status: "UPDATED",
    },
  ];

  return (
    <div className="relative min-h-screen bg-[#030303] text-zinc-100 overflow-hidden font-sans selection:bg-[#9333ea] selection:text-white">

      {/* Thinner and sharper cyber-grid background matching the screenshot */}
      <div className="absolute inset-0 cyber-grid opacity-25 pointer-events-none" />

      {/* Background neon glow gradients */}
      <div className="absolute top-[20%] left-[-10%] w-[500px] h-[500px] rounded-full bg-[#9333ea]/5 blur-[130px] pointer-events-none" />
      <div className="absolute top-[60%] right-[-15%] w-[600px] h-[600px] rounded-full bg-[#c084fc]/5 blur-[140px] pointer-events-none" />

      {/* Navigation Header */}
      <Navbar />

      {/* Hero Section */}
      <main className="relative max-w-7xl mx-auto px-8 pt-32 pb-24 min-h-[90vh] flex flex-col justify-center">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">

          {/* Hero Left Column (Info Copy) */}
          <div className="lg:col-span-5 flex flex-col gap-6 text-left relative z-10">
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-black tracking-tight text-white leading-tight uppercase font-sans">
              The Only Hub <br />
              <span className="text-[#c084fc] text-glow-purple">
                You Need.
              </span>
            </h1>

            <p className="text-zinc-400 text-xs sm:text-sm max-w-md leading-relaxed font-medium">
              Premium Roblox scripts for your favorite games. Fast, reliable, and always updated.
            </p>

            <div className="pt-2">
              <a
                href="#get-key"
                className="inline-block px-8 py-3.5 rounded bg-gradient-to-r from-[#9333ea] to-[#7c3aed] text-[10px] font-extrabold tracking-widest text-white shadow-[0_0_20px_rgba(147,51,234,0.4)] hover:shadow-[0_0_30px_rgba(147,51,234,0.7)] hover:from-[#a855f7] hover:to-[#8b5cf6] transition-all duration-300 transform hover:scale-[1.01] uppercase"
              >
                Get Script
              </a>
            </div>
          </div>



        </div>
      </main>



      {/* Licensing / Key Activation Gateway Section */}
      <section id="get-key" className="relative border-t border-white/[0.02] py-24 bg-[#08080c]/20">
        <div className="max-w-4xl mx-auto px-8">
          <div className="rounded-xl border border-[#1f1f2a] bg-[#0a0a0f]/80 p-8 md:p-12 relative overflow-hidden">

            {/* Top border laser decoration */}
            <div className="absolute top-0 left-0 w-6 h-[1.5px] bg-[#9333ea]" />
            <div className="absolute top-0 left-0 w-[1.5px] h-6 bg-[#9333ea]" />
            <div className="absolute bottom-0 right-0 w-6 h-[1.5px] bg-[#c084fc]" />
            <div className="absolute bottom-0 right-0 w-[1.5px] h-6 bg-[#c084fc]" />

            <div className="max-w-xl mx-auto text-center space-y-6">
              <span className="text-[9px] font-extrabold tracking-widest text-[#c084fc] block uppercase font-mono">
                Key Retrieval System
              </span>
              <h2 className="text-xl sm:text-2xl font-black text-white uppercase">
                Initialize Free Script Key
              </h2>
              <p className="text-zinc-400 text-xs leading-relaxed max-w-md mx-auto">
                Authenticate your hub instance. Enter your HipHub License Key below to validate signature credentials and acquire the injection scripts.
              </p>

              {/* Validation panel */}
              {!validated ? (
                <form onSubmit={handleValidate} className="mt-8 flex flex-col sm:flex-row items-stretch gap-3 max-w-md mx-auto">
                  <input
                    type="text"
                    value={licenseKey}
                    onChange={(e) => setLicenseKey(e.target.value)}
                    disabled={validating}
                    placeholder="ENTER HIPHUB KEY (e.g. HIPHUB-XXXX)..."
                    className="flex-1 bg-[#13131c] border border-[#232332] rounded px-3 py-2.5 font-mono text-[10px] text-white placeholder-zinc-700 outline-none focus:border-[#9333ea] transition-all focus:shadow-[0_0_12px_rgba(147,51,234,0.15)]"
                    required
                  />
                  <button
                    type="submit"
                    disabled={validating}
                    className="px-6 py-2.5 rounded bg-gradient-to-r from-[#9333ea] to-[#7c3aed] text-white font-mono text-[9px] font-extrabold tracking-widest hover:shadow-[0_0_15px_rgba(147,51,234,0.3)] transition-all duration-300 disabled:opacity-50 uppercase"
                  >
                    {validating ? "CHECKING..." : "Verify"}
                  </button>
                </form>
              ) : (
                <div className="mt-8 p-5 rounded border border-[#22c55e]/25 bg-[#22c55e]/5 space-y-3 animate-pulse">
                  <p className="text-[#4ade80] font-mono text-[10px] font-extrabold tracking-wider uppercase">
                    {validationMsg}
                  </p>
                  <div className="flex flex-col sm:flex-row justify-center gap-3 pt-1">
                    <button
                      onClick={() => {
                        const loadstring = `_G.hiphub_key = "${licenseKey}"\nloadstring(game:HttpGet('https://hiphub.cloud/api/script-roblox/gag'))()`;
                        navigator.clipboard.writeText(loadstring);
                        alert("Script loadstring copied to clipboard!");
                      }}
                      className="px-6 py-2.5 rounded bg-[#22c55e] text-black font-mono text-[9px] font-extrabold tracking-widest shadow-[0_0_15px_rgba(34,197,94,0.3)] hover:shadow-[0_0_25px_rgba(34,197,94,0.6)] transition-all duration-300 uppercase cursor-pointer"
                    >
                      Copy Script
                    </button>
                  </div>
                </div>
              )}

              {validating && (
                <p className="text-zinc-500 font-mono text-[9px] animate-pulse mt-3">
                  {validationMsg}
                </p>
              )}

              {!validated && !validating && detectedKey && (
                <p className="text-[9px] font-mono text-[#22c55e] mt-3 uppercase tracking-widest animate-pulse font-bold">
                  ● Active 24H Key Detected: {detectedKey} (Auto-Filled)
                </p>
              )}

              {!validated && !validating && !detectedKey && (
                <p className="text-[9px] font-mono text-zinc-600 mt-3">
                  Any mock text will validate instantly. Retrieve a 24H device-locked key from the Get Key gateway.
                </p>
              )}
            </div>

          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 border-t border-white/[0.02] bg-[#060609] font-mono text-[9px] text-zinc-600">
        <div className="max-w-7xl mx-auto px-8 flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-2">
            <span className="text-white font-extrabold text-[10px] uppercase tracking-wider">HipHub</span>
            <span className="text-zinc-800">|</span>
            <span>SECURE SYSTEM MODULES</span>
          </div>

          <div className="flex items-center gap-6">
            <a href="#" className="hover:text-[#c084fc] transition-colors">SECURITY</a>
            <a href="#" className="hover:text-[#c084fc] transition-colors">WIKI</a>
            <a href="https://discord.gg/wXskXWCAQ" target="_blank" rel="noopener noreferrer" className="hover:text-[#c084fc] transition-colors">DISCORD</a>
          </div>

          <div>
            <span>© {new Date().getFullYear()} HIPHUB PROTOCOL. ALL RIGHTS RESERVED.</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
