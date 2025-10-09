# UI Architecture Guide

## 🎯 Component-Based UI System

This project uses a **component-based UI architecture** to make UI editing easier for artists and maintain cleaner code for developers.

---

## 📁 Folder Structure

```
scenes/
  ui/
    components/          # Small reusable UI pieces
    sections/           # Composed UI sections
    menus/             # Complete standalone menus
    overlays/          # Full-screen overlays

scripts/ui/
  components/          # Scripts for components
  sections/           # Scripts for sections
  menus/             # Scripts for menus
```

---

## 🏗️ Architecture Principles

### 1. **Components are Reusable Scenes**
Instead of creating UI with code like this:
```gdscript
# ❌ OLD WAY - Creates UI in code
var checkbox = CheckBox.new()
checkbox.text = "Era: ANCIENT"
add_child(checkbox)
```

We now use pre-built scene components:
```gdscript
# ✅ NEW WAY - Instantiate scene component
const CHECKBOX_SCENE = preload("res://scenes/ui/components/advert_checkbox.tscn")
var checkbox = CHECKBOX_SCENE.instantiate()
checkbox.setup("Era: ANCIENT", {"type": "era"})
add_child(checkbox)
```

### 2. **Composition over Creation**
Build complex UIs by composing smaller components together in the scene editor, not in code.

### 3. **Data-Driven Components**
Components expose clean APIs. You pass data to them, they handle displaying it.

```gdscript
# Component API example
advertisement_section.populate_for_soul(soul, discovery_log)
```

### 4. **Separation of Concerns**
- **Artists** control layout, spacing, colors, fonts (in .tscn files)
- **Developers** control logic, data flow, signals (in .gd files)

---

## 📦 Component Types

### **Tier 1: Components** (Building Blocks)
Small, focused, single-purpose UI elements.

**Example: `advert_checkbox.tscn`**
```
AdvertCheckBox (CheckBox)
  └─ Script: advert_checkbox.gd
```

**Usage:**
```gdscript
var checkbox = AdvertCheckBox.new()  # or instantiate scene
checkbox.setup("Era: ANCIENT", {"type": "era"})
checkbox.set_checked_silent(true)
checkbox.toggled_with_data.connect(_on_checkbox_toggled)
```

**What Artists Can Edit:**
- Checkbox size, font, colors
- Spacing and padding
- Hover/pressed/disabled states (in theme)

---

### **Tier 2: Sections** (Composed Components)
Larger UI sections composed from multiple components.

**Example: `advertisement_section.tscn`**
```
AdvertisementSection (VBoxContainer)
  ├─ Separator (HSeparator)
  ├─ Header (Label) - "ADVERTISE PROPERTIES"
  └─ ContentMargin (HBoxContainer)
      ├─ Indent (Control)
      └─ ControlsVBox (VBoxContainer)
          ├─ EraCheckbox (AdvertCheckBox instance)
          ├─ DeathCheckbox (AdvertCheckBox instance)
          ├─ StatsLabel (Label)
          └─ StatsContainer (VBoxContainer)
```

**Usage:**
```gdscript
advertisement_section.populate_for_soul(soul, discovery_log)
# That's it! Component handles everything internally
```

**What Artists Can Edit:**
- Entire section layout
- Spacing between elements
- Header text and color
- Indentation amount
- Background styling

---

### **Tier 3: Menus** (Complete Systems)
Full menu systems composed from sections and components.

**Example: `soul_context_menu.tscn`**
```
SoulContextMenu (Control)
  └─ Panel (PanelContainer)
      └─ MainVBox (VBoxContainer)
          ├─ TitleLabel
          ├─ ColumnsHBox (left/right info display)
          ├─ JobStatusContainer
          ├─ AdvertisementSection (instance)
          └─ ButtonsHBox (action buttons)
```

**What Artists Can Edit:**
- Overall menu size and position
- Panel background style
- Button arrangement and styling
- Spacing between all sections

---

## 🎨 Benefits for Artists

### **Visual Editing**
1. Open any component in Godot editor
2. See the actual UI layout
3. Drag/drop to rearrange
4. Adjust properties visually
5. Preview in isolation

### **Consistent Styling**
- Edit a component once, updates everywhere
- Use theme system for global styling
- Override per-instance when needed

### **No Code Required**
- Change colors, fonts, sizes → just edit scene properties
- Rearrange layout → drag nodes in scene tree
- Adjust spacing → edit container properties

---

## 💻 Benefits for Developers

### **Cleaner Code**
Before:
```gdscript
# 150 lines of UI creation code
var separator = HSeparator.new()
add_child(separator)
var label = Label.new()
label.text = "..."
label.add_theme_color_override(...)
add_child(label)
# ... 140 more lines
```

After:
```gdscript
# One line
advertisement_section.populate_for_soul(soul, discovery_log)
```

