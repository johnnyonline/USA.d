import { useEffect, useState } from "react";

// Define breakpoints in pixels
export const breakpoints = {
  sm: 480, // Small devices
  md: 768, // Medium devices
  lg: 1024, // Large devices
  xl: 1280, // Extra large devices
  "2xl": 1536, // 2X Extra large devices
} as const;

export type Breakpoint = keyof typeof breakpoints;

interface ViewportInfo {
  width: number;
  height: number;
  breakpoint: Breakpoint;
  isMobile: boolean;
  isTablet: boolean;
  isDesktop: boolean;
}

function getCurrentBreakpoint(width: number): Breakpoint {
  if (width < breakpoints.sm) return "sm";
  if (width < breakpoints.md) return "md";
  if (width < breakpoints.lg) return "lg";
  if (width < breakpoints.xl) return "xl";
  return "2xl";
}

export function useViewport(): ViewportInfo {
  const [viewport, setViewport] = useState<ViewportInfo>({
    width: typeof window !== "undefined" ? window.innerWidth : breakpoints.lg,
    height: typeof window !== "undefined" ? window.innerHeight : 800,
    breakpoint: "lg",
    isMobile: false,
    isTablet: false,
    isDesktop: true,
  });

  useEffect(() => {
    const handleResize = () => {
      const width = window.innerWidth;
      const height = window.innerHeight;
      const breakpoint = getCurrentBreakpoint(width);

      setViewport({
        width,
        height,
        breakpoint,
        isMobile: width < breakpoints.md,
        isTablet: width >= breakpoints.md && width < breakpoints.lg,
        isDesktop: width >= breakpoints.lg,
      });
    };

    // Set initial viewport info
    handleResize();

    // Add event listener
    window.addEventListener("resize", handleResize);

    // Cleanup
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  return viewport;
}

// Helper to get column count based on viewport and mode
export function getResponsiveColumns(
  viewport: ViewportInfo,
  mode: "positions" | "loading" | "actions",
  defaultColumns: number = 3,
): number {
  if (viewport.isMobile) return 1;
  if (viewport.isTablet) return 2;
  if (mode === "actions") return 4;
  return defaultColumns;
}

// Helper for responsive card dimensions
export function getCardDimensions(viewport: ViewportInfo, mode: string) {
  const baseCardHeight = mode === "actions" ? 144 : 180;
  const baseGap = 24;

  return {
    height: viewport.isMobile
      ? baseCardHeight * 0.8 // Slightly smaller for mobile
      : viewport.isTablet
      ? baseCardHeight * 0.9 // Slightly smaller for tablet
      : baseCardHeight,
    gap: viewport.isMobile
      ? 16 // Fixed gap for mobile
      : viewport.isTablet
      ? 20 // Fixed gap for tablet
      : baseGap, // Default gap for desktop
  };
}
