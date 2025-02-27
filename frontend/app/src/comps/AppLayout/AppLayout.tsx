"use client";

import type { ReactNode } from "react";

import { useAbout } from "@/src/comps/About/About";
import { ProtocolStats } from "@/src/comps/ProtocolStats/ProtocolStats";
import { TopBar } from "@/src/comps/TopBar/TopBar";
import * as env from "@/src/env";
import { css } from "@/styled-system/css";
import { TextButton } from "@liquity2/uikit";

export const LAYOUT_WIDTH = 1092;
export const MIN_WIDTH = 960;

export function AppLayout({
  children,
}: {
  children: ReactNode;
}) {
  return (
    <div
      className={css({
        display: "flex",
        flexDirection: "column",
        alignItems: "flex-start",
        width: "100%",
        minHeight: "100vh",
        margin: "0 auto",
        background: "background",
      })}
      style={{
        minWidth: `${MIN_WIDTH}px`,
        maxWidth: `${LAYOUT_WIDTH + 24 * 2}px`,
      }}
    >
      <div
        className={css({
          width: "100%",
          flexGrow: 0,
          flexShrink: 0,
          paddingBottom: 48,
        })}
      >
        <TopBar />
      </div>
      <div
        className={css({
          flexGrow: 1,
          display: "flex",
          flexDirection: "column",
        })}
        style={{
          width: `${LAYOUT_WIDTH + 24 * 2}px`,
        }}
      >
        <div
          className={css({
            flexGrow: 1,
            display: "flex",
            flexDirection: "column",
            width: "100%",
            padding: "0 24px",
          })}
        >
          {children}
        </div>
        <div
          className={css({
            width: "100%",
            padding: "48px 24px 0",
          })}
        >
          <BuildInfo />
          <ProtocolStats />
        </div>
      </div>
    </div>
  );
}

function BuildInfo() {
  const about = useAbout();
  return (
    <div
      className={css({
        display: "flex",
        alignItems: "center",
        justifyContent: "flex-end",
        height: 40,
      })}
    >
      <TextButton
        label={`${about.fullVersion} (${about.contractsHash})`}
        title={`About Liquity V2 App v${env.APP_VERSION}-${env.COMMIT_HASH} (contracts hash: ${about.contractsHash})`}
        onClick={() => {
          about.openModal();
        }}
        className={css({
          color: "dimmed",
        })}
        style={{
          fontSize: 12,
        }}
      />
    </div>
  );
}
