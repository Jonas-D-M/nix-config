#!/usr/bin/env node
// Claude Code statusline — vendored, GSD-free.
// Shows: model · current task (from todos) · directory · context-usage bar ·
// subscription usage.
// Derived from the GSD statusline, stripped of all GSD-specific behaviour
// (planning-state reader, update-check, and the context-monitor bridge file).

const fs = require("fs");
const path = require("path");
const os = require("os");

// Nerd Font Material Design battery glyphs, empty → full (10% steps).
// Verify these render in your terminal before relying on them; the Material
// Design block moved wholesale in Nerd Fonts v3.
const BATT = [
  "\u{F008E}",
  "\u{F007A}",
  "\u{F007B}",
  "\u{F007C}",
  "\u{F007D}",
  "\u{F007E}",
  "\u{F007F}",
  "\u{F0080}",
  "\u{F0081}",
  "\u{F0082}",
  "\u{F0079}",
];

// Nerd Font Material Design clock, marking the rate-limit window reset time.
// Deliberately NOT U+21BB (↻): that codepoint is absent from JetBrainsMono Nerd
// Font, so terminals silently substitute it from a fallback face and it lands at
// the wrong weight and width beside the battery. Staying inside the Material
// Design block keeps both glyphs from the same design family.
const CLOCK = "\u{F0150}";

// Material Design skull, shown once context usage is critical. Replaces a 💀
// emoji: that was double-width and drawn from the system colour-emoji face, so
// it shifted the whole line's alignment the moment it appeared.
const SKULL = "\u{F068C}";

// Segment divider. Dimmed on purpose — previously the pipes were emitted bare
// after a reset, so they rendered at full foreground brightness while the
// content around them was dim, making the dividers louder than the data.
const SEP = " \x1b[2m·\x1b[0m ";

// Bar cells: heavy rule for consumed, light rule for remaining. Not █/░ — ten
// light-shade blocks have near-full cell coverage in JetBrains Mono and merge
// into one solid slab, which read as a filled bar at 0% usage.
const BAR_FULL = "━";
const BAR_EMPTY = "─";
const BAR_WIDTH = 10;

// Continuous green → amber → red ramp keyed on usage percentage.
const lerp = (a, b, t) => Math.round(a + (b - a) * t);
function usageColor(pct) {
  const t = pct < 50 ? pct / 50 : (pct - 50) / 50;
  const [r, g, b] =
    pct < 50
      ? [lerp(0, 220, t), lerp(200, 180, t), lerp(80, 0, t)]
      : [220, lerp(180, 40, t), lerp(0, 40, t)];
  return `\x1b[38;2;${r};${g};${b}m`;
}

