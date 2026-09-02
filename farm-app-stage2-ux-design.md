# Digital Farm Management System — Stage 2: UX/UI Design
## Part 1 of 2 — Information Architecture, Navigation, Screen Inventory, Flows, Dashboard, Design System
(Part 2 — wireframes, high-fidelity screens, and clickable prototype — follows once this structure is approved.)

Designed for: Farm Owner (primary), Farm Manager (secondary). Flutter, Android-first, Material Design 3.

---

## 1. Information Architecture

```
Auth
 ├─ Splash
 ├─ Onboarding (first launch only)
 ├─ Login
 ├─ Register
 └─ Forgot Password
      ↓
Farm Setup
 ├─ Create Farm
 └─ Farm Details (edit)
      ↓
┌─────────────── Main App Shell (bottom nav) ───────────────┐
│  Dashboard   Inventory   Finance   Reports   More          │
└──────────────────────────────────────────────────────────┘
      Inventory ─ Livestock / Feed / Drugs & Vaccines / Equipment
      Finance   ─ Purchases / Expenses / Sales / Profit & Loss
      Reports   ─ Livestock / Feed / Drugs / Equipment / Financial
      More      ─ Notifications / Settings / Profile / Farm Info / Help / Logout
```

**Why this shape:**
- **Auth → Farm Setup → Shell** is a strict linear gate — a farmer can't get lost before they have a farm, and every screen after this point can safely assume `farm_id` is known (matches the "everything belongs to a farm" architecture decision from Stage 1).
- **Four flat top-level destinations** (not counting Auth) instead of deep nesting — Dashboard, Inventory, Finance, Reports are the four things a farmer actually thinks in terms of. "Livestock" isn't a top-level tab on its own because it's one of four *inventory* concerns the farmer mentally groups together (along with Feed, Drugs, Equipment) — nesting it under Inventory keeps the top nav from growing past 5 items as the app scales.
- **Settings/Notifications live under "More"**, not the main row — they're low-frequency compared to recording a sale or checking stock, so they shouldn't cost a thumb-reach on every use.
- **Reports is separate from Finance** even though farmers might think "reports = money" — because Reports also covers livestock/feed/drug/equipment reporting, and conflating it with Finance would bury non-financial reports.

---

## 2. Navigation Pattern: Bottom Navigation (4 items) + FAB + Drawer-free "More" tab

**Recommendation: Bottom Navigation Bar**, not a drawer or nav rail.

**Why:**
- **Nav rail** is built for tablet/desktop-width screens — wrong fit for an Android-phone-first, one-handed farmer app.
- **Drawer** hides destinations behind a hamburger tap, adding a tap to every navigation action — directly conflicts with the "every major action reachable within 3 taps" requirement, and drawers are proven to get less discovery/use than bottom tabs on mobile.
- **Bottom nav** keeps the 4 things a farmer does constantly (check dashboard, check inventory, log a sale/expense, check reports) one tap away, thumb-reachable on any phone size, and always visible so the farmer never has to wonder "where am I."
- A **center-docked Floating Action Button** on the Dashboard opens the Quick Actions sheet (Record Sale, Record Expense, Record Feed Usage, Record Pig Movement, Record Drug Usage) — this is the single fastest path to the actions farmers repeat many times a day, independent of which tab they're on.
- **"More" absorbs Settings/Notifications/Help** as the 5th bottom-nav slot instead of a drawer, keeping everything in the same flat, thumb-reachable pattern rather than mixing two navigation metaphors.

**Scalability for future modules (Marketplace, Veterinary):** new modules attach as new entries inside "More" first (soft-launch, e.g. "Veterinary (Beta)"), and only get promoted to a full bottom-nav tab if usage data shows farmers need it at that frequency — the bottom nav itself never needs a redesign, only new destinations layered under an existing tab (e.g., Veterinary lives logically next to Drugs under Inventory, since a vet visit is conceptually adjacent to treatment records).

---

## 3. Screen Inventory

