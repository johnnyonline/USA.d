import type { Address, Position, PositionLoanUncommitted } from "@/src/types";
import type { ReactNode } from "react";

import content from "@/src/content";
import { ACCOUNT_POSITIONS } from "@/src/demo-mode";
import { DEMO_MODE } from "@/src/env";
import { getCardDimensions, getResponsiveColumns, useViewport } from "@/src/hooks/useViewport";
import { useStakePosition } from "@/src/liquity-utils";
import { useEarnPositionsByAccount, useLoansByAccount } from "@/src/subgraph-hooks";

import { css } from "@/styled-system/css";
import { a, useSpring, useTransition } from "@react-spring/web";
import * as dn from "dnum";
import { useEffect, useRef, useState } from "react";
import { match, P } from "ts-pattern";
import { EmptyPositionCard } from "./EmptyPositionCard";
import { NewPositionCard } from "./NewPositionCard";
import { PositionCard } from "./PositionCard";
import { PositionCardEarn } from "./PositionCardEarn";
import { PositionCardLoan } from "./PositionCardLoan";
import { PositionCardStake } from "./PositionCardStake";

type Mode = "positions" | "loading" | "actions";

export function Positions({
  address,
  columns,
  showNewPositionCard = true,
  title = (mode) => (
    mode === "loading"
      ? " "
      : mode === "positions"
      ? content.home.myPositionsTitle
      : content.home.openPositionTitle
  ),
}: {
  address: null | Address;
  columns?: number;
  showNewPositionCard?: boolean;
  title?: (mode: Mode) => ReactNode;
}) {
  const loans = useLoansByAccount(address);
  const earnPositions = useEarnPositionsByAccount(address);
  const stakePosition = useStakePosition(address);

  const isPositionsPending = Boolean(
    address && (
      loans.isPending
      || earnPositions.isPending
      || stakePosition.isPending
    ),
  );

  const positions = isPositionsPending ? [] : (
    DEMO_MODE ? ACCOUNT_POSITIONS : [
      ...loans.data ?? [],
      ...earnPositions.data ?? [],
      ...stakePosition.data && dn.gt(stakePosition.data.deposit, 0) ? [stakePosition.data] : [],
    ]
  );

  let mode: Mode = address && positions && positions.length > 0
    ? "positions"
    : isPositionsPending
    ? "loading"
    : "actions";

  // preloading for 1 second, prevents flickering
  // since the account doesn't reconnect instantly
  const [preLoading, setPreLoading] = useState(true);
  useEffect(() => {
    const timer = setTimeout(() => {
      setPreLoading(false);
    }, 500);
    return () => clearTimeout(timer);
  }, []);

  if (preLoading) {
    mode = "loading";
  }

  return (
    <PositionsGroup
      columns={columns}
      mode={mode}
      positions={positions ?? []}
      showNewPositionCard={showNewPositionCard}
      title={title}
    />
  );
}

function PositionsGroup({
  columns = 3,
  mode,
  onTitleClick,
  positions,
  title,
  showNewPositionCard,
}: {
  columns?: number;
  mode: Mode;
  onTitleClick?: () => void;
  positions: Exclude<Position, PositionLoanUncommitted>[];
  title: (mode: Mode) => ReactNode;
  showNewPositionCard: boolean;
}) {
  const title_ = title(mode);
  const viewport = useViewport();

  // Get responsive columns based on viewport
  const responsiveColumns = getResponsiveColumns(viewport, mode, columns);

  // Get responsive card dimensions
  const { height: cardHeight } = getCardDimensions(viewport, mode);

  const cards = match(mode)
    .returnType<Array<[number, ReactNode]>>()
    .with("positions", () => {
      let cards: Array<[number, ReactNode]> = [];

      if (showNewPositionCard) {
        cards.push([positions.length ?? -1, <NewPositionCard key="new" />]);
      }

      cards = cards.concat(
        positions.map((position, index) => (
          match(position)
            .returnType<[number, ReactNode]>()
            .with({ type: P.union("borrow", "multiply") }, (p) => [
              index,
              <PositionCardLoan key={index} {...p} />,
            ])
            .with({ type: "earn" }, (p) => [
              index,
              <PositionCardEarn key={index} {...p} />,
            ])
            .with({ type: "stake" }, (p) => [
              index,
              <PositionCardStake key={index} {...p} />,
            ])
            .exhaustive()
        )) ?? [],
      );

      return cards;
    })
    .with("loading", () => [
      [0, <PositionCard key="0" loading />],
      [1, <PositionCard key="1" loading />],
      [2, <PositionCard key="2" loading />],
    ])
    .with("actions", () =>
      showNewPositionCard
        ? [[0, <EmptyPositionCard key="empty" />]]
        : [])
    .exhaustive();

  if (mode === "actions") {
    columns = 1;
  }

  const containerHeight = mode === "actions"
    ? "auto"
    : "auto";

  const positionTransitions = useTransition(cards, {
    keys: ([index]) => `${mode}${index}`,
    from: {
      display: "none",
      opacity: 0,
      transform: "scale(0.9)",
    },
    enter: {
      display: "grid",
      opacity: 1,
      transform: "scale(1)",
    },
    leave: {
      display: "none",
      opacity: 0,
      transform: "scale(1)",
      immediate: true,
    },
    config: {
      mass: 1,
      tension: 1600,
      friction: 120,
    },
  });

  const animateHeight = useRef(false);
  if (mode === "loading") {
    animateHeight.current = true;
  }

  const containerSpring = useSpring({
    initial: { height: mode === "actions" ? "auto" : cardHeight },
    from: { height: mode === "actions" ? "auto" : cardHeight },
    to: { height: containerHeight },
    immediate: !animateHeight.current || mode === "loading" || mode === "actions",
    config: {
      mass: 1,
      tension: 2400,
      friction: 100,
    },
  });

  return (
    <div>
      {title_ && (
        <h1
          className={css({
            fontSize: {
              base: 24,
              small: 28,
              medium: 32,
            },
            color: "content",
            userSelect: "none",
            paddingBottom: {
              base: 24,
              small: 28,
              medium: 32,
            },
          })}
          onClick={onTitleClick}
        >
          {title_}
        </h1>
      )}
      <a.div
        className={css({
          position: "relative",
        })}
        style={{
          ...containerSpring,
        }}
      >
        <a.div
          className={css({
            display: "grid",
            gap: {
              base: "24px",
              small: "28px",
              medium: "32px",
            },
            width: mode === "actions" ? "100%" : "auto",
          })}
          style={{
            gridTemplateColumns: mode === "actions"
              ? "1fr"
              : `repeat(${responsiveColumns}, 1fr)`,
            gridAutoRows: mode === "actions" ? "auto" : "auto",
          }}
        >
          {positionTransitions((style, [_, card]) => (
            <a.div
              className={css({
                display: "grid",
                height: "auto",
                width: "100%",
                willChange: "transform, opacity",
              })}
              style={style}
            >
              {card}
            </a.div>
          ))}
        </a.div>
      </a.div>
    </div>
  );
}
