# SMARTOYS — AI Brand Guidelines (Tool‑Ready)

**Source of truth:** *SMARTOYS — Charte Graphique 2021* and provided logo assets. fileciteturn0file0  
Use this document as a **single, copy‑pasteable set of constraints** for AI tools (text, image, layout, video, social templates).

---

## 1) Brand essentials (non‑negotiable)

### Brand name
- **SMARTOYS** (all caps in the logotype; in running text you may use “Smartoys” if needed for readability).

### Slogan / tagline
- **CHOOSE YOUR WORLD** (uppercase).  
- Uses **Red Hat Text** (see Typography).

### Logo structure (do not alter)
The brand book states repeatedly that the logo elements **must not be modified**:
- **Do not change spacing** between symbol + name + baseline/tagline.
- **Do not re‑align** elements in a different way.
- **Do not change relative scale** of the elements. fileciteturn0file0

> In practice for AI tools: **never “redesign” the logo**. Place it as an imported asset, or if you must recreate, recreate *exactly* with correct proportions and spacing (no stylistic interpretation).

### Approved logo variants (use case)
From the brand book:
- **Name** (wordmark only) — for business cards, stationery, packaging, products, partnerships, institutional comms, website, social. fileciteturn0file0
- **Symbol** (the “M” symbol) — same usage set as above; use when the full logo is too small. fileciteturn0file0
- **Full logo** (symbol + name) — for stationery, packaging, products, partnerships, institutional comms, social. fileciteturn0file0
- **Full logo + baseline** — for partnerships & institutional comms. fileciteturn0file0

---

## 2) Color system

### Core palette (official)
Use these **exact** values.

| Role | Name | HEX | RGB | CMYK |
|---|---|---|---|---|
| Primary background / text | Black | **#1D1D1B** | 29, 29, 27 | 0, 0, 0, 100 |
| Primary background / text | White | **#FFFFFF** | 255, 255, 255 | 0, 0, 0, 0 |
| Accent 1 (primary) | Powersuit | **#FF143E** | 255, 20, 62 | 0, 94, 64, 0 |
| Accent 2 (secondary) | Pacman | **#F9EB0F** | 249, 235, 15 | 8, 0, 88, 0 |

(Colors from the brand book.) fileciteturn0file0