Legend: **P**=Purpose · **Actions**=Primary (bold) / secondary · **Empty**=empty-state CTA

### Auth
| Screen | P | Primary User | Actions | Empty/Error notes |
|---|---|---|---|---|
| Splash | Brand + session check, routes to Login or Dashboard | Both | auto-route (2s max) | — |
| Onboarding | 3-slide value intro, first launch only | Both | **Get Started**, Skip | — |
| Login | Authenticate | Both | **Log In**; Forgot Password, Register link | Error: inline "Incorrect email/phone or password" |
| Register | Create account | Both | **Create Account**; Login link | Validation: phone/email format, password strength meter |
| Forgot Password | Reset via email/SMS code | Both | **Send Reset Code** → **Verify & Reset** | Error: "Code expired, resend?" |

### Farm Setup
| Screen | P | Primary User | Actions | Empty/Error |
|---|---|---|---|---|
| Create Farm | First-run farm profile capture | Farmer | **Create Farm** | Validation: name + location required, rest optional |
| Farm Details | View/edit farm profile | Farmer | **Save Changes**; Add Manager (future) | — |

### Dashboard
| Screen | P | Primary User | Actions | Empty/Loading |
|---|---|---|---|---|
| Dashboard (Home) | At-a-glance farm status + fast entry point | Both | FAB → Quick Actions; tap any summary card to drill in | Empty: "No activity yet — record your first movement" · Loading: skeleton cards |

### Inventory — Livestock
| Screen | P | Actions | Empty |
|---|---|---|---|
| Livestock Overview | Per-species stock summary (Pigs/Cattle/Chickens/Dogs cards) | tap species card → category breakdown | "No livestock recorded" → Add Opening Stock |
| Species Category List | Stock by category within a species (e.g. pig: Sow/Boar/Piglet...) | **Record Movement**, filter by category | "No categories yet" (admin can add custom) |
| Movement History | Ledger of all movements for a species/category | Filter by date/type, Search | "No movements in this range" |
| Record Movement (form) | Log birth/purchase/sale/death/cull/transfer | **Save**; cancel | Validation: quantity > 0, can't exceed stock on reduction types unless admin override |

### Inventory — Feed
| Screen | P | Actions | Empty |
|---|---|---|---|
| Feed List | All feed items, current stock, low-stock flagged | **Add Feed Item**, Search, Filter by species | "No feed records" → Add First Feed |
| Feed Detail | Item info + transaction history | **Record Purchase**, **Record Usage**, Edit, Record Waste | — |
| Record Feed Purchase (form) | Log purchase, auto-updates stock + creates expense | **Save** | Validation: bag×size = kg auto-calculated |
| Record Feed Usage (form) | Log usage, reduces stock | **Save** | Validation: can't exceed current stock (soft warn, admin override) |

### Inventory — Drugs & Vaccines
| Screen | P | Actions | Empty |
|---|---|---|---|
| Drug List | All items, expiry-flagged, low-stock flagged | **Add Drug Item**, Search, Filter (expiring/expired) | "No drug records" → Add First Item |
| Drug Detail | Item info, batches (FIFO order), history | **Record Purchase**, **Record Usage/Treatment** | — |
| Record Drug Purchase (form) | Log purchase w/ batch + expiry | **Save** | Validation: expiry date required if applicable |
| Record Treatment (form) | Log usage against an animal/category | **Save** | Validation: dose + quantity required |

### Inventory — Equipment
| Screen | P | Actions | Empty |
|---|---|---|---|
| Equipment List | All equipment, condition badges | **Add Equipment**, Search, Filter by condition | "No equipment recorded" |
| Equipment Detail | Info + maintenance history | **Log Maintenance**, Edit, Retire | — |
| Log Maintenance (form) | Record service event | **Save** | Validation: next maintenance date optional but recommended |

