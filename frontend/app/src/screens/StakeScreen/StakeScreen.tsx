"use client";

import { Amount } from "@/src/comps/Amount/Amount";
import { Field } from "@/src/comps/Field/Field";
import { InputTokenBadge } from "@/src/comps/InputTokenBadge/InputTokenBadge";
import { Screen } from "@/src/comps/Screen/Screen";
import { StakePositionSummary } from "@/src/comps/StakePositionSummary/StakePositionSummary";
import content from "@/src/content";
import { dnumMax } from "@/src/dnum-utils";
import { parseInputFloat } from "@/src/form-utils";
import { fmtnum } from "@/src/formatting";
import { useStakePosition } from "@/src/liquity-utils";
import { useAccount, useBalance } from "@/src/services/Ethereum";
import { usePrice } from "@/src/services/Prices";
import { useTransactionFlow } from "@/src/services/TransactionFlow";
import { infoTooltipProps } from "@/src/uikit-utils";
import { css } from "@/styled-system/css";
import {
  AnchorTextButton,
  Button,
  HFlex,
  InfoTooltip,
  InputField,
  Tabs,
  TextButton,
  TokenIcon,
  VFlex,
} from "@liquity2/uikit";
import * as dn from "dnum";
import { useParams, useRouter } from "next/navigation";
import { useState } from "react";
import { PanelRewards } from "./PanelRewards";
import { PanelVoting } from "./PanelVoting";

const TABS = [
  { label: content.stakeScreen.tabs.deposit, id: "deposit" },
  { label: content.stakeScreen.tabs.rewards, id: "rewards" },
  { label: content.stakeScreen.tabs.voting, id: "voting" },
];

export function StakeScreen() {
  const router = useRouter();
  const { action = "deposit" } = useParams();
  const account = useAccount();
  const stakePosition = useStakePosition(account.address ?? null);

  return (
    <Screen
      heading={{
        title: (
          <HFlex>
            {content.stakeScreen.headline(<TokenIcon size={24} symbol="LQTY" />)}
          </HFlex>
        ),
        subtitle: (
          <>
            {content.stakeScreen.subheading}{" "}
            <AnchorTextButton
              label={content.stakeScreen.learnMore[1]}
              href={content.stakeScreen.learnMore[0]}
              external
            />
          </>
        ),
      }}
      gap={48}
    >
      <StakePositionSummary
        stakePosition={stakePosition.data ?? null}
      />
      <VFlex gap={24}>
        <Tabs
          items={TABS.map(({ label, id }) => ({
            label,
            panelId: `p-${id}`,
            tabId: `t-${id}`,
          }))}
          selected={TABS.findIndex(({ id }) => id === action)}
          onSelect={(index) => {
            router.push(`/stake/${TABS[index].id}`, { scroll: false });
          }}
        />

        {action === "deposit" && <PanelUpdateStake />}
        {action === "rewards" && <PanelRewards />}
        {action === "voting" && <PanelVoting />}
      </VFlex>
    </Screen>
  );
}