function runStatusline() {
  let input = "";
  // Timeout guard: if stdin doesn't close within 3s (e.g. pipe issues on
  // Windows/Git Bash), exit silently instead of hanging.
  const stdinTimeout = setTimeout(() => process.exit(0), 3000);
  process.stdin.setEncoding("utf8");
  process.stdin.on("data", (chunk) => (input += chunk));
  process.stdin.on("end", () => {
    clearTimeout(stdinTimeout);
    try {
      const data = JSON.parse(input);
      const model = data.model?.display_name || "Claude";
      const dir = data.workspace?.current_dir || process.cwd();
      const session = data.session_id || "";
      const remaining = data.context_window?.remaining_percentage;

      // Context window display (shows USED percentage scaled to usable context).
      // Claude Code reserves a buffer for autocompact — ~16.5% of the window by
      // default, overridable via CLAUDE_CODE_AUTO_COMPACT_WINDOW (a token count).
      const totalCtx = data.context_window?.total_tokens || 1_000_000;
      const acw = parseInt(
        process.env.CLAUDE_CODE_AUTO_COMPACT_WINDOW || "0",
        10,
      );
      const AUTO_COMPACT_BUFFER_PCT =
        acw > 0 ? Math.min(100, (acw / totalCtx) * 100) : 16.5;
      let ctx = "";
      if (remaining != null) {
        // Normalize: subtract buffer from remaining, scale to usable range.
        const usableRemaining = Math.max(
          0,
          ((remaining - AUTO_COMPACT_BUFFER_PCT) /
            (100 - AUTO_COMPACT_BUFFER_PCT)) *
            100,
        );
        const used = Math.max(
          0,
          Math.min(100, Math.round(100 - usableRemaining)),
        );

        // Build progress bar. Any non-zero usage claims at least one cell, so an
        // all-empty bar unambiguously means "nothing used yet" rather than
        // "under 10% and rounded away".
        const filled =
          used > 0 ? Math.max(1, Math.floor((used / 100) * BAR_WIDTH)) : 0;
        const bar =
          BAR_FULL.repeat(filled) + BAR_EMPTY.repeat(BAR_WIDTH - filled);

        // Color based on usable context thresholds.
        if (used < 50) {
          ctx = `\x1b[32m${bar} ${used}%\x1b[0m`;
        } else if (used < 65) {
          ctx = `\x1b[33m${bar} ${used}%\x1b[0m`;
        } else if (used < 80) {
          ctx = `\x1b[38;5;208m${bar} ${used}%\x1b[0m`;
        } else {
          ctx = `\x1b[5;31m${SKULL} ${bar} ${used}%\x1b[0m`;
        }
      }

      // Subscription usage — 5-hour rolling window, with a countdown to reset.
      // Data is absent for non-subscribers and until the first API response of a
      // session; always render the segment (with a dim placeholder) so the
      // statusline layout stays stable instead of flickering fields in and out.
      //
      // The battery DRAINS as usage climbs: full+green means budget remaining,
      // empty+red means the window is nearly spent.
      let usage;
      const w = data.rate_limits?.five_hour;
      if (w && w.used_percentage != null) {
        const pct = Math.max(0, Math.min(100, Math.round(w.used_percentage)));
        const icon = BATT[Math.round((100 - pct) / 10)];
        const blink = pct >= 97 ? "\x1b[5m" : "";

        // Local wall-clock time the window resets (resets_at is Unix epoch seconds).
        let reset = "";
        if (w.resets_at) {
          const d = new Date(w.resets_at * 1000);
          const hh = String(d.getHours()).padStart(2, "0");
          const mm = String(d.getMinutes()).padStart(2, "0");
          reset = ` ${CLOCK} ${hh}:${mm}`;
        }

        usage = `${blink}${usageColor(pct)}${icon} ${pct}%${reset}\x1b[0m`;
      } else {
        usage = `\x1b[2m${BATT[10]} --%\x1b[0m`;
      }

      // Current task from the in-progress todo, if any.
      let task = "";
      const homeDir = os.homedir();
      const claudeDir =
        process.env.CLAUDE_CONFIG_DIR || path.join(homeDir, ".claude");
      const todosDir = path.join(claudeDir, "todos");
      if (session && fs.existsSync(todosDir)) {
        try {
          const files = fs
            .readdirSync(todosDir)
            .filter(
              (f) =>
                f.startsWith(session) &&
                f.includes("-agent-") &&
                f.endsWith(".json"),
            )
            .map((f) => ({
              name: f,
              mtime: fs.statSync(path.join(todosDir, f)).mtime,
            }))
            .sort((a, b) => b.mtime - a.mtime);

          if (files.length > 0) {
            try {
              const todos = JSON.parse(
                fs.readFileSync(path.join(todosDir, files[0].name), "utf8"),
              );
              const inProgress = todos.find((t) => t.status === "in_progress");
              if (inProgress) task = inProgress.activeForm || "";
            } catch (e) {}
          }
        } catch (e) {
          // Silently fail on filesystem errors — don't break the statusline.
        }
      }

      // Output — join present fields with a consistent separator so every
      // segment aligns the same way.
      const dirname = path.basename(dir);
      const segments = [`\x1b[2m${model}\x1b[0m`];
      if (task) segments.push(`\x1b[1m${task}\x1b[0m`);
      segments.push(`\x1b[2m${dirname}\x1b[0m`);
      if (ctx) segments.push(ctx);
      segments.push(usage);
      process.stdout.write(segments.join(SEP));
    } catch (e) {
      // Silent fail — don't break the statusline on parse errors.
    }
  });
}

if (require.main === module) runStatusline();