### Finance
| Screen | P | Actions | Empty |
|---|---|---|---|
| Purchases List | Non-inventory + inventory purchase log | **Add Purchase**, Filter by category/date | "No purchases yet" |
| Expenses List | All expenses | **Add Expense**, Filter | "No expenses yet" |
| Sales List | All sales | **Add Sale**, Filter | "No sales yet" |
| Record Sale (form) | Log sale, auto-updates livestock stock | **Save** | Validation: quantity ≤ current stock for that category |
| Profit & Loss | Revenue vs expense summary, date-range | Change range, drill into category | "Not enough data yet for this period" |

### Reports
| Screen | P | Actions | Empty |
|---|---|---|---|
| Reports Hub | Choose report type (Livestock/Feed/Drugs/Equipment/Financial) | tap category | — |
| Report Detail | Filtered report w/ summary cards + minimal chart | Filter (date/category), **Export PDF**, **Export CSV** | "No data for selected filters" |

### More
| Screen | P | Actions |
|---|---|---|
| Notifications | List of alerts, priority-sorted | Tap → relevant screen; Mark read; Dismiss |
| Settings | Entry point to sub-settings | Profile, Farm Info, Units, Notification Prefs, Security, About, Help, **Logout** |
| Profile | Edit name/contact/password | **Save** |
| Units | kg vs bags, currency | **Save** |
| Notification Preferences | Toggle alert types | **Save** |
| Help | FAQ / contact support | — |

**Total: 36 screens for Stage 1 MVP** — deliberately no more; anything not on this list is out of scope until Stage 2/3 modules are approved.

---

## 4. Core User Flows

**Login → Dashboard**
Splash checks session token → valid: Dashboard. Invalid/none: Login → enter credentials → validate → on success, cache token, route to Dashboard (or Create Farm if user has zero farms).

**Record Feed Purchase** (thumb-first, ≤30 sec target)
Dashboard FAB → "Record Feed Purchase" → select feed item (or "+ New Feed Item") → enter bags or kg (numeric keypad, bag-size auto-converts) → cost per unit (defaults to last used price) → date (defaults to today) → **Save** → snackbar "Feed purchase recorded, stock updated" → stock badge updates live on Feed list without navigating away.

**Record Livestock Movement (e.g. Pig Sale)**
Inventory → Livestock → select species → select category → **Record Movement** → movement type = Sale → quantity (numeric keypad, current stock shown inline as a guardrail) → if quantity > current stock, inline warning + confirm-to-override (admin only) → optional: link to a Sale record (pre-fills Sales form with same quantity) → **Save** → stock updates + audit log entry created silently.

**Record Drug Treatment**
Inventory → Drugs → select item → **Record Usage** → select animal category → dose + quantity → reason (dropdown: Routine/Illness/Injury/Preventive) → **Save** → stock decrements using oldest non-expired batch first (FIFO) automatically, no manual batch selection required from the farmer.

**Generate Report**
Reports → select category (e.g. Financial) → default range = "This Month" (editable) → **Export PDF** or **Export CSV** → share sheet opens (WhatsApp/email/save) — export is one tap away from every report, since sharing a report with a buyer/vet/accountant is a common real-world need.

Each flow above satisfies: clear start, one decision point per screen (not stacked), inline validation before submit, and a visible system response (snackbar/stock update) confirming completion — matching the "can the farmer complete this in under 30 seconds" validation bar.

---

## 5. Dashboard Design

| Section | Content | Why it's here |
|---|---|---|
| Farm Summary (header) | Farm name, owner, quick farm-switcher (future multi-farm) | Orientation — confirms which farm you're viewing |
| Livestock Summary | One compact card per species: total + trend arrow (↑/↓ since last week) | Answers Q1/Q2 from the PRD instantly without a chart |
| Feed Summary | Total stock (kg), low-stock count as a red badge | Answers Q3/Q4; badge draws the eye only when action is needed |
| Drug Summary | Low-stock count, expiring-soon count | Answers Q5/Q6; two numbers, no list clutter |
| Equipment Summary | Needs-repair count | Only shown if non-zero — avoids dashboard clutter when nothing needs attention |
| Financial Summary | This month: revenue, expenses, net (color-coded green/red) | Answers Q8/Q9/Q10 in one glance |
| Recent Activity | Last 5 events, chronological, icon-coded | Reassures the farmer their recent entries registered correctly |
| Notifications banner | Only shows if unread alerts exist, collapses if none | Avoids "empty notification bell" clutter |
| Quick Actions (FAB) | Sheet with the 5 highest-frequency actions | The core anti-notebook value prop — replacing a paper entry takes one FAB tap, not four taps through menus |

