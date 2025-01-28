"use client";

import { useAbout } from "@/src/comps/About/About";
import { ProtocolStats } from "@/src/comps/ProtocolStats/ProtocolStats";
import { TopBar } from "@/src/comps/TopBar/TopBar";
import * as env from "@/src/env";
import { css } from "@/styled-system/css";
import { TextButton } from "@liquity2/uikit";
import type { ReactNode } from "react";

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
        maxWidth: {
          base: "100%",
          small: "100%",
          medium: "1140px", // Previous LAYOUT_WIDTH + padding
        },
        padding: {
          base: "0 16px",
          small: "0 20px",
          medium: "0 24px",
        },
      })}
    >
      <div
        className={css({
          width: "100%",
          flexGrow: 0,
          flexShrink: 0,
          paddingBottom: {
            base: "24px",
            small: "32px",
            medium: "48px",
          },
        })}
      >
        <TopBar />
      </div>
      <div
        className={css({
          flexGrow: 1,
          display: "flex",
          flexDirection: "column",
          width: "100%",
        })}
      >
        <div
          className={css({
            flexGrow: 1,
            display: "flex",
            flexDirection: "column",
            width: "100%",
            padding: {
              base: "0 12px",
              small: "0 16px",
              medium: "0 24px",
            },
          })}
        >
          {children}
        </div>
        <div
          className={css({
            width: "100%",
            padding: {
              base: "32px 12px 0",
              small: "40px 16px 0",
              medium: "48px 24px 0",
            },
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
