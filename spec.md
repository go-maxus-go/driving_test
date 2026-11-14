# Product & UX Specification: German Driving Theory Exam Trainer (Klasse B)

> **Role:** Principal UX Designer & Product Architect  
> **Target Platform:** Cross-platform Flutter Application (Mobile-first Portrait, Responsive Tablet/Desktop Split-View, Offline-First)  
> **Dataset Baseline:** Official German Class B Catalog (`assets/driving_theory_questions_b.json` — **1,592 questions** across **14 Themes** and **92 Chapters**, including **464 static-image questions**, **225 cockpit-video questions** with end-frame freeze images, **57 numeric-input questions**, **8 three-sign visual-option questions**, and **276 `-M` visual-variant mother questions**).  
> **Authentication:** None. 100% local-first, zero-registration, instant-launch experience.

---

## 1. High-Level Overview & Product Vision

Preparing for the German theoretical driving exam (*Theoretische Führerscheinprüfung Klasse B* at TÜV or DEKRA) is a high-stakes, rule-dense milestone. Learners must master **1,592 official questions** where:
- Any multiple-choice question can have **1, 2, or all 3 answers correct**—missing a single ticked box or ticking one extra box yields **zero partial credit** and full *Fehlerpunkte* (2 to 5 error points).
- Answering **two 5-point questions wrong** causes an **instant exam failure** even though $5 + 5 = 10$ error points normally falls within the 10-point allowance.
- **Video hazard questions** follow strict, unforgiving exam-day playback rules (maximum 5 viewings *before* seeing the question text and options; zero replays once the question is revealed).

### Core UX North Star
Build **the fastest, calmest, most ergonomic German driving theory trainer ever made**—an app that respects the learner's time on a 4-minute U-Bahn ride just as well as during a 45-minute Sunday afternoon mock exam.

### Four Foundational Design Pillars
1. **Zero-Ceremony Entry:** No splash-screen carousels, no sign-up walls, no cloud accounts, no "choose a plan" modals. First app open lands directly on the actionable Training Cockpit.
2. **Muscle-Memory Ergonomics:** Every answer option is a full-width single-tap card in the natural thumb zone. The primary action button (*Check Answer* $\rightarrow$ *Next Question*) stays anchored at the **exact same screen coordinates**, allowing effortless single-thumb rhythm on mobile and single-key (`Space`/`Enter` + `1`/`2`/`3`) flow on desktop.
3. **Diagnostic Clarity Over Gamified Noise:** When a user makes a mistake, they immediately see *what they picked that was wrong*, *what correct answer they missed*, and *why*—without celebratory confetti animations slowing down 50-question study sprints.
4. **Zero Exam-Day Surprises:** Practice Mode optimizes for learning speed and video scrubbing; Exam Mode faithfully enforces official TÜV/DEKRA Class B rules (30 questions, 45:00 timer, 20 *Grundstoff* + 10 *Zusatzstoff*, 10-point / two-5-point fail rule, 5x pre-question video lock).

---

## 2. UX Brainstorming & Concept Selection

Before converging on our architecture, we explored four distinct UX paradigms and brainstormed high-leverage features tailored to German driving learners.

### 2.1 Architectural Concepts Explored

#### Concept A: Classic Hierarchical Catalog ("The Digital Textbook")
- **How it works:** Opens to a tree of 14 Themes and 92 Chapters (`1.1 Danger Teaching` $\rightarrow$ `1.1.01 Basic Forms...`), mimicking traditional driving school workbooks.
- **Pros:** Predictable structure; aligns with evening *Theorieunterricht* lessons at the *Fahrschule*.
- **Cons:** High decision fatigue on launch (3–4 taps just to reach Question 1); poor cross-topic retention; users over-study `1.1` and neglect `2.7 Technology`.

#### Concept B: Linear Gamified Skill-Tree ("The Duolingo Path")
- **How it works:** Locks topics into sequential nodes with hearts, XP gems, streaks, and mascot animations.
- **Pros:** Approachable for reluctant learners; clear sense of "what to do next."
- **Cons:** Artificial locking frustrates learners who want to drill *Priority (`1.3`)* before tomorrow's driving lesson; celebratory transitions waste 2–3 seconds per question (adding 50+ minutes of dead time across 1,592 questions).

#### Concept C: Minimalist Endless Deck ("Anki / Tinder Swipe")
- **How it works:** Opens straight into a full-screen question stream powered purely by spaced repetition.
- **Pros:** Zero-click entry; maximal focus on questions.
- **Cons:** Opaque progress ("When am I actually ready for TÜV?"); weak support for targeted topic study or structured 30-question exam simulations; swipe gestures conflict with multi-select German questions.

#### Concept D (SELECTED): The Adaptive "Fahrschul-Cockpit" + Dual-Mode Ergonomic Player
- **How it works:** Combines a **1-Tap Smart Cockpit Home** with a **3-Tab Shallow Navigation Bar** (*Train*, *Topics*, *Progress*) and a **Fixed-Thumb-Zone Question Player**.
  - The Home Cockpit surfaces an honest **Exam Readiness Gauge**, a giant **1-Tap Smart Session CTA** (auto-blending unseen, low-exposure, and mistake-prone questions), **1-Tap Smart Filter Pills** (*Frequent Mistakes*, *Least Answered*, *5-Point Traps*, *Videos*, *Numbers*), and a **1-Tap Exam Simulation launcher**.
  - Learners who want structured study switch to **Topics** in 1 tap and launch any Theme or Chapter immediately.
- **Why Concept D Wins:** It delivers **1-tap entry** like Concept C, **full catalog control** like Concept A, and **adaptive guidance** like Concept B—with zero gamified bloat.

| Evaluation Criterion | A: Catalog Tree | B: Gamified Path | C: Endless Deck | **D: Adaptive Cockpit (Winner)** |
| :--- | :---: | :---: | :---: | :---: |
| Taps to answer 1st question | 3–4 taps | 2–3 taps | **0–1 taps** | **1 tap** |
| Mistake & Low-Exposure Drilling | Manual | Hidden | Automatic only | **1-Tap Smart Pills + Auto** |
| Topic-Specific Study | Excellent | Poor (Locked) | Weak | **Excellent (1-Tap Topics Tab)** |
| Honest TÜV Readiness Clarity | Low | Medium (XP != Pass) | Low | **High (Readiness % + Mock Pass Rate)** |
| Speed per 50-Question Sprint | Fast | Slow (Animations) | Fast | **Fastest (Fixed-Coordinate CTA)** |

---

### 2.2 Brainstormed High-Impact Features for the German Exam

Beyond the core requirements, we evaluated domain-specific pain points of Class B candidates in Germany and selected the highest-ROI features to include in the design:

1. **3-Stage Mastery & "Trouble Questions" (*Problemkinder*) Engine (Included):**
   - Simply answering a question right once can be a lucky guess. Each question moves through **Unseen** $\rightarrow$ **Learning (1x right)** $\rightarrow$ **Mastered (2x consecutive right)**. Any wrong answer immediately tags the question as a **Mistake** and resets consecutive streak to `0` (requiring 2 consecutive correct answers to clear).
2. **Smart Drill Presets: "Most Mistakes" & "Least Answered" (Included — Core + Enhanced):**
   - Dedicated 1-tap smart queues on the Home Cockpit for **Mistakes** (sorted by highest mistake-to-attempt ratio & recent failures) and **Least Answered** (prioritizing `0`-attempt unseen questions first, then `1`-attempt questions).
3. **"5-Point Instant-Fail Trap" Drill (Included):**
   - Because getting just *two* 5-point questions wrong fails the German exam, a dedicated 1-tap **5-Point Questions** filter lets learners bulletproof the highest-risk items (`Right-of-Way`, `Cockpit Hazards`, `Braking`).
4. **Dual-Behavior Video Player: "Exam Realism" vs. "Practice Scrubbing" (Included):**
   - *Exam Mode:* Enforces official TÜV rules—up to 5 plays, no pause/scrub, and switching to the question permanently replaces the video with the final freeze-frame (`Standbild` from `local_image_paths`).
   - *Practice Mode:* Defaults to instant playback with option to toggle Exam-Style hidden question, **and** after submitting an answer, unlocks a **scrubbable video timeline + replay** so the learner can rewind and spot the hidden cyclist in the mirror!
5. **`-M` Mother-Question Variation Callout (Included):**
   - 276 questions in our catalog end with `-M` (*Mutterfrage*). On exam day, TÜV randomizes car colors, weather, or vehicle types (van vs. sedan) in these scenes so rote image memorizers fail. In Practice explanations, `-M` questions display a subtle **"Exam Variation Notice"** badge reminding learners to learn the *traffic rule*, not the red car's color.
6. **German/English Comma-Normalized Custom Numpad (Included):**
   - 57 questions require typing numbers (including decimals stored with German commas like `1,5`, `1,6`, `2,5`, `2,8`, `3,5`). Instead of triggering the OS keyboard (which shifts layout and mixes `.` vs `,`), the Question Player renders a clean inline **3x4 Ergonomic Numpad** where `.` and `,` are treated identically.
7. **Official "TÜV Classic" Exam Skin Toggle (Included as Optional Exam Setting):**
   - An optional switch inside Exam Mode that styles the 30-question navigator and bottom bar like the Spartan green/grey TÜV/DEKRA tablet software to eliminate exam-day visual anxiety.
8. **Quick Reference Drawer: Braking Formulas & Road Signs (Included in Topics Tab):**
   - Instant cheat-sheet cards for the 3 mandatory German formulas (*Reaktionsweg*: $(\text{Speed} \div 10) \times 3$; *Bremsweg*: $(\text{Speed} \div 10)^2$; *Gefahrenbremsung*: $\text{Bremsweg} \div 2$) and visual sign comparisons.
9. **Local JSON Backup Export/Import (Included in Progress Settings):**
   - Keeps the zero-account promise while preventing heartbreak if a user switches phones two days before their exam.

---

## 3. Information Architecture & Navigation Model

### 3.1 Top-Level Sitemap

```mermaid
flowchart TD
    Launch["App Launch (Zero Login / Instant Local Load)"] --> Shell["Main App Shell (3-Tab Bottom Nav / Side Rail)"]

    subgraph Shell["Main App Shell"]
        Tab1["1. Train (Home Cockpit)"]
        Tab2["2. Topics (14 Themes / 92 Chapters)"]
        Tab3["3. Progress (Readiness & Analytics)"]
    end

    Tab1 -->|"1 Tap: Smart Practice"| Player["Practice Question Player (Full-Screen Focus)"]
    Tab1 -->|"1 Tap: Mistakes / Least Answered / 5-Pt / Video / Numbers"| Player
    Tab1 -->|"1 Tap: Start Mock Exam"| Exam["Exam Simulation Player (30 Qs • 45:00)"]

    Tab2 -->|"1 Tap on any Theme or Chapter"| Player
    Tab2 -->|"Multi-Select Topics + Start"| Player
    Tab2 -->|"Reference Chip"| Ref["Formula & Sign Cheat-Sheet Modal"]

    Tab3 -->|"1 Tap on Weak Topic"| Player
    Tab3 -->|"1 Tap on Past Exam"| Verdict["Exam Verdict & Review Screen"]

    Exam -->|"Submit Exam / Timer = 00:00"| Verdict
    Verdict -->|"1 Tap: Practice Mistakes"| Player
    Verdict -->|"Tap any Question"| ExamReview["Read-Only Exam Question Inspector"]
```

### 3.2 Navigation Chrome Rules
- **3 Persistent Top-Level Destinations** (Bottom Navigation Bar on mobile portrait; Left Navigation Rail on tablet landscape / desktop $\ge 840\text{dp}$):
  1. **Train** (Icon: Steering wheel / Play bolt) — Default landing screen.
  2. **Topics** (Icon: Layered grid) — Full catalog of *Grundstoff* (`1.x`) and *Zusatzstoff Class B* (`2.x`).
  3. **Progress** (Icon: Readiness gauge / Chart) — Detailed metrics, weak-spot diagnosis, exam history, and local data backup.
- **Immersive Focus Rule:** Entering the **Practice Question Player** or **Exam Simulation Player** hides the bottom navigation bar completely so 100% of vertical real estate belongs to the traffic media, question, answer cards, and primary thumb CTA.
- **Instant Session Persistence:** Every tap in Practice or Exam mode saves locally in $<10\text{ms}$. Closing the app mid-question or mid-exam resumes seamlessly from a **"Resume Active Session (Q 14/30 • 28:14 left)"** banner on the Home Cockpit.

---

## 4. German Exam Rules & Smart Learning Mechanics

### 4.1 Catalog Structure (`1,592` Class B Questions)
| Section | Theme Prefix | Official Scope | Themes | Questions | Exam Weight |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **Grundstoff** (Basic Material) | `Theme 1.1` – `1.8` | General traffic rules, danger teaching, priority, road signs, environment | 7 | **823** | **20 questions** per exam |
| **Zusatzstoff Klasse B** (Class B Add-on) | `Theme 2.1` – `2.8` | Car-specific rules, technology, lighting, highways, dimensions/loads | 7 | **769** | **10 questions** per exam |
| **Total** | `1.x` + `2.x` | Complete Class B Question Pool | **14** (92 chapters) | **1,592** | **30 questions** per exam |

