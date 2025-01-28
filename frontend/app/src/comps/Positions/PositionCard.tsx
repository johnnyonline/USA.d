import type { HTMLAttributes, ReactElement, ReactNode } from "react";

import { getCardDimensions, useViewport } from "@/src/hooks/useViewport";
import { IconArrowRight, LoadingSurface } from "@liquity2/uikit";
import { a, useSpring } from "@react-spring/web";
import { forwardRef, useState } from "react";
import { css, cx } from "../../../styled-system/css";

type Cell = {
  label: ReactNode;
  value: ReactNode;
};

type ElementOrString = ReactElement | string;

export const PositionCard = forwardRef<
  HTMLAnchorElement,
  {
    contextual?: ReactNode;
    heading?: ElementOrString | ElementOrString[];
    loading?: boolean;
    main?: Cell;
    secondary?: ReactNode;
  } & HTMLAttributes<HTMLAnchorElement>
>(function PositionCard({
  contextual,
  heading,
  loading,
  main,
  secondary,
  ...anchorProps
}, ref) {
  const viewport = useViewport();
  const [heading1, heading2] = Array.isArray(heading) ? heading : [heading];

  const [hovered, setHovered] = useState(false);
  const [active, setActive] = useState(false);

  const hoverSpring = useSpring({
    progress: hovered ? 1 : 0,
    transform: active
      ? "scale(1)"
      : hovered
      ? "scale(1.01)"
      : "scale(1)",
    boxShadow: hovered && !active
      ? "0 2px 4px rgba(0, 0, 0, 0.1)"
      : "0 2px 4px rgba(0, 0, 0, 0)",
    immediate: active,
    config: {
      mass: 1,
      tension: 1800,
      friction: 80,
    },
  });

  // Get responsive dimensions
  const { height: baseHeight } = getCardDimensions(viewport, "positions");

  // Calculate responsive padding and gaps
  const responsivePadding = viewport.isMobile ? "8px 12px" : "12px 16px";
  const responsiveGap = viewport.isMobile ? 12 : 20;
  const responsiveFontSizes = {
    heading: viewport.isMobile ? 10 : 12,
    main: viewport.isMobile ? 24 : 28,
    secondary: viewport.isMobile ? 12 : 14,
  };

  return (
    <a.a
      ref={ref}
      {...anchorProps}
      onBlur={() => setActive(false)}
      onMouseDown={() => setActive(true)}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onMouseUp={() => setActive(false)}
      className={cx(
        "group",
        css({
          position: "relative",
          overflow: "hidden",
          display: "flex",
          flexDirection: "column",
          padding: responsivePadding,
          borderRadius: 8,
          outline: "none",
          "--background": "token(colors.position)",
          height: baseHeight,
          _focusVisible: {
            outline: "2px solid token(colors.focused)",
          },
        }),
      )}
      style={loading ? {} : {
        transform: hoverSpring.transform,
        boxShadow: hoverSpring.boxShadow,
        background: "var(--background)",
      }}
    >
      {loading && (
        <LoadingSurface
          className={css({
            "--loading-color": "token(colors.brandGreen)",
            opacity: 0.8,
          })}
        />
      )}
      <section
        className={css({
          display: "flex",
          flexDirection: "column",
          gap: responsiveGap,
          height: "100%",
        })}
        style={{
          opacity: loading ? 0 : 1,
          pointerEvents: loading ? "none" : "auto",
        }}
      >
        <header
          className={css({
            display: "flex",
            justifyContent: "space-between",
            color: "positionContentAlt",
          })}
        >
          <h1
            className={css({
              fontSize: responsiveFontSizes.heading,
              textTransform: "uppercase",
            })}
          >
            {heading1}
          </h1>
          {heading2 && (
            <div
              className={css({
                fontSize: responsiveFontSizes.secondary,
                color: "positionContent",
              })}
            >
              {heading2}
            </div>
          )}
          {contextual || (
            <div
              className={css({
                transition: "transform 100ms",
                _groupHover: {
                  transform: `
                    translate3d(0, 0, 0)
                    scale3d(1.2, 1.2, 1)
                  `,
                },
                _groupFocus: {
                  transform: `
                    translate3d(4px, 0, 0)
                  `,
                },
              })}
            >
              <IconArrowRight size={20} />
            </div>
          )}
        </header>
        {main && (
          <div
            className={css({
              display: "flex",
              flexDirection: "column",
              marginTop: viewport.isMobile ? -16 : -24,
            })}
          >
            <div
              className={css({
                color: "positionContent",
                fontSize: responsiveFontSizes.main,
              })}
            >
              {main.value}
            </div>
            <div
              className={css({
                fontSize: responsiveFontSizes.secondary,
                color: "positionContentAlt",
              })}
            >
              {main.label}
            </div>
          </div>
        )}
        <div className={css({ flexGrow: 1 })} />

        {secondary && (
          <div
            className={css({
              marginTop: "auto",
              fontSize: responsiveFontSizes.secondary,
            })}
          >
            {secondary}
          </div>
        )}
      </section>
    </a.a>
  );
});
