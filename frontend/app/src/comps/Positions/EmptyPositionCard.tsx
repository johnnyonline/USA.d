import { css } from "@/styled-system/css";
import Link from "next/link";

export function EmptyPositionCard() {
  return (
    <div
      className={css({
        display: "flex",
        width: "100%",
        height: "62px",
        justifyContent: "space-between",
        alignItems: "center",
        padding: "12px 12px 12px 24px",
        border: "2px solid",
        borderColor: "desert:500",
        background: "desert:100",
        borderRadius: "16px",
        textDecoration: "none",
      })}
    >
      <div
        className={css({
          display: "flex",
          height: "18px",
          alignItems: "center",
          fontWeight: "bold",
          gap: "8px",
          color: "desert:900",
        })}
      >
        <span>You Have not Borrowed Any USA.d</span>
      </div>

      <Link
        href="/borrow"
        className={css({
          padding: "8px 16px",
          background: "desert:700",
          color: "desert:900",
          border: "2px solid",
          borderColor: "desert:700",
          borderRadius: "999px",
          cursor: "pointer",
          _hover: {
            background: "desert:800",
            color: "white",
          },
        })}
      >
        Borrow USA.d
      </Link>
    </div>
  );
}