### 4.2 Question Formats Supported
Every screen layout adapts cleanly to all **5 structural variants** present in the official Class B dataset:
1. **Standard Text Multiple-Choice (892 questions):** Question text + 2 or 3 text options (`A`, `B`, `C`), where **1, 2, or 3** options are correct.
2. **Static Image + Multiple-Choice (456 questions):** High-detail traffic illustration/photo (`local_image_paths[0]`) + question text + 2 or 3 text options.
3. **3-Sign Visual Multiple-Choice (8 questions, e.g., `1.4.40-013`):** Question text + 3 road-sign images mapped directly onto Answer Cards `A`, `B`, `C` (where `option.text` is empty).
4. **Cockpit Video + Multiple-Choice (225 questions):** 10–15s animated 3D traffic video (`local_video_paths[0]`) paired with an end-of-scene freeze-frame image (`local_image_paths[0]`).
5. **Numeric Free-Input / *Zahleneingabefragen* (57 questions, e.g., `1.2.02-111`):** `options: []`; user enters an integer or 1-decimal value (`0` to `130`, e.g., `60` km/h or `1,6` mm tread depth) with unit suffix extracted/displayed clearly.

### 4.3 Authentic Exam Simulation Rules (TÜV / DEKRA Class B)
- **Question Generator:** Draws **30 unique questions** stratified realistically: **20 from Grundstoff (`1.x`)** and **10 from Zusatzstoff (`2.x`)**, matching official point-value distribution (typically ~110 total possible points across 2-, 3-, 4-, and 5-point items, including 2–3 video questions).
- **Time Limit:** **45:00 countdown timer**. Auto-submits when `00:00` is reached.
- **Scoring & Zero Partial Credit:**
  - A question awards **0 Fehlerpunkte** *only* if the user's selected set of options matches `correct_answers` **exactly** (or numeric value matches after `,`/`.` normalization).
  - Any discrepancy (1 missing correct option or 1 extra wrong option) adds the **entire question point value** (`2`, `3`, `4`, or `5` Fehlerpunkte).
- **Pass / Fail Conditions (First License / *Ersterwerb* — Default):**
  - **PASS (*Bestanden*):** Total Fehlerpunkte $\le 10$ **AND** fewer than two 5-point questions answered wrong.
  - **FAIL (*Nicht bestanden*):**
    - Reason A: Total Fehlerpunkte $\ge 11$, **OR**
    - Reason B (*Zwei-5-Punkte-Regel*): Total Fehlerpunkte $= 10$ caused by **two wrong 5-point questions**.
  - *(Optional Setting in Preferences: "License Extension / Erweiterung" mode lowers threshold to max **6 Fehlerpunkte**).*

### 4.4 Per-Question Local Tracking & Smart Queue Ranking
For every `question_id`, local storage maintains lightweight telemetry:
- `attempts_count` (int), `correct_count` (int), `wrong_count` (int)
- `consecutive_correct` (int — resets to `0` on any mistake)
- `last_answered_at` (timestamp), `last_outcome` (`correct` | `wrong` | `unseen`)
- `is_bookmarked` (bool)

This powers the two requested smart filters with deterministic, transparent sorting:
1. **"Most Mistakes" Filter (`Fehlertraining`):**
   - Includes any question with `wrong_count >= 1`.
   - **Sort order:**
     1. Currently unrecovered mistakes (`last_outcome == wrong` or `consecutive_correct < 2`) first,
     2. Highest mistake rate ($\frac{\text{wrong\_count}}{\text{attempts\_count}}$) + total `wrong_count`,
     3. Higher `points` weight (`5` $\rightarrow$ `2`).
2. **"Least Answered" Filter (`Wenig geübt & Neu`):**
   - Prioritizes under-practiced questions across the entire catalog (or within a chosen topic).
   - **Sort order:**
     1. Ascending `attempts_count` (`0` unseen questions first, then `1` attempt, then `2` attempts...),
     2. Oldest `last_answered_at` timestamp as tie-breaker,
     3. Shuffled within equal-count buckets so topics interleave naturally.

---

## 5. Ergonomics, Visual Design & Interaction System

### 5.1 Thumb-Zone & Fixed-Coordinate Action Architecture
On mobile portrait (`360–430dp` wide), the user holds the phone one-handed for 15–30 minutes at a time:
- **Top 15% (Glanceable Zone — Read-Only):** Exit button, live session score pill (`✓ 14   ✗ 2   ◷ 34 left`), points badge (`5 Pts`), bookmark star. Rarely tapped.
- **Upper-Middle 35% (Visual Media & Question Zone):** 16:9 image/video container + high-contrast question text (`18sp`–`20sp`, line-height `1.35`, max 65 chars/line). Tap image to zoom full-screen.
- **Lower-Middle 38% (Single-Tap Answer Zone):** Full-width answer cards (`min-height: 56dp`, `12dp` vertical gap, `16dp` horizontal padding). Tapping **anywhere** on the card toggles selection with crisp haptic feedback (`selectionClick`).
- **Bottom 12% (Fixed-Coordinate Primary CTA Zone):** Full-width `56dp`-tall primary button pinned above safe-area inset:
  - **Before submission:** Label is **`Check Answer`** (enabled as soon as $\ge 1$ option is selected or numeric input is non-empty; also supports an explicit subtle *"Skip"* icon button to the left).
  - **After submission:** The **exact same button** transforms in place into **`Next Question →`**.
  - **Ergonomic Payoff:** When a user answers correctly, their thumb does **not** move a single millimeter: `Tap Answer` $\rightarrow$ `Tap Check` $\rightarrow$ `Tap Next` (same spot!). When they answer **incorrectly**, a `350ms` micro-guard prevents accidental double-tap skipping before they notice the red highlight and auto-opened explanation!

### 5.2 Four-State Answer Highlighting System (Accessible & Colorblind-Safe)
Because German multiple-choice questions require distinguishing *wrongly ticked* options from *missed correct* options, color alone is never enough. Every card uses **Color + Border Style + Semantic Icon + Micro-Label**:

| Post-Submit Option State | Visual Border & Surface | Leading Badge / Icon | Trailing Micro-Label | Meaning to Learner |
| :--- | :--- | :--- | :--- | :--- |
| **1. Selected & Correct** *(True Positive)* | `2dp` Solid Emerald (`#15803D`), Soft Green Tint (`#DCFCE7` / dark `#052E16`) | Filled Green Checkbox + `✓` | **`Correct`** | You rightly selected this answer. |
| **2. Selected & Wrong** *(False Positive)* | `2dp` Solid Crimson (`#B91C1C`), Soft Red Tint (`#FEE2E2` / dark `#450A0A`), subtle text strikethrough | Filled Red Box + `✗` | **`Wrong choice`** | You ticked this, which cost you the question. |
| **3. Unselected & Correct** *(Missing Answer!)* | **`2dp` Dashed Amber-Green (`#D97706` / `#16A34A`)**, Warm Highlight Tint (`#FEF3C7` / dark `#422006`) | Outlined Check Ring + `!` | **`Missed!`** *(Pill)* | **Crucial:** This was ALSO right, and you forgot to select it! |
| **4. Unselected & Wrong** *(True Negative)* | `1dp` Muted Neutral (`#E5E7EB`), `55%` opacity | Empty Muted Checkbox | *(None)* | Correctly ignored; fades into background so eyes focus on states 1–3. |

