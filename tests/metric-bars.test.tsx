import React from "react";
import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { MetricBars } from "@/components/MetricBars";

describe("MetricBars", () => {
  it("hides labels by default and reveals selected bar details on tap", () => {
    render(
      <MetricBars
        bars={[
          { id: "focus", value: 74, color: "#00b4d8", revealed: false },
          { id: "momentum", value: 52, color: "#ff9f1c", revealed: false },
          { id: "progress", value: 36, color: "#2a9d8f", revealed: false }
        ]}
      />
    );

    expect(screen.queryByText(/Focus\s+74%/)).not.toBeInTheDocument();
    const focusButton = screen.getByRole("button", { name: "Focus metric" });
    fireEvent.click(focusButton);
    expect(screen.getByText("Focus 74%")).toBeInTheDocument();
  });
});
