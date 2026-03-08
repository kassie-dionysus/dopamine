"use client";

import React from "react";
import { useState } from "react";
import type { BarState, MetricId } from "@/lib/types";

const LABELS: Record<MetricId, string> = {
  focus: "Focus",
  momentum: "Momentum",
  progress: "Progress"
};

interface MetricBarsProps {
  bars: BarState[];
}

export function MetricBars({ bars }: MetricBarsProps) {
  const [revealedId, setRevealedId] = useState<MetricId | null>(null);

  return (
    <section className="metric-strip" aria-label="Metrics">
      {bars.map((bar) => {
        const isRevealed = revealedId === bar.id;
        return (
          <button
            className="metric-bar"
            key={bar.id}
            style={{ ["--bar-color" as string]: bar.color, ["--bar-width" as string]: `${bar.value}%` }}
            onClick={() => setRevealedId(isRevealed ? null : bar.id)}
            type="button"
            aria-label={`${LABELS[bar.id]} metric`}
          >
            <span className="metric-fill" />
            {isRevealed ? <span className="metric-reveal">{LABELS[bar.id]} {Math.round(bar.value)}%</span> : null}
          </button>
        );
      })}
    </section>
  );
}