### **Better Testing**
- Test components in isolation
- Create test scenes for individual components
- Easier to debug specific UI pieces

### **Reusability**
- Use same component in multiple menus
- Consistent behavior across game
- DRY (Don't Repeat Yourself) principle

---

## 📚 Existing Components

### Components (`scenes/ui/components/`)

#### `advert_checkbox.tscn`
Universal checkbox for all advertisement types (properties, stats, etc).

**API:**
```gdscript
setup(display_text: String, user_data: Dictionary = {})
set_checked_silent(is_checked: bool)
signal toggled_with_data(is_checked: bool, user_data: Dictionary)
```

**Examples:**
```gdscript
# Simple property
checkbox.setup("Era: ANCIENT", {"type": "era"})

# Stat with exact value
checkbox.setup("  Strength: 85 (exact)", {
    "type": "stat",
    "stat_key": 0,
    "advert_type": "exact",
    "value": 85
})

# Stat with range
checkbox.setup("  Intelligence: 70-90 (range)", {
    "type": "stat",
    "stat_key": 1,
    "advert_type": "range",
    "min": 70,
    "max": 90
})
```

### Sections (`scenes/ui/sections/`)

#### `advertisement_section.tscn`
Complete advertisement controls section with all checkboxes.

**API:**
```gdscript
populate_for_soul(soul: SoulData, discovery_log: DiscoveryLog)
```

---

## 🚀 Creating New Components

### Step 1: Create Component Scene
```
scenes/ui/components/my_component.tscn
```
1. Create in Godot: Scene → New Scene
2. Choose root node type (Button, Label, VBoxContainer, etc)
3. Build structure visually
4. Attach script

### Step 2: Create Component Script
```gdscript
# scripts/ui/components/my_component.gd
extends Button
class_name MyComponent

## Brief description

signal interaction_happened(data)

## Public API function
func setup_with_data(data: Dictionary) -> void:
	text = data.get("label", "Default")
	# ... configure component
```

### Step 3: Use Component
```gdscript
# In another script
const MY_COMPONENT = preload("res://scenes/ui/components/my_component.tscn")

func add_items():
	var component = MY_COMPONENT.instantiate()
	component.setup_with_data({"label": "Click Me"})
	component.interaction_happened.connect(_on_interaction)
	container.add_child(component)
```

---

## 🔄 Migration Guide

### Converting Code-Based UI to Components

**Before:**
```gdscript
func _ready():
	var label = Label.new()
	label.text = "Hello"
	label.add_theme_color_override("font_color", Color.RED)
	add_child(label)
```

**After:**
1. Create `info_label.tscn` with Label node
2. Set color in scene properties (not code)
3. Create script with `set_text()` method
4. Use: `label.set_text("Hello")`

---

## 🎯 Best Practices

### ✅ DO
- Create small, focused components
- Use clear, descriptive names
- Expose clean public APIs
- Keep styling in scenes, logic in scripts
- Document component APIs
- Use signals for communication

### ❌ DON'T
- Create UI with `.new()` in code
- Hardcode colors/fonts in scripts
- Make giant multi-purpose components
- Mix business logic with UI code
- Create deep inheritance hierarchies

---

## 🔮 Future Improvements

### Potential Additional Components
- `action_button.tscn` - Styled button with icon support
- `info_panel.tscn` - Panel with header/content structure
- `confirmation_dialog.tscn` - Reusable confirmation popup
- `stat_display.tscn` - Display stat name/value/bar

### Potential Sections
- `soul_details_section.tscn` - Two-column soul info
- `button_bar.tscn` - Horizontal action buttons
- `inventory_list_item.tscn` - Single soul in list

### Theme System
- Create centralized theme resource
- Define all colors/fonts once
- Apply globally to all components

---

## 📞 Questions?

**For Artists:**
- "Where do I change button colors?" → Edit the scene properties
- "How do I rearrange elements?" → Drag in scene tree
- "Can I preview this?" → Yes! Open component scene

**For Developers:**
- "How do I instantiate?" → `SCENE.instantiate()`
- "How do I pass data?" → Call component's public methods
- "How do I get events?" → Connect to component signals

---

## 📝 Example: Full Workflow

### Artist Task: "Make buttons bigger"
1. Open `scenes/ui/menus/soul_context_menu.tscn`
2. Select button node
3. Change `custom_minimum_size.x` to 120
4. Save
5. Done! Changes apply everywhere

### Developer Task: "Add new property checkbox"
1. Open `scenes/ui/sections/advertisement_section.tscn`
2. Drag `property_checkbox.tscn` into ControlsVBox
3. Name it appropriately
4. Open `advertisement_section.gd`
5. Add `@onready var new_checkbox = $Path/To/NewCheckbox`
6. Configure in `populate_for_soul()` method
7. Connect signal if needed

---

Built with ❤️ for better UI development!