### 5.3 Desktop, Tablet & Web Keyboard Ergonomics
On hardware-keyboard devices ($\ge 840\text{dp}$ wide split-screen layout: Media on Left 50%, Question + Answers + Explanation on Right 50%):
- `1`, `2`, `3` (or `A`, `B`, `C`): Toggle option A, B, C with a single keystroke.
- `Space` or `Enter`: Submit answer $\rightarrow$ press `Space` or `Enter` again to advance to Next Question.
- `R`: Replay video (when allowed) or zoom image.
- `B`: Bookmark/star question.
- **Result:** A power user on a laptop can complete 100 questions without ever touching the mouse or trackpad.

---

## 6. Detailed Screen-by-Screen Specifications

---

### Screen 1: Home / Training Cockpit (`Train` Tab)

**Purpose:** Instant orientation + 1-tap launch into the highest-value study mode. Zero clutter, zero login prompts.

#### Wireframe Layout (Mobile Portrait)
```text
┌──────────────────────────────────────────────────────────┐
│  🚗 Klasse B Trainer                        🌙  ⚙️       │
├──────────────────────────────────────────────────────────┤
│  [Optional Resume Banner — only if session paused]       │
│  ▶ Resume Mock Exam #4  (Q 18/30 • 24:10 left)    [Go]   │
├──────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────┐  │
│  │   ╭───────╮   EXAM READINESS: 68% (Almost Ready)   │  │
│  │  │  68%   │   ✓ 940 Mastered  •  ✗ 74 Mistakes     │  │
│  │   ╰───────╯   ○ 578 Unseen of 1,592 total          │  │
│  │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒░░░░░░░░░  (59% + 5% + 36%)     │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  ⚡ SMART PRACTICE                        [Start →]│  │
│  │  Adaptive mix: 8 mistakes • 12 unseen • 5 review   │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  TARGETED DRILLS (1 Tap to Start)                        │
│  ┌─────────────────────────┐ ┌─────────────────────────┐ │
│  │ ✗ Most Mistakes    (74) │ │ ○ Least Answered  (578) │ │
│  │ High error-rate items   │ │ Unseen & 1x-seen items  │ │
│  └─────────────────────────┘ └─────────────────────────┘ │
│  ┌─────────────────────────┐ ┌─────────────────────────┐ │
│  │ ⚠️ 5-Point Traps  (198) │ │ 🎬 Video Scenes   (225) │ │
│  │ Instant-fail risk       │ │ Cockpit hazard clips    │ │
│  └─────────────────────────┘ └─────────────────────────┘ │
│  [ 🔢 Number Input (57) ]  [ ★ Saved (19) ]              │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  ⏱️ EXAM SIMULATION (30 Qs • 45 min)      [Begin]  │  │
│  │  Official TÜV/DEKRA rules • Last score: 6 Pts ✓    │  │
│  └────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────┤
│      [ ⚡ Train ]       [ 📚 Topics ]    [ 📊 Progress ] │
└──────────────────────────────────────────────────────────┘
```

#### Component & Behavior Details
1. **Readiness Hero Card:**
   - Displays composite **Exam Readiness Score (`0%–100%`)** calculated from Catalog Mastery (`60%` weight: Mastered + 0.5 $\times$ Learning over 1,592) and Recent Mock Exam Performance (`40%` weight: passing last 3 mock exams with $\le 10$ Fehlerpunkte).
   - Shows global tri-metric summary right at the top: **Mastered/Correct (`✓`)**, **Active Mistakes (`✗`)**, and **Unseen/Remaining (`○`)**, backed by a 3-segment stacked progress bar.
   - Tapping the Readiness Card jumps directly to the **Progress** tab.
2. **Primary Hero Button — `⚡ Smart Practice`:**
   - Launches immediately into Question 1 of an adaptive endless/batched session (default 25 questions per batch with "Continue +25" at end, or exit anytime with zero lost progress).
   - Selection algorithm per 25 questions: `35%` Active Mistakes (due for recovery), `45%` Unseen / Least-Answered questions across balanced themes, `20%` Spaced-Repetition review of older Mastered items.
3. **Targeted Drills Grid (1-Tap Launchers):**
   - **`✗ Most Mistakes (count)`:** Launches immediately into the `Fehlertraining` queue sorted by highest error frequency & unrecovered status. Disabled/celebrated with a green *"0 Mistakes — All Clear!"* state if empty.
   - **`○ Least Answered (count)`:** Badge displays unseen count (`attempts == 0`), or total low-exposure count (`attempts <= 1`) once all 1,592 have been seen at least once. Tapping starts immediately from the least-practiced questions.
   - **`⚠️ 5-Point Traps`**, **`🎬 Video Scenes`**, **`🔢 Number Input`**, **`★ Saved`:** Instant 1-tap specialized practice queues.
4. **Exam Simulation Card (`⏱️ Exam Simulation`):**
   - 1 tap starts a fresh 30-question official Class B exam immediately (no intermediate "Are you sure?" dialog—an inline settings gear on the card lets advanced users toggle *45m Timer visibility*, *TÜV Classic Skin*, or *6-Point Extension Mode* if desired).

---

### Screen 2: Practice Question Player

**Purpose:** Ultra-fast, crystal-clear reading, single-tap selection, unmistakable feedback, and inline explanations.

