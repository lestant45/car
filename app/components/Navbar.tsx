"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${scrolled
          ? "bg-[#030303]/90 backdrop-blur-md border-b border-[#1f1f2a]/60 py-3 shadow-[0_4px_30px_rgba(0,0,0,0.8)]"
          : "bg-transparent border-b border-white/[0.02] py-5"
        }`}
    >
      <div className="max-w-7xl mx-auto px-8 flex items-center justify-between">

        {/* Left: Brand Logo */}
        <Link href="/" className="flex items-center gap-2 group">
          <Image
            src="/LOGO_H_6.png"
            alt="HipHub Logo"
            width={28}
            height={28}
            className="w-7 h-7 object-contain"
          />
          <span className="text-sm font-black tracking-widest text-white uppercase font-sans">
            HipHub
          </span>
        </Link>

        {/* Center: Navigation Links */}
        <nav className="flex items-center gap-8 text-[10px] font-extrabold tracking-widest text-zinc-400 font-sans">
          <Link
            href="/"
            className="hover:text-white transition-colors duration-200 uppercase relative py-1"
          >
            Home
          </Link>
          <Link
            href="/get-key"
            className="hover:text-white transition-colors duration-200 uppercase relative py-1"
          >
            Get Key
          </Link>
          <a
            href="https://discord.gg/wXskXWCAQ"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-[#c084fc] transition-colors duration-200 uppercase relative py-1"
          >
            Discord
          </a>
        </nav>

        {/* Right: Buy Now CTA */}
        <div>
          <a
            href="#buy"
            className="px-5 py-2.5 rounded bg-gradient-to-r from-[#9333ea] to-[#7c3aed] text-[9px] font-extrabold tracking-widest text-white shadow-[0_0_15px_rgba(147,51,234,0.3)] hover:shadow-[0_0_25px_rgba(147,51,234,0.6)] hover:from-[#a855f7] hover:to-[#8b5cf6] transition-all duration-300 uppercase font-sans"
          >
            Buy Now
          </a>
        </div>

      </div>
    </header>
  );
}
