# Smartoys Email Templates Brand Update Plan

## Executive Summary

Update all 8 HTML email templates in the Smartoys templates directory to comply with the new brand guidelines documented in `examples/smartoys/templates/brand/smartoys-brand.md`.

**Project Location:** `examples/smartoys/templates/html/`

**Affected Templates:**
1. `birthday.html`
2. `deposit_sold.html`
3. `game_repost.html`
4. `reservation_booked.html`
5. `reservation_ready.html`
6. `second_hand.html`
7. `welcome_store.html`
8. `welcome_web.html`

---

## Brand Violations Identified

### Critical Issues (All Templates)

#### 1. **Typography - Wrong Font Family**
- **Current:** `font-family: 'Open sans', Arial, sans-serif`
- **Required:** `font-family: 'Red Hat Text', Arial, sans-serif`
- **Impact:** 100% of text elements across all templates
- **Brand Rule:** Red Hat Text is the primary brand font (Bold for titles, Medium for subtitles, Regular for body)

#### 2. **Color - Incorrect Primary Accent (Powersuit)**
- **Current:** `#a0141c` (maroon/burgundy)
- **Required:** `#FF143E` (Powersuit red)
- **Locations:**
  - Header background: `bgcolor="#a0141c"`
  - CTA buttons: `bgcolor="#a0141c"`
  - Price/accent text: `color:#a0141c`
  - Footer decorative elements: `bgcolor="#a0141c"`
  - Social media section accents
- **Brand Rule:** Powersuit #FF143E is the official primary accent color

#### 3. **Color - Incorrect Footer Background**
- **Current:** `bgcolor="#14181d"` (near-black with blue tint)
- **Required:** `bgcolor="#1D1D1B"` (brand black)
- **Locations:** Footer section background and "Contactez-nous" button
- **Brand Rule:** Black #1D1D1B is the official brand black

#### 4. **Logo Asset Reference**
- **Current:** `http://mailing.smartoys.be/media/images/generic/logo.png`
- **Recommended:** Update to use new brand logo assets from `/brand/` directory
- **Available Assets:**
  - `_Smartoys_logo_colors.png`
  - `_Smartoys_logo_Name_colors.png`
  - `_Smartoys_logo_Symbol_colors.png`
- **Brand Rule:** Logo must not be modified; use approved variants

#### 5. **Background Color Consistency**
- **Current:** `bgcolor="#eceff3"` (light gray)
- **Status:** ACCEPTABLE - This neutral background works for email compatibility
- **Note:** While brand guidelines prefer #1D1D1B backgrounds, email best practices require lighter backgrounds for body content

---

## Systematic Fix Strategy

### Phase 1: Global Find & Replace Operations

Apply these changes to ALL 8 templates:

#### A. Font Family Updates
```css
/* Find all instances */
font-family: 'Open sans', Arial, sans-serif
font-family: 'open sans', arial, sans-serif

/* Replace with */
font-family: 'Red Hat Text', Arial, sans-serif
```

**Additional font-family instances to update:**
- CSS in `<style>` tags: `.textbutton a { font-family: 'open sans', arial, sans-serif !important;}`
- Inline styles on all `<td>` elements with text

#### B. Color Updates - Powersuit Red

**Pattern 1: Background colors**
```html
<!-- Find -->
bgcolor="#a0141c"

<!-- Replace -->
bgcolor="#FF143E"
```

**Pattern 2: Inline text colors**
```html
<!-- Find -->
color:#a0141c

<!-- Replace -->
color:#FF143E
```

**Pattern 3: CSS color references**
```html
<!-- Find -->
style="border-left:10px solid #a0141c;"

<!-- Replace -->
style="border-left:10px solid #FF143E;"
```

#### C. Color Updates - Brand Black

**Footer backgrounds:**
```html
<!-- Find -->
bgcolor="#14181d"

<!-- Replace -->
bgcolor="#1D1D1B"
```

**Footer text colors:**
```html
<!-- Find -->
color:#14181d

<!-- Replace -->
color:#1D1D1B
```

#### D. Logo Reference Updates

**Current logo reference:**
```html
<img label="logo" src="http://mailing.smartoys.be/media/images/generic/logo.png" alt="img" width="300" style="display:block; line-height:0px; font-size:0px; border:0px;" />
```

**Decision Required:** Determine new logo hosting location
- Option A: Update mailing server with new brand logo
- Option B: Use relative path to brand assets
- Option C: Host on CDN and update all references

---

## Template-Specific Details

### Common Structure (All Templates)

All templates follow this consistent structure:

