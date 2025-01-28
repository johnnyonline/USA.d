"use client";
import { Logo } from "@/src/comps/Logo/Logo";
import { Tag } from "@/src/comps/Tag/Tag";
import content from "@/src/content";
import { DEPLOYMENT_FLAVOR } from "@/src/env";
import { css } from "@/styled-system/css";
import { IconBorrow, IconDashboard, IconEarn, IconStake } from "@liquity2/uikit";
import Link from "next/link";
import type { ComponentProps } from "react";
import { AccountButton } from "./AccountButton";
import { Menu } from "./Menu";

const menuItems: ComponentProps<typeof Menu>["menuItems"] = [
  [content.menu.dashboard, "/", IconDashboard],
  [content.menu.borrow, "/borrow", IconBorrow],
  [content.menu.earn, "/earn", IconEarn],
  [content.menu.ecosystem, "https://app.asymmetry.finance/", IconStake],
  [content.menu.asf, "https://app.asymmetry.finance/veasf", IconStake],
];

const formatAppName = (name: string) => {
  const words = name.split(" ");
  if (words.length > 1) {
    return words.map((word, index) => (
      <span
        key={index}
        className={css({
          display: "block",
          lineHeight: "1.2",
        })}
      >
        {word}
      </span>
    ));
  }
  return name;
};

export function TopBar() {
  return (
    <div
      className={css({
        position: "relative",
        zIndex: 1,
        height: 72,
      })}
    >
      <div
        className={css({
          position: "relative",
          zIndex: 1,
          display: "flex",
          justifyContent: "space-between",
          gap: 16,
          maxWidth: 1280,
          height: "100%",
          margin: "0 auto",
          padding: "16px 24px",
          fontSize: 16,
          fontWeight: 500,
          background: "background",
        })}
      >
        <Link
          href="/"
          className={css({
            position: "relative",
            display: "flex",
            alignItems: "center",
            gap: 16,
            height: "100%",
            paddingRight: 8,
            _focusVisible: {
              borderRadius: 4,
              outline: "2px solid token(colors.focused)",
            },
            _active: {
              translate: "0 1px",
            },
          })}
        >
          <div
            className={css({
              flexShrink: 0,
            })}
          >
            <Logo />
          </div>
          <div
            className={css({
              flexShrink: 0,
              display: "flex",
              alignItems: "center",
              gap: 8,
            })}
          >
            <div
              className={css({
                whiteSpace: "normal",
                textAlign: "left",
              })}
            >
              {formatAppName(content.appName)}
            </div>
            {DEPLOYMENT_FLAVOR !== "" && (
              <div
                className={css({
                  display: "flex",
                })}
              >
                <Tag
                  size="mini"
                  css={{
                    color: "accentContent",
                    background: "brandCoral",
                    border: 0,
                    textTransform: "uppercase",
                  }}
                >
                  {DEPLOYMENT_FLAVOR}
                </Tag>
              </div>
            )}
          </div>
        </Link>
        <Menu menuItems={menuItems} />
        <AccountButton />
      </div>
    </div>
  );
}
