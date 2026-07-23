# CHANGELOG

## 0.0.4

- Add fullscreen component

## 0.0.3

- SideSplitLayout: Add `SidePanel.keepAlive` to preserve panel state after closing
- SideSplitLayout: Expose `panelAnimationDuration` and `panelAnimationCurve` with defaults `200ms` and `Curves.easeOutCubic`
- SideSplitLayout: Animate panel width during open, close, and continuous A-to-B transitions
- SideSplitLayout: Keep controlled `selectedIndex` changes stable while width animation is running
- Tests: Cover keep-alive state retention, custom animation config, continuous A-to-B width animation, and controlled mode animation stability
- Example: Update SideSplitLayout demo to showcase draft preservation, continuous A-to-B width animation, and controlled-mode stability

## 0.0.2

- SideSplitLayout: Add initialSelectedIndex (uncontrolled initial active panel)
- SideSplitLayout: Stabilize toggle behavior on fast repeated taps in controlled mode
- Example: Update SideSplitLayoutDemo to use initialSelectedIndex and keep label in sync
- Example: Adjust default proportional size in SplitLayoutDemo
- Tests: Add coverage for initialSelectedIndex and controlled repeated taps

## 0.0.1

- SideSplitLayout
- SplitLayout
