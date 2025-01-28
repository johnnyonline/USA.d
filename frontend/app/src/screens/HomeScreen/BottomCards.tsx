import { css } from "@/styled-system/css";
import { ASF, SUSDAF } from "@liquity2/uikit";
import React from "react";

interface CardProps {
  title: string;
  description: string;
  actionText: string;
  icon: React.ReactNode;
}

const Card: React.FC<CardProps> = ({ title, description, actionText, icon }) => {
  return (
    <div
      className={css({
        flex: 1,
        display: "flex",
        flexDirection: "column",
        gap: "20px",
        backgroundColor: "rgba(245, 230, 212, 0.5)", // Lighter desert tone
        padding: "28px",
        borderRadius: "16px",
        minWidth: { base: "100%", medium: "0" },
        transition: "transform 0.2s ease",
        _hover: {
          transform: "translateY(-2px)",
        },
      })}
    >
      <div>
        {icon}
      </div>
      <div
        className={css({
          display: "flex",
          flexDirection: "column",
          gap: "12px",
        })}
      >
        <h3
          className={css({
            fontSize: "24px",
            fontWeight: "700",
            color: "#402108", // Dark brown for contrast
            lineHeight: "1.2",
          })}
        >
          {title}
        </h3>
        <p
          className={css({
            fontSize: "16px",
            color: "#804e13", // Medium brown for readability
            lineHeight: "1.5",
          })}
        >
          {description}
        </p>
      </div>
      <a
        href="#"
        className={css({
          alignSelf: "flex-start",
          fontSize: "16px",
          fontWeight: "600",
          color: "#804e13", // Medium brown
          textDecoration: "underline",
          cursor: "pointer",
          _hover: {
            color: "#402108", // Darker on hover
          },
        })}
      >
        {actionText}
      </a>
    </div>
  );
};

const MultiTokenIcon = () => (
  <div
    className={css({
      position: "relative",
      width: "48px",
      height: "48px",
    })}
  >
    {/* First Dollar Icon */}
    <div
      className={css({
        position: "absolute",
        left: "0",
        top: "4px",
        width: "32px",
        height: "32px",
        borderRadius: "full",
        backgroundColor: "#E7F5EF",
        border: "2px solid #00A661",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      })}
    >
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
        <path
          d="M8 3V13M10 5H7C6.44772 5 6 5.44772 6 6C6 6.55228 6.44772 7 7 7H9C9.55228 7 10 7.44772 10 8C10 8.55228 9.55228 9 9 9H6"
          stroke="#00A661"
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    </div>
    {/* Second Dollar Icon */}
    <div
      className={css({
        position: "absolute",
        left: "8px",
        top: "4px",
        width: "32px",
        height: "32px",
        borderRadius: "full",
        backgroundColor: "#E7F5EF",
        border: "2px solid #00A661",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      })}
    >
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
        <path
          d="M8 3V13M10 5H7C6.44772 5 6 5.44772 6 6C6 6.55228 6.44772 7 7 7H9C9.55228 7 10 7.44772 10 8C10 8.55228 9.55228 9 9 9H6"
          stroke="#00A661"
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    </div>
    {/* Bitcoin Icon */}
    <div
      className={css({
        position: "absolute",
        left: "16px",
        top: "4px",
        width: "32px",
        height: "32px",
        borderRadius: "full",
        backgroundColor: "#FFF5E6",
        border: "2px solid #F7931A",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      })}
    >
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
        <path
          d="M11.5 4.5C11.5 2.84315 10.1569 1.5 8.5 1.5H4.5V7.5H8.5C10.1569 7.5 11.5 6.15685 11.5 4.5Z"
          fill="#F7931A"
        />
        <path
          d="M11.5 11.5C11.5 13.1569 10.1569 14.5 8.5 14.5H4.5V8.5H8.5C10.1569 8.5 11.5 9.84315 11.5 11.5Z"
          fill="#F7931A"
        />
      </svg>
    </div>
  </div>
);

export const BottomCards: React.FC = () => {
  return (
    <div
      className={css({
        display: "flex",
        flexDirection: { base: "column", medium: "row" },
        gap: "24px",
        padding: "32px",
        backgroundColor: "transparent",
        border: "2px solid #e6c7a0",
        borderRadius: "20px",
        width: "100%",
        maxWidth: "1280px",
        margin: "0 auto",
      })}
    >
      <Card
        icon={
          <img
            alt={SUSDAF.name}
            src={SUSDAF.icon}
            height={48}
            width={48}
          />
        }
        title="Borrow with USA.d"
        description="Cover liquidations to earn USA.d and collateral assets."
        actionText="Borrow"
      />
      <Card
        icon={<MultiTokenIcon />}
        title="Earn with USA.d"
        description="Cover liquidations to earn USA.d and collateral assets."
        actionText="Earn"
      />
      <Card
        icon={
          <img
            alt={ASF.name}
            src={ASF.icon}
            height={48}
            width={48}
          />
        }
        title="Lock ASF"
        description="Accrue voting power by staking your ASF."
        actionText="Lock"
      />
    </div>
  );
};
