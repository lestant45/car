"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";

interface DeviceInfo {
  ip: string;
  browser: string;
  os: string;
  isp: string;
  country: string;
  city: string;
}

interface KeyData {
  key: string;
  role?: string;
  generatedAt: number;
  expiresAt: number;
  ip: string;
  userAgent: string;
}

export default function GetKeyPage() {
  const [mounted, setMounted] = useState(false);

  // Loading & Checklist Telemetry states
  const [deviceInfo, setDeviceInfo] = useState<DeviceInfo>({
    ip: "Scanning...",
    browser: "Analyzing...",
    os: "Detecting...",
    isp: "Quering DNS...",
    country: "Locating...",
    city: "Locating...",
  });

  // Checkpoint & Key States
  const [checkpointTimer, setCheckpointTimer] = useState(5);
  const [checkpointPassed, setCheckpointPassed] = useState(false);
  const [generatingKey, setGeneratingKey] = useState(false);
  const [generationStep, setGenerationStep] = useState("");
  const [generatedKey, setGeneratedKey] = useState<KeyData | null>(null);
  const [timeLeftStr, setTimeLeftStr] = useState("");
  const [verificationCode, setVerificationCode] = useState("");

  // Detect Device & Fetch IP
  useEffect(() => {
    setTimeout(() => {
      setMounted(true);
    }, 0);

    // 1. Detect Browser & OS
    const ua = navigator.userAgent;
    let browser = "Unknown Browser";
    let os = "Unknown OS";

    if (ua.indexOf("Firefox") > -1) browser = "Mozilla Firefox";
    else if (ua.indexOf("Chrome") > -1) browser = "Google Chrome";
    else if (ua.indexOf("Safari") > -1) browser = "Apple Safari";
    else if (ua.indexOf("Edge") > -1) browser = "Microsoft Edge";

    if (ua.indexOf("Windows") > -1) os = "Windows OS";
    else if (ua.indexOf("Macintosh") > -1) os = "macOS";
    else if (ua.indexOf("Linux") > -1) os = "Linux OS";
    else if (ua.indexOf("Android") > -1) os = "Android";
    else if (ua.indexOf("iPhone") > -1) os = "iOS";

    // 2. Fetch IP Telemetry
    const fetchTelemetry = async () => {
      try {
        const res = await fetch("https://ipapi.co/json/");
        if (res.ok) {
          const data = await res.json();
          setDeviceInfo({
            ip: data.ip || "127.0.0.1",
            browser,
            os,
            isp: data.org || "Unknown ISP",
            country: data.country_name || "Unknown Country",
            city: data.city || "Unknown City",
          });
        } else {
          throw new Error("Failed to load telemetry");
        }
      } catch {
        // Fallback simulated data if API fails or is blocked
        setDeviceInfo({
          ip: "185.220.101.5",
          browser,
          os,
          isp: "DigitalOcean Transit AS",
          country: "Germany",
          city: "Frankfurt",
        });
      }
    };

    fetchTelemetry();

    // Check if key already exists in localStorage
    const savedKey = localStorage.getItem("hiphub_key_data");
    if (savedKey) {
      try {
        const parsed: KeyData = JSON.parse(savedKey);
        const now = Date.now();
        if (parsed.expiresAt > now) {
          setTimeout(() => {
            setGeneratedKey(parsed);
            setCheckpointPassed(true);
          }, 0);
        } else {
          localStorage.removeItem("hiphub_key_data");
        }
      } catch {
        localStorage.removeItem("hiphub_key_data");
      }
    }
  }, []);

  // Checkpoint Countdown Timer
  useEffect(() => {
    if (!mounted || generatedKey) return;

    const interval = setInterval(() => {
      setCheckpointTimer((t) => {
        if (t <= 1) {
          clearInterval(interval);
          setCheckpointPassed(true);
          return 0;
        }
        return t - 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [mounted, generatedKey]);

  // Live Countdown Timer for Key Expiration
  useEffect(() => {
    if (!generatedKey) return;

    const updateCountdown = () => {
      const now = Date.now();
      const diff = generatedKey.expiresAt - now;

      if (diff <= 0) {
        setGeneratedKey(null);
        localStorage.removeItem("hiphub_key_data");
        setTimeLeftStr("Expired");
        setCheckpointPassed(false);
        setCheckpointTimer(5);
        return;
      }

      const hours = Math.floor(diff / (1000 * 60 * 60));
      const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((diff % (1000 * 60)) / 1000);

      const hStr = hours.toString().padStart(2, "0");
      const mStr = minutes.toString().padStart(2, "0");
      const sStr = seconds.toString().padStart(2, "0");

      setTimeLeftStr(`${hStr}h ${mStr}m ${sStr}s`);
    };

    updateCountdown();
    const interval = setInterval(updateCountdown, 1000);
    return () => clearInterval(interval);
  }, [generatedKey]);

  // Handle Key Generation Click
  const handleGenerateKey = async () => {
    if (generatingKey) return;

    if (!verificationCode.trim()) {
      alert("Verification Code Required! Please join our Discord and generate a code first.");
      return;
    }

    setGeneratingKey(true);
    setGenerationStep("FINGERPRINTING DEVICE SIGNATURE...");

    setTimeout(() => {
      setGenerationStep("BINDING LOCAL TELEMETRY PACKETS...");
      setTimeout(() => {
        setGenerationStep("COMPILING 24H SECURITY CERTIFICATE...");
        setTimeout(async () => {
          try {
            const res = await fetch("/api/keys/generate", {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
              },
              body: JSON.stringify({
                browser: deviceInfo.browser,
                os: deviceInfo.os,
                isp: deviceInfo.isp,
                country: deviceInfo.country,
                city: deviceInfo.city,
                code: verificationCode.trim(),
              }),
            });

            const data = await res.json().catch(() => ({ success: false, error: "Failed to parse server response" }));

            if (res.ok && data.success) {
              const keyObj: KeyData = {
                key: data.key,
                role: data.role,
                generatedAt: data.generatedAt,
                expiresAt: data.expiresAt,
                ip: data.ip,
                userAgent: data.userAgent,
              };
              localStorage.setItem("hiphub_key_data", JSON.stringify(keyObj));
              setGeneratedKey(keyObj);
            } else {
              alert(data.error || "Key generation failed. Please check your verification code.");
            }
          } catch (err) {
            console.error("Key generation request failed:", err);
            alert("Network error. Failed to connect to key server.");
          } finally {
            setGeneratingKey(false);
          }
        }, 800);
      }, 800);
    }, 800);
  };

  if (!mounted) {
    return (
      <div className="min-h-screen bg-[#030303] flex items-center justify-center font-mono text-xs text-zinc-500">
        INITIALIZING SECURITY GATEWAY...
      </div>
    );
  }

  return (
    <div className="relative min-h-screen bg-[#030303] text-zinc-100 font-sans selection:bg-[#9333ea] selection:text-white overflow-hidden">

      {/* Thinner grid background */}
      <div className="absolute inset-0 cyber-grid opacity-25 pointer-events-none" />

      {/* Neon glows */}
      <div className="absolute top-[15%] left-[-5%] w-[450px] h-[450px] rounded-full bg-[#9333ea]/5 blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[15%] right-[-5%] w-[450px] h-[450px] rounded-full bg-[#c084fc]/5 blur-[120px] pointer-events-none" />

      {/* Header */}
      <header className="fixed top-0 left-0 right-0 z-50 bg-[#030303]/80 backdrop-blur-md border-b border-[#1f1f2a]/60 py-4">
        <div className="max-w-5xl mx-auto px-6 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2 group">
            <Image
              src="/LOGO_H_6.png"
              alt="HipHub Logo"
              width={26}
              height={26}
              className="w-6.5 h-6.5 object-contain"
            />
            <span className="text-sm font-black tracking-widest text-white uppercase font-sans">
              HipHub
            </span>
          </Link>
          <span className="text-[9px] font-bold font-mono tracking-widest text-[#c084fc] bg-[#9333ea]/10 border border-[#9333ea]/35 rounded px-2.5 py-1 uppercase">
            System Key Gateway
          </span>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-4xl mx-auto px-6 pt-32 pb-24 flex flex-col items-center justify-center min-h-screen relative z-10">

        <div className="w-full max-w-md">

          {/* Key Generation Checkpoint */}
          <div className="rounded-xl border border-[#1f1f2a] bg-[#0a0a0f]/90 p-6 shadow-[0_4px_30px_rgba(0,0,0,0.5)] relative overflow-hidden">
            {/* Scanline laser animation */}
            <div className="absolute inset-x-0 h-[1.5px] bg-gradient-to-r from-transparent via-[#c084fc] to-transparent top-0 animate-laser-scan pointer-events-none" />

            {!generatedKey ? (
              <div className="text-center space-y-6 py-4">
                <div className="w-12 h-12 rounded-full border border-[#9333ea]/30 bg-[#9333ea]/5 flex items-center justify-center mx-auto shadow-[0_0_15px_rgba(147,51,234,0.15)]">
                  <svg className="w-6 h-6 text-[#c084fc] animate-pulse" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M15 7a2 2 0 012 2m-5a5 5 0 11-5-5h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2h-1a2 2 0 01-2-2v-1a2 2 0 00-2-2h-1a2 2 0 00-2-2h-3a2 2 0 00-2-2V9a2 2 0 012-2h3m-6 0a2 2 0 00-2 2v3m2-3V9" />
                  </svg>
                </div>

                <div className="space-y-2">
                  <h2 className="text-base font-extrabold text-white uppercase tracking-wider">Securing Access Checkpoint</h2>
                  <p className="text-zinc-400 text-xs max-w-sm mx-auto leading-relaxed">
                    {!checkpointPassed
                      ? "Analyzing browser environment to verify client identity integrity. Hold connection..."
                      : "Environment verification complete. Key queue initialized."
                    }
                  </p>
                </div>

                {/* Countdown / Generation Actions */}
                {!checkpointPassed ? (
                  <div className="inline-flex flex-col items-center gap-2">
                    <div className="px-6 py-3 rounded bg-[#13131c] border border-[#232332] font-mono text-xs font-black tracking-widest text-[#c084fc]">
                      CHECKPOINT LOCKOUT: {checkpointTimer}s
                    </div>
                    <span className="text-[8px] font-mono text-zinc-600 uppercase">PREVENTING SCRIPT TELEMETRY HARVESTING</span>
                  </div>
                ) : (
                  <div className="flex flex-col items-stretch gap-6 pt-2 text-left">
                    {/* Step 1: Join Discord */}
                    <div className="p-4 rounded-lg bg-[#0d0d15]/50 border border-[#1f1f2a] space-y-3 hover:border-[#9333ea]/30 transition-all duration-300">
                      <div className="flex items-start gap-3">
                        <div className="w-8 h-8 rounded-md bg-[#5865F2]/10 border border-[#5865F2]/20 flex items-center justify-center text-[#5865F2] shrink-0 mt-0.5">
                          <svg className="w-4.5 h-4.5" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.462-.63.874-1.295 1.226-1.994.021-.041.001-.09-.041-.106a13.094 13.094 0 0 1-1.873-.894.077.077 0 0 1-.008-.128c.126-.093.252-.19.372-.287a.075.075 0 0 1 .077-.011c3.92 1.793 8.18 1.793 12.061 0a.073.073 0 0 1 .078.009c.12.099.246.195.373.289a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.894.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.156-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.156 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.156-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.156 2.418z" />
                          </svg>
                        </div>
                        <div>
                          <h3 className="text-xs font-bold text-white uppercase tracking-wider">Step 1: Join Discord</h3>
                          <p className="text-[10px] text-zinc-400 mt-0.5">Access our Discord server to generate a security verification code.</p>
                        </div>
                      </div>
                      <a
                        href={process.env.NEXT_PUBLIC_DISCORD_INVITE_URL || "https://discord.gg/9HVwnzn8J"}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center justify-center gap-2 w-full py-2.5 rounded bg-[#5865F2] hover:bg-[#4752c4] text-white font-mono text-[9px] font-black tracking-widest uppercase transition-all duration-300 shadow-[0_0_15px_rgba(88,101,242,0.2)] hover:shadow-[0_0_20px_rgba(88,101,242,0.4)]"
                      >
                        Join Discord Server
                        <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                        </svg>
                      </a>
                    </div>

                    {/* Step 2: Verification Code Input */}
                    <div className="p-4 rounded-lg bg-[#0d0d15]/50 border border-[#1f1f2a] space-y-3 hover:border-[#9333ea]/30 transition-all duration-300">
                      <div className="flex items-start gap-3">
                        <div className="w-8 h-8 rounded-md bg-[#9333ea]/10 border border-[#9333ea]/20 flex items-center justify-center text-[#c084fc] shrink-0 mt-0.5">
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                          </svg>
                        </div>
                        <div>
                          <h3 className="text-xs font-bold text-white uppercase tracking-wider">Step 2: Enter Verification Code</h3>
                          <p className="text-[10px] text-zinc-400 mt-0.5">Go to <code className="text-[#c084fc] font-bold">#verification-script</code> or click the button in Discord.</p>
                        </div>
                      </div>

                      <div className="relative">
                        <input
                          type="text"
                          value={verificationCode}
                          onChange={(e) => setVerificationCode(e.target.value)}
                          placeholder="HH-XXXXXX"
                          disabled={generatingKey}
                          className="w-full px-3 py-2.5 rounded bg-[#13131c] border border-[#232332] text-white font-mono text-xs placeholder:text-zinc-700 focus:outline-none focus:border-[#9333ea] focus:ring-1 focus:ring-[#9333ea]/40 transition-all duration-300 uppercase tracking-widest text-center"
                        />
                        <div className="absolute right-3 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-[#9333ea] animate-pulse" />
                      </div>
                    </div>

                    {/* Generator button/loading */}
                    <div className="flex flex-col items-center gap-4 pt-2">
                      {generatingKey ? (
                        <div className="space-y-3 w-full text-center">
                          <span className="font-mono text-[9px] text-[#c084fc] block tracking-wider animate-pulse uppercase">
                            {generationStep}
                          </span>
                          <div className="w-full h-1 bg-[#13131c] border border-[#232332] rounded overflow-hidden relative">
                            <div className="h-full bg-gradient-to-r from-[#9333ea] to-[#c084fc] animate-[laser-scan_1.5s_linear_infinite]" style={{ width: "40%" }} />
                          </div>
                        </div>
                      ) : (
                        <button
                          onClick={handleGenerateKey}
                          className="w-full py-3.5 rounded bg-gradient-to-r from-[#9333ea] to-[#7c3aed] text-white font-mono text-[10px] font-black tracking-widest shadow-[0_0_20px_rgba(147,51,234,0.3)] hover:shadow-[0_0_30px_rgba(147,51,234,0.6)] hover:from-[#a855f7] hover:to-[#8b5cf6] transition-all duration-300 uppercase text-center cursor-pointer"
                        >
                          Verify & Generate Secure Key
                        </button>
                      )}
                    </div>
                  </div>
                )}
              </div>
            ) : (
              // Active Generated Key UI Panel
              <div className="space-y-6 py-2">
                <div className="text-center border-b border-[#1f1f2a]/60 pb-4">
                  <span className={`text-[9px] font-bold tracking-widest uppercase font-mono border px-2.5 py-1 rounded ${
                    generatedKey.role === "premium"
                      ? "text-[#c084fc] bg-[#9333ea]/10 border-[#9333ea]/35"
                      : "text-[#22c55e] bg-[#22c55e]/10 border-[#22c55e]/30"
                  }`}>
                    ● {generatedKey.role === "premium" ? "Premium" : "Free"} Key Active & Device Bound
                  </span>
                  <h2 className="text-base font-black text-white mt-4 uppercase">Your Secure Key Credentials</h2>
                </div>

                {/* Secure Key Card */}
                <div className="relative rounded-lg border border-[#22c55e]/20 bg-[#22c55e]/5 p-5 text-center space-y-3 shadow-[0_0_15px_rgba(34,197,94,0.05)]">
                  <div className="text-[8px] font-mono text-[#4ade80] uppercase tracking-widest block font-bold">CRYPTO SIGNATURE TOKEN</div>
                  <span className="font-mono text-sm sm:text-base font-black text-white tracking-widest select-all block">
                    {generatedKey.key}
                  </span>
                  <button
                    onClick={() => {
                      navigator.clipboard.writeText(generatedKey.key);
                      alert("Key copied to clipboard!");
                    }}
                    className="inline-block px-4 py-1.5 rounded border border-[#22c55e]/30 text-[#4ade80] hover:bg-[#22c55e]/10 font-mono text-[8px] font-bold tracking-wider transition-colors uppercase"
                  >
                    Copy Token
                  </button>
                </div>

                {/* Expiry / Stats info */}
                <div className="grid grid-cols-2 gap-4 font-mono text-[9px] text-zinc-500 border-t border-[#1f1f2a]/60 pt-4">
                  <div className="space-y-1">
                    <span className="uppercase block font-bold">VALID DURATION / ROLE</span>
                    <span className="text-white font-bold">{generatedKey.role === "premium" ? "Lifetime" : "3 Hours"} ({generatedKey.role === "premium" ? "Premium" : "Free"})</span>
                  </div>
                  <div className="space-y-1 text-right">
                    <span className="uppercase block font-bold">TIME REMAINING</span>
                    <span className="text-[#c084fc] font-black text-[11px] block tracking-wide text-glow-purple">
                      {timeLeftStr || "Calculating..."}
                    </span>
                  </div>
                </div>

                {/* Return button */}
                <div className="pt-3 text-center">
                  <Link
                    href="/"
                    className="inline-block px-8 py-3.5 rounded bg-white text-black font-mono text-[10px] font-extrabold tracking-widest hover:bg-zinc-200 transition-colors uppercase"
                  >
                    Return to Hub Dashboard
                  </Link>
                </div>
              </div>
            )}

          </div>

        </div>
      </main>

      {/* Footer */}
      <footer className="py-8 border-t border-white/[0.02] bg-[#030303] font-mono text-[9px] text-zinc-600 text-center">
        <div className="max-w-5xl mx-auto px-6 flex flex-col sm:flex-row items-center justify-between gap-4">
          <span>© {new Date().getFullYear()} HIPHUB GATEWAY SERVICE. ALL RIGHTS RESERVED.</span>
          <div className="flex gap-4">
            <a href="#" className="hover:text-white">SECURITY DEPT</a>
            <a href="#" className="hover:text-white">API DEEP LINK</a>
          </div>
        </div>
      </footer>

    </div>
  );
}