### Practical usage rules for AI outputs
- Default look: **dark (Black #1D1D1B) background** with **high contrast** typography.
- Use **Powersuit** for key highlights (CTA, emphasis, icon accents).
- Use **Pacman** sparingly as a secondary highlight (badges, small UI accents, secondary CTA).
- Avoid introducing new “nearby” colors.  
  *Note:* Some SVG assets may contain close variants (e.g., #EE214A / #EBEE24). Normalize to the official HEX values above for consistency.

### Forbidden
- Pastel versions of Powersuit/Pacman.
- Gradients that introduce extra hues (unless the gradient stays inside black→black, or inside a single accent family without adding new colors).

---

## 3) Typography

### Primary font family
- **Red Hat Text** (titles, subtitles, body, slogan). fileciteturn0file0

### Weights / hierarchy
From the brand book:
- **Titles:** Red Hat Text **Bold**
- **Subtitles:** Red Hat Text **Medium**
- **Body text:** Red Hat Text **Regular** (prefer White at 100% for body copy)
- **Emphasis / callouts:** **Powersuit + Bold** fileciteturn0file0

### Typography rules for AI tools
- Keep text blocks clean and readable; avoid decorative fonts.
- Use consistent casing: slogan is **uppercase**.
- If Red Hat Text isn’t available in a tool:
  - Use a **neutral, modern sans‑serif** with similar proportions (avoid geometric display faces).
  - Keep weight mapping: Bold / Medium / Regular.

---

## 4) Layout & visual style (derived from examples)

Based on the brand book mockups (business cards, merch, social grid): fileciteturn0file0
- **Minimal, high‑contrast compositions** with plenty of negative space.
- Frequent use of **black surfaces** with neon‑like accents (Powersuit / Pacman).
- Brand mark often appears **small and confident** (corner placement) or **very large** as a bold graphic statement (oversized symbol on merch).

### Composition guidelines for AI-generated visuals
- Prefer **simple geometry** and uncluttered backgrounds.
- Avoid busy textures behind the logo; keep the mark readable.
- When showing products (games/consoles/merch), use clean studio lighting and let brand accents frame the content.

---

## 5) Logo placement rules for AI outputs

Because the brand book doesn’t specify numeric clear-space, follow these safe rules:
- Leave **generous breathing room** around the logo (no touching edges).
- Never place the logo over complex imagery that reduces legibility.
- Use **white** logo on black, or **black** on white, or the **color version** on black where contrast is strong.
- Do not add shadows, outlines, bevels, strokes, glow, or 3D effects to the mark.

---

## 6) Copy & tone (defaults for AI writing)

The brand book focuses on visual identity; it doesn’t define voice. Use these defaults unless you provide a separate tone/voice guide:
- **Short, energetic, confident** sentences.
- Vocabulary aligned with gaming & pop culture, but **not cringe/slang-heavy**.
- Favor **benefit-led** copy and clear CTAs.
- Keep punctuation controlled (avoid excessive emojis).

---

## 7) Tool-specific instructions (copy/paste)

### A) SYSTEM / STYLE INSTRUCTIONS for text models (brand-safe)
Paste this into a “system” or “style” field:

- Follow SMARTOYS brand identity.
- Use Red Hat Text hierarchy: Titles Bold, Subtitles Medium, Body Regular.
- Use color references only from: Black #1D1D1B, White #FFFFFF, Powersuit #FF143E, Pacman #F9EB0F.
- Slogan must be “CHOOSE YOUR WORLD” (uppercase).
- Never redesign or stylize the logo; treat it as a fixed asset with unmodified proportions and spacing.
- Default to high-contrast, minimal, modern look; avoid clutter and decorative fonts.

### B) IMAGE GENERATION PROMPT SNIPPET (visual brand lock)
Append this to image prompts:

“SMARTOYS visual identity: deep near-black background (#1D1D1B), high contrast, minimal composition, accents in magenta-red (#FF143E) and bright yellow (#F9EB0F). Clean modern sans-serif typography similar to Red Hat Text. No extra colors. Logo (if present) must be placed as-is without distortion, effects, or re-drawing.”

### C) DESIGN QA CHECKLIST (use to validate outputs)
An output is **brand-compliant** only if:
- ✅ Uses only the official palette and maintains high contrast.
- ✅ Uses Red Hat Text (or closest neutral sans if unavailable) with correct weight hierarchy.
- ✅ Logo is not distorted, re-aligned, recolored outside palette, or altered in spacing.
- ✅ Layout is minimal and readable; logo has breathing room.
- ✅ Slogan (if used) is exactly **CHOOSE YOUR WORLD**.

---

## 8) Small “brand token” block (for programmatic tools)

```yaml
brand: SMARTOYS
slogan: "CHOOSE YOUR WORLD"
colors:
  black:   { hex: "#1D1D1B", rgb: [29,29,27], cmyk: [0,0,0,100] }
  white:   { hex: "#FFFFFF", rgb: [255,255,255], cmyk: [0,0,0,0] }
  powersuit: { hex: "#FF143E", rgb: [255,20,62], cmyk: [0,94,64,0] }
  pacman:  { hex: "#F9EB0F", rgb: [249,235,15], cmyk: [8,0,88,0] }
typography:
  family: "Red Hat Text"
  title:   { weight: "Bold" }
  subtitle:{ weight: "Medium" }
  body:    { weight: "Regular" }
usage_rules:
  logo:
    no_distort: true
    no_realign: true
    no_respace: true
    no_effects: ["shadow","stroke","outline","glow","3d","bevel"]
style:
  vibe: ["minimal","high-contrast","modern","gaming-adjacent"]
  default_background: "#1D1D1B"
```

---

### Notes for teams
- If you later share a tone-of-voice or messaging guide, we can extend section 6 with exact wording rules and examples (FR/EN, formality, taglines, etc.).
