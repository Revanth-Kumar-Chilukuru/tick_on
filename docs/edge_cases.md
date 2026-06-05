# TickOn Edge Cases & Future Considerations

This document tracks edge cases and how we handle them to make the app robust.

### 1. Long Task Titles
**Scenario:** A user types a very long paragraph as a task title.
**Handling:** We enforce a `maxLength` on the input field and use text wrapping + ellipses (`TextOverflow.ellipsis`) in the UI cards so the layout doesn't break.

### 2. Rapid Checkbox Spamming
**Scenario:** User rapidly taps the checkbox multiple times to see animations or try to break the state.
**Handling:** An Easter Egg is triggered! We track the rapid taps. If a threshold is crossed, we show a dialog: *"Go focus on your work instead of playing with this. - Revanth"*.

### 3. Late Night Routine Resets
**Scenario:** A night owl stays up past midnight. At 12:01 AM, their routines for the "previous day" reset before they go to sleep.
**Handling:** Added a "Day Starts At" setting (e.g., 3:00 AM) so the app calculates "today" based on the user's customized waking hour.

### 4. Unticking Completed Items
**Scenario:** A user accidentally completes a task and tries to untick it.
**Handling:** 
- **Routines:** Shows a quiet SnackBar with an "Undo" option.
- **Tasks:** Shows a Lottie dialog asking *"But you said you completed, what changed? - Revanth"*.

### 5. App Smoothness (High Refresh Rate)
**Scenario:** Modern phones have 90Hz/120Hz displays. Flutter apps can sometimes stutter if state rebuilds are too heavy.
**Handling:** Using `const` constructors everywhere, minimizing Provider rebuilds by using `Consumer` strictly on small widgets, and caching animations.