#### Wireframe: State A (Answering) vs. State B (Submitted with Mistake / Missing Answer)
```text
STATE A: ANSWERING                                    STATE B: SUBMITTED (1 Missed, 1 Wrong)
┌──────────────────────────────────────────────────┐  ┌──────────────────────────────────────────────────┐
│ ✕   [ ✓ 12  •  ✗ 2  •  11 left ]     [4 Pts] ☆  │  │ ✕   [ ✓ 12  •  ✗ 3  •  10 left ]     [4 Pts] ☆  │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░ (15 / 25)          │  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░ (15 / 25)          │
├──────────────────────────────────────────────────┤  ├──────────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────────┐ │  │ ┌──────────────────────────────────────────────┐ │
│ │                                              │ │  │ │ [✗ Not quite — +4 Error Points]    [🔍 Zoom] │ │
│ │       [ 16:9 Traffic Image or Video ]        │ │  │ │       [ 16:9 Image / Scrubbable Video ]      │ │
│ │                                        [🔍]  │ │  │ └──────────────────────────────────────────────┘ │
│ └──────────────────────────────────────────────┘ │  │ 1.1.01-001 • Danger Teaching          [Variant-M]│
│ 1.1.01-001 • Danger Teaching                     │  │ What should you understand by defensive driving? │
│ What should you understand by defensive driving? │  │                                                  │
│                                                  │  │ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│ ┌──────────────────────────────────────────────┐ │  │ ┃ [✓] A. Not insisting on your rights  Correct ┃ │
│ │ [✓] A. Not insisting on your rights          │ │  │ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│ └──────────────────────────────────────────────┘ │  │ ┏╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍┓ │
│ ┌──────────────────────────────────────────────┐ │  │ ┇ [!] B. Allowing for others' mistakes Missed! ┇ │
│ │ [ ] B. Allowing for other people's mistakes  │ │  │ ┗╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍┛ │
│ └──────────────────────────────────────────────┘ │  │ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│ ┌──────────────────────────────────────────────┐ │  │ ┃ [✗] C. Stopping at every crossroads    Wrong ┃ │
│ │ [✓] C. Stopping at every crossroads          │ │  │ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│ └──────────────────────────────────────────────┘ │  │ ┌─ 💡 Why? (Explanation) ──────────────────────┐ │
│                                                  │  │ │ Defensive driving means not insisting on     │ │
│                                                  │  │ │ right of way and anticipating others' errors │ │
│                                                  │  │ │ —not stopping unnecessarily and impeding...  │ │
│                                                  │  │ └──────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────┤  ├──────────────────────────────────────────────────┤
│  [⏭]         [   Check Answer   ]                │  │              [  Next Question →  ]               │
└──────────────────────────────────────────────────┘  └──────────────────────────────────────────────────┘
```

#### Deep Component & Variant Details
1. **Live Session Progress Header (Always Visible):**
   - **Left:** `✕` Close session (saves all answered questions immediately; no confirmation popup needed in Practice Mode!).
   - **Center Status Pill:** Displays real-time session tally:
     - `✓ 12` (Answered Correctly in green)
     - `✗ 3` (Answered Incorrectly in red)
     - `10 left` (Remaining questions in current queue; in endless mode shows `Q 15 • 578 unseen left`).
   - **Right:** Official **Points Pill** (`2 Pts`, `3 Pts`, `4 Pts`, or amber-highlighted `5 Pts`) + **1-Tap Bookmark Star (`☆` / `★`)**.
   - **Thin Progress Hairline:** Visualizes completion across the current session.

2. **Adaptive Media Stage:**
   - **Text-Only Question (895 items):** Media stage collapses completely (`0dp` height), allowing larger `21sp` question typography and extra breathing room.
   - **Static Image Question (464 items):** `16:9` rounded container (`max-height: 28%` viewport height so all 3 options still fit above the fold without scrolling!). Tap anywhere on the image or `[🔍]` for instant pinch-to-zoom full-screen lightbox (crucial for reading tiny dashboard mirrors or distant speed-limit signs!).
   - **3-Sign Visual Options Question (8 items):** Instead of a top banner image, each Answer Card `A`, `B`, `C` renders a crisp `72x72dp` traffic sign thumbnail alongside its checkbox (with tap-on-sign zoom icon).
   - **Video Hazard Question in Practice Mode (225 items):**
     - Auto-plays muted `16:9` MP4 clip at `60fps` immediately on arrival (German exam videos have no audio cues—they are purely visual).
     - Includes a subtle **"Exam Realism" toggle pill** in the corner of the video player:
       - *Standard Practice (Default):* Question & options are visible while video plays so learners can study fast, with unlimited `[↻ Replay]` button.
       - *Exam-Style Video Mode:* Hides question & options behind `"Show Question (4 plays left)"` just like TÜV.
     - **Post-Submission Video Superpower:** Once the user clicks `Check Answer`, the video unlocks a **scrubbable timeline slider** so if they got the question wrong, they can drag back to `00:08` and see the child stepping out behind the bus.

3. **Numeric Input Variant (*Zahleneingabefragen* — 57 items):**
   - Replaces the 3 option cards with:
     - A centered **Large Answer Display Box** (`[  1,6  ] mm` or `[  60  ] km/h` — unit auto-inferred from question stem when unambiguous, or plain numeric field).
     - An ergonomic inline **3x4 Custom Numpad** (`1–9`, `,/.`, `0`, `⌫`) right in the thumb zone—no slow OS keyboard slide-up!
     - Typing `1.6` or `1,6` both evaluate as **Correct** against `"1,6"`.
   - **Post-Submission Numeric Feedback:**
     - If wrong, highlights user's typed number in Red (`✗ Your answer: 50`) directly beside a Green pill (`✓ Correct answer: 60`) and auto-expands the explanation card.

4. **Explanation Display Logic (`💡 Why?`):**
   - **When Incorrect OR Missing any Correct Option:** The Explanation Card **auto-expands immediately** directly below the options (smooth `180ms` layout reveal, auto-scrolling gently if needed while keeping `Next Question →` pinned at the bottom). If the question ID ends with `-M`, appends a compact callout: *"🎭 Visual Variant Question (-M): Vehicle colors, types, or weather may change in the real exam—focus on the underlying rule."*
   - **When 100% Correct:** Shows a compact 1-line green banner + collapsed **`[💡 Why is this right? ▾]`** chip. Tapping expands the full `comment` in 1 click (users can also flip *"Always auto-expand explanations"* in Settings).

---

### Screen 3: Topic & Catalog Selector (`Topics` Tab)

**Purpose:** Let learners study specific driving-school themes/chapters in 1 tap, see exact per-topic mastery (`Correct / Wrong / Left`), or combine multiple topics.

#### Wireframe Layout
```text
┌──────────────────────────────────────────────────────────┐
│  📚 Topics & Catalog                    🔍  [📐 Formulas]│
├──────────────────────────────────────────────────────────┤
│  [ All Class B (1,592) ] [ Grundstoff 1.x ] [ Class B 2.x]│
├──────────────────────────────────────────────────────────┤
│  GRUNDSTOFF (BASIC MATERIAL • 823 Qs)                    │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ 🚦 1.3 Priority (Right of Way)              [▶ 54] │  │
│  │ ✓ 31 Mastered  •  ✗ 9 Mistakes  •  ○ 14 Left       │  │
│  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒░░░░░                      [▾ 2]  │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ ⚠️ 1.1 Danger Teaching                     [▶ 239] │  │
│  │ ✓ 140 Mastered •  ✗ 18 Mistakes •  ○ 81 Left       │  │
│  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░░░                      [▴ 9]  │  │
│  │ ├──────────────────────────────────────────────────┤  │
│  │ │ 1.1.01 Basic Forms of Traffic Behavior    [▶ 18] │  │
│  │ │ ✓ 15 • ✗ 1 • ○ 2    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░          │  │
│  │ ├──────────────────────────────────────────────────┤  │
│  │ │ 1.1.02 Behavior Towards Pedestrians       [▶ 34] │  │
│  │ │ ✓ 12 • ✗ 6 • ○ 16   ▓▓▓▓▓▓▒▒▒░░░░░░░░░          │  │
│  │ └──────────────────────────────────────────────────┘  │
│                                                          │
│  ZUSATZSTOFF KLASSE B (CAR SPECIFIC • 769 Qs)            │
│  ┌────────────────────────────────────────────────────┐  │
│  │ 🔧 2.7 Technology                          [▶ 160] │  │
│  │ ✓ 42 Mastered  •  ✗ 15 Mistakes •  ○ 103 Left      │  │
│  │ ▓▓▓▓▓▒▒░░░░░░░░░░░░░░░                     [▾ 11]  │  │
│  └────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────┤
│      [ ⚡ Train ]       [ 📚 Topics ]    [ 📊 Progress ] │
└──────────────────────────────────────────────────────────┘
```