function PanelUpdateStake() {
  const account = useAccount();
  const txFlow = useTransactionFlow();
  const lqtyPrice = usePrice("LQTY");

  const [mode, setMode] = useState<"deposit" | "withdraw">("deposit");
  const [value, setValue] = useState("");
  const [focused, setFocused] = useState(false);

  const stakePosition = useStakePosition(account.address ?? null);

  const parsedValue = parseInputFloat(value);

  const value_ = (focused || !parsedValue || dn.lte(parsedValue, 0))
    ? value
    : `${dn.format(parsedValue)}`;

  const depositDifference = dn.mul(
    parsedValue ?? dn.from(0, 18),
    mode === "withdraw" ? -1 : 1,
  );

  const updatedDeposit = stakePosition.data?.deposit
    ? dnumMax(
      dn.add(stakePosition.data?.deposit, depositDifference),
      dn.from(0, 18),
    )
    : dn.from(0, 18);

  const hasDeposit = stakePosition.data?.deposit && dn.gt(stakePosition.data?.deposit, 0);

  const updatedShare = stakePosition.data?.totalStaked && dn.gt(stakePosition.data?.totalStaked, 0)
    ? dn.div(updatedDeposit, dn.add(stakePosition.data.totalStaked, depositDifference))
    : dn.from(0, 18);

  const lqtyBalance = useBalance(account.address, "LQTY");

  const allowSubmit = Boolean(account.isConnected && parsedValue && dn.gt(parsedValue, 0));

  const rewardsLusd = dn.from(0, 18);
  const rewardsEth = dn.from(0, 18);

  return (
    <>
      <Field
        field={
          <InputField
            id="input-staking-change"
            contextual={
              <InputTokenBadge
                background={false}
                icon={<TokenIcon symbol="LQTY" />}
                label="LQTY"
              />
            }
            label={{
              start: mode === "withdraw" ? "You withdraw" : "You deposit",
              end: (
                <Tabs
                  compact
                  items={[
                    { label: "Deposit", panelId: "panel-deposit", tabId: "tab-deposit" },
                    { label: "Withdraw", panelId: "panel-withdraw", tabId: "tab-withdraw" },
                  ]}
                  onSelect={(index, { origin, event }) => {
                    setMode(index === 1 ? "withdraw" : "deposit");
                    setValue("");
                    if (origin !== "keyboard") {
                      event.preventDefault();
                      (event.target as HTMLElement).focus();
                    }
                  }}
                  selected={mode === "withdraw" ? 1 : 0}
                />
              ),
            }}
            labelHeight={32}
            onFocus={() => setFocused(true)}
            onChange={setValue}
            onBlur={() => setFocused(false)}
            value={value_}
            placeholder="0.00"
            secondary={{
              start: parsedValue && lqtyPrice.data ? `$${dn.format(dn.mul(parsedValue, lqtyPrice.data), 2)}` : null,
              end: mode === "deposit"
                ? (
                  <TextButton
                    label={`Max. ${(fmtnum(lqtyBalance.data ?? 0))} LQTY`}
                    onClick={() => {
                      setValue(dn.toString(lqtyBalance.data ?? dn.from(0, 18)));
                    }}
                  />
                )
                : (
                  stakePosition.data?.deposit && (
                    <TextButton
                      label={`Max. ${fmtnum(stakePosition.data.deposit, 2)} LQTY`}
                      onClick={() => {
                        setValue(dn.toString(stakePosition.data.deposit));
                      }}
                    />
                  )
                ),
            }}
          />
        }
        footer={{
          start: (
            <Field.FooterInfo
              label="New voting power"
              value={
                <HFlex>
                  <div>
                    <Amount value={updatedShare} percentage suffix="%" />
                  </div>
                  <InfoTooltip>
                    Voting power is the percentage of the total staked LQTY that you own.
                  </InfoTooltip>
                </HFlex>
              }
            />
          ),
        }}
      />
      <div
        className={css({
          display: "flex",
          justifyContent: "center",
          flexDirection: "column",
          gap: 24,
          width: "100%",
          paddingTop: 16,
        })}
      >
        {hasDeposit && (
          <HFlex justifyContent="space-between">
            <div
              className={css({
                display: "flex",
                alignItems: "center",
                gap: 8,
              })}
            >
              <label
                className={css({
                  display: "flex",
                  alignItems: "center",
                  gap: 8,
                  cursor: "pointer",
                  userSelect: "none",
                })}
              >
                {content.stakeScreen.depositPanel.rewardsLabel}
              </label>
              <InfoTooltip
                {...infoTooltipProps(content.stakeScreen.infoTooltips.alsoClaimRewardsDeposit)}
              />
            </div>
            <div
              className={css({
                display: "flex",
                gap: 24,
              })}
            >
              <div>
                <Amount value={rewardsLusd} />{" "}
                <span
                  className={css({
                    color: "contentAlt",
                  })}
                >
                  LUSD
                </span>
              </div>
              <div>
                <Amount value={rewardsEth} />{" "}
                <span
                  className={css({
                    color: "contentAlt",
                  })}
                >
                  ETH
                </span>
              </div>
            </div>
          </HFlex>
        )}
        <Button
          disabled={!allowSubmit}
          label="Next: Summary"
          mode="primary"
          size="large"
          wide
          onClick={() => {
            if (account.address) {
              txFlow.start({
                flowId: mode === "deposit" ? "stakeDeposit" : "unstakeDeposit",
                backLink: [`/stake`, "Back to stake position"],
                successLink: ["/", "Go to the Dashboard"],
                successMessage: "The stake position has been updated successfully.",

                lqtyAmount: dn.abs(depositDifference),
                stakePosition: {
                  type: "stake",
                  owner: account.address,
                  deposit: updatedDeposit,
                  share: updatedShare,
                  totalStaked: dn.add(
                    stakePosition.data?.totalStaked ?? dn.from(0, 18),
                    depositDifference,
                  ),
                  rewards: {
                    eth: rewardsEth,
                    lusd: rewardsLusd,
                  },
                },
                prevStakePosition: stakePosition.data
                    && dn.gt(stakePosition.data.deposit, 0)
                  ? stakePosition.data
                  : null,
              });
            }
          }}
        />
      </div>
    </>
  );
}
