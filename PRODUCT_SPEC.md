# Beans: Product Specification

## 1. Product Vision

**Beans is a privacy-first, offline-first article reader designed for commuters who want a distraction-free reading experience.**

It's like a warm cup of coffee for your articles - save them, savor them, enjoy them anywhere, anytime.

---

## 2. The Problem

Commuters and power users want to read saved articles without:
- Internet dependency (subway, planes, dead zones)
- Ads and clutter
- Sync issues
- Privacy concerns with cloud-based readers

---

## 3. The User Persona

**The Coffee Reader**: A power user who reads 10-50 articles per week, values privacy, and wants a curated reading experience that works offline. They're technical enough to install apps and share content, but want a magical, effortless experience.

---

## 4. The Experience

### 4.1 The Save Moment

**Trigger**: User finds an article they want to read later.

**Action**: Tap "Share" → Select "Beans"

**What Happens**:
- "Blending beans" animation plays (coffee beans swirl and blend)
- Article immediately downloads in background
- Haptic feedback when complete
- Notification: "Your coffee is ready!"

**Emotion**: "That was satisfying. It just works."

---

### 4.2 The Discovery Experience (To-Read)

**Visual**: Warm, cozy coffee shop aesthetic

**Navigation**: Tinder-style card stack

**Card Shows**:
- Article title (prominent, beautiful typography)
- Author/site name (smaller, muted)
- Domain favicon
- Estimated reading time (e.g., "5 min brew")
- A subtle coffee-colored progress indicator

**Interactions**:
- **Swipe right** → Open and start reading
- **Swipe left** → Skip/remove from queue
- **Tap** → Quick preview modal (first few paragraphs)
- **Long press** → Move to another section or delete

**Emotion**: "This is fun, like discovering new coffee blends."

---

### 4.3 The Reading Experience

**Visual**: Clean, typography-focused, zero distractions

**Layout**:
- Title at top
- Author/site below
- Beautiful typography (serif for long-form)
- Progress bar at bottom (subtle)
- Theme toggle (top right)

**Themes**:
- **Light**: Like a bright café (white, soft grays, coffee accents)
- **Sepia**: Like old paper books (warm beige, brown ink)
- **Dark**: Like reading by lamplight (deep charcoal, warm text)

**Features**:
- Auto-save reading position
- Tap edges to page up/down
- Pinch to adjust font size
- "Done" button to mark complete
- "Save for later" button to re-queue

**Emotion**: "I can focus. This feels peaceful."

---

### 4.4 The Organization Model

Three sections, three mental states:

**To-Read** → "What's in my queue?"
- Swipe navigation
- Fresh, undiscovered articles
- Excitement, curiosity

**In-Progress** → "What was I reading?"
- List view (no swipes)
- Partially read articles
- Continuity, return

**Read** → "What have I enjoyed?"
- List view with search
- Completed archive
- Satisfaction, reference

**Section Transitions**:
- Automatic based on reading progress
- Manual override (user control)
- "Save for later" always available

---

## 5. Key Features

### Core Features (MVP)

1. **Save from Anywhere**
   - iOS Share Sheet integration
   - Instant download
   - Coffee bean animation

2. **Swipe to Discover**
   - Tinder-style card navigation
   - Quick preview on tap
   - Estimated reading time

3. **Distraction-Free Reading**
   - Three themes (Light/Sepia/Dark)
   - Beautiful typography
   - Reading progress tracking
   - Auto-save position

4. **Smart Organization**
   - Three-section model
   - Auto-move on completion
   - Manual overrides

5. **Offline-First**
   - Works without internet
   - All content downloaded
   - No sync dependencies

---

## 6. The Coffee Theme

**Visual Language**:
- Warm color palette (espresso, latte, crema tones)
- Organic shapes, soft edges
- Subtle animations (steam rising, beans swirling)
- Cozy, inviting atmosphere

**Metaphors**:
- Save = "Brewing" or "Blending beans"
- Read = "Sipping" or "Enjoying"
- Queue = "Coffee bar" or "Brew list"
- Archive = "Finished cups"

**Emotion**: Warm, comforting, personal

---

## 7. Success Criteria

**User Experience**:
- Save animation feels magical (haptic + visual)
- To-Read swipe navigation is fun, not tedious
- Reading experience is distraction-free
- Offline mode works flawlessly
- App feels native and responsive

**Engagement**:
- Users save 5+ articles in first week
- Users complete 50%+ of saved articles
- Users open app 3+ times per week
- Low churn after first month

**Delight**:
- "Wow" moment on first save
- Comments like "This feels so nice"
- Word-of-mouth sharing

---

## 8. Anti-Patterns (What We're NOT)

- ❌ Not a social network (no sharing, no comments)
- ❌ Not a newsletter reader (different use case)
- ❌ Not a bookmark manager (too static)
- ❌ Not a Pocket clone with coffee skin (different UX philosophy)
- ❌ Not a productivity tool (no goals, no streaks, no guilt)

---

## 9. Future Directions (Post-MVP)

**Phase 2: Search & Organization**
- Full-text search across all articles
- Tags and collections
- Smart folders (auto-group by domain, topic)

**Phase 3: Intelligence**
- AI article summarization (local, private)
- Auto-tagging and categorization
- Reading recommendations

**Phase 4: Multi-Platform**
- Mac companion app
- Web reader for desktop
- Android version

---

*Version: 1.0*
*Last Updated: 2025-12-25*