#### Interaction & Click-Minimizing Details
- **1-Tap Topic Start (`[▶ 54]`):** Tapping a Theme Card (or its `[▶]` pill) **immediately launches** the Practice Question Player scoped to that theme—prioritizing *Mistakes + Unseen* questions first so the user doesn't waste time re-answering already-mastered items! (Inside the player's top filter chip, 1 tap switches between *Unfinished & Mistakes (23)*, *Mistakes Only (9)*, or *All Questions (54)*).
- **Chapter Accordion (`[▾ 9]`):** Tapping the chevron expands the granular chapters (`1.1.01` through `1.1.09`) inline without pushing a new navigation page. Tapping any chapter starts practicing that chapter in **1 tap**.
- **Multi-Topic Selection Mode:** Long-pressing any Theme/Chapter (or tapping a `"Select Multiple"` header icon) reveals checkboxes on cards and a floating bottom CTA: **`Practice 3 Selected Topics (142 left) →`**.
- **Instant Keyword Search (`🔍`):** Typing `"autobahn"`, `"trailer"`, `"alcohol"`, or a question ID (`"1.4.40-013"`) filters chapters and individual questions live as you type.
- **`[📐 Formulas]` Quick Reference Sheet:** Opens a clean modal sheet summarizing Stopping Distance (*Anhalteweg*), Minimum Tread Depth (`1,6 mm`), Blood Alcohol (`0,0 ‰` in *Probezeit* / `< 21`), and Speed Limits inside/outside built-up areas.

---

### Screen 4: Exam Simulation Player (*Prüfungssimulation*)

**Purpose:** Authentic 30-question, 45-minute test environment that builds calm confidence for exam day.

#### Wireframe Layout (Mobile Portrait — Video Phase 1 vs. Question Phase 2)
```text
VIDEO PHASE 1 (Before Revealing Question)             QUESTION PHASE 2 (Standard / Post-Video Lock)
┌──────────────────────────────────────────────────┐  ┌──────────────────────────────────────────────────┐
│ ✕ Exit   ⏱️ 41:18    [Q 7 / 30]    [Grid ▦] [Abgabe]│ ✕ Exit   ⏱️ 40:52    [Q 7 / 30]    [Grid ▦] [Abgabe]
│ ●●●●●●◉○○○○○○○○○○○○○○○○○○○○○○○ (6 answered, 1 ⚑) │  │ ●●●●●●◉○○○○○○○○○○○○○○○○○○○○○○○ (6 answered, 1 ⚑) │
├──────────────────────────────────────────────────┤  ├──────────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────────┐ │  │ ┌──────────────────────────────────────────────┐ │
│ │                                              │ │  │ │ [Standbild / Final Scene Frame — Locked 🔒]  │ │
│ │     [ 16:9 Cockpit Hazard Video Playing ]    │ │  │ │       [ 16:9 Freeze-Frame Image ]      [🔍]  │ │
│ │              (No Pause / Scrub)              │ │  │ └──────────────────────────────────────────────┘ │
│ └──────────────────────────────────────────────┘ │  │ [4 Points] • Grundstoff               [⚑ Flag Q] │
│                                                  │  │ How should you behave in this situation?         │
│   🎬 Watch the traffic scene carefully.          │  │                                                  │
│   Pay attention to mirrors, speed, and signs.    │  │ ┌──────────────────────────────────────────────┐ │
│                                                  │  │ │ [✓] A. Brake immediately                     │ │
│   Plays remaining: ● ● ● ● ○  (4 of 5 left)      │  │ └──────────────────────────────────────────────┘ │
│                                                  │  │ ┌──────────────────────────────────────────────┐ │
│   [ ↻ Watch Video Again (4 left) ]               │  │ │ [ ] B. Continue at unchanged speed           │ │
│                                                  │  │ └──────────────────────────────────────────────┘ │
│   ℹ️ Note: Once you open the question, you can   │  │ ┌──────────────────────────────────────────────┐ │
│      no longer replay the video (TÜV rule).      │  │ │ [✓] C. Stay ready to steer right             │ │
│                                                  │  │ └──────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────┤  ├──────────────────────────────────────────────────┤
│      [ Show Question & Answers (Aufgabe) → ]     │  │ [ ← Prev ]                    [ Next (Q 8) → ] │
└──────────────────────────────────────────────────┘  └──────────────────────────────────────────────────┘
```

#### Authentic Exam Rules & Ergonomics
1. **Zero Mid-Exam Grading:** Selecting options updates the question's status dot from Hollow (`○` Unanswered) to Filled (`●` Answered), with **zero** right/wrong feedback until the exam is handed in.
2. **45:00 Non-Stress Timer:**
   - Displays `⏱️ 41:18` in calm neutral text; shifts to warm amber at `< 05:00` and gentle red at `< 01:00`. Tapping `⏱️` collapses the digits to `⏱️ ••:••` for timer-anxious learners (re-expands automatically at 5 minutes remaining).
3. **30-Question Strip & `[Grid ▦]` Navigator Sheet:**
   - Tapping `[Grid ▦]` (or swiping the dot strip) opens a 6x5 numbered grid (`1–20 Grundstoff`, `21–30 Zusatzstoff B`) showing Answered (`●`), Unanswered (`○`), and Flagged-for-Review (`⚑`) items. Tap any number to jump in **1 tap**.
4. **Strict 2-Phase Video Handling:**
   - Phase 1 plays the video without showing the question stem or options. User can tap `[↻ Watch Video Again]` up to **5 times total**.
   - Tapping **`[Show Question & Answers →]`** transitions permanently to Phase 2 for that exam attempt, displaying `local_image_paths[0]` (the final freeze-frame) with a subtle `🔒 Video finished` badge.
5. **Smart Hand-In Guard (`[Abgabe / Submit]`):**
   - On Question 30, `[Next →]` becomes **`[Finish & Grade Exam ✓]`** (or user can tap `[Abgabe]` anytime).
   - If **all 30 questions** have answers and `0` are flagged: **1 tap submits immediately** to the Verdict Screen!
   - If any questions are **unanswered** (e.g., 2 skipped) or **flagged (`⚑`)**: Shows a compact bottom sheet: *"You have 2 unanswered questions (Q11, Q24). [Jump to Q11] or [Submit Anyway]"*.
