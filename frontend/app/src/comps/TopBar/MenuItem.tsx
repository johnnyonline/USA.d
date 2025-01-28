import type { ReactNode } from "react";

import { css } from "@/styled-system/css";

export function MenuItem({
  icon,
  label,
  selected,
}: {
  icon: ReactNode;
  label: string;
  selected?: boolean;
}) {
  return (
    <div
      aria-selected={selected}
      className={css({
        display: "flex",
        alignItems: "center",
        gap: 12,
        height: "100%",
        color: selected ? "selected" : "infoSurfaceContent",
        cursor: "pointer",
        userSelect: "none",
        _hover: {
          color: "accent",
        },
      })}
    >
      <div
        className={css({
          display: "grid",
          placeItems: "center",
          width: 24,
          height: 24,
        })}
      >
        {icon}
      </div>
      {label}
    </div>
  );
}
