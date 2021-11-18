-- Copyright 2007-2021 Mitchell. See LICENSE.
-- Light theme for Textadept.
-- Contributions by Ana Balan.

local view, colors, styles = view, lexer.colors, lexer.styles

-- Greyscale colors.
colors.dark_black = 0x282B2F
colors.black = 0x484B4F -- #5F5B58
colors.light_black = 0x686B6F -- #6F6B68
colors.grey_black = 0x616468 -- #686461
colors.dark_grey = 0x787B7F -- #7F7B78
colors.grey = 0x888B8F -- #8F8B88
colors.light_grey = 0x989B9F -- #9F9B98
colors.grey_white = 0xB7B8BF -- #BFB8B7
colors.dark_white = 0xC7C8CF -- #CFC8C7
colors.white = 0xECECEC
colors.light_white = 0xFFFFFF

-- Dark colors.
colors.dark_red = 0x083880 -- #803808
colors.dark_blue = 0xC09050 -- #5090C0
colors.dark_yellow = 0x98A8B0 -- #B0A898
colors.dark_green = 0xC09050 -- #5090C0
colors.dark_teal = colors.dark_green
colors.dark_purple = 0x085090 -- #905008
colors.dark_orange = 0x3060A0 -- #A06030
colors.dark_pink = colors.dark_purple
colors.dark_lavender = colors.dark_purple

-- Normal colors.
colors.red = 0x3060C0 -- '#C06030'
colors.blue = 0xE0D0C0 -- '#C0D0E0'
colors.yellow = 0xB8C8D0 -- '#D0C8B8'
colors.green = 0xE0B070 -- '#70B0E0'
colors.teal = colors.green
colors.purple = 0x2870B0 -- '#B07028'
colors.orange = 0x70A8E0 -- '#E0A870'
colors.pink = colors.purple
colors.lavender = colors.purple

-- Light colors.
colors.light_red = 0x70A8E0 -- '#E0A870'
colors.light_blue = 0xF8E0C8 -- '#C8E0F8'
colors.light_yellow = 0xD8E8F0 -- '#F0E8D8'
colors.light_green = 0xF0A080 -- '#80A0F0'
colors.light_teal = colors.light_green
colors.light_purple = 0x3880C0 -- '#C08038'
colors.light_orange = 0x80B8F0 -- '#F0B880'
colors.light_pink = colors.light_purple
colors.light_lavender = colors.light_purple

if false then end

-- Default font.
if not font then
  font = WIN32 and 'Courier New' or OSX and 'Monaco' or 'Bitstream Vera Sans Mono'
end
if not size then size = not OSX and 10 or 12 end
if not bgcol then bgcol = colors.white end

-- Predefined styles.
styles.default = {font = font, size = size, fore = colors.black, back = bgcol}
styles.line_number = {fore = colors.light_grey, back = bgcol}
-- styles.control_char = {}
styles.indent_guide = {fore = colors.dark_white}
styles.call_tip = {fore = colors.light_black, back = colors.dark_white}
styles.fold_display_text = {fore = colors.grey}

-- Token styles.
styles.comment = {fore = colors.light_grey, italics = true}
styles.constant = {fore = colors.red}
styles.embedded = {fore = colors.dark_blue, back = colors.dark_white}
styles.error = {fore = colors.red, italics = true}
styles['function'] = {fore = colors.dark_orange}
styles.identifier = {  }
styles.keyword = {fore = colors.dark_grey, italics = true, underlined = true}
styles.label = {fore = colors.dark_orange}
styles.number = {fore = colors.dark_purple, bold = true}
styles.operator = {fore = colors.dark_green}
styles.preprocessor = {fore = colors.dark_yellow}
styles.regex = {fore = colors.dark_green}
styles.string = {fore = colors.dark_purple, bold = true, italics = true}
styles.type = {fore = colors.lavender}
styles.variable = {fore = colors.dark_lavender}
styles.whitespace = { fore = colors.grey_white }

-- Element colors.
-- view.element_color[view.ELEMENT_SELECTION_TEXT] = colors.light_black
view.element_color[view.ELEMENT_SELECTION_BACK] = colors.grey_white
-- view.element_color[view.ELEMENT_SELECTION_ADDITIONAL_TEXT] = colors.light_black
view.element_color[view.ELEMENT_SELECTION_ADDITIONAL_BACK] = colors.grey_white
-- view.element_color[view.ELEMENT_SELECTION_SECONDARY_TEXT] = colors.light_black
view.element_color[view.ELEMENT_SELECTION_SECONDARY_BACK] = colors.grey_white
-- view.element_color[view.ELEMENT_SELECTION_INACTIVE_TEXT] = colors.light_black
view.element_color[view.ELEMENT_SELECTION_INACTIVE_BACK] = colors.dark_white
view.element_color[view.ELEMENT_CARET] = colors.grey_black
-- view.element_color[view.ELEMENT_CARET_ADDITIONAL] =
view.element_color[view.ELEMENT_CARET_LINE_BACK] = 0xE0E0E0

-- Fold Margin.
view:set_fold_margin_color(true, bgcol)
view:set_fold_margin_hi_color(true, bgcol)

-- Markers.
-- view.marker_fore[textadept.bookmarks.MARK_BOOKMARK] = colors.white
view.marker_back[textadept.bookmarks.MARK_BOOKMARK] = colors.dark_blue
-- view.marker_fore[textadept.run.MARK_WARNING] = colors.white
view.marker_back[textadept.run.MARK_WARNING] = colors.light_yellow
-- view.marker_fore[textadept.run.MARK_ERROR] = colors.white
view.marker_back[textadept.run.MARK_ERROR] = colors.light_red
for i = buffer.MARKNUM_FOLDEREND, buffer.MARKNUM_FOLDEROPEN do -- fold margin
  view.marker_fore[i] = colors.white
  view.marker_back[i] = colors.grey
  view.marker_back_selected[i] = colors.grey_black
end

-- Indicators.
view.indic_fore[ui.find.INDIC_FIND] = colors.yellow
view.indic_alpha[ui.find.INDIC_FIND] = 128
view.indic_fore[textadept.editing.INDIC_BRACEMATCH] = colors.dark_black
view.indic_stroke_width[textadept.editing.INDIC_BRACEMATCH] = 1000
view.indic_fore[textadept.editing.INDIC_HIGHLIGHT] = colors.orange
view.indic_alpha[textadept.editing.INDIC_HIGHLIGHT] = 128
view.indic_fore[textadept.snippets.INDIC_PLACEHOLDER] = colors.grey_black

-- Call tips.
view.call_tip_fore_hlt = colors.light_blue

-- Long Lines.
view.edge_color = colors.grey

-- Find & replace pane entries.
ui.find.entry_font = font .. ' ' .. size