6. **Accidental Exit Protection:** Unlike Practice Mode, tapping `✕ Exit` mid-exam offers **`[Pause & Save for Later]`** vs. **`[Discard Exam]`** so 25 minutes of work is never lost to an accidental back-swipe.

---

### Screen 5: Exam Verdict & Mistake Breakdown

**Purpose:** Deliver an unmistakable Pass/Fail verdict, explain exact German *Fehlerpunkte* math, and turn exam mistakes into instant practice in **1 tap**.

#### Wireframe Layout (Example: Failed via Two-5-Point Rule or Passed)
```text
┌──────────────────────────────────────────────────────────┐
│  ✕ Close            Mock Exam #5 Result         [↻ New]  │
├──────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────┐  │
│  │  ✅ PASSED! (BESTANDEN)          /* OR ❌ FAILED */ │  │
│  │                                                    │  │
│  │         6 / 10 Error Points (Fehlerpunkte)         │  │
│  │         ▓▓▓▓▓▓░░░░│  (Max allowed: 10 Pts)         │  │
│  │                                                    │  │
│  │  ✓ 28 Correct   •   ✗ 2 Wrong   •   ⏱️ 14m 22s     │  │
│  │  ✓ 5-Point Rule OK (0 of max 1 failed)             │  │
│  └────────────────────────────────────────────────────┘  │
│  *Note: If failed with 2x 5-pt errors (10/10 pts), red   │
│   callout explains: "Failed: Two 5-point questions wrong │
│   triggers automatic failure under German exam rules."   │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  🎯 Practice These 2 Mistakes Now        [Start →] │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  BREAKDOWN BY SECTION                                    │
│  • Grundstoff (Q 1–20):      19/20 right  (3 Error Pts)  │
│  • Zusatzstoff B (Q 21–30):   9/10 right  (3 Error Pts)  │
│                                                          │
│  REVIEW QUESTIONS   [ Wrong Only (2) ]  [ All 30 ]       │
│  ┌────────────────────────────────────────────────────┐  │
│  │ ✗ Q9 • [3 Pts] Road Use (1.2.02-111)               │  │
│  │   "You want to use an autobahn. What maximum..."   │  │
│  │   Your answer: 50  •  Correct: 60          [View ▸]│  │
│  └────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────┐  │
│  │ ✗ Q24 • [3 Pts] Technology (2.7.01-009)            │  │
│  │   "What happens if tire pressure is far too low?"  │  │
│  │   1 missed option (B)                      [View ▸]│  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

#### Key Details
- **Default Filter = `Wrong Only`:** Immediately lists the exact questions that cost points—no scrolling past 28 green cards to find the 2 mistakes!
- **Inline Expand or Full View:** Tapping a mistake card expands its full 4-state option breakdown + explanation inline (or opens media zoom).
- **Automatic Mistake Recording:** Any question answered wrong in Exam Mode is automatically added to the user's global **Most Mistakes (`Fehlertraining`)** queue.

---

### Screen 6: Progress, Readiness & Weak-Topic Insights (`Progress` Tab)

**Purpose:** Give zero-registration users complete visibility into how much they've practiced, how often they make mistakes, and exactly which topics need work.

#### Wireframe Layout
```text
┌──────────────────────────────────────────────────────────┐
│  📊 Your Progress                         [💾 Backup]    │
├──────────────────────────────────────────────────────────┤
│  CATALOG COVERAGE (1,592 Official Questions)             │
│  ┌────────────────┐ ┌────────────────┐ ┌───────────────┐ │
│  │ ✓ 940 (59%)    │ │ ✗ 74 (5%)      │ │ ○ 578 (36%)   │ │
│  │ Mastered/Right │ │ Need Recovery  │ │ Unseen / Left │ │
│  └────────────────┘ └────────────────┘ └───────────────┘ │
│  Overall Accuracy: 86%  •  Total Answers Given: 1,840    │
│                                                          │
│  TOPICS NEEDING TRAINING (Ranked by Mistake Rate)        │
│  ┌────────────────────────────────────────────────────┐  │
│  │ 1. 🚦 1.3 Priority          32% error rate [Train] │  │
│  │    9 active mistakes • 14 unseen                   │  │
│  ├────────────────────────────────────────────────────┤  │
│  │ 2. 🔧 2.7 Technology        24% error rate [Train] │  │
│  │    15 active mistakes • 103 unseen                 │  │
│  ├────────────────────────────────────────────────────┤  │
│  │ 3. 🛑 1.4 Road Sign         18% error rate [Train] │  │
│  │    11 active mistakes • 40 unseen                  │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  MOCK EXAM HISTORY (Last 5 Attempts • Pass: ≤10 Pts)     │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Pts │ 18✗                                         │  │
│  │  10 ─┼───────14✗────9✓─────8✓─────6✓── (Pass Line) │  │
│  │      └─────────────────────────────────            │  │
│  │        #1    #2     #3     #4     #5               │  │
│  │  Passed 3 in a row! Ready for TÜV booking.         │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  EXPOSURE DISTRIBUTION                                   │
│  • Never answered (0x):   578 Qs          [Practice →]   │
│  • Answered once (1x):    412 Qs          [Practice →]   │
│  • Answered 2+ times:     602 Qs                         │
└──────────────────────────────────────────────────────────┘
```

#### Key Details
- **Zero-Account Privacy & Safety (`[💾 Backup]`):** Exports a tiny `<200 KB` `driving_progress_backup.json` via OS share sheet (or imports one) + provides a guarded *"Reset Progress"* action in Settings.
- **Actionable Analytics:** Every single insight row has a direct **`[Train]`** button—seeing a problem and fixing that problem are never more than **1 tap** apart.

---

## 7. Critical User Journeys (CUJs) & Click-Count Optimization

Every core workflow has been engineered to eliminate intermediate menus, modal confirmations, and cursor/thumb travel.

### CUJ Summary Table
| # | Critical User Journey | Overhead Taps Before Q1 | Taps Per Question Answered |
| :- | :--- | :---: | :---: |
| **CUJ 1** | **Quick Daily Study** (App launch $\rightarrow$ answering Question 1) | **1 tap** | $N$ option taps + **1** Submit + **1** Next (same spot) |
| **CUJ 2** | **Drill Frequent Mistakes** (Launch $\rightarrow$ mistake-only queue) | **1 tap** | $N$ option taps + **1** Submit + **1** Next |
| **CUJ 3** | **Practice Least-Answered / Unseen Questions** | **1 tap** | $N$ option taps + **1** Submit + **1** Next |
| **CUJ 4** | **Train a Specific Topic** (e.g., *1.3 Priority*) | **2 taps** (`Topics` $\rightarrow$ `Priority`) | $N$ option taps + **1** Submit + **1** Next |
| **CUJ 5** | **Take a Full 30-Question Mock Exam & See Verdict** | **1 tap** (`Exam Simulation`) | $N$ option taps + **1** `Next` (Submit only at end!) |
| **CUJ 6** | **Understand a Mistake & Recover It** | **0 extra taps** (auto-shown!) | Explanation opens automatically on error |
| **CUJ 7** | **Fix Weakest Topic from Progress Analytics** | **2 taps** (`Progress` $\rightarrow$ `[Train]`) | $N$ option taps + **1** Submit + **1** Next |

---

### Detailed Step-by-Step CUJ Walkthroughs

#### CUJ 1: Commuter 3-Minute Quick Practice (Goal: Answer 10 questions on the U-Bahn)
1. **Open App:** Lands directly on **Home Cockpit** (`0` taps). Readiness and remaining unseen counts are immediately visible.
2. **Tap `⚡ Smart Practice` (`Tap 1`):** Question 1 renders immediately.
3. **Read & Select:** User taps Option A (`Tap 2`) and Option B (`Tap 3`)—full-width cards toggle instantly.
4. **Submit:** Thumb drops `15mm` to bottom bar and taps **`Check Answer`** (`Tap 4`).
   - *If Correct:* Options A & B highlight Emerald Green; session pill increments `✓ +1` and decrements `left -1`.
   - *If Wrong / Missing Option:* Wrong choice highlights Red (`✗`), missed correct option highlights Dashed Amber (`Missed!`), and the **Explanation Card auto-expands** (`0` extra taps!).
5. **Advance:** Without moving their thumb at all, user taps **`Next Question →`** (`Tap 5`, identical pixel position to `Check Answer`).
6. **Exit Anytime:** User's train arrives $\rightarrow$ taps `✕` (`1` tap) or simply locks phone. Progress is already saved locally.

#### CUJ 2 & CUJ 3: Drilling "Most Mistakes" or "Least Answered"
1. **Open App** $\rightarrow$ **Home Cockpit** (`0` taps).
2. **Tap `✗ Most Mistakes (74)`** *or* **`○ Least Answered (578)`** right on the Home Cockpit (`Tap 1`).
3. **Question 1 loads immediately**—sorted by highest mistake severity (for *Most Mistakes*) or lowest `attempts_count` starting at `0` (for *Least Answered*).
   - *Zero* filter-configuration modals, *zero* "Select question count" popups, *zero* "Click Start" confirmation screens!

#### CUJ 4: Studying a Specific Topic Before Evening Driving School
1. From Home, tap **`📚 Topics`** in the bottom bar (`Tap 1`).
2. User sees each Theme's exact `✓ Mastered`, `✗ Mistakes`, and `○ Left` counts. User taps **`🚦 1.3 Priority [▶ 54]`** (`Tap 2`).
   - *(Optional Chapter precision: Tap `[▾]` on `1.1 Danger Teaching` $\rightarrow$ tap `1.1.02 Behavior Towards Pedestrians` = `3` taps total).*
3. Practice Question Player opens immediately with Priority questions.

#### CUJ 5: Full 30-Question Official Exam Simulation
1. From Home, tap **`⏱️ Exam Simulation [Begin]`** (`Tap 1`).
2. **Questions 1–30:**
   - Standard/Image Qs: Tap option(s) $\rightarrow$ tap **`Next →`** (Notice: **1 fewer tap per question** than Practice Mode because there is no per-question grading step!).
   - Video Qs (e.g., Q7): Video auto-plays $\rightarrow$ tap `[↻ Watch Again]` if needed (up to 5x) $\rightarrow$ tap **`Show Question & Answers →`** $\rightarrow$ view freeze-frame, tap option(s), tap **`Next →`**.
3. **Question 30:** Tap **`Finish & Grade Exam ✓`** (`1` tap when all 30 answered).
4. **Verdict Screen:** Displays **`✅ PASSED (6 / 10 Error Points)`** or **`❌ FAILED`** immediately, with `0` extra taps needed to see every mistake below, and **1 tap** on **`🎯 Practice These Mistakes Now`** to master them right away.

---

## 8. Edge Cases, Accessibility & Dataset Implementation Notes

### 8.1 Dataset-Specific Handling (`assets/driving_theory_questions_b.json`)
During technical discovery of the repository's 1,592-question JSON and media assets, we identified four critical data behaviors the UI and asset pipeline must handle gracefully:
1. **Numeric Comma Normalization (`57` questions):** `correct_answers[0].letter` contains German comma decimals (`"1,5"`, `"1,6"`, `"2,5"`, `"2,8"`, `"3,5"`). The evaluation parser must normalize `,` $\leftrightarrow$ `.`, trim whitespace, and compare numerically while displaying localized formatting cleanly.
2. **Video + Freeze-Frame Pairing (`225` questions):** Every video question in the JSON includes *both* `local_video_paths: ["videos/X.mp4"]` and `local_image_paths: ["images/X.png"]`. The app must treat `local_video_paths.isNotEmpty` as a **Video Question**, using `local_image_paths[0]` specifically as the video poster frame and the **Phase 2 post-video `Standbild`** in Exam Mode!
3. **3-Sign Visual Option Questions (`8` questions, e.g., `1.4.40-013`):** These have `options` A, B, C with `text: ""` and 3 distinct sign URLs in `image_urls` (`..._a1.png`, `..._a2.png`, `..._a3.png`), whereas `local_image_paths` currently points all 3 entries to `"images/1_4_40-013.png"` (which holds only `_a3.png` due to filename collision during scraping). During asset prep/build, those 8 questions' `_a1.png`, `_a2.png`, and `_a3.png` files should be saved distinctly (e.g., `images/1_4_40-013_a1.png`..`_a3.png`) and rendered directly inside Answer Cards `A`, `B`, and `C`.
4. **2-Option vs. 3-Option Questions (`58` two-option items vs. `1,477` three-option items):** Answer list dynamically renders `options.length` cards (`A, B` or `A, B, C`) without empty third placeholders.

### 8.2 Accessibility, Dark Mode & Offline Resilience
- **100% Offline Operation:** All JSON questions, `images/*.png`, and `videos/*.mp4` bundle locally—zero network latency in subway tunnels.
- **Color Vision Deficiency (Protanopia / Deuteranopia):** Red vs. Green states are reinforced by distinct **icons** (`✓` vs `✗` vs `!`), **border strokes** (solid vs. dashed), and explicit **text pills** (`Correct`, `Wrong choice`, `Missed!`).
- **Dynamic Text Scaling & High-Contrast Dark Mode:** Supports OS font scaling up to `130%` without clipping answer text (cards grow vertically and scroll smoothly above the sticky CTA bar). Dark mode uses deep slate surfaces (`#0F172A` / `#1E293B`) so studying in bed doesn't strain eyes while preserving true-color rendering on road-sign images.