Explicitly **not** included: line/bar charts, historical trend graphs, or anything requiring interpretation — those live in Reports, not the Dashboard, per the "avoid overloading the dashboard with charts" instruction.

---

## 6. Forms, Search/Filter, Notifications — Shared Patterns

**Forms:** every entry form uses: numeric keypad for quantities/amounts, date picker defaulting to today, dropdown/autocomplete for categorized fields (never free-text where a category exists), and pre-filled defaults from the last entry of the same type (e.g. last supplier, last unit price) to minimize typing. Validation is inline and blocking only for data-integrity rules (negative stock, missing required date); everything else is a soft warning with override.

**Search & Filters:** a single persistent search bar pattern reused across Livestock/Feed/Drugs/Equipment/Purchases/Expenses/Sales lists — same placement (top of list), same filter-chip row beneath it (Category, Date range, Status), same sort control (top-right icon). Consistency here means a farmer who learns search once has learned it everywhere.

**Notifications:** each has a priority color (red=expired/critical, amber=low-stock/expiring-soon, blue=informational), a leading icon matching its category, one action button that deep-links to the relevant screen (e.g. "View Item"), and swipe-to-dismiss. Notifications are batched, not per-transaction — e.g. one "3 feed items low" card, not three separate cards — to avoid alert fatigue.

---

## 7. Design System Foundations

**Typography (Material 3 type scale, Android-optimized):**
- Display/Headline reserved for empty-state illustrations only
- Title Large (22sp) — screen titles
- Title Medium (16sp) — card headers, list section headers
- Body Large (16sp) — primary content, form labels
- Body Medium (14sp) — secondary/meta text
- Label Large (14sp, medium weight) — button text
Minimum body text size: 14sp — never smaller, for readability by non-technical/older users.

**Color palette (semantic, not just brand):**
- Primary (brand green — agricultural, growth) — primary buttons, active nav item
- Secondary (earth brown/tan) — accents, secondary buttons
- Success (green) — profit, stock healthy, completed actions
- Warning (amber) — low stock, expiring soon
- Error (red) — expired, negative balance, validation errors
- Surface/Background — light mode default; dark-mode-ready token pairs defined alongside

**Spacing:** 4px base unit grid — 4/8/12/16/24/32. Card padding 16px, list item height minimum 56px (touch-target compliant), FAB 56px diameter.

**Core components:** Dashboard Summary Card, Stat Badge (with trend arrow), Inventory List Tile (name + stock + status badge), Quick Action Button (icon + label, in FAB sheet), Search Bar (persistent, consistent placement), Filter Chip (multi-select), Empty State (illustration + message + CTA button), Confirmation Dialog (used before any destructive/reduction action), Notification Card, Bottom Sheet (used for Quick Actions and form entry on small actions), Snackbar (success/error feedback after every save).

All buttons minimum 48×48dp touch target (Android accessibility minimum), consistent 8dp corner radius across cards/buttons/inputs for a cohesive Material 3 look without feeling clinical.

---

## Next Step

This covers deliverables 1–4 (Information Architecture, Navigation Map, Screen Inventory, User Flows) plus dashboard design and design system foundations.

Remaining deliverables — **wireframes, high-fidelity mockups, and a clickable prototype** — are visual artifacts, not more spec text. I'd suggest building these next as an interactive HTML/Flutter-style mockup for the highest-value screens first (Dashboard, Feed Inventory + Record Purchase flow, Livestock Movement flow) rather than all 36 screens at once, so you can validate the direction before I extend it to the full set.

Want me to go ahead and build that interactive mockup for those 3-4 screens?