```
1. DOCTYPE & HTML setup
2. <head> with meta tags and CSS styles
3. <body bgcolor="#eceff3">
   - Header section (logo on #a0141c background) ← UPDATE
   - Content sections (white background)
   - Footer section (#14181d background) ← UPDATE
   - Social media section
   - Copyright footer
```

### Template Inventory & Unique Elements

#### 1. **birthday.html**
- **Purpose:** Birthday greeting email
- **Unique Elements:**
  - Birthday-specific messaging
  - Gift/discount offer section
- **Violations:** All standard violations listed above

#### 2. **deposit_sold.html**
- **Purpose:** Notification that consignment items sold
- **Unique Elements:**
  - Multiple product listing sections (0-4 products)
  - Dynamic visibility based on {visibility_N} variables
  - Sold price display in Powersuit red ← UPDATE color
- **Special Notes:** Ecogaming banner image included

#### 3. **game_repost.html**
- **Purpose:** Post-purchase follow-up about Ecogaming
- **Unique Elements:**
  - Duplicate HTML structure (appears twice in file)
  - Ecogaming promotional content
  - Average used price display ← UPDATE color
- **Special Notes:** File contains complete HTML twice (lines 1-1234, 1234-2467)

#### 4. **reservation_booked.html**
- **Purpose:** Reservation confirmation
- **Unique Elements:**
  - Single product display
  - Store location information section (light gray background #e6e9ed)
  - Payment information section
  - Icons for delivery and payment
- **Special Notes:** More structured layout with information cards

#### 5. **reservation_ready.html**
- **Purpose:** Reservation ready for pickup
- **Unique Elements:**
  - Single product display
  - Ecogaming promotional section
  - Store location information
  - Additional ecogaming banner image
- **Special Notes:** Similar structure to reservation_booked.html

#### 6. **second_hand.html**
- **Purpose:** New second-hand inventory notification
- **Unique Elements:**
  - Multiple product listings (visible + hidden for dynamic content)
  - Product descriptions with ellipsis
  - Uses display:none for conditional products
- **Special Notes:** Includes hidden product templates for dynamic expansion

#### 7. **welcome_store.html**
- **Purpose:** Welcome email for in-store customers
- **Unique Elements:**
  - Store-specific welcome messaging
  - Loyalty program information
- **Violations:** All standard violations

#### 8. **welcome_web.html**
- **Purpose:** Welcome email for web customers
- **Unique Elements:**
  - Web-specific welcome messaging
  - Account setup information
- **Violations:** All standard violations

---

## Implementation Checklist

### For Each Template

- [ ] Update all `font-family: 'Open sans'` → `font-family: 'Red Hat Text'`
- [ ] Update all `bgcolor="#a0141c"` → `bgcolor="#FF143E"`
- [ ] Update all `color:#a0141c` → `color:#FF143E"`
- [ ] Update all `bgcolor="#14181d"` → `bgcolor="#1D1D1B"`
- [ ] Update all `color:#14181d` → `color:#1D1D1B"`
- [ ] Update logo src to new brand asset path
- [ ] Verify all color values match brand palette exactly
- [ ] Test rendering in major email clients
- [ ] Validate HTML structure remains intact
- [ ] Check responsive media queries still function

---

## Brand Compliance Validation

### Required Brand Elements

✅ **Colors (Exact HEX values required):**
- Black: `#1D1D1B` (RGB: 29, 29, 27)
- White: `#FFFFFF` (RGB: 255, 255, 255)
- Powersuit (primary accent): `#FF143E` (RGB: 255, 20, 62)
- Pacman (secondary accent): `#F9EB0F` (RGB: 249, 235, 15)

✅ **Typography:**
- Font family: Red Hat Text
- Title weight: Bold
- Subtitle weight: Medium
- Body text weight: Regular

✅ **Logo:**
- No modifications to spacing, alignment, or scale
- Use approved variants from brand assets
- Maintain aspect ratio
- Ensure sufficient breathing room

### Email Client Compatibility Notes

The templates must maintain compatibility with:
- Gmail (web, iOS, Android)
- Outlook (Windows, Mac, web)
- Apple Mail (iOS, macOS)
- Yahoo Mail
- Other common email clients

**Web Fonts Consideration:**
- `Red Hat Text` may not be supported in all email clients
- Include fallback: `'Red Hat Text', Arial, sans-serif`
- Consider using web font import if email platform supports it

---

## Testing Strategy

### Visual Regression Testing

Compare before/after screenshots for each template:

1. **Header section** - Logo and brand color
2. **CTA buttons** - Color accuracy
3. **Price/accent text** - Color consistency
4. **Footer section** - Background color
5. **Overall typography** - Font rendering

### Brand Compliance Checks

For each updated template, verify:

- [ ] All colors match brand palette exactly (use color picker)
- [ ] No instances of old colors (#a0141c, #14181d) remain
- [ ] Font-family is Red Hat Text throughout
- [ ] Logo maintains original proportions
- [ ] High contrast maintained for readability

### Functional Testing

- [ ] All dynamic variables still work ({contactfield=firstname}, {products_name_0}, etc.)
- [ ] Conditional visibility sections function correctly
- [ ] Links are not broken
- [ ] Images load correctly
- [ ] Responsive design works on mobile
- [ ] Email renders in test email clients

---

## Risk Assessment

### Low Risk
- Font family changes (simple find/replace)
- Color hex code updates (simple find/replace)
- Logo path updates (single location per template)

### Medium Risk
- Email client compatibility with Red Hat Text font
- Color rendering across different email clients
- Image hosting changes if logo path is modified

### Mitigation Strategies
- Test in multiple email clients before deployment
- Keep Arial as fallback font
- Maintain table-based layout for maximum compatibility
- Use color profiles that work across platforms
- Document all changes for rollback if needed

---

## Estimated Scope

### Changes Per Template
- **Estimated replacements:** 30-50 instances per template
- **Code changes:** ~200-300 lines modified per template
- **Total across 8 templates:** ~1,600-2,400 line changes

### Breakdown by Category
- Font family updates: ~15 instances × 8 templates = 120 changes
- Powersuit color updates: ~10 instances × 8 templates = 80 changes
- Footer color updates: ~5 instances × 8 templates = 40 changes
- Logo updates: 1 instance × 8 templates = 8 changes

---

## Deliverables

1. **8 Updated HTML Email Templates** with brand-compliant styling
2. **Before/After Documentation** showing key visual changes
3. **Testing Report** confirming email client compatibility
4. **Brand Compliance Certificate** verifying all templates meet guidelines

---

## Next Steps

### Recommended Approach

1. **Create backup** of all current templates
2. **Update one template first** (e.g., welcome_web.html) as proof of concept
3. **Test thoroughly** in multiple email clients
4. **Get stakeholder approval** on visual changes
5. **Apply changes systematically** to remaining templates
6. **Conduct final QA** across all templates
7. **Deploy to staging** environment
8. **Production deployment** after final approval

### Questions to Resolve Before Implementation

1. **Logo hosting:** Where will the new brand logo files be hosted?
   - Current: `http://mailing.smartoys.be/media/images/generic/logo.png`
   - New location needed for brand assets

2. **Web font delivery:** Should we implement web font loading for Red Hat Text?
   - Pros: Better brand consistency
   - Cons: Limited email client support, potential loading issues

3. **Deployment timeline:** When should updated templates go live?
   - Coordinate with marketing campaigns
   - Consider phased rollout vs. all-at-once

4. **Approval process:** Who needs to sign off on visual changes?
   - Brand team
   - Marketing team
   - Technical team

---

## Appendix: Color Reference Quick Guide

### Brand Colors (Official)
```css
/* Primary */
--brand-black: #1D1D1B;
--brand-white: #FFFFFF;

/* Accents */
--powersuit-red: #FF143E;    /* Primary accent - replaces #a0141c */
--pacman-yellow: #F9EB0F;    /* Secondary accent */
```

### Old Colors to Remove
```css
--old-maroon: #a0141c;       /* REMOVE - replace with #FF143E */
--old-footer: #14181d;       /* REMOVE - replace with #1D1D1B */
```

### Acceptable Supporting Colors
```css
--email-bg: #eceff3;         /* OK - light gray for email body */
--info-section: #e6e9ed;     /* OK - for information cards */
--separator: #ebebeb;        /* OK - for dividers */
--text-gray: #7f8c8d;        /* OK - for secondary text */
--text-mid: #3b3b3b;         /* OK - for body text on white */
--note-text: #696969;        /* OK - for disclaimer text */
```

---

## Implementation Files Reference

### Source Files
- Brand Guidelines: `examples/smartoys/templates/brand/smartoys-brand.md`
- Logo Assets: `examples/smartoys/templates/brand/_Smartoys_logo_*.png`

### Templates to Update
```
examples/smartoys/templates/html/
├── birthday.html
├── deposit_sold.html
├── game_repost.html
├── reservation_booked.html
├── reservation_ready.html
├── second_hand.html
├── welcome_store.html
└── welcome_web.html
```

### Output Location
Same directory - files will be updated in place (with backups recommended)

---

**Document Version:** 1.0  
**Created:** 2026-01-03  
**Author:** Architect Mode  
**Status:** Ready for Implementation
