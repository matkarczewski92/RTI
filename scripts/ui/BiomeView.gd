extends Control

signal biome_map_requested

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")
const LayoutScale := preload("res://scripts/helpers/LayoutScale.gd")

const TOP_BAR_SCENE := preload("res://scenes/ui/TopBar.tscn")
const BOTTOM_NAV_SCENE := preload("res://scenes/ui/BottomNav.tscn")
const HABITAT_SLOT_SCENE := preload("res://scenes/habitat/HabitatSlot.tscn")
const OFFLINE_INCOME_POPUP_SCRIPT := preload("res://scripts/ui/OfflineIncomePopup.gd")
const SETTINGS_MODAL_SCRIPT := preload("res://scripts/ui/SettingsModal.gd")

const BACKGROUND_PATH := "res://assets/art/biomes/green_meadow_background.png"
const BIOMES_CONFIG_PATH := "res://data/biomes.json"
const LOGO_PATH := "res://assets/art/ui/logo.png"
const EDIT_ICON_PATH := "res://assets/art/ui/icons/menu/edit_icon.png"
const MALE_ICON_PATH := "res://assets/art/ui/icons/menu/male.png"
const FEMALE_ICON_PATH := "res://assets/art/ui/icons/menu/female.png"
const FREE_ICON_PATH := "res://assets/art/ui/icons/menu/free.png"
const ASSIGNED_ICON_PATH := "res://assets/art/ui/icons/menu/in_habitad.png"
const HAPPY_ICON_PATH := "res://assets/art/ui/icons/menu/happy.png"
const INCOME_ICON_PATH := "res://assets/art/ui/icons/menu/income.png"
const FOOD_ICON_PATH := "res://assets/art/ui/icons/menu/food.png"
const WATER_ICON_PATH := "res://assets/art/ui/icons/menu/water.png"
const CLEAN_ICON_PATH := "res://assets/art/ui/icons/menu/clean.png"
const PLAY_ICON_PATH := "res://assets/art/ui/icons/menu/play.png"
const FOOD_ACTION_ICON_PATH := "res://assets/art/ui/icons/menu/food_add.png"
const WATER_ACTION_ICON_PATH := "res://assets/art/ui/icons/menu/wather_add.png"
const CLEAN_ACTION_ICON_PATH := "res://assets/art/ui/icons/menu/clean_add.png"
const COOLDOWN_ICON_PATH := "res://assets/art/ui/icons/menu/cooldown.png"
const ALERT_ICON_PATH := "res://assets/art/ui/icons/menu/alert.png"
const WORKERS_ICON_PATH := "res://assets/art/ui/icons/menu/emp_team.png"
const UPGRADE_BUTTON_ICON_PATH := "res://assets/art/ui/icons/menu/upgrade_button.png"
const UPGRADES_DESIGN_DIR := "res://assets/art/ui/upgrades_design/"
const UPGRADES_BG_PATH          := UPGRADES_DESIGN_DIR + "background.png"
const UPGRADES_TITLE_PL_PATH    := UPGRADES_DESIGN_DIR + "upgrades_pl.png"
const UPGRADES_TITLE_EN_PATH    := UPGRADES_DESIGN_DIR + "upgrades_en.png"
const UPGRADES_ROW_BG_PATH      := UPGRADES_DESIGN_DIR + "single_quest_background.png"
const UPGRADES_PRICE_BADGE_PATH := UPGRADES_DESIGN_DIR + "price.png"
const UPGRADES_BUY_PL_PATH      := UPGRADES_DESIGN_DIR + "buy_button_pl.png"
const UPGRADES_BUY_EN_PATH      := UPGRADES_DESIGN_DIR + "buy_button_en.png"
const UPGRADES_LEVEL_ICON_PATH  := UPGRADES_DESIGN_DIR + "upgrade_lvl.png"
const UPGRADES_CURRENT_ICON_PATH := UPGRADES_DESIGN_DIR + "actual.png"
const UPGRADES_NEXT_ICON_PATH   := UPGRADES_DESIGN_DIR + "next_lvl.png"

# Przycisk zamknięcia
const UPGRADE_CLOSE_ANCHOR_LEFT   := 0.785
const UPGRADE_CLOSE_ANCHOR_TOP    := 0.052
const UPGRADE_CLOSE_ANCHOR_RIGHT  := 0.945
const UPGRADE_CLOSE_ANCHOR_BOTTOM := 0.160

# Grafika tytułu (upgrades_pl / upgrades_en) — −35% z zachowaniem środka
const UPGRADE_TITLE_ANCHOR_LEFT   := 0.316
const UPGRADE_TITLE_ANCHOR_TOP    := 0.026
const UPGRADE_TITLE_ANCHOR_RIGHT  := 0.719
const UPGRADE_TITLE_ANCHOR_BOTTOM := 0.116

# Obszar scrolla z listą ulepszeń — kafelki −15% szerokości
const UPGRADES_VIEW_EXTRA_H_FRAC   := 0.10   # o tyle % wyższe tło Ulepszeń
const UPGRADE_SCROLL_LEFT_ANCHOR   := 0.115
const UPGRADE_SCROLL_TOP_ANCHOR    := 0.15
const UPGRADE_SCROLL_RIGHT_ANCHOR  := 0.880
const UPGRADE_SCROLL_BOTTOM_ANCHOR := 0.955

# Kafelek pojedynczego ulepszenia
const UPGRADE_CARD_MIN_HEIGHT  := 405  # minimalna wysokość kafelka (+10%)
const UPGRADE_INFO_ICON_SIZE   := 33   # rozmiar ikon przy wierszach info
const UPGRADE_ACTION_TOP_SPACER := 68  # odstęp górny przed badge/button (przesuwa w dół)
const UPGRADE_CARD_MARGIN_LEFT := 18   # lewy margines wewnętrzny (px)
const UPGRADE_CARD_MARGIN_V    := 14   # górny/dolny margines wewnętrzny (px)
const UPGRADE_CARD_CONTENT_V_EXTRA := 50  # dodatkowy margines góra/dół — zawartość o ~15% niższa, tło bez zmian
const UPGRADE_CARD_ROW_SEP     := 8   # odstęp elementów w wierszu (px)
const UPGRADE_LIST_SEPARATION  := -16  # odstęp między kafelkami (ujemny = nakładanie)

# Kolumna ikony ulepszenia
const UPGRADE_ICON_COLUMN_W := 140  # szerokość kolumny ikony (px)
const UPGRADE_ICON_SIZE     := 136  # rozmiar ikony ulepszenia (px)

# Rozmiary tekstu w kafelku (pt)
const UPGRADE_TEXT_NAME_SIZE := 32
const UPGRADE_TEXT_DESC_SIZE := 22
const UPGRADE_TEXT_INFO_SIZE := 22

# Kolumna akcji (cena + przycisk)
const UPGRADE_ACTION_COLUMN_W    := 332  # szerokość kolumny akcji (+20% badge)
const UPGRADE_ACTION_LEFT_MARGIN := -180   # przesunięcie badge/button w prawo (~5%)
const UPGRADE_PRICE_BADGE_W      := 332  # szerokość plakietki ceny (+20%)
const UPGRADE_PRICE_BADGE_H   := 88   # wysokość plakietki ceny (px)
const UPGRADE_PRICE_TEXT_SIZE := 24
const UPGRADE_BUY_BTN_W       := 205  # szerokość przycisku Kup (+10%)
const UPGRADE_BUY_BTN_H       := 88   # wysokość przycisku Kup (px)
const SHOP_DESIGN_DIR := "res://assets/art/ui/shop_design/"
const SHOP_BG_PL_PATH := SHOP_DESIGN_DIR + "shop_pl_background.png"
const SHOP_BG_EN_PATH := SHOP_DESIGN_DIR + "shop_en_background.png"
const SHOP_RESOURCE_CARD_BG_PATH := SHOP_DESIGN_DIR + "wate_and_food_background.png"
const SHOP_REPTILE_ROW_BG_PATH := SHOP_DESIGN_DIR + "animals_background.png"
const SHOP_TITLE_PL_PATH := SHOP_DESIGN_DIR + "title_pl.png"
const SHOP_TITLE_EN_PATH := SHOP_DESIGN_DIR + "title_en.png"
const SHOP_BUY_COMMON_BUTTON_PATH := SHOP_DESIGN_DIR + "button_buy_common.png"
const SHOP_BUY_RARE_BUTTON_PATH := SHOP_DESIGN_DIR + "button_buy_rare.png"
const SHOP_FOOD_ICON_PATH := "res://assets/art/ui/icons/menu/food_ico.png"
const SHOP_WATER_ICON_PATH := "res://assets/art/ui/icons/menu/water_ico.png"
const SHOP_REPTILE_CARD_HEIGHT := 333
const SHOP_REPTILE_TEXT_BONUS := 10
const SHOP_REPTILE_PORTRAIT_SIZE := Vector2(246, 246)
const SHOP_REPTILE_HABITAT_ICON_SIZE := Vector2(98, 98)
const SHOP_REPTILE_RARITY_ICON_SIZE := Vector2(24, 24)
const SHOP_REPTILE_DROPDOWN_SIZE := Vector2(175, 54)
const SHOP_REPTILE_BUY_BUTTON_SIZE := Vector2(213, 75)
const SHOP_REPTILE_BUTTON_TEXT_BONUS := 8
const QUESTS_DESIGN_DIR := "res://assets/art/ui/quests_design/"
const QUESTS_BG_PATH       := QUESTS_DESIGN_DIR + "background.png"
const QUESTS_TITLE_PL_PATH := QUESTS_DESIGN_DIR + "tasks_pl.png"
const QUESTS_TITLE_EN_PATH := QUESTS_DESIGN_DIR + "tasks_en.png"
const QUESTS_CARD_BG_PATH  := QUESTS_DESIGN_DIR + "single_quest_background.png"
const QUESTS_CLAIM_PL_PATH := QUESTS_DESIGN_DIR + "claim_pl.png"
const QUESTS_CLAIM_EN_PATH := QUESTS_DESIGN_DIR + "claim_en.png"

# Przycisk zamknięcia (ułamek rozmiaru widoku)
const QUEST_CLOSE_ANCHOR_LEFT   := 0.785
const QUEST_CLOSE_ANCHOR_TOP    := 0.045
const QUEST_CLOSE_ANCHOR_RIGHT  := 0.945
const QUEST_CLOSE_ANCHOR_BOTTOM := 0.145

# Grafika tytułu (tasks_pl / tasks_en)
const QUEST_TITLE_ANCHOR_LEFT   := 0.310
const QUEST_TITLE_ANCHOR_TOP    := 0.030
const QUEST_TITLE_ANCHOR_RIGHT  := 0.713
const QUEST_TITLE_ANCHOR_BOTTOM := 0.120

# Obszar scrolla z listą questów
const QUEST_SCROLL_LEFT_ANCHOR   := 0.113
const QUEST_SCROLL_TOP_ANCHOR    := 0.14
const QUEST_SCROLL_RIGHT_ANCHOR  := 0.887
const QUEST_SCROLL_BOTTOM_ANCHOR := 0.985

# Kafelek pojedynczego questa
const QUEST_CARD_MIN_HEIGHT    := 268  # minimalna wysokość kafelka (px)
const QUEST_CARD_MARGIN        := 14   # wewnętrzny margines kafelka z każdej strony (px)
const QUEST_CARD_TEXT_INDENT   := 12   # wcięcie tekstów po lewej (px)
const QUEST_CARD_ROW_SEP       := 12   # odstęp między kolumną info a akcją (px)
const QUEST_LIST_SEPARATION    := 8    # odstęp między kafelkami questów (px)

# Rozmiary tekstu wewnątrz kafelka (pt)
const QUEST_TEXT_TITLE_SIZE    := 29
const QUEST_TEXT_DESC_SIZE     := 24
const QUEST_TEXT_PROGRESS_SIZE := 24
const QUEST_TEXT_REWARD_SIZE   := 24
const QUEST_TEXT_STATUS_SIZE   := 24

# Rozmiar przycisku Odbierz
const QUEST_CLAIM_BTN_W := 190
const QUEST_CLAIM_BTN_H := 80

# Progressbar questa
const QUEST_PROGRESS_BAR_HEIGHT      := 20   # wysokość paska (+50% z 13px)
const QUEST_PROGRESS_BAR_WIDTH_RATIO := 0.80 # szerokość paska (0.80 = -20%)
const QUEST_ACTION_RIGHT_PADDING     := 18   # przesunięcie przycisku w lewo (≈5% karty)
const ANIMALS_DESIGN_DIR := "res://assets/art/ui/animals_design/"
const ANIMALS_BG_PATH := ANIMALS_DESIGN_DIR + "background.png"
const ANIMALS_SINGLE_CARD_BG_PATH := ANIMALS_DESIGN_DIR + "single_background.png"
const ANIMALS_REF_SIZE := Vector2(911, 1672)
# Animals screen layout knobs in background.png reference pixels. Adjust these to fine tune the design overlay.
const ANIMALS_TITLE_RECT := Rect2(280, 77, 367, 151)
const ANIMALS_OWNED_TAB_RECT := Rect2(32, 337, 260, 96)
const ANIMALS_GALLERY_TAB_RECT := Rect2(327, 337, 260, 96)
const ANIMALS_ACHIEVEMENTS_TAB_RECT := Rect2(625, 337, 260, 96)
const ANIMALS_CLOSE_BUTTON_RECT := Rect2(780, 130, 118, 118)
const ANIMALS_CONTENT_AREA_RECT := Rect2(74, 496, 820, 1144)
const ANIMALS_PANEL_TOP_GAP := 0.0
const ANIMALS_PANEL_BOTTOM_GAP := 0.0
const ANIMALS_WINDOW_EXTRA_W := 1.15  # szerokość okna bez zmiany zawartości (+15%)
const ANIMALS_WINDOW_EXTRA_H := 1.05  # wysokość okna bez zmiany zawartości (+5%)
const ANIMALS_CONTENT_X_OFFSET := 0.05  # przesunięcie zawartości w prawo (% szer. okna)
const ANIMALS_TITLE_X_EXTRA    := 0.00  # dodatkowe przesunięcie tytułu w prawo
const ANIMALS_TABS_X_EXTRA     := 0.00  # dodatkowe przesunięcie zakładek w prawo
const ANIMALS_TAB_RAISE_RATIO := 0.57
const ANIMALS_TAB_GRAPHIC_SCALE := 0.80
const ANIMALS_ACTIVE_TAB_UNDERLINE_COLOR := Color(1.0, 0.78, 0.16, 1.0)
const ANIMALS_ACTIVE_TAB_UNDERLINE_WIDTH_RATIO := 0.46
const ANIMALS_ACTIVE_TAB_UNDERLINE_HEIGHT_RATIO := 0.035
const ANIMALS_ACTIVE_TAB_UNDERLINE_Y_RATIO := 0.70
const ANIMALS_CARD_SCALE := 1.32
const ANIMALS_CARD_BACKGROUND_WIDTH_SCALE := 1.045
const ANIMALS_CARD_BACKGROUND_HEIGHT_SCALE := 2.355
const ANIMALS_CARD_LIST_SEPARATION := 18
const ANIMALS_GALLERY_LIST_SEPARATION := 18
const ANIMALS_ACHIEVEMENTS_LIST_SEPARATION := 18
const ANIMALS_GALLERY_SLOT_BACKGROUND_HEIGHT_SCALE := 1.0
const ANIMALS_ACHIEVEMENT_CARD_BACKGROUND_HEIGHT_SCALE := 1.10
const ANIMALS_CARD_ACTION_LEFT_SHIFT_RATIO := 0.10
const ANIMALS_CARD_IMAGE_SCALE := 1.70
const ANIMALS_CARD_TEXT_SCALE := 1.25
const ANIMALS_RARITY_ICON_SCALE := 1.50
const ANIMALS_GALLERY_CONTENT_SCALE := 0.7975
const ANIMALS_GALLERY_SCROLL_WIDTH_SCALE := 1.0
const REPTILE_MGMT_LEGACY_BACKGROUND_PATH := "res://assets/art/ui/reptile_mgm/background.png"
const REPTILE_MGMT_FRAME_PATH := "res://assets/art/ui/reptile_mgm/reptile_mgm_background.png"
const REPTILE_MGMT_TITLE_PL_PATH := "res://assets/art/ui/reptile_mgm/title_pl.png"
const REPTILE_MGMT_TITLE_EN_PATH := "res://assets/art/ui/reptile_mgm/title_en.png"
const REPTILE_MGMT_SAND_BG_PATH := "res://assets/art/ui/reptile_mgm/sand_background.png"
const REPTILE_MGMT_STONE_BG_PATH := "res://assets/art/ui/reptile_mgm/stone_background.png"
const REPTILE_MGMT_GRASS_BG_PATH := "res://assets/art/ui/reptile_mgm/grass_background.png"
const REPTILE_MGMT_JUNGLE_BG_PATH := "res://assets/art/ui/reptile_mgm/jungle_background.png"
const REPTILE_MGMT_CLOSE_PATH := "res://assets/art/ui/reptile_mgm/close.png"
const REPTILE_MGMT_FEED_PATH := "res://assets/art/ui/reptile_mgm/feed.png"
const REPTILE_MGMT_WATER_PATH := "res://assets/art/ui/reptile_mgm/water.png"
const REPTILE_MGMT_CLEAN_PATH := "res://assets/art/ui/reptile_mgm/clean.png"
const REPTILE_MGMT_PLAY_PATH := "res://assets/art/ui/reptile_mgm/play.png"
const REPTILE_MGMT_EXPORT_PATH := "res://assets/art/ui/reptile_mgm/export.png"
const REPTILE_MGMT_UPGRADE_PATH := "res://assets/art/ui/reptile_mgm/upgrade.png"
const HABITAT_OPTIONS_BG_PATH := "res://assets/art/ui/reptile_mgm/habitats_options_background.png"
const HABITAT_OPTIONS_REFERENCE_SIZE := Vector2(983, 1417)
const HABITAT_OPTIONS_WINDOW_SCALE := 0.665
const HABITAT_OPTIONS_CENTER_OFFSET := Vector2.ZERO
const HABITAT_OPTIONS_TITLE_CENTER := Vector2(491.5, 145.0)
const HABITAT_OPTIONS_TITLE_SIZE := Vector2(500.0, 88.0)
const HABITAT_OPTIONS_SUBTITLE_CENTER := Vector2(491.5, 230.0)
const HABITAT_OPTIONS_SUBTITLE_SIZE := Vector2(520.0, 58.0)
const HABITAT_OPTIONS_ROW_BUTTON_START_Y := 392.0
const HABITAT_OPTIONS_ROW_STEP_Y := 266.0
const HABITAT_OPTIONS_ROW_NAME_X := 563.0
const HABITAT_OPTIONS_ROW_PRICE_X := 550.0
const HABITAT_OPTIONS_ROW_NAME_Y_OFFSET := -34.0
const HABITAT_OPTIONS_ROW_PRICE_Y_OFFSET := 42.0
const HABITAT_OPTIONS_ROW_TEXT_SIZE := Vector2(340.0, 62.0)
const HABITAT_OPTIONS_BUY_BUTTON_CENTER_X := 785.0
const HABITAT_OPTIONS_BUY_BUTTON_SIZE := Vector2(230.0, 108.0)
const HABITAT_OPTIONS_CANCEL_CENTER := Vector2(491.5, 1366.0)
const HABITAT_OPTIONS_CANCEL_SIZE := Vector2(690.0, 84.0)
const HABITAT_IN_PROGRESS_PATH := "res://assets/art/habitats/in_progress.png"
const HABITATS_PATH := "res://data/habitats.json"
const BIOME_HABITAT_LAYOUTS_PATH := "res://data/biome_habitat_layouts.json"
const LAYOUT_REF_W := 1080.0
const LAYOUT_REF_H := 1920.0

var biome_id: String = "green_meadow"
var _biome_config: Dictionary = {}
var _biome_layout_slots: Array = []
var _biome_workers_config: Dictionary = {}
var _layout_reference_size := Vector2(LAYOUT_REF_W, LAYOUT_REF_H)
const STATE_NOT_PURCHASED := "not_purchased"
const STATE_PURCHASED_EMPTY := "purchased_empty"
const STATE_OCCUPIED := "occupied"
const TOP_BAR_HEIGHT := 150.722775
const BOTTOM_NAV_HEIGHT := 226.157092875
const UI_MODAL_CANVAS_LAYER := 100
const BIOMES_DATA_PATH := "res://data/biomes.json"
const EXP_BAR_PATH := "res://assets/art/ui/exp_progressbar.png"
const BIOME_BAR_PATH := "res://assets/art/ui/biome_progressbar.png"
const PROGRESS_BAR_ROW_HEIGHT := 81
const PROGRESS_BARS_HEIGHT := PROGRESS_BAR_ROW_HEIGHT * 2 + 32
const POPUP_TEXT_PRIMARY := Color(0.14, 0.10, 0.07, 1.0)
const POPUP_TEXT_SECONDARY := Color(0.28, 0.22, 0.15, 1.0)
const POPUP_TEXT_ACCENT := Color(0.35, 0.24, 0.08, 1.0)
const POPUP_TEXT_SUCCESS := Color(0.10, 0.36, 0.14, 1.0)
const BUTTON_TEXT_COLOR := Color(1.0, 0.98, 0.90, 1.0)
const RARITY_ICON_SIZE := Vector2(32, 32)
const MANAGEMENT_PORTRAIT_SIZE := Vector2(520, 520)
const REPTILE_MGMT_REFERENCE_SIZE := Vector2(941, 1672)
const REPTILE_MGMT_HABITAT_BG_CENTER := Vector2(480.5, 400.0)
const REPTILE_MGMT_HABITAT_BG_SIZE := Vector2(878.0, 610.0)
const REPTILE_MGMT_FRAME_CENTER := Vector2(470.5, 836.0)
const REPTILE_MGMT_WINDOW_SCALE := 0.90
const REPTILE_MGMT_TITLE_CENTER := Vector2(490.5, 60.0)
const REPTILE_MGMT_TITLE_SIZE := Vector2(335.0, 75.0)
const REPTILE_MGMT_CLOSE_CENTER := Vector2(860.0, 103.0)
const REPTILE_MGMT_CLOSE_SIZE := Vector2(124.0, 128.0)
const REPTILE_MGMT_LVL_TEXT_CENTER := Vector2(140.0, 95.0)
const REPTILE_MGMT_LVL_VALUE_CENTER := Vector2(136.0, 130.0)
const REPTILE_MGMT_XP_BAR_CENTER := Vector2(318.0, 156.0)
const REPTILE_MGMT_XP_BAR_SIZE := Vector2(192.0, 28.0)
const REPTILE_MGMT_XP_TEXT_SIZE := Vector2(174.0, 28.0)
const REPTILE_MGMT_NAME_CENTER := Vector2(230.0, 265.0)
const REPTILE_MGMT_NAME_SIZE := Vector2(300.0, 60.0)
const REPTILE_MGMT_EDIT_CENTER := Vector2(420.0, 218.0)
const REPTILE_MGMT_EDIT_SIZE := Vector2(72.0, 72.0)
const REPTILE_MGMT_INFO_ROW_START_Y := 312.0
const REPTILE_MGMT_INFO_ROW_STEP := 48.0
const REPTILE_MGMT_INFO_LABEL_CENTER_X := 199.0
const REPTILE_MGMT_INFO_VALUE_CENTER_X := 356.0
const REPTILE_MGMT_INFO_BONUS_CENTER := Vector2(266.0, 602.0)
const REPTILE_MGMT_EXPORT_CENTER := Vector2(335.0, 1605.0)
const REPTILE_MGMT_EXPORT_SIZE := Vector2(290.0*1.5, 44.0*1.5)
const REPTILE_MGMT_PORTRAIT_CENTER := Vector2(682.0, 440.0)
const REPTILE_MGMT_PORTRAIT_SIZE := Vector2(470.0, 470.0)
const REPTILE_MGMT_NEEDS_TITLE_CENTER := Vector2(254.0, 704.0)
const REPTILE_MGMT_INCOME_TITLE_CENTER := Vector2(681.0, 704.0)
const REPTILE_MGMT_SECTION_TITLE_SIZE := Vector2(310.0, 52.0)
const REPTILE_MGMT_NEED_ROW_START_Y := 764.0
const REPTILE_MGMT_NEED_ROW_STEP := 85.0
const REPTILE_MGMT_INCOME_ROW_START_Y := 775.0
const REPTILE_MGMT_INCOME_ROW_STEP := 48.0
const REPTILE_MGMT_ACTIONS_TITLE_CENTER := Vector2(470.5, 1152.0)
const REPTILE_MGMT_ACTIONS_TITLE_SIZE := Vector2(300.0, 46.0)
const REPTILE_MGMT_FEEDBACK_CENTER := Vector2(470.5, 1206.0)
const REPTILE_MGMT_FEEDBACK_SIZE := Vector2(760.0, 36.0)
const REPTILE_MGMT_CARE_BUTTON_SIZE := Vector2(160.0, 160.0)
const REPTILE_MGMT_FEED_CENTER := Vector2(165.0, 1248.0)
const REPTILE_MGMT_WATER_CENTER := Vector2(370.0, 1248.0)
const REPTILE_MGMT_CLEAN_CENTER := Vector2(585.0, 1248.0)
const REPTILE_MGMT_PLAY_CENTER := Vector2(795.0, 1248.0)
const REPTILE_MGMT_UPGRADE_TITLE_CENTER := Vector2(470.5, 1384.0)
const REPTILE_MGMT_UPGRADE_TITLE_SIZE := Vector2(480.0, 48.0)
const REPTILE_MGMT_HABITAT_LEVEL_LABEL_CENTER := Vector2(174.0, 1440.0)
const REPTILE_MGMT_HABITAT_CURRENT_LEVEL_CENTER := Vector2(116.0, 1508.0)
const REPTILE_MGMT_HABITAT_NEXT_LEVEL_CENTER := Vector2(243.0, 1508.0)
const REPTILE_MGMT_HABITAT_ARROW_CENTER := Vector2(182.0, 1507.0)
const REPTILE_MGMT_UPGRADE_COST_LABEL_CENTER := Vector2(370.0, 1440.0)
const REPTILE_MGMT_UPGRADE_COST_VALUE_CENTER := Vector2(370.0, 1548.0)
const REPTILE_MGMT_UPGRADE_TIME_LABEL_CENTER := Vector2(533.0, 1440.0)
const REPTILE_MGMT_UPGRADE_TIME_VALUE_CENTER := Vector2(531.0, 1548.0)
const REPTILE_MGMT_HABITAT_BONUS_LABEL_CENTER := Vector2(756.0, 1440.0)
const REPTILE_MGMT_HABITAT_BONUS_VALUE_CENTER := Vector2(756.0, 1475.0)
const REPTILE_MGMT_UPGRADE_BUTTON_CENTER := Vector2(757.0, 1570.0)
const REPTILE_MGMT_UPGRADE_BUTTON_SIZE := Vector2(252.0, 92.0)
const DISCOVERY_PORTRAIT_SIZE := Vector2(132, 132)
const DISCOVERY_RARITY_ICON_SIZE := Vector2(112, 112)
const DISCOVERY_POPUP_BG_PATH := "res://assets/art/ui/reptile_mgm/discovery_new.png"
const DISCOVERY_POPUP_REF_SIZE := Vector2(983, 1417)
const DISCOVERY_POPUP_WINDOW_SCALE := 0.665
const DISCOVERY_POPUP_ICON_CENTER := Vector2(491.5, 215.0)
const DISCOVERY_POPUP_ICON_REF_SIZE := Vector2(310.0, 310.0)
const DISCOVERY_POPUP_TITLE_CENTER := Vector2(491.5, 375.0)
const DISCOVERY_POPUP_TITLE_REF_SIZE := Vector2(720.0, 70.0)
const DISCOVERY_POPUP_PORTRAIT_CENTER := Vector2(491.5, 660.0)
const DISCOVERY_POPUP_PORTRAIT_REF_SIZE := Vector2(475.0, 475.0)
const DISCOVERY_POPUP_DETAIL_CENTER_X := 491.5
const DISCOVERY_POPUP_DETAIL_REF_SIZE := Vector2(700.0, 58.0)
const DISCOVERY_POPUP_SPECIES_Y := 924.0
const DISCOVERY_POPUP_VARIANT_Y := 999.0
const DISCOVERY_POPUP_SEX_Y := 1074.0
const DISCOVERY_POPUP_RARITY_Y := 1148.0
const DISCOVERY_POPUP_OK_CENTER := Vector2(491.5, 1371.0)
const DISCOVERY_POPUP_OK_REF_SIZE := Vector2(675.0, 100.0)
const NAME_POPUP_BG_PATH := "res://assets/art/ui/small_design/name_change_background.png"
const NAME_POPUP_REF_SIZE := Vector2(900, 660)
const NAME_POPUP_WINDOW_SCALE := 0.70
const NAME_POPUP_TITLE_CENTER := Vector2(450.0, 88.0)
const NAME_POPUP_TITLE_REF_SIZE := Vector2(760.0, 85.0)
const NAME_POPUP_TITLE_FONT_SIZE := 38
const NAME_POPUP_PORTRAIT_CENTER := Vector2(158.0, 205.0)
const NAME_POPUP_PORTRAIT_SIZE := Vector2(200.0*1.55, 210.0*1.55)
const NAME_POPUP_PORTRAIT_REF_SIZE := NAME_POPUP_PORTRAIT_SIZE
const NAME_POPUP_SPECIES_CENTER := Vector2(540.0, 215.0)
const NAME_POPUP_SPECIES_REF_SIZE := Vector2(490.0, 70.0)
const NAME_POPUP_SPECIES_FONT_SIZE := 30
const NAME_POPUP_PROMPT_CENTER := Vector2(450.0, 350.0)
const NAME_POPUP_PROMPT_REF_SIZE := Vector2(760.0, 65.0)
const NAME_POPUP_PROMPT_FONT_SIZE := 30
const NAME_POPUP_INPUT_CENTER := Vector2(460.0, 430.0)
const NAME_POPUP_INPUT_REF_SIZE := Vector2(740.0, 72.0)
const NAME_POPUP_INPUT_FONT_SIZE := 28
const NAME_POPUP_CANCEL_CENTER := Vector2(240.0, 544.0)
const NAME_POPUP_CANCEL_REF_SIZE := Vector2(320.0, 84.0)
const NAME_POPUP_CANCEL_FONT_SIZE := 32
const NAME_POPUP_SAVE_CENTER := Vector2(655.0, 544.0)
const NAME_POPUP_SAVE_REF_SIZE := Vector2(320.0, 84.0)
const NAME_POPUP_SAVE_FONT_SIZE := 32
const NAME_POPUP_VALIDATION_FONT_SIZE := 16
const MGMT_POPUP_BG_PATH := "res://assets/art/ui/small_design/build_habitat.png"
const MGMT_POPUP_REF_SIZE := Vector2(1058.0, 1260.0)
const MGMT_POPUP_WINDOW_SCALE := 0.82
const MGMT_POPUP_TITLE_CENTER := Vector2(525.0, 85.0)
const MGMT_POPUP_TITLE_REF_SIZE := Vector2(830.0, 115.0)
const MGMT_POPUP_TITLE_FONT_SIZE := 48
const MGMT_POPUP_CLOSE_CENTER := Vector2(975.0, 68.0)
const MGMT_POPUP_CLOSE_REF_SIZE := Vector2(108.0, 108.0)
const MGMT_POPUP_PREVIEW_CENTER := Vector2(255.0, 460.0)
const MGMT_POPUP_PREVIEW_REF_SIZE := Vector2(430.0, 430.0)
const MGMT_POPUP_ROW1_CENTER := Vector2(665.0, 250.0)
const MGMT_POPUP_ROW2_CENTER := Vector2(665.0, 345.0)
const MGMT_POPUP_ROW3_CENTER := Vector2(665.0, 435.0)
const MGMT_POPUP_ROW4_CENTER := Vector2(665.0, 525.0)
const MGMT_POPUP_ROW5_CENTER := Vector2(665.0, 615.0)
const MGMT_POPUP_ROW_LABEL_SIZE := Vector2(280.0, 100.0)
const MGMT_POPUP_ROW_VALUE_X := 918.0
const MGMT_POPUP_ROW_VALUE_SIZE := Vector2(190.0, 100.0)
const MGMT_POPUP_ROW_FONT_SIZE := 26
const MGMT_POPUP_BTN1_CENTER := Vector2(559.0, 790.0)
const MGMT_POPUP_BTN2_CENTER := Vector2(555.0, 943.0)
const MGMT_POPUP_BTN3_CENTER := Vector2(559.0, 1099.0)
const MGMT_POPUP_BTN_SIZE := Vector2(910.0, 112.0)
const MGMT_POPUP_BTN_FONT_SIZE := 40
const LOGO_SIZE := Vector2(150, 112)
const NAME_MAX_LENGTH := 16
const GALLERY_REPTILE_IDS := ["leopard_gecko", "bearded_dragon", "corn_snake", "steppe_tortoise", "small_monitor", "chameleon", "bullsnake", "collared_lizard", "western_earless_lizard", "ornate_box_turtle", "western_hognose_snake", "prairie_rattlesnake"]
const GALLERY_RARITIES := ["common", "rare", "ultra_rare", "exceptional",]

var habitat_data: Array = []
var habitat_slots: Dictionary = {}
var action_popup: PopupPanel
var feedback_modal: Control
var confirmation_modal: Control
var level_up_modal: Control
var reptile_selection_modal: Control
var management_modal: Control
var management_modal_mouse_filter_backup: Array = []
var habitat_purchase_modal: Control
var variant_discovery_modal: Control
var naming_modal: Control
var shop_view: Control
var animals_view: Control
var quests_view: Control
var workers_view: Control
var upgrades_view: Control
var settings_modal: Control
var _animals_step: int = 0
var _animals_selected_species_id: String = ""
var _animals_group_navigating: bool = false
var next_step_widget: PanelContainer
var next_step_label: Label
var progress_bars_widget: Control
var xp_progress_bar: ProgressBar
var xp_progress_label: Label
var biome_unlock_bar_row: Control
var biome_unlock_progress_bar: ProgressBar
var biome_unlock_label: Label
var pending_name_instance_id: String = ""
var current_management_instance_id: String = ""
var current_management_feedback_key: String = ""
var care_update_timer: Timer
var offline_income_popup: CanvasLayer
var ui_modal_layer: CanvasLayer
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_timer: SceneTreeTimer
var _upgrade_purchase_in_progress: bool = false


func _ready() -> void:
	_load_biome_config()
	_load_biome_layout()
	ReptileSystem.migrate_save_state()
	ReptileSystem.apply_time_updates(true, true)
	ReptileSystem.sync_discovered_variants_from_owned_reptiles()
	habitat_data = _load_habitats()
	_build_layout()
	_setup_care_update_timer()
	if EconomySystem.has_signal("income_progress_updated"):
		EconomySystem.income_progress_updated.connect(_on_income_progress_updated)
	if EconomySystem.has_signal("income_tick"):
		EconomySystem.income_tick.connect(_on_income_tick)
	if EconomySystem.has_signal("player_level_up"):
		EconomySystem.player_level_up.connect(_on_player_level_up)
	if EconomySystem.has_signal("currency_changed"):
		EconomySystem.currency_changed.connect(_on_currency_changed_for_bars)
	if EconomySystem.has_signal("player_level_changed"):
		EconomySystem.player_level_changed.connect(_on_player_level_changed_for_bars)
	if has_node("/root/WorkerSystem") and WorkerSystem.has_signal("workers_changed"):
		WorkerSystem.workers_changed.connect(_on_workers_changed)
	if has_node("/root/UpgradeSystem") and UpgradeSystem.has_signal("upgrades_changed"):
		UpgradeSystem.upgrades_changed.connect(_on_upgrades_changed)
	if ReptileSystem.has_signal("reptile_leveled_up") and not ReptileSystem.reptile_leveled_up.is_connected(_on_reptile_leveled_up):
		ReptileSystem.reptile_leveled_up.connect(_on_reptile_leveled_up)
	if not GameState.language_changed.is_connected(_on_language_changed):
		GameState.language_changed.connect(_on_language_changed)
	GameState.state_changed.connect(_refresh_habitat_slots)
	if has_node("/root/QuestSystem"):
		if QuestSystem.has_signal("quest_completed") and not QuestSystem.quest_completed.is_connected(_on_quest_state_changed):
			QuestSystem.quest_completed.connect(_on_quest_state_changed)
		if QuestSystem.has_signal("quest_claimed") and not QuestSystem.quest_claimed.is_connected(_on_quest_state_changed):
			QuestSystem.quest_claimed.connect(_on_quest_state_changed)
	call_deferred("_notify_biome_opened")


func _load_biome_config() -> void:
	_biome_config = {}
	var file := FileAccess.open(BIOMES_DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_ARRAY:
		return
	for entry in data:
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("id", "")) == biome_id:
			_biome_config = entry as Dictionary
			return


func _load_biome_layout() -> void:
	_biome_layout_slots = []
	_biome_workers_config = {}
	_layout_reference_size = Vector2(LAYOUT_REF_W, LAYOUT_REF_H)
	var file := FileAccess.open(BIOME_HABITAT_LAYOUTS_PATH, FileAccess.READ)
	if file == null:
		push_warning("BiomeView: biome_habitat_layouts.json not found, using fallback layout.")
		_biome_layout_slots = _get_fallback_layout()
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("BiomeView: biome_habitat_layouts.json malformed, using fallback layout.")
		_biome_layout_slots = _get_fallback_layout()
		return
	_layout_reference_size = _get_layout_reference_resolution(data as Dictionary)
	var layouts: Variant = (data as Dictionary).get("layouts", null)
	if layouts == null or typeof(layouts) != TYPE_DICTIONARY:
		push_warning("BiomeView: no 'layouts' key in biome_habitat_layouts.json, using fallback.")
		_biome_layout_slots = _get_fallback_layout()
		return
	var biome_layout: Variant = (layouts as Dictionary).get(biome_id, null)
	if biome_layout == null or typeof(biome_layout) != TYPE_DICTIONARY:
		push_warning("BiomeView: no layout for biome '" + biome_id + "' in biome_habitat_layouts.json, using fallback.")
		_biome_layout_slots = _get_fallback_layout()
		return
	var slots_raw: Variant = (biome_layout as Dictionary).get("slots", null)
	if slots_raw == null or typeof(slots_raw) != TYPE_ARRAY:
		push_warning("BiomeView: invalid 'slots' for biome '" + biome_id + "', using fallback.")
		_biome_layout_slots = _get_fallback_layout()
		return
	_biome_layout_slots = slots_raw as Array
	var wb: Variant = (biome_layout as Dictionary).get("workers_button", null)
	if wb != null and typeof(wb) == TYPE_DICTIONARY:
		_biome_workers_config = wb as Dictionary
	else:
		_biome_workers_config = {}


func _get_fallback_layout() -> Array:
	return [
		{"slot_id": biome_id + "_slot_1", "x": 300, "y": 480},
		{"slot_id": biome_id + "_slot_2", "x": 780, "y": 570},
		{"slot_id": biome_id + "_slot_3", "x": 300, "y": 795},
		{"slot_id": biome_id + "_slot_4", "x": 780, "y": 900},
		{"slot_id": biome_id + "_slot_5", "x": 300, "y": 1125},
		{"slot_id": biome_id + "_slot_6", "x": 780, "y": 1230},
	]


func _get_layout_reference_resolution(data: Dictionary) -> Vector2:
	var ref_value: Variant = data.get("reference_resolution", {})
	if typeof(ref_value) != TYPE_DICTIONARY:
		return Vector2(LAYOUT_REF_W, LAYOUT_REF_H)

	var ref: Dictionary = ref_value as Dictionary
	var width: float = max(1.0, float(ref.get("width", LAYOUT_REF_W)))
	var height: float = max(1.0, float(ref.get("height", LAYOUT_REF_H)))
	return Vector2(width, height)


func _get_layout_runtime_scale() -> float:
	return LayoutScale.viewport_scale(get_viewport_rect().size, _layout_reference_size)


func _get_background_cover_scale() -> float:
	return LayoutScale.cover_scale(get_viewport_rect().size, _layout_reference_size)


func _get_background_cover_origin(scale: float) -> Vector2:
	return LayoutScale.cover_origin(get_viewport_rect().size, scale, _layout_reference_size)


func _rebuild_layout() -> void:
	_load_biome_config()
	_load_biome_layout()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	habitat_slots.clear()
	action_popup = null
	feedback_modal = null
	confirmation_modal = null
	level_up_modal = null
	reptile_selection_modal = null
	management_modal = null
	management_modal_mouse_filter_backup.clear()
	habitat_purchase_modal = null
	variant_discovery_modal = null
	naming_modal = null
	shop_view = null
	animals_view = null
	quests_view = null
	workers_view = null
	upgrades_view = null
	settings_modal = null
	_animals_step = 0
	_animals_selected_species_id = ""
	_animals_group_navigating = false
	next_step_widget = null
	next_step_label = null
	progress_bars_widget = null
	xp_progress_bar = null
	xp_progress_label = null
	biome_unlock_bar_row = null
	biome_unlock_progress_bar = null
	biome_unlock_label = null
	pending_name_instance_id = ""
	current_management_instance_id = ""
	current_management_feedback_key = ""
	care_update_timer = null
	offline_income_popup = null
	ui_modal_layer = null
	_toast_panel = null
	_toast_label = null
	_toast_timer = null
	_upgrade_purchase_in_progress = false
	_build_layout()
	_setup_care_update_timer()


func _setup_care_update_timer() -> void:
	if care_update_timer != null:
		care_update_timer.queue_free()

	care_update_timer = Timer.new()
	care_update_timer.name = "CareUpdateTimer"
	care_update_timer.wait_time = 1.0
	care_update_timer.autostart = true
	care_update_timer.timeout.connect(_on_care_update_timer_timeout)
	add_child(care_update_timer)


func _on_care_update_timer_timeout() -> void:
	ReptileSystem.apply_time_updates(false)
	_refresh_habitat_slots()
	if management_modal != null and not current_management_instance_id.is_empty():
		_show_management_for_instance_id(current_management_instance_id, false)


func _on_income_progress_updated(_progress: float, _time_left: int) -> void:
	_refresh_habitat_income_progress()


func _on_income_tick(amount: float) -> void:
	if amount <= 0.0:
		return

	_show_income_float(amount)
	_refresh_habitat_income_progress()


func _on_player_level_up(levels: Array, reward_amount: float) -> void:
	_show_level_up_popup(levels, reward_amount)
	_refresh_progress_bars()


func _on_currency_changed_for_bars(currency_id: String, _amount: Variant) -> void:
	if currency_id == "xp":
		_refresh_progress_bars()


func _on_player_level_changed_for_bars(_level: int) -> void:
	_refresh_progress_bars()


func _on_reptile_leveled_up(instance_id: String, reptile_id: String, new_level: int) -> void:
	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var instance_value: Variant = instances.get(instance_id, {})
	var instance: Dictionary = {}
	if typeof(instance_value) == TYPE_DICTIONARY:
		instance = instance_value as Dictionary
	var reptile: Dictionary = ReptileSystem.get_reptile(reptile_id)
	var species_name: String = _get_reptile_display_name(instance, reptile) if not instance.is_empty() else LocalizationSystem.tr_key(str(reptile.get("name_key", reptile_id)))
	var text: String = LocalizationSystem.tr_key("reptile_level_up_toast")
	text = text.replace("{species_name}", species_name).replace("{level}", str(new_level))
	_show_toast_raw(text)
	if management_modal != null and current_management_instance_id == instance_id:
		_show_management_for_instance_id(instance_id, false)


func _on_workers_changed() -> void:
	_refresh_habitat_slots()
	if management_modal != null and not current_management_instance_id.is_empty():
		_show_management_for_instance_id(current_management_instance_id, false)


func _on_upgrades_changed() -> void:
	_refresh_habitat_slots()
	if management_modal != null and not current_management_instance_id.is_empty():
		_show_management_for_instance_id(current_management_instance_id, false)
	if upgrades_view != null:
		_show_upgrades_view()


func _on_language_changed(_language: String) -> void:
	var reopen_settings: bool = settings_modal != null and not bool(settings_modal.get_meta("closing_for_reset", false))
	_rebuild_layout()
	if reopen_settings:
		call_deferred("_show_settings_screen")


func _build_layout() -> void:
	_add_background()
	_add_top_bar()
	_add_progress_bars_widget()
	_add_map_area()
	_add_workers_shortcut()
	_add_bottom_nav()
	_add_offline_income_popup()
	_add_toast()


func _add_background() -> void:
	var background: TextureRect = TextureRect.new()
	background.name = "BiomeBackground"
	var bg_path: String = str(_biome_config.get("background_path", BACKGROUND_PATH))
	background.texture = AssetPaths.load_texture(bg_path)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)

	if background.texture != null:
		return

	var fallback := ColorRect.new()
	fallback.name = "BackgroundFallback"
	fallback.color = Color(0.45, 0.75, 0.45, 1.0)
	fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fallback)
	move_child(fallback, 0)


func _add_top_bar() -> void:
	var top_bar: Control = TOP_BAR_SCENE.instantiate() as Control
	top_bar.name = "TopBar"
	var top_bar_art: String = str(_biome_config.get("top_bar_path", ""))
	if not top_bar_art.is_empty() and top_bar.has_method("set") and "art_path" in top_bar:
		top_bar.art_path = top_bar_art
	if "biome_id" in top_bar:
		top_bar.biome_id = biome_id
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = TOP_BAR_HEIGHT
	if top_bar.has_signal("settings_pressed"):
		top_bar.connect("settings_pressed", Callable(self, "_show_settings_screen"))
	add_child(top_bar)


func _add_top_logo() -> void:
	var logo_texture: Texture2D = AssetPaths.load_texture(LOGO_PATH)
	if logo_texture == null:
		push_warning("Top-left logo missing: " + LOGO_PATH)
		return

	var logo: TextureRect = TextureRect.new()
	logo.name = "GameLogo"
	logo.texture = logo_texture
	logo.anchor_left = 0.0
	logo.anchor_top = 0.0
	logo.anchor_right = 0.0
	logo.anchor_bottom = 0.0
	logo.offset_left = 10.0
	logo.offset_top = 0.0
	logo.offset_right = 10.0 + LOGO_SIZE.x
	logo.offset_bottom = LOGO_SIZE.y
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)


func _add_workers_shortcut() -> void:
	var wb := _biome_workers_config
	var cover_scale := _get_background_cover_scale()
	var cover_origin := _get_background_cover_origin(cover_scale)
	var wb_xr := float(wb.get("x_from_right", 900))
	var wb_yb := float(wb.get("y_from_bottom", 435))
	var wb_w := float(wb.get("width", 318)) * cover_scale
	var wb_h := float(wb.get("height", 318)) * cover_scale
	var wb_icon_w := float(wb.get("icon_width", wb.get("width", 318))) * cover_scale
	var wb_icon_h := float(wb.get("icon_height", wb.get("height", 318))) * cover_scale
	var center := cover_origin + Vector2(_layout_reference_size.x - wb_xr, _layout_reference_size.y - wb_yb) * cover_scale

	var button: Button = Button.new()
	button.name = "WorkersShortcut"
	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = center.x - wb_w * 0.5
	button.offset_top = center.y - wb_h * 0.5
	button.offset_right = center.x + wb_w * 0.5
	button.offset_bottom = center.y + wb_h * 0.5
	button.custom_minimum_size = Vector2(wb_w, wb_h)
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _make_transparent_button_style())
	button.add_theme_stylebox_override("hover", _make_transparent_button_style())
	button.add_theme_stylebox_override("pressed", _make_transparent_button_style())
	button.pressed.connect(_show_workers_view)
	add_child(button)

	var content: CenterContainer = CenterContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)

	var icon: TextureRect = _make_fixed_texture(WORKERS_ICON_PATH, Vector2(wb_icon_w, wb_icon_h))
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_child(icon)


func _add_bottom_nav() -> void:
	var bottom_nav: Control = BOTTOM_NAV_SCENE.instantiate() as Control
	bottom_nav.name = "BottomNav"
	var bottom_art: String = str(_biome_config.get("bottom_menu_path", ""))
	if not bottom_art.is_empty() and "art_path" in bottom_nav:
		bottom_nav.art_path = bottom_art
	bottom_nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_nav.offset_top = -BOTTOM_NAV_HEIGHT
	bottom_nav.offset_bottom = 0
	if bottom_nav.has_signal("nav_pressed"):
		bottom_nav.connect("nav_pressed", Callable(self, "_on_bottom_nav_pressed"))
	add_child(bottom_nav)
	call_deferred("_update_quest_badge")


func _add_offline_income_popup() -> void:
	offline_income_popup = OFFLINE_INCOME_POPUP_SCRIPT.new() as CanvasLayer
	offline_income_popup.name = "OfflineIncomePopup"
	add_child(offline_income_popup)


func _show_settings_screen() -> void:
	if settings_modal != null and is_instance_valid(settings_modal):
		settings_modal.move_to_front()
		return

	settings_modal = SETTINGS_MODAL_SCRIPT.new() as Control
	settings_modal.name = "SettingsModal"
	settings_modal.z_index = 220
	settings_modal.connect("closed", func() -> void:
		settings_modal = null
	)
	settings_modal.connect("reset_completed", func() -> void:
		settings_modal = null
		_rebuild_layout()
	)
	add_child(settings_modal)


func _add_map_area() -> void:
	var play_area := Control.new()
	play_area.name = "PlayArea"
	play_area.anchor_left = 0.0
	play_area.anchor_top = 0.0
	play_area.anchor_right = 1.0
	play_area.anchor_bottom = 1.0
	play_area.offset_top = TOP_BAR_HEIGHT + PROGRESS_BARS_HEIGHT + 4
	play_area.offset_bottom = -(BOTTOM_NAV_HEIGHT + 18)
	add_child(play_area)

	_add_habitat_slots(play_area)


func _add_next_step_widget() -> void:
	next_step_widget = PanelContainer.new()
	next_step_widget.name = "NextStepWidget"
	next_step_widget.anchor_left = 0.0
	next_step_widget.anchor_top = 0.0
	next_step_widget.anchor_right = 1.0
	next_step_widget.anchor_bottom = 0.0
	next_step_widget.offset_left = 18.0
	next_step_widget.offset_top = TOP_BAR_HEIGHT + 8.0
	next_step_widget.offset_right = -18.0
	next_step_widget.offset_bottom = TOP_BAR_HEIGHT + 52.0
	next_step_widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_step_widget.add_theme_stylebox_override("panel", _make_next_step_style())
	add_child(next_step_widget)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	next_step_widget.add_child(margin)

	next_step_label = Label.new()
	next_step_label.clip_text = true
	next_step_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_step_label.add_theme_font_size_override("font_size", 14)
	next_step_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_label_color(next_step_label, POPUP_TEXT_PRIMARY)
	margin.add_child(next_step_label)
	_refresh_next_step_widget()


func _refresh_next_step_widget() -> void:
	if next_step_widget == null or next_step_label == null:
		return
	if not has_node("/root/QuestSystem") or not QuestSystem.has_method("get_next_step_quest"):
		next_step_widget.visible = false
		return

	var state: Dictionary = QuestSystem.get_next_step_quest()
	if state.is_empty():
		next_step_widget.visible = false
		return

	var title: String = LocalizationSystem.tr_key(str(state.get("title_key", "")))
	next_step_label.text = LocalizationSystem.tr_key("ui.next_step").replace("{quest}", title)
	next_step_widget.visible = true


func _make_next_step_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.88, 0.64, 0.88)
	style.border_color = Color(0.42, 0.30, 0.12, 0.35)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.set_corner_radius_all(8)
	return style


func _add_progress_bars_widget() -> void:
	progress_bars_widget = Control.new()
	progress_bars_widget.name = "ProgressBarsWidget"
	progress_bars_widget.anchor_left = 0.10
	progress_bars_widget.anchor_top = 0.0
	progress_bars_widget.anchor_right = 0.90
	progress_bars_widget.anchor_bottom = 0.0
	progress_bars_widget.offset_top = TOP_BAR_HEIGHT + 4
	progress_bars_widget.offset_bottom = TOP_BAR_HEIGHT + PROGRESS_BARS_HEIGHT
	progress_bars_widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(progress_bars_widget)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	progress_bars_widget.add_child(margin)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	var xp_art := _make_art_progress_bar(EXP_BAR_PATH, Color(0.25, 0.55, 1.0, 0.80))
	xp_progress_bar = xp_art["bar"]
	xp_progress_label = xp_art["label"]
	column.add_child(xp_art["outer"])

	var biome_art := _make_art_progress_bar(BIOME_BAR_PATH, Color(0.22, 0.72, 0.28, 0.80))
	biome_unlock_bar_row = biome_art["outer"]
	biome_unlock_progress_bar = biome_art["bar"]
	biome_unlock_label = biome_art["label"]
	column.add_child(biome_unlock_bar_row)

	_refresh_progress_bars()


func _make_art_progress_bar(texture_path: String, fill_color: Color) -> Dictionary:
	var outer := Control.new()
	outer.custom_minimum_size = Vector2(0, PROGRESS_BAR_ROW_HEIGHT)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tex := TextureRect.new()
	tex.texture = load(texture_path)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_SCALE
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(tex)

	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.anchor_left = 0.06
	bar.anchor_right = 0.94
	bar.anchor_top = 0.0
	bar.anchor_bottom = 1.0
	bar.offset_top = 20
	bar.offset_bottom = -20
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("fill", fill_style)
	bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	outer.add_child(bar)

	var lbl := Label.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.90))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(lbl)

	return {"outer": outer, "bar": bar, "label": lbl}


func _refresh_progress_bars() -> void:
	if xp_progress_bar == null or xp_progress_label == null:
		return

	var total_xp: float = float(GameState.get_value("xp", 0))
	var effective_level: int = 1
	while total_xp >= float(EconomySystem.get_required_xp_for_level(effective_level + 1)):
		effective_level += 1
	var xp_for_current: float = float(EconomySystem.get_required_xp_for_level(effective_level))
	var xp_for_next: float = float(EconomySystem.get_required_xp_for_level(effective_level + 1))
	var xp_in_level: int = max(0, int(total_xp - xp_for_current))
	var xp_needed: int = max(1, int(xp_for_next - xp_for_current))
	var xp_ratio: float = clamp(float(xp_in_level) / float(xp_needed), 0.0, 1.0)
	xp_progress_bar.value = xp_ratio * 100.0
	xp_progress_label.text = (
		LocalizationSystem.tr_key("ui.xp_to_next_level")
			.replace("{current}", str(xp_in_level))
			.replace("{needed}", str(xp_needed))
			.replace("{next}", str(effective_level + 1))
	)

	var current_level: int = max(1, int(GameState.get_value("level", 1)))
	if biome_unlock_bar_row == null:
		return

	var biome_data: Dictionary = _get_next_biome_unlock_data()
	var req_level: int = int(biome_data.get("req_level", 0))
	if biome_data.is_empty() or req_level <= 0 or current_level >= req_level:
		biome_unlock_bar_row.visible = false
		return

	biome_unlock_bar_row.visible = true
	biome_unlock_progress_bar.value = clamp(float(current_level) / float(req_level), 0.0, 1.0) * 100.0
	var biome_name: String = LocalizationSystem.tr_key(str(biome_data.get("name_key", "biome.new_biome")))
	biome_unlock_label.text = (
		biome_name + ": " + LocalizationSystem.tr_key("ui.biome_unlock_level_req")
			.replace("{current}", str(current_level))
			.replace("{target}", str(req_level))
	)


func _get_next_biome_unlock_data() -> Dictionary:
	var file: FileAccess = FileAccess.open(BIOMES_DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return {}
	var biomes: Array = parsed as Array
	var next_id: String = ""
	for biome_value in biomes:
		if typeof(biome_value) != TYPE_DICTIONARY:
			continue
		var biome: Dictionary = biome_value as Dictionary
		if str(biome.get("id", "")) == biome_id:
			next_id = str(biome.get("next_biome_id", ""))
			break
	if next_id.is_empty():
		return {}
	for biome_value in biomes:
		if typeof(biome_value) != TYPE_DICTIONARY:
			continue
		var biome: Dictionary = biome_value as Dictionary
		if str(biome.get("id", "")) != next_id:
			continue
		var req: Dictionary = biome.get("unlock_requirements", {}) as Dictionary
		return {
			"id": next_id,
			"name_key": str(biome.get("name_key", "biome.new_biome")),
			"req_level": int(req.get("level", 0))
		}
	return {}


func _add_habitat_slots(parent: Control) -> void:
	var default_slot_w := 390.0
	var default_slot_h := 330.0
	var default_empty_w := 195.0
	var default_empty_h := 195.0
	var default_purchased_w := 409.5
	var default_purchased_h := 409.5
	var cover_scale := _get_background_cover_scale()
	var cover_origin := _get_background_cover_origin(cover_scale)
	var play_area_screen_top := float(TOP_BAR_HEIGHT + PROGRESS_BARS_HEIGHT + 4)

	var count: int = min(habitat_data.size(), _biome_layout_slots.size())
	for index in count:
		var habitat: Dictionary = habitat_data[index] as Dictionary
		var slot_def: Variant = _biome_layout_slots[index]
		if typeof(slot_def) != TYPE_DICTIONARY:
			push_warning("BiomeView: slot definition at index " + str(index) + " is not a dictionary, skipping.")
			continue
		var slot_data: Dictionary = slot_def as Dictionary

		var x_ref := float(slot_data.get("x", _layout_reference_size.x * 0.5))
		var y_ref := float(slot_data.get("y", _layout_reference_size.y * 0.5))
		var slot_center := cover_origin + Vector2(x_ref, y_ref) * cover_scale - Vector2(0.0, play_area_screen_top)
		var slot_scale := float(slot_data.get("scale", 1.0))

		var slot_w := float(slot_data.get("slot_width",  default_slot_w * slot_scale)) * cover_scale
		var slot_h := float(slot_data.get("slot_height", default_slot_h * slot_scale)) * cover_scale
		var empty_w := float(slot_data.get("empty_width",  default_empty_w * slot_scale)) * cover_scale
		var empty_h := float(slot_data.get("empty_height", default_empty_h * slot_scale)) * cover_scale
		var purchased_w := float(slot_data.get("purchased_width",  default_purchased_w * slot_scale)) * cover_scale
		var purchased_h := float(slot_data.get("purchased_height", default_purchased_h * slot_scale)) * cover_scale

		var slot_size     := Vector2(slot_w, slot_h)
		var empty_size    := Vector2(empty_w, empty_h)
		var purchased_size := Vector2(purchased_w, purchased_h)

		var empty_offset := Vector2(
			float(slot_data.get("empty_offset_x", 0)),
			float(slot_data.get("empty_offset_y", 0))
		) * cover_scale
		var purchased_offset := Vector2(
			float(slot_data.get("purchased_offset_x", 0)),
			float(slot_data.get("purchased_offset_y", -21))
		) * cover_scale

		var slot: Control = HABITAT_SLOT_SCENE.instantiate() as Control
		var habitat_id: String = str(habitat.get("id", ""))
		var slot_index: int = int(habitat.get("slot_index", index + 1))
		var state: String = _get_habitat_state(habitat_id)

		slot.name = "HabitatSlot" + str(slot_index)
		if slot_data.has("z_index"):
			slot.z_index = int(slot_data.get("z_index", 0))
		slot.anchor_left = 0.0
		slot.anchor_top = 0.0
		slot.anchor_right = 0.0
		slot.anchor_bottom = 0.0
		slot.offset_left = slot_center.x - slot_size.x * 0.5
		slot.offset_top = slot_center.y - slot_size.y * 0.5
		slot.offset_right = slot_center.x + slot_size.x * 0.5
		slot.offset_bottom = slot_center.y + slot_size.y * 0.5
		slot.call("set_visual_tuning", empty_size, purchased_size, empty_offset, purchased_offset)
		slot.call("setup", habitat_id, slot_index, state)
		if slot.has_method("set_empty_texture"):
			var art_folder: String = str(_biome_config.get("habitat_art_folder", "res://assets/art/habitats/"))
			slot.call("set_empty_texture", art_folder + "habitat_slot_empty.png")
		if slot.has_method("set_habitat_texture"):
			slot.call("set_habitat_texture", _get_habitat_texture_path(habitat_id))
		if slot.has_method("set_upgrade_status"):
			slot.call("set_upgrade_status", _is_habitat_in_progress(habitat_id), _get_habitat_in_progress_status_text(habitat_id))
		slot.call("set_occupied_icon", _get_habitat_reptile_icon_path(habitat_id) if state == STATE_OCCUPIED else "")
		slot.connect("habitat_pressed", Callable(self, "_on_habitat_pressed"))
		parent.add_child(slot)
		habitat_slots[habitat_id] = slot


func _on_habitat_pressed(habitat_id: String) -> void:
	var habitat: Dictionary = _get_habitat_data(habitat_id)
	if habitat.is_empty():
		return

	var state: String = _get_habitat_state(habitat_id)
	if state == STATE_NOT_PURCHASED:
		_show_purchase_popup(habitat)
	elif state == STATE_PURCHASED_EMPTY:
		_show_habitat_management_popup(habitat_id)
	else:
		_show_management_popup(habitat_id)


func _show_purchase_popup(habitat: Dictionary) -> void:
	_close_habitat_purchase_modal()

	var background_texture: Texture2D = AssetPaths.load_texture(HABITAT_OPTIONS_BG_PATH)
	if background_texture == null:
		push_warning("BiomeView: missing habitat options background: " + HABITAT_OPTIONS_BG_PATH)
		_show_legacy_purchase_popup(habitat)
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var reference_scale: float = min(viewport_size.x / HABITAT_OPTIONS_REFERENCE_SIZE.x, viewport_size.y / HABITAT_OPTIONS_REFERENCE_SIZE.y) * HABITAT_OPTIONS_WINDOW_SCALE
	var reference_origin: Vector2 = (viewport_size - HABITAT_OPTIONS_REFERENCE_SIZE * reference_scale) * 0.5 + HABITAT_OPTIONS_CENTER_OFFSET * reference_scale
	var habitat_id: String = str(habitat.get("id", ""))
	var slot_index: int = int(habitat.get("slot_index", 0))
	var purchase_cost: int = EconomySystem.get_next_habitat_price(biome_id, habitat_data.size())

	habitat_purchase_modal = Control.new()
	habitat_purchase_modal.name = "HabitatPurchaseModal"
	habitat_purchase_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	habitat_purchase_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(habitat_purchase_modal)

	var overlay: ColorRect = ColorRect.new()
	overlay.name = "DimOverlay"
	overlay.color = Color(0.04, 0.05, 0.04, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	habitat_purchase_modal.add_child(overlay)

	var background: TextureRect = TextureRect.new()
	background.name = "HabitatOptionsBackground"
	background.texture = background_texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	habitat_purchase_modal.add_child(background)
	_position_reference_control(background, HABITAT_OPTIONS_REFERENCE_SIZE * 0.5, HABITAT_OPTIONS_REFERENCE_SIZE, reference_origin, reference_scale)

	_add_habitat_options_label(habitat_purchase_modal, LocalizationSystem.tr_key("habitat.title"), HABITAT_OPTIONS_TITLE_CENTER, HABITAT_OPTIONS_TITLE_SIZE, 64, POPUP_TEXT_ACCENT, HORIZONTAL_ALIGNMENT_CENTER, reference_origin, reference_scale, true)
	_add_habitat_options_label(habitat_purchase_modal, LocalizationSystem.tr_key("habitat.choose_type"), HABITAT_OPTIONS_SUBTITLE_CENTER, HABITAT_OPTIONS_SUBTITLE_SIZE, 34, POPUP_TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_CENTER, reference_origin, reference_scale, false)

	if purchase_cost < 0:
		_add_habitat_options_label(habitat_purchase_modal, LocalizationSystem.tr_key("ui.all_habitats_purchased"), Vector2(491.5, 720.0), Vector2(720.0, 120.0), 30, POPUP_TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_CENTER, reference_origin, reference_scale, false)
	else:
		var row_index: int = 0
		for habitat_type in _get_habitat_options_order():
			_add_habitat_option_row(habitat_purchase_modal, habitat_id, slot_index, habitat_type, purchase_cost, row_index, reference_origin, reference_scale)
			row_index += 1

	_add_habitat_options_button(habitat_purchase_modal, LocalizationSystem.tr_key("ui.cancel"), HABITAT_OPTIONS_CANCEL_CENTER, HABITAT_OPTIONS_CANCEL_SIZE, 38, Callable(self, "_close_habitat_purchase_modal"), reference_origin, reference_scale)


func _show_legacy_purchase_popup(habitat: Dictionary) -> void:
	_close_habitat_purchase_modal()

	var habitat_id: String = str(habitat.get("id", ""))
	var slot_index: int = int(habitat.get("slot_index", 0))
	var purchase_cost: int = EconomySystem.get_next_habitat_price(biome_id, habitat_data.size())

	habitat_purchase_modal = Control.new()
	habitat_purchase_modal.name = "HabitatPurchaseModal"
	habitat_purchase_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(habitat_purchase_modal)

	var overlay: ColorRect = ColorRect.new()
	overlay.name = "DimOverlay"
	overlay.color = Color(0.04, 0.05, 0.04, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	habitat_purchase_modal.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.5)
	habitat_purchase_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 560)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("ui.habitat"), 22)
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	column.add_child(title)

	var helper: Label = _make_popup_label(LocalizationSystem.tr_key("ui.choose_habitat_type"), 14)
	_apply_label_color(helper, POPUP_TEXT_SECONDARY)
	column.add_child(helper)

	if purchase_cost < 0:
		var sold_out_label: Label = _make_popup_label(LocalizationSystem.tr_key("ui.all_habitats_purchased"), 15)
		_apply_label_color(sold_out_label, POPUP_TEXT_SECONDARY)
		column.add_child(sold_out_label)
	else:
		var grid: GridContainer = GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		column.add_child(grid)

		for habitat_type in ReptileSystem.get_habitat_types():
			grid.add_child(_make_habitat_type_purchase_card(habitat_id, slot_index, str(habitat_type), purchase_cost))

	column.add_child(_make_popup_button("ui.cancel", func() -> void:
		_close_habitat_purchase_modal()
	))


func _get_habitat_options_order() -> Array[String]:
	var preferred_order: Array[String] = ["grass", "sand", "stone", "jungle"]
	var available: Array[String] = ReptileSystem.get_habitat_types()
	var result: Array[String] = []
	for habitat_type in preferred_order:
		if available.has(habitat_type):
			result.append(habitat_type)
	for habitat_type in available:
		if not result.has(habitat_type):
			result.append(habitat_type)
	return result


func _add_habitat_option_row(parent: Control, habitat_id: String, slot_index: int, habitat_type: String, purchase_cost: int, row_index: int, origin: Vector2, scale: float) -> void:
	var row_button_y: float = HABITAT_OPTIONS_ROW_BUTTON_START_Y + HABITAT_OPTIONS_ROW_STEP_Y * float(row_index)
	var localized_name: String = LocalizationSystem.tr_key(ReptileSystem.get_habitat_type_label_key(habitat_type))
	var price_text: String = LocalizationSystem.tr_key("currency.repticash") + " " + str(purchase_cost)

	_add_habitat_options_label(parent, localized_name, Vector2(HABITAT_OPTIONS_ROW_NAME_X, row_button_y + HABITAT_OPTIONS_ROW_NAME_Y_OFFSET), HABITAT_OPTIONS_ROW_TEXT_SIZE, 39, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_LEFT, origin, scale, true)
	_add_habitat_options_label(parent, price_text, Vector2(HABITAT_OPTIONS_ROW_PRICE_X, row_button_y + HABITAT_OPTIONS_ROW_PRICE_Y_OFFSET), HABITAT_OPTIONS_ROW_TEXT_SIZE, 36, POPUP_TEXT_SUCCESS, HORIZONTAL_ALIGNMENT_LEFT, origin, scale, false)

	var buy_callable: Callable = Callable(self, "_on_habitat_option_buy_pressed").bind(habitat_id, slot_index, habitat_type)
	_add_habitat_options_button(parent, LocalizationSystem.tr_key("ui.buy"), Vector2(HABITAT_OPTIONS_BUY_BUTTON_CENTER_X, row_button_y), HABITAT_OPTIONS_BUY_BUTTON_SIZE, 42, buy_callable, origin, scale)


func _add_habitat_options_label(parent: Control, text: String, reference_center: Vector2, reference_size: Vector2, base_font_size: int, color: Color, alignment: HorizontalAlignment, origin: Vector2, scale: float, with_shadow: bool) -> Label:
	var label: Label = _make_reference_label(text, base_font_size, color, alignment, scale)
	label.clip_text = false
	if with_shadow:
		label.add_theme_color_override("font_shadow_color", Color(0.10, 0.06, 0.02, 0.85))
		label.add_theme_constant_override("shadow_offset_x", max(1, int(round(2.0 * scale))))
		label.add_theme_constant_override("shadow_offset_y", max(1, int(round(3.0 * scale))))
	parent.add_child(label)
	_position_reference_control(label, reference_center, reference_size, origin, scale)
	return label


func _add_habitat_options_button(parent: Control, text: String, reference_center: Vector2, reference_size: Vector2, base_font_size: int, pressed_callable: Callable, origin: Vector2, scale: float) -> Button:
	var button: Button = _make_reference_hitbox_button(pressed_callable)
	button.tooltip_text = text
	parent.add_child(button)
	_position_reference_control(button, reference_center, reference_size, origin, scale)

	var label: Label = _make_reference_label(text, base_font_size, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, scale)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_color_override("font_shadow_color", Color(0.08, 0.08, 0.08, 0.90))
	label.add_theme_constant_override("shadow_offset_y", max(1, int(round(3.0 * scale))))
	button.add_child(label)
	return button


func _on_habitat_option_buy_pressed(habitat_id: String, slot_index: int, habitat_type: String) -> void:
	if habitat_purchase_modal == null:
		return
	var current_state: Dictionary = _get_saved_habitat_state(habitat_id)
	if bool(current_state.get("purchased", false)):
		return
	_try_purchase_habitat(habitat_id, slot_index, habitat_type)


func _make_habitat_type_purchase_card(habitat_id: String, slot_index: int, habitat_type: String, purchase_cost: int) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 180)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var _hab_folder: String = str(_biome_config.get("habitat_art_folder", "res://assets/art/habitats/"))
	var preview: TextureRect = _make_fixed_texture(_hab_folder + ReptileSystem.normalize_habitat_type(habitat_type) + "_basic.png", Vector2(118, 78))
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(preview)

	var name_label: Label = _make_popup_label(LocalizationSystem.tr_key(ReptileSystem.get_habitat_type_label_key(habitat_type)), 14)
	_apply_label_color(name_label, POPUP_TEXT_PRIMARY)
	column.add_child(name_label)

	var price_label: Label = _make_popup_label(LocalizationSystem.tr_key("currency.repticash") + " " + str(purchase_cost), 12)
	_apply_label_color(price_label, POPUP_TEXT_SECONDARY)
	column.add_child(price_label)

	var buy_button: Button = _make_popup_button("ui.buy", func() -> void:
		_try_purchase_habitat(habitat_id, slot_index, habitat_type)
	)
	buy_button.custom_minimum_size = Vector2(0, 40)
	buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_button.disabled = purchase_cost > 0 and not EconomySystem.can_afford("repticash", purchase_cost)
	buy_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	buy_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	buy_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	buy_button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.45, 0.45, 0.42, 0.75)))
	_apply_button_text_color(buy_button, BUTTON_TEXT_COLOR)
	column.add_child(buy_button)

	return card


func _show_placeholder_popup(title_key: String, body_key: String) -> void:
	var popup: PopupPanel = _create_action_popup()
	var column: VBoxContainer = _add_popup_column(popup)

	column.add_child(_make_popup_label(LocalizationSystem.tr_key(title_key), 20))
	column.add_child(_make_popup_label(LocalizationSystem.tr_key(body_key), 14))
	column.add_child(_make_popup_button("ui.open_management" if title_key == "ui.reptile_management" else "ui.add_reptile", func() -> void:
		popup.hide()
	))
	column.add_child(_make_popup_button("ui.cancel", func() -> void:
		popup.hide()
	))

	popup.popup_centered(Vector2(360, 230))


func _show_reptile_assignment_popup(habitat_id: String) -> void:
	_close_reptile_selection_modal()
	if _is_habitat_building(habitat_id):
		_show_message_popup("habitat.building_in_progress")
		return
	if _is_habitat_upgrading(habitat_id):
		_show_message_popup("habitat.upgrading")
		return

	reptile_selection_modal = Control.new()
	reptile_selection_modal.name = "ReptileAssignmentModal"
	reptile_selection_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	reptile_selection_modal.z_index = 30
	add_child(reptile_selection_modal)

	var overlay: ColorRect = ColorRect.new()
	overlay.name = "DimOverlay"
	overlay.color = Color(0.04, 0.05, 0.04, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	reptile_selection_modal.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 20
	center.offset_right = -20
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.5)
	reptile_selection_modal.add_child(center)

	var viewport_size: Vector2 = get_viewport_rect().size
	var modal_width: float = min(max(viewport_size.x * 0.9, 560.0), viewport_size.x - 40.0)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(modal_width, 610)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("ui.choose_reptile"), 21)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	header.add_child(title)

	var close_button: Button = Button.new()
	close_button.text = LocalizationSystem.tr_key("ui.close")
	close_button.custom_minimum_size = Vector2(88, 42)
	_apply_button_text_color(close_button, POPUP_TEXT_PRIMARY)
	close_button.pressed.connect(_close_reptile_selection_modal)
	header.add_child(close_button)

	var subtitle: Label = _make_popup_label(LocalizationSystem.tr_key("ui.available_reptiles"), 13)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_label_color(subtitle, POPUP_TEXT_SECONDARY)
	column.add_child(subtitle)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 450)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.custom_minimum_size = Vector2(max(0.0, modal_width - 36.0), 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var instances: Array = ReptileSystem.get_owned_unassigned_reptiles()
	if instances.is_empty():
		_close_reptile_selection_modal()
		_show_no_available_reptiles_popup()
		return

	for instance_value in instances:
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue

		var instance: Dictionary = instance_value as Dictionary
		list.add_child(_make_assignable_reptile_card(instance, habitat_id))

	column.add_child(_make_popup_button("ui.cancel", func() -> void:
		_close_reptile_selection_modal()
	))


func _show_no_available_reptiles_popup() -> void:
	_close_reptile_selection_modal()

	reptile_selection_modal = Control.new()
	reptile_selection_modal.name = "NoAvailableReptilesModal"
	reptile_selection_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(reptile_selection_modal)

	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.04, 0.05, 0.04, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	reptile_selection_modal.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.5)
	reptile_selection_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 260)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("ui.no_available_reptiles"), 20)
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	column.add_child(title)

	var message: Label = _make_popup_label(LocalizationSystem.tr_key("ui.no_available_reptiles_message"), 14)
	_apply_label_color(message, POPUP_TEXT_SECONDARY)
	column.add_child(message)

	var open_shop: Button = _make_popup_button("ui.open_shop", func() -> void:
		_close_reptile_selection_modal()
		_show_shop_view()
	)
	open_shop.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	open_shop.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	open_shop.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	_apply_button_text_color(open_shop, BUTTON_TEXT_COLOR)
	column.add_child(open_shop)

	column.add_child(_make_popup_button("ui.cancel", func() -> void:
		_close_reptile_selection_modal()
	))


func _make_assignable_reptile_card(instance: Dictionary, habitat_id: String) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 140)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	var reptile_id: String = str(instance.get("reptile_id", ""))
	var reptile: Dictionary = ReptileSystem.get_reptile(reptile_id)
	var variant: Dictionary = ReptileSystem.get_owned_animal_variant(instance)

	var icon: TextureRect = _make_fixed_texture(ReptileSystem.get_owned_animal_image_path(instance), Vector2(88, 88))
	row.add_child(icon)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var name_label: Label = Label.new()
	name_label.text = _get_reptile_display_name(instance, reptile)
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 15)
	_apply_label_color(name_label, POPUP_TEXT_PRIMARY)
	info.add_child(name_label)

	var species_label: Label = Label.new()
	species_label.text = LocalizationSystem.tr_key(str(reptile.get("name_key", reptile_id)))
	species_label.clip_text = true
	species_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(species_label, POPUP_TEXT_SECONDARY)
	info.add_child(species_label)

	var rarity_row: HBoxContainer = HBoxContainer.new()
	rarity_row.add_theme_constant_override("separation", 6)
	info.add_child(rarity_row)
	var display_rarity: String = str(instance.get("rarity", str(variant.get("rarity", "common"))))
	var rarity_icon_path: String = ReptileSystem.RARITY_ICON_PATHS.get(display_rarity, str(variant.get("rarity_icon_path", "")))
	rarity_row.add_child(_make_rarity_icon(rarity_icon_path, RARITY_ICON_SIZE))

	var rarity: Label = Label.new()
	rarity.text = LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(display_rarity))
	rarity.clip_text = true
	rarity.add_theme_font_size_override("font_size", 12)
	_apply_label_color(rarity, POPUP_TEXT_ACCENT)
	rarity_row.add_child(rarity)

	var sex_label: Label = Label.new()
	sex_label.text = LocalizationSystem.tr_key("ui.sex") + ": " + _get_localized_sex(str(instance.get("sex", "male")))
	sex_label.clip_text = true
	sex_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(sex_label, POPUP_TEXT_SECONDARY)
	info.add_child(sex_label)

	var habitat: Dictionary = _get_saved_habitat_state(habitat_id)
	var preferred_type: String = ReptileSystem.get_reptile_preferred_habitat_type(reptile_id)
	if not preferred_type.is_empty() and not habitat.is_empty():
		var current_type: String = ReptileSystem.normalize_habitat_type(str(habitat.get("habitat_type", "grass")))
		var compatibility: int = 100 if current_type == preferred_type else 50
		var habitat_label: Label = Label.new()
		habitat_label.text = LocalizationSystem.tr_key("habitat.best_type") + ": " + LocalizationSystem.tr_key(ReptileSystem.get_habitat_type_label_key(preferred_type)) + " | " + LocalizationSystem.tr_key("habitat.compatibility_income") + ": " + str(compatibility) + "%"
		habitat_label.clip_text = true
		habitat_label.add_theme_font_size_override("font_size", 11)
		_apply_label_color(habitat_label, POPUP_TEXT_SECONDARY)
		info.add_child(habitat_label)

	var action_area: CenterContainer = CenterContainer.new()
	action_area.custom_minimum_size = Vector2(104, 0)
	action_area.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(action_area)

	var button: Button = Button.new()
	button.text = LocalizationSystem.tr_key("ui.place_reptile")
	button.custom_minimum_size = Vector2(96, 48)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	_apply_button_text_color(button, BUTTON_TEXT_COLOR)
	button.pressed.connect(func() -> void:
		_place_owned_reptile(str(instance.get("instance_id", "")), habitat_id)
	)
	action_area.add_child(button)

	return card


func _make_resource_buy_card(resource_id: String) -> Control:
	var icon_path: String = SHOP_FOOD_ICON_PATH if resource_id == "food" else SHOP_WATER_ICON_PATH
	var label_key: String = "shop.buy_food" if resource_id == "food" else "shop.buy_water"

	var shop_cfg: Dictionary = {}
	if has_node("/root/ReptileSystem"):
		var rs: Node = get_node("/root/ReptileSystem")
		if rs.has_method("get_shop_config"):
			shop_cfg = rs.call("get_shop_config", resource_id)

	var price: int = int(shop_cfg.get("price", 50))
	var amount: int = int(shop_cfg.get("amount", 20))
	var current: int = 0
	var max_val: int = 100
	if has_node("/root/ReptileSystem"):
		var rs: Node = get_node("/root/ReptileSystem")
		current = int(rs.call("get_biome_resource_current", biome_id, resource_id))
		max_val = int(rs.call("get_biome_resource_max", biome_id, resource_id))

	var is_full: bool = current >= max_val

	var card: Control = Control.new()
	card.custom_minimum_size = Vector2(0, 254)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS

	card.add_child(_make_shop_texture_background(SHOP_RESOURCE_CARD_BG_PATH))

	var icon: Control = _make_icon_or_fallback(icon_path, Vector2(107, 107), resource_id[0].to_upper())
	_position_shop_control(icon, Vector2(0.50, 0.255), Vector2(107, 107))
	card.add_child(icon)

	var name_lbl: Label = _make_popup_label(LocalizationSystem.tr_key(label_key).to_upper(), 23)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
	name_lbl.add_theme_constant_override("shadow_offset_x", 0)
	name_lbl.add_theme_constant_override("shadow_offset_y", 0)
	_apply_label_color(name_lbl, POPUP_TEXT_PRIMARY)
	_position_shop_control(name_lbl, Vector2(0.50, 0.500), Vector2(230, 36))
	card.add_child(name_lbl)

	var level_lbl: Label = _make_popup_label(str(current) + "/" + str(max_val), 25)
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_apply_label_color(level_lbl, POPUP_TEXT_ACCENT)
	_position_shop_control(level_lbl, Vector2(0.50, 0.605), Vector2(214, 34))
	card.add_child(level_lbl)

	var amount_cost_row: HBoxContainer = HBoxContainer.new()
	amount_cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	amount_cost_row.add_theme_constant_override("separation", 11)
	_position_shop_control(amount_cost_row, Vector2(0.50, 0.705), Vector2(270, 34))
	card.add_child(amount_cost_row)

	var amount_lbl: Label = _make_popup_label(LocalizationSystem.tr_key("shop.resource_amount").replace("{amount}", str(amount)), 27)
	amount_lbl.custom_minimum_size = Vector2(82, 34)
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_apply_label_color(amount_lbl, POPUP_TEXT_SUCCESS)
	_make_label_visually_bold(amount_lbl)
	amount_cost_row.add_child(amount_lbl)

	var cost_lbl: Label = _make_popup_label(LocalizationSystem.tr_key("currency.repticash") + " " + str(price), 23)
	cost_lbl.custom_minimum_size = Vector2(126, 34)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_apply_label_color(cost_lbl, POPUP_TEXT_ACCENT)
	_make_label_visually_bold(cost_lbl)
	amount_cost_row.add_child(cost_lbl)

	var btn: Button = Button.new()
	btn.text = LocalizationSystem.tr_key("shop.resource_full").to_upper() if is_full else LocalizationSystem.tr_key("ui.buy").to_upper()
	btn.disabled = is_full
	btn.mouse_default_cursor_shape = Control.CURSOR_ARROW if btn.disabled else Control.CURSOR_POINTING_HAND
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", _make_transparent_button_style())
	btn.add_theme_stylebox_override("hover", _make_transparent_button_style())
	btn.add_theme_stylebox_override("pressed", _make_transparent_button_style())
	btn.add_theme_stylebox_override("disabled", _make_transparent_button_style())
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(func() -> void:
		var result: Dictionary = ReptileSystem.buy_resource(biome_id, resource_id)
		if not bool(result.get("success", false)):
			_show_message_popup(str(result.get("message_key", "ui.not_enough_rs")))
			return
		_show_shop_view()
	)
	_apply_button_text_color(btn, BUTTON_TEXT_COLOR if not is_full else Color(0.88, 0.84, 0.72, 0.75))
	_position_shop_control(btn, Vector2(0.50, 0.870), Vector2(198, 54))
	card.add_child(btn)

	return card


func _make_resource_buy_card_fallback(resource_id: String) -> Control:
	var icon_path: String = FOOD_ICON_PATH if resource_id == "food" else WATER_ICON_PATH
	var label_key: String = "shop.buy_food" if resource_id == "food" else "shop.buy_water"

	var shop_cfg: Dictionary = {}
	if has_node("/root/ReptileSystem"):
		var rs: Node = get_node("/root/ReptileSystem")
		if rs.has_method("get_shop_config"):
			shop_cfg = rs.call("get_shop_config", resource_id)

	var price: int = int(shop_cfg.get("price", 50))
	var amount: int = int(shop_cfg.get("amount", 20))
	var current: int = 0
	var max_val: int = 100
	if has_node("/root/ReptileSystem"):
		var rs: Node = get_node("/root/ReptileSystem")
		current = int(rs.call("get_biome_resource_current", biome_id, resource_id))
		max_val = int(rs.call("get_biome_resource_max", biome_id, resource_id))

	var is_full: bool = current >= max_val

	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var col: VBoxContainer = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	margin.add_child(col)

	var icon: Control = _make_icon_or_fallback(icon_path, Vector2(48, 48), resource_id[0].to_upper())
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(icon)

	var name_lbl: Label = _make_popup_label(LocalizationSystem.tr_key(label_key), 13)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_color(name_lbl, POPUP_TEXT_PRIMARY)
	col.add_child(name_lbl)

	var level_lbl: Label = _make_popup_label(str(current) + "/" + str(max_val), 12)
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_color(level_lbl, POPUP_TEXT_ACCENT)
	col.add_child(level_lbl)

	var amount_lbl: Label = _make_popup_label(LocalizationSystem.tr_key("shop.resource_amount").replace("{amount}", str(amount)), 12)
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_color(amount_lbl, POPUP_TEXT_SUCCESS)
	col.add_child(amount_lbl)

	var cost_lbl: Label = _make_popup_label(LocalizationSystem.tr_key("currency.repticash") + " " + str(price), 12)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_color(cost_lbl, POPUP_TEXT_ACCENT)
	col.add_child(cost_lbl)

	var btn: Button = Button.new()
	btn.text = LocalizationSystem.tr_key("shop.resource_full") if is_full else LocalizationSystem.tr_key("ui.upgrade_buy")
	btn.disabled = is_full
	btn.custom_minimum_size = Vector2(0, 38)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_ARROW if btn.disabled else Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("disabled", _make_button_style(Color(0.45, 0.45, 0.42, 0.75)))
	btn.pressed.connect(func() -> void:
		var result: Dictionary = ReptileSystem.buy_resource(biome_id, resource_id)
		if not bool(result.get("success", false)):
			_show_message_popup(str(result.get("message_key", "ui.not_enough_rs")))
			return
		_show_shop_view()
	)
	_apply_button_text_color(btn, POPUP_TEXT_PRIMARY)
	col.add_child(btn)

	return card


func _make_shop_reptile_card(reptile: Dictionary) -> Control:
	var card: Control = Control.new()
	card.custom_minimum_size = Vector2(0, SHOP_REPTILE_CARD_HEIGHT)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS

	var row_bg: TextureRect = _make_shop_texture_background(QUESTS_CARD_BG_PATH)
	row_bg.anchor_left = 0.054
	row_bg.anchor_top = 0.03
	row_bg.anchor_right = 0.946
	row_bg.anchor_bottom = 0.97
	card.add_child(row_bg)

	var reptile_id: String = str(reptile.get("id", ""))
	var variant: Dictionary = ReptileSystem.get_variant_for_reptile(reptile_id, str(reptile.get("default_variant_id", "")))

	var portrait: TextureRect = _make_fixed_texture(_get_variant_image_path(reptile, variant, true), Vector2(144, 144))
	_position_shop_control(portrait, Vector2(0.175, 0.500), SHOP_REPTILE_PORTRAIT_SIZE)
	card.add_child(portrait)

	var name_label: Label = Label.new()
	name_label.text = LocalizationSystem.tr_key(str(reptile.get("name_key", reptile_id))).to_upper()
	name_label.clip_text = true
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 15 + SHOP_REPTILE_TEXT_BONUS)
	_apply_label_color(name_label, POPUP_TEXT_PRIMARY)
	_position_shop_control(name_label, Vector2(0.515, 0.250), Vector2(430, 46))
	card.add_child(name_label)

	var income: Control = _make_shop_reptile_income_row(reptile_id, float(reptile.get("base_income_per_minute", 0.0)))
	_position_shop_control(income, Vector2(0.515, 0.445), Vector2(430, 92))
	card.add_child(income)

	var preferred_type: String = ReptileSystem.get_reptile_preferred_habitat_type(reptile_id)
	var habitat_text := ""
	if not preferred_type.is_empty():
		habitat_text = LocalizationSystem.tr_key("habitat.best_type") + ": " + LocalizationSystem.tr_key(ReptileSystem.get_habitat_type_label_key(preferred_type))

	var habitat_hint: Label = Label.new()
	habitat_hint.text = habitat_text
	habitat_hint.clip_text = true
	habitat_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	habitat_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	habitat_hint.add_theme_font_size_override("font_size", 10 + SHOP_REPTILE_TEXT_BONUS)
	_apply_label_color(habitat_hint, POPUP_TEXT_SECONDARY)
	_position_shop_control(habitat_hint, Vector2(0.515, 0.605), Vector2(430, 38))
	card.add_child(habitat_hint)

	var sex_selector: OptionButton = OptionButton.new()
	sex_selector.add_item(LocalizationSystem.tr_key("ui.male"), 0)
	sex_selector.add_item(LocalizationSystem.tr_key("ui.female"), 1)
	sex_selector.add_theme_stylebox_override("normal", _make_button_style(Color(0.20, 0.10, 0.05, 0.96)))
	sex_selector.add_theme_stylebox_override("hover", _make_button_style(Color(0.28, 0.14, 0.07, 0.96)))
	sex_selector.add_theme_stylebox_override("pressed", _make_button_style(Color(0.16, 0.08, 0.04, 0.96)))
	sex_selector.add_theme_color_override("font_color", BUTTON_TEXT_COLOR)
	sex_selector.add_theme_color_override("font_hover_color", BUTTON_TEXT_COLOR)
	sex_selector.add_theme_font_size_override("font_size", 12 + SHOP_REPTILE_TEXT_BONUS)
	_position_shop_control(sex_selector, Vector2(0.365, 0.740), SHOP_REPTILE_DROPDOWN_SIZE)
	card.add_child(sex_selector)

	var common_button: Control = _make_shop_variant_texture_button(reptile_id, "common", sex_selector)
	_position_shop_control(common_button, Vector2(0.785, 0.4005), SHOP_REPTILE_BUY_BUTTON_SIZE)
	card.add_child(common_button)

	var rare_button: Control = _make_shop_variant_texture_button(reptile_id, "rare", sex_selector)
	_position_shop_control(rare_button, Vector2(0.785, 0.6595), SHOP_REPTILE_BUY_BUTTON_SIZE)
	card.add_child(rare_button)

	_make_scroll_safe(card)
	return card


func _make_shop_reptile_card_fallback(reptile: Dictionary) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 174)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	var reptile_id: String = str(reptile.get("id", ""))
	var variant: Dictionary = ReptileSystem.get_variant_for_reptile(reptile_id, str(reptile.get("default_variant_id", "")))

	var icon: TextureRect = _make_fixed_texture(_get_variant_image_path(reptile, variant, true), Vector2(92, 92))
	row.add_child(icon)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var name_label: Label = Label.new()
	name_label.text = LocalizationSystem.tr_key(str(reptile.get("name_key", reptile_id)))
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 15)
	_apply_label_color(name_label, POPUP_TEXT_PRIMARY)
	info.add_child(name_label)

	var rarity_row: HBoxContainer = HBoxContainer.new()
	rarity_row.add_theme_constant_override("separation", 6)
	info.add_child(rarity_row)

	rarity_row.add_child(_make_rarity_icon(str(variant.get("rarity_icon_path", "")), RARITY_ICON_SIZE))

	var rarity: Label = Label.new()
	rarity.text = LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(str(variant.get("rarity", "common"))))
	rarity.clip_text = true
	rarity.add_theme_font_size_override("font_size", 12)
	_apply_label_color(rarity, POPUP_TEXT_ACCENT)
	rarity_row.add_child(rarity)

	var income: Label = Label.new()
	income.text = LocalizationSystem.tr_key("ui.base_income") + ": " + LocalizationSystem.tr_key("currency.repticash") + " " + str(int(reptile.get("base_income_per_minute", 0))) + " " + LocalizationSystem.tr_key("ui.per_minute")
	income.clip_text = true
	income.add_theme_font_size_override("font_size", 12)
	_apply_label_color(income, POPUP_TEXT_SECONDARY)
	info.add_child(income)

	var preferred_type: String = ReptileSystem.get_reptile_preferred_habitat_type(reptile_id)
	if not preferred_type.is_empty():
		var habitat_hint: Label = Label.new()
		habitat_hint.text = LocalizationSystem.tr_key("habitat.best_type") + ": " + LocalizationSystem.tr_key(ReptileSystem.get_habitat_type_label_key(preferred_type))
		habitat_hint.clip_text = true
		habitat_hint.add_theme_font_size_override("font_size", 12)
		_apply_label_color(habitat_hint, POPUP_TEXT_SECONDARY)
		info.add_child(habitat_hint)

	var sex_row: HBoxContainer = HBoxContainer.new()
	sex_row.add_theme_constant_override("separation", 6)
	info.add_child(sex_row)

	var sex_label: Label = Label.new()
	sex_label.text = LocalizationSystem.tr_key("ui.sex") + ":"
	sex_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(sex_label, POPUP_TEXT_SECONDARY)
	sex_row.add_child(sex_label)

	var sex_selector: OptionButton = OptionButton.new()
	sex_selector.custom_minimum_size = Vector2(122, 34)
	sex_selector.add_item(LocalizationSystem.tr_key("ui.male"), 0)
	sex_selector.add_item(LocalizationSystem.tr_key("ui.female"), 1)
	sex_row.add_child(sex_selector)

	var action_area: VBoxContainer = VBoxContainer.new()
	action_area.custom_minimum_size = Vector2(154, 0)
	action_area.alignment = BoxContainer.ALIGNMENT_CENTER
	action_area.add_theme_constant_override("separation", 8)
	row.add_child(action_area)

	action_area.add_child(_make_shop_variant_button(reptile_id, "common", sex_selector))
	action_area.add_child(_make_shop_variant_button(reptile_id, "rare", sex_selector))

	_make_scroll_safe(card)
	return card


func _make_shop_variant_texture_button(reptile_id: String, rarity: String, sex_selector: OptionButton) -> TextureButton:
	var variant: Dictionary = ReptileSystem.get_shop_variant_for_rarity(reptile_id, rarity)
	var button: TextureButton = TextureButton.new()
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_normal = AssetPaths.load_texture(SHOP_BUY_RARE_BUTTON_PATH if rarity == "rare" else SHOP_BUY_COMMON_BUTTON_PATH)
	button.texture_hover = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.texture_disabled = button.texture_normal
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var label: Label = Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 52
	label.offset_right = -8
	label.offset_top = 6
	label.offset_bottom = -6
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12 + SHOP_REPTILE_BUTTON_TEXT_BONUS)
	label.add_theme_color_override("font_color", BUTTON_TEXT_COLOR)
	label.add_theme_color_override("font_shadow_color", Color(0.08, 0.05, 0.01, 0.90))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)

	var rarity_label: String = LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(rarity))
	if variant.is_empty():
		label.text = LocalizationSystem.tr_key("shop.unavailable").to_upper()
		button.disabled = true
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		return button

	var price: int = ReptileSystem.get_shop_purchase_price(reptile_id, rarity)
	var price_text: String = LocalizationSystem.tr_key("ui.free") if price == 0 else LocalizationSystem.tr_key("currency.repticash") + " " + str(price)
	label.text = (LocalizationSystem.tr_key("ui.buy") + " " + rarity_label).to_upper() + "\n" + price_text
	button.disabled = price > 0 and not EconomySystem.can_afford("repticash", price)
	if button.disabled:
		label.add_theme_color_override("font_color", Color(0.86, 0.83, 0.72, 0.70))
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	button.pressed.connect(func() -> void:
		_try_shop_buy_reptile(reptile_id, rarity, _get_selected_sex(sex_selector))
	)
	return button


func _make_shop_variant_button(reptile_id: String, rarity: String, sex_selector: OptionButton) -> Button:
	var variant: Dictionary = ReptileSystem.get_shop_variant_for_rarity(reptile_id, rarity)
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(146, 56)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.45, 0.45, 0.42, 0.75)))
	_apply_button_text_color(button, BUTTON_TEXT_COLOR)

	var rarity_label: String = LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(rarity))

	if variant.is_empty():
		button.icon = AssetPaths.load_texture(ReptileSystem.get_rarity_icon_path(rarity))
		button.expand_icon = true
		button.text = rarity_label + "\n" + LocalizationSystem.tr_key("shop.unavailable")
		button.disabled = true
		return button

	var price: int = ReptileSystem.get_shop_purchase_price(reptile_id, rarity)
	var price_text: String = LocalizationSystem.tr_key("ui.free") if price == 0 else LocalizationSystem.tr_key("currency.repticash") + " " + str(price)
	var rarity_icon_path: String = str(variant.get("rarity_icon_path", ReptileSystem.get_rarity_icon_path(rarity)))
	button.icon = AssetPaths.load_texture(rarity_icon_path)
	if button.icon == null:
		button.icon = AssetPaths.load_texture(ReptileSystem.get_rarity_icon_path(rarity))
	button.expand_icon = true
	button.text = LocalizationSystem.tr_key("ui.buy") + " " + rarity_label + "\n" + price_text
	button.disabled = price > 0 and not EconomySystem.can_afford("repticash", price)
	button.pressed.connect(func() -> void:
		_try_shop_buy_reptile(reptile_id, rarity, _get_selected_sex(sex_selector))
	)
	return button


func _place_owned_reptile(instance_id: String, habitat_id: String) -> void:
	var result: Dictionary = ReptileSystem.assign_reptile_to_habitat(instance_id, habitat_id, biome_id)
	if not bool(result.get("success", false)):
		_show_message_popup(str(result.get("message_key", "ui.not_enough_currency")))
		return

	_refresh_habitat_slots()
	_close_reptile_selection_modal()
	_notify_quest_event("reptile_assigned")
	if action_popup != null:
		action_popup.hide()


func _show_management_popup(habitat_id: String) -> void:
	current_management_feedback_key = ""
	var instance: Dictionary = ReptileSystem.get_reptile_for_habitat(habitat_id)
	_show_management_for_instance(instance)


func _show_management_for_instance_id(instance_id: String, clear_feedback: bool = true) -> void:
	if clear_feedback:
		current_management_feedback_key = ""

	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var instance_value: Variant = instances.get(instance_id, {})
	if typeof(instance_value) != TYPE_DICTIONARY:
		_show_message_popup("ui.reptile_unavailable")
		return

	_show_management_for_instance(instance_value as Dictionary)


func _show_management_for_instance(instance: Dictionary) -> void:
	var preserved_feedback_key: String = current_management_feedback_key
	_close_management_modal()
	current_management_feedback_key = preserved_feedback_key
	if instance.is_empty():
		_show_message_popup("ui.reptile_unavailable")
		return
	current_management_instance_id = str(instance.get("instance_id", ""))

	var reptile: Dictionary = ReptileSystem.get_reptile(str(instance.get("reptile_id", "")))
	var variant: Dictionary = ReptileSystem.get_owned_animal_variant(instance)
	var is_assigned: bool = _is_reptile_instance_assigned(instance)

	management_modal = Control.new()
	management_modal.name = "ReptileManagementModal"
	management_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	management_modal.z_index = 80
	add_child(management_modal)
	management_modal.move_to_front()

	var overlay: ColorRect = ColorRect.new()
	overlay.name = "DimOverlay"
	overlay.color = Color(0.04, 0.05, 0.04, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	management_modal.add_child(overlay)

	var nav_cover: ColorRect = ColorRect.new()
	nav_cover.name = "BottomNavigationCover"
	nav_cover.color = Color(0.02, 0.04, 0.03, 0.88)
	nav_cover.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav_cover.offset_top = -BOTTOM_NAV_HEIGHT
	nav_cover.offset_bottom = 0
	management_modal.add_child(nav_cover)

	var panel_layer: Control = Control.new()
	panel_layer.name = "ReptileManagementPanel"
	panel_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	management_modal.add_child(panel_layer)

	var viewport_size: Vector2 = get_viewport_rect().size
	var reference_scale: float = min(viewport_size.x / REPTILE_MGMT_REFERENCE_SIZE.x, viewport_size.y / REPTILE_MGMT_REFERENCE_SIZE.y) * REPTILE_MGMT_WINDOW_SCALE
	var reference_origin: Vector2 = (viewport_size - REPTILE_MGMT_REFERENCE_SIZE * reference_scale) * 0.5

	var habitat_background: TextureRect = TextureRect.new()
	habitat_background.name = "HabitatPortraitBackground"
	var habitat_background_path: String = _get_reptile_management_background_path(instance)
	habitat_background.texture = AssetPaths.load_texture(habitat_background_path)
	if habitat_background.texture == null and habitat_background_path != REPTILE_MGMT_GRASS_BG_PATH:
		habitat_background.texture = AssetPaths.load_texture(REPTILE_MGMT_GRASS_BG_PATH)
	habitat_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	habitat_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	habitat_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_layer.add_child(habitat_background)
	_position_reference_control(habitat_background, REPTILE_MGMT_HABITAT_BG_CENTER, REPTILE_MGMT_HABITAT_BG_SIZE, reference_origin, reference_scale)

	var panel_background: TextureRect = TextureRect.new()
	panel_background.name = "ReptileManagementFrame"
	panel_background.texture = AssetPaths.load_texture(REPTILE_MGMT_FRAME_PATH)
	if panel_background.texture == null:
		panel_background.texture = AssetPaths.load_texture(REPTILE_MGMT_LEGACY_BACKGROUND_PATH)
	panel_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel_background.stretch_mode = TextureRect.STRETCH_SCALE
	panel_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_layer.add_child(panel_background)
	_position_reference_control(panel_background, REPTILE_MGMT_FRAME_CENTER, REPTILE_MGMT_REFERENCE_SIZE, reference_origin, reference_scale)

	var title_art: TextureRect = TextureRect.new()
	title_art.name = "TitleArt"
	title_art.texture = AssetPaths.load_texture(_get_reptile_management_title_path())
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if title_art.texture != null:
		panel_layer.add_child(title_art)
		_position_reference_control(title_art, REPTILE_MGMT_TITLE_CENTER, REPTILE_MGMT_TITLE_SIZE, reference_origin, reference_scale)
	else:
		var title_label: Label = _make_reference_label(LocalizationSystem.tr_key("management.reptile").to_upper(), 40, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, reference_scale)
		title_label.add_theme_color_override("font_shadow_color", Color(0.18, 0.10, 0.04, 0.95))
		title_label.add_theme_constant_override("shadow_offset_x", max(1, int(round(3.0 * reference_scale))))
		title_label.add_theme_constant_override("shadow_offset_y", max(1, int(round(4.0 * reference_scale))))
		panel_layer.add_child(title_label)
		_position_reference_control(title_label, REPTILE_MGMT_TITLE_CENTER, REPTILE_MGMT_TITLE_SIZE, reference_origin, reference_scale)

	var close_button: Button = _make_reference_hitbox_button(Callable(self, "_close_management_modal"))
	panel_layer.add_child(close_button)
	_position_reference_control(close_button, REPTILE_MGMT_CLOSE_CENTER, REPTILE_MGMT_CLOSE_SIZE, reference_origin, reference_scale)

	var name_label: Label = _make_reference_label(_get_reptile_display_name(instance, reptile), 40, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_LEFT, reference_scale)
	name_label.clip_text = true
	panel_layer.add_child(name_label)
	_position_reference_control(name_label, REPTILE_MGMT_NAME_CENTER, REPTILE_MGMT_NAME_SIZE, reference_origin, reference_scale)

	var edit_button: Button = _make_edit_icon_button(str(instance.get("instance_id", "")))
	panel_layer.add_child(edit_button)
	_position_reference_control(edit_button, REPTILE_MGMT_EDIT_CENTER, REPTILE_MGMT_EDIT_SIZE, reference_origin, reference_scale)

	var species_name: String = LocalizationSystem.tr_key(str(reptile.get("name_key", "ui.reptile_management_placeholder")))
	var mgmt_rarity: String = str(instance.get("rarity", str(variant.get("rarity", "common"))))
	var rarity_name: String = LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(mgmt_rarity))
	var sex_name: String = _get_localized_sex(str(instance.get("sex", "male")))
	var status_key: String = "animals.status.assigned" if is_assigned else "animals.status.free"
	var habitat_name: String = _get_habitat_display_name(str(instance.get("habitat_id", ""))) if is_assigned else "-"
	var habitat_type: String = _get_reptile_management_habitat_type(instance)
	var habitat_type_name: String = LocalizationSystem.tr_key(ReptileSystem.get_habitat_type_label_key(habitat_type)) if not habitat_type.is_empty() else "-"
	var info_rows: Array = [
		{"key": "reptile.species", "value": species_name},
		{"key": "reptile.rarity", "value": rarity_name},
		{"key": "reptile.sex", "value": sex_name},
		{"key": "reptile.status", "value": LocalizationSystem.tr_key(status_key)},
		{"key": "reptile.habitat", "value": habitat_name},
		{"key": "nav.biome", "value": habitat_type_name}
	]
	var info_y: float = REPTILE_MGMT_INFO_ROW_START_Y
	for row_data in info_rows:
		_add_management_info_row(panel_layer, str(row_data.get("key", "")), str(row_data.get("value", "")), info_y, reference_origin, reference_scale)
		info_y += REPTILE_MGMT_INFO_ROW_STEP
	_add_management_level_bonus_row(panel_layer, instance, reference_origin, reference_scale)
	if is_assigned:
		_add_management_export_button(panel_layer, str(instance.get("habitat_id", "")), reference_origin, reference_scale)
	_add_management_reptile_level_block(panel_layer, instance, reference_origin, reference_scale)

	var portrait: TextureRect = TextureRect.new()
	portrait.name = "ReptilePortrait"
	portrait.texture = AssetPaths.load_texture(ReptileSystem.get_owned_animal_image_path(instance))
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_layer.add_child(portrait)
	_position_reference_control(portrait, REPTILE_MGMT_PORTRAIT_CENTER, REPTILE_MGMT_PORTRAIT_SIZE, reference_origin, reference_scale)

	var needs_title: Label = _make_reference_label(LocalizationSystem.tr_key("management.needs").to_upper(), 30, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, reference_scale)
	needs_title.add_theme_color_override("font_shadow_color", Color(0.10, 0.20, 0.06, 0.85))
	needs_title.add_theme_constant_override("shadow_offset_x", max(1, int(round(2.0 * reference_scale))))
	needs_title.add_theme_constant_override("shadow_offset_y", max(1, int(round(3.0 * reference_scale))))
	panel_layer.add_child(needs_title)
	_position_reference_control(needs_title, REPTILE_MGMT_NEEDS_TITLE_CENTER, REPTILE_MGMT_SECTION_TITLE_SIZE, reference_origin, reference_scale)

	var income_title: Label = _make_reference_label(LocalizationSystem.tr_key("management.income").to_upper(), 30, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, reference_scale)
	income_title.add_theme_color_override("font_shadow_color", Color(0.10, 0.20, 0.06, 0.85))
	income_title.add_theme_constant_override("shadow_offset_x", max(1, int(round(2.0 * reference_scale))))
	income_title.add_theme_constant_override("shadow_offset_y", max(1, int(round(3.0 * reference_scale))))
	panel_layer.add_child(income_title)
	_position_reference_control(income_title, REPTILE_MGMT_INCOME_TITLE_CENTER, REPTILE_MGMT_SECTION_TITLE_SIZE, reference_origin, reference_scale)

	var happiness: int = _get_percent_state(instance, "happiness", 100)
	var satiety: int = _get_percent_state(instance, "hunger", 100)
	var hydration: int = _get_percent_state(instance, "hydration", 100)
	var cleanliness: int = _get_percent_state(instance, "cleanliness", 100)
	_add_management_need_row(panel_layer, "care.happiness", happiness, Color(0.31, 0.76, 0.08, 1.0), REPTILE_MGMT_NEED_ROW_START_Y, reference_origin, reference_scale)
	_add_management_need_row(panel_layer, "care.hunger", satiety, Color(0.38, 0.84, 0.10, 1.0), REPTILE_MGMT_NEED_ROW_START_Y + REPTILE_MGMT_NEED_ROW_STEP, reference_origin, reference_scale)
	_add_management_need_row(panel_layer, "care.hydration", hydration, Color(0.04, 0.64, 0.95, 1.0), REPTILE_MGMT_NEED_ROW_START_Y + REPTILE_MGMT_NEED_ROW_STEP * 2.0, reference_origin, reference_scale)
	_add_management_need_row(panel_layer, "care.cleanliness", cleanliness, Color(0.98, 0.65, 0.08, 1.0), REPTILE_MGMT_NEED_ROW_START_Y + REPTILE_MGMT_NEED_ROW_STEP * 3.0, reference_origin, reference_scale)

	var base_income: float = ReptileSystem.get_base_reptile_income(str(instance.get("reptile_id", "")))
	var happiness_multiplier: float = ReptileSystem.get_happiness_multiplier(instance.get("happiness", 100))
	var variant_multiplier: float = ReptileSystem.get_variant_income_multiplier(variant)
	var habitat_multiplier: float = ReptileSystem.get_habitat_match_multiplier(instance)
	var habitat_level_multiplier: float = ReptileSystem.get_habitat_level_income_multiplier(instance)
	var reptile_level_multiplier: float = ReptileSystem.get_reptile_income_level_multiplier(instance)
	var effective_income: float = ReptileSystem.get_effective_animal_income_per_min(instance)
	var income_rows: Array = [
		{"key": "management.base_income", "value": _format_repticash_per_min(base_income), "final": false},
		{"key": "management.happiness_multiplier", "value": _format_multiplier(happiness_multiplier), "final": false},
		{"key": "management.rarity_multiplier", "value": _format_multiplier(variant_multiplier), "final": false},
		{"key": "management.habitat_multiplier", "value": _format_multiplier(habitat_multiplier), "final": false},
		{"key": "management.habitat_level_bonus", "value": _format_multiplier(habitat_level_multiplier), "final": false},
		{"key": "management.reptile_level_bonus", "value": _format_multiplier(reptile_level_multiplier), "final": false},
		{"key": "management.effective_income", "value": _format_repticash_per_min(effective_income), "final": true}
	]
	var income_y: float = REPTILE_MGMT_INCOME_ROW_START_Y
	for income_data in income_rows:
		_add_management_income_row(panel_layer, str(income_data.get("key", "")), str(income_data.get("value", "")), bool(income_data.get("final", false)), income_y, reference_origin, reference_scale)
		income_y += REPTILE_MGMT_INCOME_ROW_STEP

	_add_management_section_title(panel_layer, "management.actions", REPTILE_MGMT_ACTIONS_TITLE_CENTER, REPTILE_MGMT_ACTIONS_TITLE_SIZE, reference_origin, reference_scale)

	var care_hint_key: String = current_management_feedback_key
	if care_hint_key.is_empty() and not is_assigned:
		care_hint_key = "care.place_reptile_to_care"
	if not care_hint_key.is_empty():
		var care_hint_text: String = LocalizationSystem.tr_key(care_hint_key) if care_hint_key.begins_with("ui.") or care_hint_key.begins_with("care.") or care_hint_key.begins_with("habitat.") else care_hint_key
		var feedback_label: Label = _make_reference_label(care_hint_text, 18, POPUP_TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_CENTER, reference_scale)
		feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel_layer.add_child(feedback_label)
		_position_reference_control(feedback_label, REPTILE_MGMT_FEEDBACK_CENTER, REPTILE_MGMT_FEEDBACK_SIZE, reference_origin, reference_scale)

	_add_management_care_button(panel_layer, "feed", "care.feed", REPTILE_MGMT_FEED_PATH, instance, is_assigned, REPTILE_MGMT_FEED_CENTER, reference_origin, reference_scale)
	_add_management_care_button(panel_layer, "water", "care.water", REPTILE_MGMT_WATER_PATH, instance, is_assigned, REPTILE_MGMT_WATER_CENTER, reference_origin, reference_scale)
	_add_management_care_button(panel_layer, "clean", "care.clean", REPTILE_MGMT_CLEAN_PATH, instance, is_assigned, REPTILE_MGMT_CLEAN_CENTER, reference_origin, reference_scale)
	_add_management_care_button(panel_layer, "play", "care.play", REPTILE_MGMT_PLAY_PATH, instance, is_assigned, REPTILE_MGMT_PLAY_CENTER, reference_origin, reference_scale)

	_add_management_habitat_upgrade_panel(panel_layer, instance, reference_origin, reference_scale)


func _get_reptile_management_title_path() -> String:
	return REPTILE_MGMT_TITLE_EN_PATH if LocalizationSystem.get_language() == "en" else REPTILE_MGMT_TITLE_PL_PATH


func _get_reptile_management_habitat_type(instance: Dictionary) -> String:
	var habitat_id: String = _id_or_empty(instance.get("habitat_id", null))
	if not habitat_id.is_empty():
		var habitat: Dictionary = _get_saved_habitat_state(habitat_id)
		if not habitat.is_empty():
			return ReptileSystem.normalize_habitat_type(str(habitat.get("habitat_type", "grass")))

	var preferred_type: String = ReptileSystem.get_reptile_preferred_habitat_type(str(instance.get("reptile_id", "")))
	if not preferred_type.is_empty():
		return ReptileSystem.normalize_habitat_type(preferred_type)

	return "grass"


func _get_reptile_management_background_path(instance: Dictionary) -> String:
	match _get_reptile_management_habitat_type(instance):
		"sand":
			return REPTILE_MGMT_SAND_BG_PATH
		"stone":
			return REPTILE_MGMT_STONE_BG_PATH
		"jungle":
			return REPTILE_MGMT_JUNGLE_BG_PATH
		_:
			return REPTILE_MGMT_GRASS_BG_PATH


func _get_habitat_level_multiplier_for_level(level: int) -> float:
	match ReptileSystem.normalize_habitat_level(level):
		2:
			return 1.25
		3:
			return 1.50
		_:
			return 1.0


func _position_reference_control(control: Control, reference_center: Vector2, reference_size: Vector2, origin: Vector2, scale: float) -> void:
	var scaled_size: Vector2 = reference_size * scale
	control.position = origin + (reference_center - reference_size * 0.5) * scale
	control.size = scaled_size
	control.custom_minimum_size = scaled_size


func _make_reference_label(text: String, base_font_size: int, color: Color, alignment: HorizontalAlignment, scale: float = 1.0) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.add_theme_font_size_override("font_size", max(9, int(round(float(base_font_size) * scale))))
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_reference_texture_button(texture_path: String, pressed_callable: Callable) -> TextureButton:
	var button: TextureButton = TextureButton.new()
	button.texture_normal = AssetPaths.load_texture(texture_path)
	button.texture_hover = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.texture_disabled = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(pressed_callable)
	return button


func _make_reference_hitbox_button(pressed_callable: Callable) -> Button:
	var button: Button = Button.new()
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	button.pressed.connect(pressed_callable)
	return button


func _add_management_section_title(parent: Control, label_key: String, reference_center: Vector2, reference_size: Vector2, origin: Vector2, scale: float) -> void:
	var title: Label = _make_reference_label(LocalizationSystem.tr_key(label_key).to_upper(), 30, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, scale)
	title.add_theme_color_override("font_shadow_color", Color(0.10, 0.20, 0.06, 0.85))
	title.add_theme_constant_override("shadow_offset_x", max(1, int(round(2.0 * scale))))
	title.add_theme_constant_override("shadow_offset_y", max(1, int(round(3.0 * scale))))
	parent.add_child(title)
	_position_reference_control(title, reference_center, reference_size, origin, scale)


func _add_management_info_row(parent: Control, label_key: String, value: String, reference_y: float, origin: Vector2, scale: float) -> void:
	var label: Label = _make_reference_label(LocalizationSystem.tr_key(label_key) + ":", 18, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_LEFT, scale)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = false
	parent.add_child(label)
	_position_reference_control(label, Vector2(REPTILE_MGMT_INFO_LABEL_CENTER_X, reference_y), Vector2(150, 30), origin, scale)

	var value_label: Label = _make_reference_label(value, 18, POPUP_TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_LEFT, scale)
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	value_label.clip_text = false
	parent.add_child(value_label)
	_position_reference_control(value_label, Vector2(REPTILE_MGMT_INFO_VALUE_CENTER_X, reference_y), Vector2(220, 30), origin, scale)


func _add_management_level_bonus_row(parent: Control, instance: Dictionary, origin: Vector2, scale: float) -> void:
	var income_bonus_percent: int = ReptileSystem.get_reptile_income_level_bonus_percent(instance)
	var bonus_text: String = LocalizationSystem.tr_key("management.level_bonus") + ": +" + str(income_bonus_percent) + "%"
	var bonus_label: Label = _make_reference_label(bonus_text, 18, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER, scale)
	bonus_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	bonus_label.clip_text = false
	parent.add_child(bonus_label)
	_position_reference_control(bonus_label, REPTILE_MGMT_INFO_BONUS_CENTER, Vector2(310, 34), origin, scale)


func _add_management_export_button(parent: Control, habitat_id: String, origin: Vector2, scale: float) -> void:
	if habitat_id.is_empty():
		return

	var button: TextureButton = _make_reference_texture_button(REPTILE_MGMT_EXPORT_PATH, Callable(self, "_confirm_remove_reptile").bind(habitat_id))
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.tooltip_text = LocalizationSystem.tr_key("habitat.remove_reptile")
	parent.add_child(button)
	_position_reference_control(button, REPTILE_MGMT_EXPORT_CENTER, REPTILE_MGMT_EXPORT_SIZE, origin, scale)

	var label: Label = _make_reference_label(LocalizationSystem.tr_key("habitat.storage_short"), 24, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, scale)
	label.add_theme_color_override("font_shadow_color", Color(0.14, 0.08, 0.03, 0.90))
	label.add_theme_constant_override("shadow_offset_y", max(1, int(round(2.0 * scale))))
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 78.0 * scale
	label.offset_right = -12.0 * scale
	label.offset_top = 2.0 * scale
	label.offset_bottom = -2.0 * scale
	button.add_child(label)


func _add_management_reptile_level_block(parent: Control, instance: Dictionary, origin: Vector2, scale: float) -> void:
	var level: int = ReptileSystem.get_reptile_level(instance)
	var max_level: int = ReptileSystem.get_reptile_max_level()
	var current_xp: int = ReptileSystem.get_reptile_xp(instance)
	var required_xp: int = ReptileSystem.get_xp_to_next_reptile_level(level)

	var level_label: Label = _make_reference_label("LVL", 24, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, scale)
	level_label.add_theme_color_override("font_shadow_color", Color(0.10, 0.07, 0.02, 0.90))
	level_label.add_theme_constant_override("shadow_offset_y", max(1, int(round(2.0 * scale))))
	parent.add_child(level_label)
	_position_reference_control(level_label, REPTILE_MGMT_LVL_TEXT_CENTER, Vector2(90, 30), origin, scale)

	var level_value: Label = _make_reference_label(str(level), 56, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, scale)
	level_value.add_theme_color_override("font_shadow_color", Color(0.10, 0.07, 0.02, 0.95))
	level_value.add_theme_constant_override("shadow_offset_y", max(1, int(round(3.0 * scale))))
	parent.add_child(level_value)
	_position_reference_control(level_value, REPTILE_MGMT_LVL_VALUE_CENTER, Vector2(100, 62), origin, scale)

	var progress: ProgressBar = ProgressBar.new()
	progress.min_value = 0
	progress.max_value = max(1, required_xp)
	progress.value = 0 if level >= max_level else current_xp
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("background", _make_progress_background_style(Color(0.03, 0.08, 0.03, 0.22)))
	progress.add_theme_stylebox_override("fill", _make_progress_fill_style(Color(0.37, 0.78, 0.12, 0.92)))
	parent.add_child(progress)
	_position_reference_control(progress, REPTILE_MGMT_XP_BAR_CENTER, REPTILE_MGMT_XP_BAR_SIZE, origin, scale)

	var xp_text: String = LocalizationSystem.tr_key("reptile_max_level") if level >= max_level else LocalizationSystem.tr_key("reptile_xp_label").replace("{current}", str(current_xp)).replace("{required}", str(required_xp))
	var xp_label: Label = _make_reference_label(xp_text, 17, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, scale)
	xp_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.02, 0.90))
	xp_label.add_theme_constant_override("shadow_offset_y", max(1, int(round(2.0 * scale))))
	xp_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	xp_label.clip_text = false
	parent.add_child(xp_label)
	_position_reference_control(xp_label, REPTILE_MGMT_XP_BAR_CENTER, REPTILE_MGMT_XP_TEXT_SIZE, origin, scale)


func _add_management_need_row(parent: Control, label_key: String, value: int, fill_color: Color, reference_y: float, origin: Vector2, scale: float) -> void:
	var label: Label = _make_reference_label(LocalizationSystem.tr_key(label_key), 22, POPUP_TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_LEFT, scale)
	parent.add_child(label)
	_position_reference_control(label, Vector2(222, reference_y), Vector2(170, 34), origin, scale)

	var progress: ProgressBar = ProgressBar.new()
	progress.min_value = 0
	progress.max_value = 100
	progress.value = value
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("background", _make_progress_background_style(Color(0.86, 0.72, 0.43, 0.35)))
	progress.add_theme_stylebox_override("fill", _make_progress_fill_style(fill_color))
	parent.add_child(progress)
	_position_reference_control(progress, Vector2(278, reference_y + 38.0), Vector2(210, 24), origin, scale)

	var value_label: Label = _make_reference_label(str(value) + "%", 22, POPUP_TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_RIGHT, scale)
	parent.add_child(value_label)
	_position_reference_control(value_label, Vector2(410, reference_y + 38.0), Vector2(58, 32), origin, scale)


func _add_management_income_row(parent: Control, label_key: String, value: String, is_final: bool, reference_y: float, origin: Vector2, scale: float) -> void:
	var color: Color = POPUP_TEXT_PRIMARY if is_final else POPUP_TEXT_SECONDARY
	var value_color: Color = POPUP_TEXT_SUCCESS if is_final else POPUP_TEXT_SECONDARY
	var font_size: int = 23 if is_final else 18
	var row_y: float = reference_y

	var label: Label = _make_reference_label(LocalizationSystem.tr_key(label_key) + ":", font_size, color, HORIZONTAL_ALIGNMENT_LEFT, scale)
	parent.add_child(label)
	_position_reference_control(label, Vector2(657, row_y), Vector2(245, 34), origin, scale)

	var value_label: Label = _make_reference_label(value, font_size, value_color, HORIZONTAL_ALIGNMENT_RIGHT, scale)
	parent.add_child(value_label)
	_position_reference_control(value_label, Vector2(821, row_y), Vector2(160, 34), origin, scale)


func _add_management_care_button(parent: Control, action_id: String, label_key: String, _texture_path: String, instance: Dictionary, is_assigned: bool, reference_center: Vector2, origin: Vector2, scale: float) -> void:
	var remaining: int = ReptileSystem.get_care_cooldown_remaining(instance, action_id)
	var button: Button = _make_reference_hitbox_button(Callable(self, "_on_care_action_pressed").bind(action_id))
	button.disabled = not is_assigned or remaining > 0
	button.modulate = Color(1.0, 1.0, 1.0, 0.48) if button.disabled else Color.WHITE
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW if button.disabled else Control.CURSOR_POINTING_HAND
	parent.add_child(button)
	_position_reference_control(button, reference_center, REPTILE_MGMT_CARE_BUTTON_SIZE, origin, scale)

	var label_text: String = _format_cooldown(remaining) if remaining > 0 else LocalizationSystem.tr_key(label_key).to_upper()
	var label: Label = _make_reference_label(label_text, 22, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, scale)
	label.add_theme_color_override("font_shadow_color", Color(0.08, 0.16, 0.04, 0.95))
	label.add_theme_constant_override("shadow_offset_x", max(1, int(round(2.0 * scale))))
	label.add_theme_constant_override("shadow_offset_y", max(1, int(round(3.0 * scale))))
	button.add_child(label)
	_position_reference_control(label, Vector2(80, 132), Vector2(140, 34), Vector2.ZERO, scale)


func _add_management_habitat_upgrade_panel(parent: Control, instance: Dictionary, origin: Vector2, scale: float) -> void:
	_add_management_section_title(parent, "management.habitat_upgrade", REPTILE_MGMT_UPGRADE_TITLE_CENTER, REPTILE_MGMT_UPGRADE_TITLE_SIZE, origin, scale)

	var habitat_id: String = _id_or_empty(instance.get("habitat_id", null))
	var habitat: Dictionary = _get_saved_habitat_state(habitat_id) if not habitat_id.is_empty() else {}
	var has_habitat: bool = not habitat.is_empty() and bool(habitat.get("purchased", false))
	var current_level: int = ReptileSystem.normalize_habitat_level(habitat.get("habitat_level", 1)) if has_habitat else 1
	var max_level: int = ReptileSystem.get_habitat_max_level()
	var is_building: bool = bool(habitat.get("is_building", false)) if has_habitat else false
	var is_upgrading: bool = bool(habitat.get("is_upgrading", false)) if has_habitat else false
	var has_next_level: bool = has_habitat and current_level < max_level and not is_building
	var next_level: int = ReptileSystem.normalize_habitat_level(habitat.get("upgrade_target_level", current_level + 1)) if is_upgrading else ReptileSystem.normalize_habitat_level(current_level + 1)

	var habitat_label: Label = _make_reference_label(LocalizationSystem.tr_key("management.habitat_level"), 20, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER, scale)
	parent.add_child(habitat_label)
	_position_reference_control(habitat_label, REPTILE_MGMT_HABITAT_LEVEL_LABEL_CENTER, Vector2(180, 28), origin, scale)

	var current_level_label: Label = _make_reference_label(str(current_level) if has_habitat else "-", 42, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, scale)
	current_level_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.12, 0.04, 0.92))
	current_level_label.add_theme_constant_override("shadow_offset_y", max(1, int(round(3.0 * scale))))
	parent.add_child(current_level_label)
	_position_reference_control(current_level_label, REPTILE_MGMT_HABITAT_CURRENT_LEVEL_CENTER, Vector2(70, 58), origin, scale)

	var arrow_label: Label = _make_reference_label("->", 34, POPUP_TEXT_SUCCESS, HORIZONTAL_ALIGNMENT_CENTER, scale)
	parent.add_child(arrow_label)
	_position_reference_control(arrow_label, REPTILE_MGMT_HABITAT_ARROW_CENTER, Vector2(52, 42), origin, scale)

	var next_text: String = str(next_level) if has_next_level else "-"
	var next_level_label: Label = _make_reference_label(next_text, 42, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, scale)
	next_level_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.12, 0.04, 0.92))
	next_level_label.add_theme_constant_override("shadow_offset_y", max(1, int(round(3.0 * scale))))
	parent.add_child(next_level_label)
	_position_reference_control(next_level_label, REPTILE_MGMT_HABITAT_NEXT_LEVEL_CENTER, Vector2(70, 58), origin, scale)

	var cost_label: Label = _make_reference_label(LocalizationSystem.tr_key("shop.cost") + ":", 20, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER, scale)
	parent.add_child(cost_label)
	_position_reference_control(cost_label, REPTILE_MGMT_UPGRADE_COST_LABEL_CENTER, Vector2(140, 28), origin, scale)

	var cost_text: String = LocalizationSystem.tr_key("currency.repticash") + " " + str(ReptileSystem.get_habitat_upgrade_cost()) if has_next_level and not is_upgrading else "-"
	var cost_value: Label = _make_reference_label(cost_text, 24, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER, scale)
	cost_value.autowrap_mode = TextServer.AUTOWRAP_OFF
	parent.add_child(cost_value)
	_position_reference_control(cost_value, REPTILE_MGMT_UPGRADE_COST_VALUE_CENTER, Vector2(150, 42), origin, scale)

	var time_label: Label = _make_reference_label(LocalizationSystem.tr_key("management.time") + ":", 20, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER, scale)
	parent.add_child(time_label)
	_position_reference_control(time_label, REPTILE_MGMT_UPGRADE_TIME_LABEL_CENTER, Vector2(130, 28), origin, scale)

	var time_text: String = "-"
	if is_upgrading:
		time_text = _format_duration_compact(ReptileSystem.get_habitat_upgrade_remaining_seconds(habitat_id))
	elif has_next_level:
		time_text = _format_duration_compact(ReptileSystem.get_habitat_upgrade_duration_seconds(current_level))
	var time_value: Label = _make_reference_label(time_text, 24, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER, scale)
	parent.add_child(time_value)
	_position_reference_control(time_value, REPTILE_MGMT_UPGRADE_TIME_VALUE_CENTER, Vector2(130, 42), origin, scale)

	var bonus_label: Label = _make_reference_label(LocalizationSystem.tr_key("management.habitat_bonus"), 20, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER, scale)
	parent.add_child(bonus_label)
	_position_reference_control(bonus_label, REPTILE_MGMT_HABITAT_BONUS_LABEL_CENTER, Vector2(210, 28), origin, scale)

	var current_bonus: String = _format_multiplier(_get_habitat_level_multiplier_for_level(current_level))
	var next_bonus: String = _format_multiplier(_get_habitat_level_multiplier_for_level(next_level)) if has_next_level else LocalizationSystem.tr_key("habitat.max_level")
	var bonus_value_text: String = current_bonus + " -> " + next_bonus if has_next_level else next_bonus
	if not has_habitat:
		bonus_value_text = "-"
	var bonus_value: Label = _make_reference_label(bonus_value_text, 24, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER, scale)
	parent.add_child(bonus_value)
	_position_reference_control(bonus_value, REPTILE_MGMT_HABITAT_BONUS_VALUE_CENTER, Vector2(230, 42), origin, scale)

	var can_upgrade: bool = has_next_level and not is_upgrading
	var upgrade_button: Button = _make_reference_hitbox_button(Callable(self, "_confirm_habitat_upgrade").bind(habitat_id))
	upgrade_button.disabled = not can_upgrade
	upgrade_button.modulate = Color(1.0, 1.0, 1.0, 0.48) if upgrade_button.disabled else Color.WHITE
	upgrade_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if upgrade_button.disabled else Control.CURSOR_POINTING_HAND
	parent.add_child(upgrade_button)
	_position_reference_control(upgrade_button, REPTILE_MGMT_UPGRADE_BUTTON_CENTER, REPTILE_MGMT_UPGRADE_BUTTON_SIZE, origin, scale)

	var upgrade_text: String = LocalizationSystem.tr_key("habitat.upgrade_confirm_button").to_upper()
	if is_upgrading:
		upgrade_text = LocalizationSystem.tr_key("habitat.upgrade_in_progress").to_upper()
	elif not has_next_level:
		upgrade_text = "MAX" if has_habitat else "-"
	var upgrade_label: Label = _make_reference_label(upgrade_text, 25, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, scale)
	upgrade_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.14, 0.04, 0.90))
	upgrade_label.add_theme_constant_override("shadow_offset_y", max(1, int(round(3.0 * scale))))
	upgrade_button.add_child(upgrade_label)
	_position_reference_control(upgrade_label, Vector2(160, 46), Vector2(165, 42), Vector2.ZERO, scale)


func _make_management_wide_button(texture_path: String, label_key: String, pressed_callable: Callable, scale: float) -> TextureButton:
	var button: TextureButton = _make_reference_texture_button(texture_path, pressed_callable)

	var label: Label = _make_reference_label(LocalizationSystem.tr_key(label_key).to_upper(), 28, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, scale)
	label.add_theme_color_override("font_shadow_color", Color(0.14, 0.08, 0.03, 0.90))
	label.add_theme_constant_override("shadow_offset_x", max(1, int(round(2.0 * scale))))
	label.add_theme_constant_override("shadow_offset_y", max(1, int(round(3.0 * scale))))
	button.add_child(label)
	_position_reference_control(label, Vector2(399, 43), Vector2(500, 54), Vector2.ZERO, scale)
	return button


func _show_habitat_management_popup(habitat_id: String) -> void:
	var habitat: Dictionary = _get_saved_habitat_state(habitat_id)
	if habitat.is_empty() or not bool(habitat.get("purchased", false)):
		_show_message_popup("ui.habitat_unavailable")
		return

	_close_management_modal()
	current_management_feedback_key = ""
	current_management_instance_id = ""

	management_modal = Control.new()
	management_modal.name = "HabitatManagementModal"
	management_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	management_modal.z_index = 20
	add_child(management_modal)

	var overlay: ColorRect = ColorRect.new()
	overlay.name = "DimOverlay"
	overlay.color = Color(0.04, 0.05, 0.04, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	management_modal.add_child(overlay)

	var background_texture: Texture2D = AssetPaths.load_texture(MGMT_POPUP_BG_PATH)
	if background_texture == null:
		push_warning("BiomeView: missing habitat management background: " + MGMT_POPUP_BG_PATH)
		_build_habitat_mgmt_popup_legacy(habitat_id, habitat)
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var reference_scale: float = min(viewport_size.x / MGMT_POPUP_REF_SIZE.x, viewport_size.y / MGMT_POPUP_REF_SIZE.y) * MGMT_POPUP_WINDOW_SCALE
	var reference_origin: Vector2 = (viewport_size - MGMT_POPUP_REF_SIZE * reference_scale) * 0.5

	var background: TextureRect = TextureRect.new()
	background.texture = background_texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	management_modal.add_child(background)
	_position_reference_control(background, MGMT_POPUP_REF_SIZE * 0.5, MGMT_POPUP_REF_SIZE, reference_origin, reference_scale)

	var title_lbl: Label = _add_habitat_options_label(management_modal, LocalizationSystem.tr_key("habitat.management"),
		MGMT_POPUP_TITLE_CENTER, MGMT_POPUP_TITLE_REF_SIZE, MGMT_POPUP_TITLE_FONT_SIZE,
		Color(0.85, 0.65, 0.10, 1.0), HORIZONTAL_ALIGNMENT_CENTER, reference_origin, reference_scale, false)
	_make_label_visually_bold(title_lbl)

	var close_btn: Button = _make_reference_hitbox_button(_close_management_modal)
	management_modal.add_child(close_btn)
	_position_reference_control(close_btn, MGMT_POPUP_CLOSE_CENTER, MGMT_POPUP_CLOSE_REF_SIZE, reference_origin, reference_scale)

	var preview_tex: Texture2D = AssetPaths.load_texture(_get_habitat_texture_path(habitat_id))
	if preview_tex != null:
		var preview: TextureRect = TextureRect.new()
		preview.texture = preview_tex
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		management_modal.add_child(preview)
		_position_reference_control(preview, MGMT_POPUP_PREVIEW_CENTER, MGMT_POPUP_PREVIEW_REF_SIZE, reference_origin, reference_scale)

	var habitat_type: String = ReptileSystem.normalize_habitat_type(str(habitat.get("habitat_type", "grass")))
	var habitat_level: int = ReptileSystem.normalize_habitat_level(habitat.get("habitat_level", 1))
	var is_building: bool = bool(habitat.get("is_building", false))
	var is_upgrading: bool = bool(habitat.get("is_upgrading", false))

	_mgmt_add_row(management_modal,
		LocalizationSystem.tr_key("habitat.type") + ":",
		LocalizationSystem.tr_key(ReptileSystem.get_habitat_type_label_key(habitat_type)),
		MGMT_POPUP_ROW1_CENTER, reference_origin, reference_scale)
	_mgmt_add_row(management_modal,
		LocalizationSystem.tr_key("habitat.level") + ":",
		LocalizationSystem.tr_key(ReptileSystem.get_habitat_level_label_key(habitat_level)),
		MGMT_POPUP_ROW2_CENTER, reference_origin, reference_scale)

	if is_building:
		_mgmt_add_row(management_modal,
			LocalizationSystem.tr_key("habitat.building_in_progress"),
			_format_duration_compact(ReptileSystem.get_habitat_build_remaining_seconds(habitat_id)),
			MGMT_POPUP_ROW3_CENTER, reference_origin, reference_scale)
	elif is_upgrading:
		_mgmt_add_row(management_modal,
			LocalizationSystem.tr_key("habitat.upgrade_in_progress"),
			_format_duration_compact(ReptileSystem.get_habitat_upgrade_remaining_seconds(habitat_id)),
			MGMT_POPUP_ROW3_CENTER, reference_origin, reference_scale)
		_mgmt_add_row(management_modal,
			LocalizationSystem.tr_key("habitat.next_level") + ":",
			LocalizationSystem.tr_key(ReptileSystem.get_habitat_level_label_key(habitat.get("upgrade_target_level", habitat_level + 1))),
			MGMT_POPUP_ROW4_CENTER, reference_origin, reference_scale)
	elif habitat_level < ReptileSystem.get_habitat_max_level():
		_mgmt_add_row(management_modal,
			LocalizationSystem.tr_key("habitat.next_level") + ":",
			LocalizationSystem.tr_key(ReptileSystem.get_habitat_level_label_key(habitat_level + 1)),
			MGMT_POPUP_ROW3_CENTER, reference_origin, reference_scale)
		_mgmt_add_row(management_modal,
			LocalizationSystem.tr_key("habitat.upgrade_cost") + ":",
			LocalizationSystem.tr_key("currency.repticash") + " " + str(ReptileSystem.get_habitat_upgrade_cost()),
			MGMT_POPUP_ROW4_CENTER, reference_origin, reference_scale)
		_mgmt_add_row(management_modal,
			LocalizationSystem.tr_key("habitat.upgrade_time") + ":",
			_format_duration_compact(ReptileSystem.get_habitat_upgrade_duration_seconds(habitat_level)),
			MGMT_POPUP_ROW5_CENTER, reference_origin, reference_scale)
	else:
		_mgmt_add_row(management_modal,
			LocalizationSystem.tr_key("habitat.next_level") + ":",
			LocalizationSystem.tr_key("habitat.max_level"),
			MGMT_POPUP_ROW3_CENTER, reference_origin, reference_scale)

	var place_btn: Button = _make_reference_hitbox_button(func() -> void:
		_close_management_modal()
		_show_reptile_assignment_popup(habitat_id)
	)
	place_btn.disabled = is_building or is_upgrading
	management_modal.add_child(place_btn)
	_position_reference_control(place_btn, MGMT_POPUP_BTN1_CENTER, MGMT_POPUP_BTN_SIZE, reference_origin, reference_scale)
	var place_lbl: Label = _make_reference_label(LocalizationSystem.tr_key("habitat.place_reptile"), MGMT_POPUP_BTN_FONT_SIZE, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, reference_scale)
	place_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	place_btn.add_child(place_lbl)

	var upgrade_btn: Button = _make_reference_hitbox_button(func() -> void:
		_confirm_habitat_upgrade(habitat_id)
	)
	upgrade_btn.disabled = is_building or is_upgrading or habitat_level >= ReptileSystem.get_habitat_max_level()
	management_modal.add_child(upgrade_btn)
	_position_reference_control(upgrade_btn, MGMT_POPUP_BTN2_CENTER, MGMT_POPUP_BTN_SIZE, reference_origin, reference_scale)
	var upgrade_lbl: Label = _make_reference_label(LocalizationSystem.tr_key("habitat.upgrade"), MGMT_POPUP_BTN_FONT_SIZE, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, reference_scale)
	upgrade_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	upgrade_btn.add_child(upgrade_lbl)

	var remove_btn: Button = _make_reference_hitbox_button(func() -> void:
		_confirm_remove_habitat(habitat_id)
	)
	remove_btn.disabled = is_upgrading
	management_modal.add_child(remove_btn)
	_position_reference_control(remove_btn, MGMT_POPUP_BTN3_CENTER, MGMT_POPUP_BTN_SIZE, reference_origin, reference_scale)
	var remove_lbl: Label = _make_reference_label(LocalizationSystem.tr_key("habitat.remove_habitat"), MGMT_POPUP_BTN_FONT_SIZE, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, reference_scale)
	remove_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	remove_btn.add_child(remove_lbl)


func _mgmt_add_row(parent: Control, label_text: String, value_text: String, row_center: Vector2, origin: Vector2, ref_scale: float) -> void:
	_add_habitat_options_label(parent, label_text,
		row_center, MGMT_POPUP_ROW_LABEL_SIZE, MGMT_POPUP_ROW_FONT_SIZE,
		POPUP_TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_LEFT, origin, ref_scale, false)
	_add_habitat_options_label(parent, value_text,
		Vector2(MGMT_POPUP_ROW_VALUE_X, row_center.y), MGMT_POPUP_ROW_VALUE_SIZE, MGMT_POPUP_ROW_FONT_SIZE,
		POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_LEFT, origin, ref_scale, false)


func _build_habitat_mgmt_popup_legacy(habitat_id: String, habitat: Dictionary) -> void:
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.1)
	management_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 500)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("habitat.management"), 21)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	header.add_child(title)

	var close_button: Button = Button.new()
	close_button.text = LocalizationSystem.tr_key("ui.close")
	close_button.custom_minimum_size = Vector2(88, 42)
	close_button.pressed.connect(_close_management_modal)
	_apply_button_text_color(close_button, POPUP_TEXT_PRIMARY)
	header.add_child(close_button)

	var preview: TextureRect = _make_fixed_texture(_get_habitat_texture_path(habitat_id), Vector2(220, 140))
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(preview)

	var habitat_type: String = ReptileSystem.normalize_habitat_type(str(habitat.get("habitat_type", "grass")))
	var habitat_level: int = ReptileSystem.normalize_habitat_level(habitat.get("habitat_level", 1))
	var is_building: bool = bool(habitat.get("is_building", false))
	var is_upgrading: bool = bool(habitat.get("is_upgrading", false))
	column.add_child(_make_management_text_row("habitat.type", LocalizationSystem.tr_key(ReptileSystem.get_habitat_type_label_key(habitat_type))))
	column.add_child(_make_management_text_row("habitat.level", LocalizationSystem.tr_key(ReptileSystem.get_habitat_level_label_key(habitat_level))))

	if is_building:
		column.add_child(_make_management_text_row("habitat.building_in_progress", _format_duration_compact(ReptileSystem.get_habitat_build_remaining_seconds(habitat_id))))
	elif is_upgrading:
		column.add_child(_make_management_text_row("habitat.upgrade_in_progress", _format_duration_compact(ReptileSystem.get_habitat_upgrade_remaining_seconds(habitat_id))))
		column.add_child(_make_management_text_row("habitat.next_level", LocalizationSystem.tr_key(ReptileSystem.get_habitat_level_label_key(habitat.get("upgrade_target_level", habitat_level + 1)))))
	elif habitat_level < ReptileSystem.get_habitat_max_level():
		column.add_child(_make_management_text_row("habitat.next_level", LocalizationSystem.tr_key(ReptileSystem.get_habitat_level_label_key(habitat_level + 1))))
		column.add_child(_make_management_text_row("habitat.upgrade_cost", LocalizationSystem.tr_key("currency.repticash") + " " + str(ReptileSystem.get_habitat_upgrade_cost())))
		column.add_child(_make_management_text_row("habitat.upgrade_time", _format_duration_compact(ReptileSystem.get_habitat_upgrade_duration_seconds(habitat_level))))
	else:
		column.add_child(_make_management_text_row("habitat.next_level", LocalizationSystem.tr_key("habitat.max_level")))

	var actions: VBoxContainer = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)

	var place_button: Button = _make_popup_button("habitat.place_reptile", func() -> void:
		_close_management_modal()
		_show_reptile_assignment_popup(habitat_id)
	)
	_style_primary_action_button(place_button)
	place_button.disabled = is_building or is_upgrading
	actions.add_child(place_button)

	var upgrade_button: Button = _make_popup_button("habitat.upgrade", func() -> void:
		_confirm_habitat_upgrade(habitat_id)
	)
	_style_primary_action_button(upgrade_button)
	upgrade_button.disabled = is_building or is_upgrading or habitat_level >= ReptileSystem.get_habitat_max_level()
	actions.add_child(upgrade_button)

	var remove_button: Button = _make_popup_button("habitat.remove_habitat", func() -> void:
		_confirm_remove_habitat(habitat_id)
	)
	remove_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.65, 0.24, 0.18, 1.0)))
	remove_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.74, 0.30, 0.22, 1.0)))
	remove_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.52, 0.18, 0.13, 1.0)))
	remove_button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.45, 0.45, 0.42, 0.75)))
	remove_button.disabled = is_upgrading
	_apply_button_text_color(remove_button, BUTTON_TEXT_COLOR)
	actions.add_child(remove_button)


func _style_primary_action_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.45, 0.45, 0.42, 0.75)))
	_apply_button_text_color(button, BUTTON_TEXT_COLOR)


func _on_bottom_nav_pressed(item_id: String) -> void:
	if item_id == "map":
		biome_map_requested.emit()
		return

	if item_id == "biome":
		_close_animals_view()
		_close_quests_view()
		_close_shop_view()
		_close_workers_view()
		_close_upgrades_view()
		_close_management_modal()
		_close_reptile_selection_modal()
		_close_habitat_purchase_modal()
		return

	if item_id == "animals":
		_show_animals_view("owned")
		return

	if item_id == "shop":
		_show_shop_view()
		return

	if item_id == "quests":
		_show_quests_view()
		return

	if item_id == "upgrades":
		_show_upgrades_view()
		return

	_show_nav_placeholder("nav." + item_id)


func _show_nav_placeholder(title_key: String) -> void:
	_close_animals_view()
	_close_quests_view()
	_close_shop_view()
	_close_workers_view()
	_close_upgrades_view()
	_show_message_popup(title_key)


func _show_shop_view() -> void:
	_close_animals_view()
	_close_quests_view()
	_close_shop_view()
	_close_workers_view()
	_close_upgrades_view()
	_close_management_modal()
	_close_reptile_selection_modal()
	_close_habitat_purchase_modal()

	if not _shop_design_assets_available():
		_show_shop_view_fallback()
		return

	shop_view = Control.new()
	shop_view.name = "ShopView"
	shop_view.anchor_left = 0.0
	shop_view.anchor_top = 0.0
	shop_view.anchor_right = 1.0
	shop_view.anchor_bottom = 1.0
	shop_view.offset_top = TOP_BAR_HEIGHT + 2
	shop_view.offset_bottom = -(BOTTOM_NAV_HEIGHT + 6)
	add_child(shop_view)
	_notify_quest_event("screen_opened", {"screen": "shop"})

	var frame: TextureRect = TextureRect.new()
	frame.texture = AssetPaths.load_texture(_get_shop_background_path())
	frame.anchor_left = 0.0
	frame.anchor_top = 0.0
	frame.anchor_right = 1.0
	frame.anchor_bottom = 1.05
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_view.add_child(frame)

	var title_art: TextureRect = TextureRect.new()
	title_art.name = "ShopTitleArt"
	var shop_title_path: String = _get_shop_title_path()
	if ResourceLoader.exists(shop_title_path) or FileAccess.file_exists(ProjectSettings.globalize_path(shop_title_path)):
		title_art.texture = AssetPaths.load_texture(shop_title_path)
	title_art.anchor_left = QUEST_TITLE_ANCHOR_LEFT
	title_art.anchor_top = QUEST_TITLE_ANCHOR_TOP
	title_art.anchor_right = QUEST_TITLE_ANCHOR_RIGHT
	title_art.anchor_bottom = QUEST_TITLE_ANCHOR_BOTTOM
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_view.add_child(title_art)
	if title_art.texture == null:
		var fallback_title: Label = _make_popup_label(LocalizationSystem.tr_key("nav.shop"), 24)
		fallback_title.name = "ShopTitleFallback"
		fallback_title.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback_title.anchor_left = QUEST_TITLE_ANCHOR_LEFT
		fallback_title.anchor_top = QUEST_TITLE_ANCHOR_TOP
		fallback_title.anchor_right = QUEST_TITLE_ANCHOR_RIGHT
		fallback_title.anchor_bottom = QUEST_TITLE_ANCHOR_BOTTOM
		fallback_title.offset_left = 0
		fallback_title.offset_top = 0
		fallback_title.offset_right = 0
		fallback_title.offset_bottom = 0
		fallback_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shop_view.add_child(fallback_title)

	var close_button: Button = Button.new()
	close_button.tooltip_text = LocalizationSystem.tr_key("ui.close")
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.add_theme_stylebox_override("normal", _make_transparent_button_style())
	close_button.add_theme_stylebox_override("hover", _make_transparent_button_style())
	close_button.add_theme_stylebox_override("pressed", _make_transparent_button_style())
	close_button.anchor_left = QUEST_CLOSE_ANCHOR_LEFT
	close_button.anchor_top = QUEST_CLOSE_ANCHOR_TOP
	close_button.anchor_right = QUEST_CLOSE_ANCHOR_RIGHT
	close_button.anchor_bottom = QUEST_CLOSE_ANCHOR_BOTTOM
	close_button.pressed.connect(_close_shop_view)
	shop_view.add_child(close_button)

	var resource_row: HBoxContainer = HBoxContainer.new()
	resource_row.anchor_left = 0.030
	resource_row.anchor_top = 0.168
	resource_row.anchor_right = 0.970
	resource_row.anchor_bottom = 0.466
	resource_row.add_theme_constant_override("separation", -120)
	resource_row.mouse_filter = Control.MOUSE_FILTER_PASS
	shop_view.add_child(resource_row)
	resource_row.add_child(_make_resource_buy_card("food"))
	resource_row.add_child(_make_resource_buy_card("water"))

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.anchor_left = 0.058
	scroll.anchor_top = 0.478
	scroll.anchor_right = 0.942
	scroll.anchor_bottom = 0.987
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	shop_view.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.mouse_filter = Control.MOUSE_FILTER_PASS
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)

	if ReptileSystem.is_first_reptile_free():
		var free_label: Label = _make_popup_label(LocalizationSystem.tr_key("ui.first_reptile_free"), 13)
		free_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_label_color(free_label, POPUP_TEXT_SUCCESS)
		list.add_child(free_label)

	var reptiles: Array = ReptileSystem.get_available_reptiles(biome_id)
	for reptile_value in reptiles:
		if typeof(reptile_value) != TYPE_DICTIONARY:
			continue

		list.add_child(_make_shop_reptile_card(reptile_value as Dictionary))


func _show_shop_view_fallback() -> void:
	shop_view = Control.new()
	shop_view.name = "ShopView"
	shop_view.anchor_left = 0.0
	shop_view.anchor_top = 0.0
	shop_view.anchor_right = 1.0
	shop_view.anchor_bottom = 1.0
	shop_view.offset_top = TOP_BAR_HEIGHT + 10
	shop_view.offset_bottom = -(BOTTOM_NAV_HEIGHT + 8)
	add_child(shop_view)
	_notify_quest_event("screen_opened", {"screen": "shop"})

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	shop_view.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("nav.shop"), 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	header.add_child(title)

	var close_button: Button = Button.new()
	close_button.text = LocalizationSystem.tr_key("ui.close")
	close_button.custom_minimum_size = Vector2(96, 42)
	close_button.pressed.connect(_close_shop_view)
	_apply_button_text_color(close_button, POPUP_TEXT_PRIMARY)
	header.add_child(close_button)

	var res_section: Label = _make_popup_label(LocalizationSystem.tr_key("shop.resources"), 17)
	res_section.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_label_color(res_section, POPUP_TEXT_ACCENT)
	column.add_child(res_section)

	var res_row: HBoxContainer = HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 10)
	column.add_child(res_row)
	res_row.add_child(_make_resource_buy_card_fallback("food"))
	res_row.add_child(_make_resource_buy_card_fallback("water"))

	var section: Label = _make_popup_label(LocalizationSystem.tr_key("shop.reptiles"), 17)
	section.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_label_color(section, POPUP_TEXT_ACCENT)
	column.add_child(section)

	if ReptileSystem.is_first_reptile_free():
		var free_label: Label = _make_popup_label(LocalizationSystem.tr_key("ui.first_reptile_free"), 13)
		free_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_apply_label_color(free_label, POPUP_TEXT_SUCCESS)
		column.add_child(free_label)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.mouse_filter = Control.MOUSE_FILTER_PASS
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var reptiles: Array = ReptileSystem.get_available_reptiles(biome_id)
	for reptile_value in reptiles:
		if typeof(reptile_value) != TYPE_DICTIONARY:
			continue

		list.add_child(_make_shop_reptile_card_fallback(reptile_value as Dictionary))


func _show_animals_view(tab_id: String = "owned") -> void:
	if not _animals_group_navigating:
		_animals_step = 0
		_animals_selected_species_id = ""
	_animals_group_navigating = false
	_close_animals_view()
	_close_quests_view()
	_close_shop_view()
	_close_workers_view()
	_close_upgrades_view()
	_close_management_modal()
	_close_reptile_selection_modal()
	_close_habitat_purchase_modal()
	ReptileSystem.sync_discovered_variants_from_owned_reptiles()

	var viewport_size: Vector2 = get_viewport_rect().size
	var available_top: float = TOP_BAR_HEIGHT + ANIMALS_PANEL_TOP_GAP
	var available_bottom: float = viewport_size.y - BOTTOM_NAV_HEIGHT - ANIMALS_PANEL_BOTTOM_GAP
	var available_height: float = max(1.0, available_bottom - available_top)
	var panel_scale: float = min(viewport_size.x / ANIMALS_REF_SIZE.x, available_height / ANIMALS_REF_SIZE.y)
	var panel_size: Vector2 = Vector2(
		ANIMALS_REF_SIZE.x * panel_scale * ANIMALS_WINDOW_EXTRA_W,
		ANIMALS_REF_SIZE.y * panel_scale * ANIMALS_WINDOW_EXTRA_H
	)
	var panel_position: Vector2 = Vector2(
		(viewport_size.x - panel_size.x) * 0.5,
		available_top + (available_height - panel_size.y) * 0.5
	)

	animals_view = Control.new()
	animals_view.name = "AnimalsView"
	animals_view.position = panel_position
	animals_view.size = panel_size
	animals_view.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(animals_view)
	if tab_id == "gallery":
		_notify_quest_event("screen_opened", {"screen": "gallery"})

	var panel_root: Control = Control.new()
	panel_root.name = "AnimalsDesignPanel"
	panel_root.position = Vector2.ZERO
	panel_root.size = panel_size
	panel_root.mouse_filter = Control.MOUSE_FILTER_PASS
	animals_view.add_child(panel_root)

	var background: TextureRect = TextureRect.new()
	background.name = "AnimalsBackground"
	background.texture = AssetPaths.load_texture(ANIMALS_BG_PATH)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_root.add_child(background)

	var _content_x: float = panel_size.x * ANIMALS_CONTENT_X_OFFSET
	var _title_x: float = _content_x + panel_size.x * ANIMALS_TITLE_X_EXTRA
	var _tabs_x: float = _content_x + panel_size.x * ANIMALS_TABS_X_EXTRA

	var title_art: TextureRect = _make_animals_design_texture(_get_animals_design_title_path())
	panel_root.add_child(title_art)
	_position_animals_design_control(title_art, ANIMALS_TITLE_RECT, panel_scale, _title_x)

	var close_button: Button = Button.new()
	close_button.name = "AnimalsCloseHitbox"
	close_button.text = ""
	close_button.flat = true
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.add_theme_stylebox_override("normal", _make_transparent_button_style())
	close_button.add_theme_stylebox_override("hover", _make_transparent_button_style())
	close_button.add_theme_stylebox_override("pressed", _make_transparent_button_style())
	close_button.pressed.connect(_close_animals_view)
	panel_root.add_child(close_button)
	_position_animals_design_control(close_button, Rect2(
		ANIMALS_CLOSE_BUTTON_RECT.position.x * ANIMALS_WINDOW_EXTRA_W,
		ANIMALS_CLOSE_BUTTON_RECT.position.y * ANIMALS_WINDOW_EXTRA_H,
		ANIMALS_CLOSE_BUTTON_RECT.size.x * ANIMALS_WINDOW_EXTRA_W,
		ANIMALS_CLOSE_BUTTON_RECT.size.y * ANIMALS_WINDOW_EXTRA_H
	), panel_scale)

	panel_root.add_child(_make_animals_design_tab_button("owned", tab_id, ANIMALS_OWNED_TAB_RECT, panel_scale, _tabs_x))
	panel_root.add_child(_make_animals_design_tab_button("gallery", tab_id, ANIMALS_GALLERY_TAB_RECT, panel_scale, _tabs_x))
	panel_root.add_child(_make_animals_design_tab_button("achievements", tab_id, ANIMALS_ACHIEVEMENTS_TAB_RECT, panel_scale, _tabs_x))

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "AnimalsContentScroll"
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	panel_root.add_child(scroll)
	var _scroll_w_scale: float = ANIMALS_GALLERY_SCROLL_WIDTH_SCALE if tab_id == "gallery" else ANIMALS_CARD_BACKGROUND_WIDTH_SCALE
	_position_animals_design_control(scroll, _scale_animals_reference_rect(ANIMALS_CONTENT_AREA_RECT, _scroll_w_scale, Vector2(1.0, 0.0)), panel_scale, _content_x)

	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.custom_minimum_size = Vector2(ANIMALS_CONTENT_AREA_RECT.size.x * _scroll_w_scale * panel_scale - 28.0, 0)
	content.add_theme_constant_override("separation", _get_animals_list_separation(tab_id))
	scroll.add_child(content)

	if tab_id == "gallery":
		_populate_animals_gallery(content)
	elif tab_id == "achievements":
		_populate_animals_achievements(content)
	else:
		_populate_owned_animals(content)


func _make_animals_design_texture(texture_path: String) -> TextureRect:
	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.texture = AssetPaths.load_texture(texture_path)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture_rect


func _make_animals_design_tab_button(tab_id: String, active_tab_id: String, reference_rect: Rect2, panel_scale: float, x_offset: float = 0.0) -> TextureButton:
	var button: TextureButton = TextureButton.new()
	button.name = "AnimalsTab" + tab_id.capitalize()
	button.texture_normal = AssetPaths.load_texture(_get_animals_design_tab_path(tab_id))
	button.texture_hover = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.modulate = Color.WHITE if tab_id == active_tab_id else Color(0.82, 0.82, 0.82, 0.96)
	button.z_index = 3 if tab_id == active_tab_id else 2
	button.pressed.connect(func() -> void:
		_show_animals_view(tab_id)
	)
	var raised_rect: Rect2 = _scale_animals_reference_rect(reference_rect, ANIMALS_TAB_GRAPHIC_SCALE)
	raised_rect.position.y -= reference_rect.size.y * ANIMALS_TAB_RAISE_RATIO
	_position_animals_design_control(button, raised_rect, panel_scale, x_offset)
	if tab_id == active_tab_id:
		_add_animals_active_tab_underline(button)
	return button


func _position_animals_design_control(control: Control, reference_rect: Rect2, panel_scale: float, x_offset: float = 0.0) -> void:
	control.position = Vector2(reference_rect.position.x * panel_scale + x_offset, reference_rect.position.y * panel_scale)
	control.size = reference_rect.size * panel_scale
	control.custom_minimum_size = reference_rect.size * panel_scale


func _scale_animals_reference_rect(reference_rect: Rect2, scale_amount: float, axes: Vector2 = Vector2.ONE) -> Rect2:
	var scale_vector: Vector2 = Vector2(
		1.0 + (scale_amount - 1.0) * axes.x,
		1.0 + (scale_amount - 1.0) * axes.y
	)
	var scaled_size: Vector2 = reference_rect.size * scale_vector
	var centered_position: Vector2 = reference_rect.position + (reference_rect.size - scaled_size) * 0.5
	return Rect2(centered_position, scaled_size)


func _add_animals_active_tab_underline(button: Control) -> void:
	var underline: ColorRect = ColorRect.new()
	underline.name = "ActiveTabUnderline"
	underline.color = ANIMALS_ACTIVE_TAB_UNDERLINE_COLOR
	underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var underline_size: Vector2 = Vector2(
		button.size.x * ANIMALS_ACTIVE_TAB_UNDERLINE_WIDTH_RATIO,
		max(2.0, button.size.y * ANIMALS_ACTIVE_TAB_UNDERLINE_HEIGHT_RATIO)
	)
	underline.position = Vector2(
		(button.size.x - underline_size.x) * 0.5,
		button.size.y * ANIMALS_ACTIVE_TAB_UNDERLINE_Y_RATIO
	)
	underline.size = underline_size
	button.add_child(underline)


func _get_animals_list_separation(tab_id: String) -> int:
	match tab_id:
		"gallery":
			return ANIMALS_GALLERY_LIST_SEPARATION
		"achievements":
			return ANIMALS_ACHIEVEMENTS_LIST_SEPARATION
		_:
			return ANIMALS_CARD_LIST_SEPARATION


func _get_animals_design_title_path() -> String:
	return ANIMALS_DESIGN_DIR + ("title_en.png" if GameState.get_language() == "en" else "title_pl.png")


func _get_animals_design_tab_path(tab_id: String) -> String:
	var suffix: String = "_en.png" if GameState.get_language() == "en" else "_pl.png"
	match tab_id:
		"gallery":
			return ANIMALS_DESIGN_DIR + "gallery" + suffix
		"achievements":
			return ANIMALS_DESIGN_DIR + "achievements" + suffix
		_:
			return ANIMALS_DESIGN_DIR + "owned" + suffix


func _make_owned_species_group_card(reptile_id: String, instances: Array) -> Control:
	var reptile: Dictionary = ReptileSystem.get_reptile(reptile_id)

	var portrait_path: String = ""
	var rarity_priority: Array[String] = ["ultra_rare", "exceptional", "rare", "common"]
	for target_rarity in rarity_priority:
		for inst_val in instances:
			if typeof(inst_val) != TYPE_DICTIONARY:
				continue
			var inst: Dictionary = inst_val as Dictionary
			if ReptileSystem.normalize_rarity(str(inst.get("rarity", "common"))) == target_rarity:
				portrait_path = ReptileSystem.get_owned_animal_image_path(inst)
				break
		if not portrait_path.is_empty():
			break
	if portrait_path.is_empty() and not instances.is_empty() and typeof(instances[0]) == TYPE_DICTIONARY:
		portrait_path = ReptileSystem.get_owned_animal_image_path(instances[0] as Dictionary)

	var rarity_counts: Dictionary = {}
	var free_count: int = 0
	for inst_val in instances:
		if typeof(inst_val) != TYPE_DICTIONARY:
			continue
		var inst: Dictionary = inst_val as Dictionary
		var rarity: String = str(inst.get("rarity", "common"))
		rarity_counts[rarity] = int(rarity_counts.get(rarity, 0)) + 1
		if not _is_reptile_instance_assigned(inst):
			free_count += 1

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = _animals_card_bg_vec(0, 104)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_animals_single_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _animals_ui_size(10))
	margin.add_theme_constant_override("margin_right", _animals_ui_size(10))
	margin.add_theme_constant_override("margin_top", _animals_ui_size(10))
	margin.add_theme_constant_override("margin_bottom", _animals_ui_size(10))
	card.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", _animals_ui_size(12))
	margin.add_child(row)

	row.add_child(_make_fixed_texture(portrait_path, _animals_image_vec(80, 80)))

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", _animals_ui_size(3))
	row.add_child(info)

	var name_lbl: Label = Label.new()
	name_lbl.text = LocalizationSystem.tr_key(str(reptile.get("name_key", reptile_id)))
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", _animals_text_size(17))
	_apply_label_color(name_lbl, POPUP_TEXT_PRIMARY)
	info.add_child(name_lbl)

	var total_lbl: Label = Label.new()
	total_lbl.text = LocalizationSystem.tr_key("animals.count") + ": " + str(instances.size()) \
		+ "   " + LocalizationSystem.tr_key("animals.status.free") + ": " + str(free_count)
	total_lbl.add_theme_font_size_override("font_size", _animals_text_size(12))
	_apply_label_color(total_lbl, POPUP_TEXT_SECONDARY)
	info.add_child(total_lbl)

	var rarity_order: Array[String] = ["common", "rare", "exceptional", "ultra_rare"]
	for rarity in rarity_order:
		if not rarity_counts.has(rarity):
			continue
		var cnt: int = int(rarity_counts[rarity])
		var icon_path: String = ReptileSystem.RARITY_ICON_PATHS.get(rarity, "")
		var label_key: String = ReptileSystem.get_rarity_label_key(rarity)
		var r_row: HBoxContainer = _make_icon_text_row(icon_path, LocalizationSystem.tr_key(label_key) + ": " + str(cnt), _animals_rarity_icon_size(22), _animals_text_size(12))
		info.add_child(r_row)

	var btn_offset: MarginContainer = MarginContainer.new()
	btn_offset.add_theme_constant_override("margin_right", _animals_ui_size(112 * ANIMALS_CARD_ACTION_LEFT_SHIFT_RATIO))
	row.add_child(btn_offset)

	var btn_col: VBoxContainer = VBoxContainer.new()
	btn_col.custom_minimum_size = _animals_ui_vec(112, 0)
	btn_col.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_offset.add_child(btn_col)

	var enter_btn: Button = _make_owned_card_action_button("animals.view_group")
	var rid: String = reptile_id
	enter_btn.pressed.connect(func() -> void:
		_animals_group_navigating = true
		_animals_step = 1
		_animals_selected_species_id = rid
		_show_animals_view("owned")
	)
	btn_col.add_child(enter_btn)

	_make_scroll_safe(card)
	return card


func _make_animals_tab_button(label_key: String, tab_id: String, active_tab_id: String) -> Button:
	var button: Button = Button.new()
	button.text = LocalizationSystem.tr_key(label_key)
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var active: bool = tab_id == active_tab_id
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.86, 0.66, 0.25, 0.95) if active else Color(0.78, 0.70, 0.55, 0.45)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.90, 0.70, 0.30, 0.95)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.72, 0.54, 0.20, 0.95)))
	_apply_button_text_color(button, POPUP_TEXT_PRIMARY)
	button.pressed.connect(func() -> void:
		_show_animals_view(tab_id)
	)
	return button


func _populate_owned_animals(parent: VBoxContainer) -> void:
	var all_instances: Array = _get_sorted_owned_instances()
	if all_instances.is_empty():
		parent.add_child(_make_owned_empty_state())
		return

	if _animals_step == 1 and not _animals_selected_species_id.is_empty():
		var back_btn := Button.new()
		back_btn.text = "← " + LocalizationSystem.tr_key("button.back")
		back_btn.custom_minimum_size = _animals_ui_vec(130, 42)
		back_btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.78, 0.70, 0.55, 0.55)))
		back_btn.add_theme_stylebox_override("hover", _make_button_style(Color(0.80, 0.72, 0.57, 0.75)))
		back_btn.add_theme_stylebox_override("pressed", _make_button_style(Color(0.68, 0.60, 0.47, 0.75)))
		_apply_button_text_color(back_btn, POPUP_TEXT_PRIMARY)
		back_btn.pressed.connect(func() -> void:
			_animals_group_navigating = true
			_animals_step = 0
			_animals_selected_species_id = ""
			_show_animals_view("owned")
		)
		parent.add_child(back_btn)

		var found: bool = false
		for inst_val in all_instances:
			if typeof(inst_val) != TYPE_DICTIONARY:
				continue
			var inst: Dictionary = inst_val as Dictionary
			if str(inst.get("reptile_id", "")) == _animals_selected_species_id:
				parent.add_child(_make_owned_reptile_card(inst))
				found = true
		if not found:
			parent.add_child(_make_owned_empty_state())
	else:
		var groups: Dictionary = {}
		var group_order: Array = []
		for inst_val in all_instances:
			if typeof(inst_val) != TYPE_DICTIONARY:
				continue
			var inst: Dictionary = inst_val as Dictionary
			var rid: String = str(inst.get("reptile_id", ""))
			if not groups.has(rid):
				groups[rid] = []
				group_order.append(rid)
			(groups[rid] as Array).append(inst)

		for rid in group_order:
			parent.add_child(_make_owned_species_group_card(rid, groups[rid] as Array))


func _show_quests_view() -> void:
	_close_quests_view()
	_close_animals_view()
	_close_shop_view()
	_close_workers_view()
	_close_upgrades_view()
	_close_management_modal()
	_close_reptile_selection_modal()
	_close_habitat_purchase_modal()
	_notify_quest_event("screen_opened", {"screen": "quests"})

	quests_view = Control.new()
	quests_view.name = "QuestsView"
	quests_view.anchor_left = 0.0
	quests_view.anchor_top = 0.0
	quests_view.anchor_right = 1.0
	quests_view.anchor_bottom = 1.0
	quests_view.offset_top = TOP_BAR_HEIGHT + 2
	quests_view.offset_bottom = -(BOTTOM_NAV_HEIGHT + 6)
	add_child(quests_view)

	if not _quests_design_assets_available():
		_show_quests_view_fallback_content(quests_view)
		return

	var background: TextureRect = TextureRect.new()
	background.name = "QuestsDesignBackground"
	background.texture = AssetPaths.load_texture(QUESTS_BG_PATH)
	background.anchor_left = 0.0
	background.anchor_top = 0.0
	background.anchor_right = 1.0
	background.anchor_bottom = 1.05
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quests_view.add_child(background)

	var title_art: TextureRect = TextureRect.new()
	title_art.name = "QuestsTitleArt"
	title_art.texture = AssetPaths.load_texture(_get_quests_title_path())
	title_art.anchor_left = QUEST_TITLE_ANCHOR_LEFT
	title_art.anchor_top = QUEST_TITLE_ANCHOR_TOP
	title_art.anchor_right = QUEST_TITLE_ANCHOR_RIGHT
	title_art.anchor_bottom = QUEST_TITLE_ANCHOR_BOTTOM
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quests_view.add_child(title_art)

	var close_button: Button = Button.new()
	close_button.name = "QuestsCloseHitbox"
	close_button.text = ""
	close_button.flat = true
	close_button.anchor_left = QUEST_CLOSE_ANCHOR_LEFT
	close_button.anchor_top = QUEST_CLOSE_ANCHOR_TOP
	close_button.anchor_right = QUEST_CLOSE_ANCHOR_RIGHT
	close_button.anchor_bottom = QUEST_CLOSE_ANCHOR_BOTTOM
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.add_theme_stylebox_override("normal", _make_transparent_button_style())
	close_button.add_theme_stylebox_override("hover", _make_transparent_button_style())
	close_button.add_theme_stylebox_override("pressed", _make_transparent_button_style())
	close_button.pressed.connect(_close_quests_view)
	quests_view.add_child(close_button)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "QuestsScroll"
	scroll.anchor_left = QUEST_SCROLL_LEFT_ANCHOR
	scroll.anchor_top = QUEST_SCROLL_TOP_ANCHOR
	scroll.anchor_right = QUEST_SCROLL_RIGHT_ANCHOR
	scroll.anchor_bottom = QUEST_SCROLL_BOTTOM_ANCHOR
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	quests_view.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.name = "QuestsList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.mouse_filter = Control.MOUSE_FILTER_PASS
	list.add_theme_constant_override("separation", QUEST_LIST_SEPARATION)
	scroll.add_child(list)
	_make_scroll_safe(list)
	_populate_quests_list(list)


func _show_workers_view() -> void:
	_close_workers_view()
	_close_animals_view()
	_close_quests_view()
	_close_shop_view()
	_close_upgrades_view()
	_close_management_modal()
	_close_reptile_selection_modal()
	_close_habitat_purchase_modal()
	_notify_quest_event("screen_opened", {"screen": "workers"})

	workers_view = Control.new()
	workers_view.name = "WorkersView"
	workers_view.anchor_left = 0.0
	workers_view.anchor_top = 0.0
	workers_view.anchor_right = 1.0
	workers_view.anchor_bottom = 1.0
	workers_view.offset_top = TOP_BAR_HEIGHT + 10
	workers_view.offset_bottom = -(BOTTOM_NAV_HEIGHT + 8)
	add_child(workers_view)

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	workers_view.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("nav.workers"), 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	header.add_child(title)

	var close_button: Button = Button.new()
	close_button.text = LocalizationSystem.tr_key("ui.close")
	close_button.custom_minimum_size = Vector2(96, 42)
	close_button.pressed.connect(_close_workers_view)
	_apply_button_text_color(close_button, POPUP_TEXT_PRIMARY)
	header.add_child(close_button)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.mouse_filter = Control.MOUSE_FILTER_PASS
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	_populate_workers_list(list)


func _show_upgrades_view() -> void:
	_close_upgrades_view()
	_close_workers_view()
	_close_animals_view()
	_close_quests_view()
	_close_shop_view()
	_close_management_modal()
	_close_reptile_selection_modal()
	_close_habitat_purchase_modal()

	_upgrade_purchase_in_progress = false
	if not _upgrades_design_assets_available():
		_show_upgrades_view_fallback()
		return

	upgrades_view = Control.new()
	upgrades_view.name = "UpgradesView"
	upgrades_view.anchor_left = 0.0
	upgrades_view.anchor_top = 0.0
	upgrades_view.anchor_right = 1.0
	upgrades_view.anchor_bottom = 1.0
	var _upg_avail_h: float = get_viewport_rect().size.y - float(TOP_BAR_HEIGHT) - 2.0 - float(BOTTOM_NAV_HEIGHT) - 6.0
	var _upg_h_extra: float = _upg_avail_h * UPGRADES_VIEW_EXTRA_H_FRAC * 0.5
	upgrades_view.offset_top = float(TOP_BAR_HEIGHT) + 2.0 - _upg_h_extra
	upgrades_view.offset_bottom = -float(BOTTOM_NAV_HEIGHT) - 6.0 + _upg_h_extra
	add_child(upgrades_view)

	var background: TextureRect = TextureRect.new()
	background.name = "UpgradesDesignBackground"
	background.texture = AssetPaths.load_texture(UPGRADES_BG_PATH)
	background.anchor_left = 0.0
	background.anchor_top = 0.0
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrades_view.add_child(background)

	var title_art: TextureRect = TextureRect.new()
	title_art.name = "UpgradesTitleArt"
	title_art.texture = AssetPaths.load_texture(_get_upgrades_title_path())
	title_art.anchor_left = UPGRADE_TITLE_ANCHOR_LEFT
	title_art.anchor_top = UPGRADE_TITLE_ANCHOR_TOP
	title_art.anchor_right = UPGRADE_TITLE_ANCHOR_RIGHT
	title_art.anchor_bottom = UPGRADE_TITLE_ANCHOR_BOTTOM
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrades_view.add_child(title_art)

	var close_button: Button = Button.new()
	close_button.name = "UpgradesCloseHitbox"
	close_button.text = ""
	close_button.flat = true
	close_button.anchor_left = UPGRADE_CLOSE_ANCHOR_LEFT
	close_button.anchor_top = UPGRADE_CLOSE_ANCHOR_TOP
	close_button.anchor_right = UPGRADE_CLOSE_ANCHOR_RIGHT
	close_button.anchor_bottom = UPGRADE_CLOSE_ANCHOR_BOTTOM
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.add_theme_stylebox_override("normal", _make_transparent_button_style())
	close_button.add_theme_stylebox_override("hover", _make_transparent_button_style())
	close_button.add_theme_stylebox_override("pressed", _make_transparent_button_style())
	close_button.pressed.connect(_close_upgrades_view)
	upgrades_view.add_child(close_button)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "UpgradesScroll"
	scroll.anchor_left = UPGRADE_SCROLL_LEFT_ANCHOR
	scroll.anchor_top = UPGRADE_SCROLL_TOP_ANCHOR
	scroll.anchor_right = UPGRADE_SCROLL_RIGHT_ANCHOR
	scroll.anchor_bottom = UPGRADE_SCROLL_BOTTOM_ANCHOR
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	upgrades_view.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.name = "UpgradesList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.mouse_filter = Control.MOUSE_FILTER_PASS
	list.add_theme_constant_override("separation", UPGRADE_LIST_SEPARATION)
	scroll.add_child(list)
	_make_scroll_safe(list)
	_populate_upgrades_list(list)


func _show_upgrades_view_fallback() -> void:
	upgrades_view = Control.new()
	upgrades_view.name = "UpgradesView"
	upgrades_view.anchor_left = 0.0
	upgrades_view.anchor_top = 0.0
	upgrades_view.anchor_right = 1.0
	upgrades_view.anchor_bottom = 1.0
	upgrades_view.offset_top = TOP_BAR_HEIGHT + 10
	upgrades_view.offset_bottom = -(BOTTOM_NAV_HEIGHT + 8)
	add_child(upgrades_view)

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	upgrades_view.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("ui.upgrades"), 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	header.add_child(title)

	var close_button: Button = Button.new()
	close_button.text = LocalizationSystem.tr_key("ui.close")
	close_button.custom_minimum_size = Vector2(96, 42)
	close_button.pressed.connect(_close_upgrades_view)
	_apply_button_text_color(close_button, POPUP_TEXT_PRIMARY)
	header.add_child(close_button)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.mouse_filter = Control.MOUSE_FILTER_PASS
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	_populate_upgrades_list_fallback(list)


func _populate_upgrades_list(parent: VBoxContainer) -> void:
	if not has_node("/root/UpgradeSystem"):
		parent.add_child(_make_popup_label(LocalizationSystem.tr_key("upgrades.unavailable"), 16))
		return

	var definitions: Array = UpgradeSystem.get_upgrade_definitions(false)
	if definitions.is_empty():
		parent.add_child(_make_popup_label(LocalizationSystem.tr_key("upgrades.unavailable"), 16))
		return

	for upgrade_value in definitions:
		if typeof(upgrade_value) != TYPE_DICTIONARY:
			continue
		parent.add_child(_make_upgrade_card(upgrade_value as Dictionary))

	var bottom_spacer: Control = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 18)
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bottom_spacer)


func _populate_upgrades_list_fallback(parent: VBoxContainer) -> void:
	if not has_node("/root/UpgradeSystem"):
		parent.add_child(_make_popup_label(LocalizationSystem.tr_key("upgrades.unavailable"), 16))
		return

	var definitions: Array = UpgradeSystem.get_upgrade_definitions(false)
	if definitions.is_empty():
		parent.add_child(_make_popup_label(LocalizationSystem.tr_key("upgrades.unavailable"), 16))
		return

	for upgrade_value in definitions:
		if typeof(upgrade_value) != TYPE_DICTIONARY:
			continue
		parent.add_child(_make_upgrade_card_fallback(upgrade_value as Dictionary))


func _make_upgrade_card(upgrade: Dictionary) -> Control:
	var upgrade_id: String = str(upgrade.get("id", ""))
	var level: int = UpgradeSystem.get_upgrade_level(upgrade_id)
	var max_level: int = int(upgrade.get("max_level", 1))
	var next_cost: int = UpgradeSystem.get_upgrade_cost(upgrade_id)
	var at_max: bool = level >= max_level

	var can_afford: bool = at_max or EconomySystem.can_afford("repticash", next_cost)

	var card: Control = Control.new()
	card.custom_minimum_size = Vector2(0, UPGRADE_CARD_MIN_HEIGHT)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var background: TextureRect = TextureRect.new()
	background.name = "UpgradeRowBackground"
	background.texture = AssetPaths.load_texture(UPGRADES_ROW_BG_PATH)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(background)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", UPGRADE_CARD_MARGIN_LEFT)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_top", UPGRADE_CARD_MARGIN_V + UPGRADE_CARD_CONTENT_V_EXTRA)
	margin.add_theme_constant_override("margin_bottom", UPGRADE_CARD_MARGIN_V + UPGRADE_CARD_CONTENT_V_EXTRA)
	card.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", UPGRADE_CARD_ROW_SEP)
	margin.add_child(row)

	var icon_column: Control = Control.new()
	icon_column.custom_minimum_size = Vector2(UPGRADE_ICON_COLUMN_W, 0)
	icon_column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(icon_column)

	var icon_size := Vector2(UPGRADE_ICON_SIZE, UPGRADE_ICON_SIZE)
	var icon: Control = _make_icon_or_fallback(str(upgrade.get("icon_path", "")), icon_size, "+")
	icon.anchor_left = 0.5
	icon.anchor_top = 0.5
	icon.anchor_right = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_left = -icon_size.x * 0.5 + 9
	icon.offset_top = -icon_size.y * 0.5
	icon.offset_right = icon_size.x * 0.5 + 9
	icon.offset_bottom = icon_size.y * 0.5
	icon_column.add_child(icon)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	row.add_child(info)

	var name_label: Label = Label.new()
	name_label.text = LocalizationSystem.tr_key(str(upgrade.get("name_key", upgrade_id)))
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.add_theme_font_size_override("font_size", UPGRADE_TEXT_NAME_SIZE)
	name_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.86, 0.48, 0.45))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	_apply_label_color(name_label, POPUP_TEXT_PRIMARY)
	info.add_child(name_label)

	var name_desc_spacer := Control.new()
	name_desc_spacer.custom_minimum_size = Vector2(0, 3)
	name_desc_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_desc_spacer)

	var desc_label: Label = Label.new()
	desc_label.text = LocalizationSystem.tr_key(str(upgrade.get("description_key", upgrade_id)))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	desc_label.custom_minimum_size = Vector2(0, 30)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_font_size_override("font_size", UPGRADE_TEXT_DESC_SIZE)
	_apply_label_color(desc_label, POPUP_TEXT_SECONDARY)
	info.add_child(desc_label)

	info.add_child(_make_upgrade_info_line(
		UPGRADES_LEVEL_ICON_PATH,
		LocalizationSystem.tr_key("ui.upgrade_level") + " " + str(level) + " / " + str(max_level),
		POPUP_TEXT_ACCENT
	))

	info.add_child(_make_upgrade_info_line(
		UPGRADES_CURRENT_ICON_PATH,
		LocalizationSystem.tr_key("ui.upgrade_current_effect") + ": " + _format_upgrade_effect(upgrade, level),
		POPUP_TEXT_SUCCESS if level > 0 else POPUP_TEXT_SECONDARY
	))

	var effect_spacer: Control = Control.new()
	effect_spacer.custom_minimum_size = Vector2(0, 6)
	effect_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(effect_spacer)

	if not at_max:
		info.add_child(_make_upgrade_info_line(
			UPGRADES_NEXT_ICON_PATH,
			LocalizationSystem.tr_key("ui.upgrade_next_effect") + ": " + _format_upgrade_effect(upgrade, level + 1),
			POPUP_TEXT_SECONDARY
		))
	else:
		info.add_child(_make_upgrade_info_line(
			UPGRADES_NEXT_ICON_PATH,
			LocalizationSystem.tr_key("ui.upgrade_max"),
			POPUP_TEXT_SUCCESS
		))

	var push_spacer: Control = Control.new()
	push_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	push_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(push_spacer)

	var price_text: String = "MAX" if at_max else _format_upgrade_cost_text(next_cost)
	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	info.add_child(action_row)

	var badge: Control = _make_upgrade_price_badge(price_text, at_max)
	badge.custom_minimum_size = Vector2(0, UPGRADE_PRICE_BADGE_H)
	badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(badge)

	if at_max:
		var max_lbl: Label = _make_upgrade_max_state_label()
		max_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_row.add_child(max_lbl)
	elif can_afford:
		var btn: TextureButton = _make_upgrade_buy_texture_button(upgrade_id)
		btn.custom_minimum_size = Vector2(0, UPGRADE_BUY_BTN_H)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_row.add_child(btn)

	_make_scroll_safe(card)
	return card


func _make_upgrade_card_fallback(upgrade: Dictionary) -> Control:
	var upgrade_id: String = str(upgrade.get("id", ""))
	var level: int = UpgradeSystem.get_upgrade_level(upgrade_id)
	var max_level: int = int(upgrade.get("max_level", 1))
	var next_cost: int = UpgradeSystem.get_upgrade_cost(upgrade_id)
	var at_max: bool = level >= max_level

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 178)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var icon_column: CenterContainer = CenterContainer.new()
	icon_column.custom_minimum_size = Vector2(104, 104)
	icon_column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon_column)

	var icon: Control = _make_icon_or_fallback(str(upgrade.get("icon_path", "")), Vector2(92, 92), "+")
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_column.add_child(icon)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var name_label: Label = Label.new()
	name_label.text = LocalizationSystem.tr_key(str(upgrade.get("name_key", upgrade_id)))
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 16)
	_apply_label_color(name_label, POPUP_TEXT_PRIMARY)
	info.add_child(name_label)

	var desc_label: Label = Label.new()
	desc_label.text = LocalizationSystem.tr_key(str(upgrade.get("description_key", upgrade_id)))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(desc_label, POPUP_TEXT_SECONDARY)
	info.add_child(desc_label)

	var level_label: Label = Label.new()
	level_label.text = LocalizationSystem.tr_key("ui.upgrade_level") + " " + str(level) + " / " + str(max_level)
	level_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(level_label, POPUP_TEXT_ACCENT)
	info.add_child(level_label)

	var current_label: Label = Label.new()
	current_label.text = LocalizationSystem.tr_key("ui.upgrade_current_effect") + ": " + _format_upgrade_effect(upgrade, level)
	current_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(current_label, POPUP_TEXT_SUCCESS if level > 0 else POPUP_TEXT_SECONDARY)
	info.add_child(current_label)

	if not at_max:
		var next_label: Label = Label.new()
		next_label.text = LocalizationSystem.tr_key("ui.upgrade_next_effect") + ": " + _format_upgrade_effect(upgrade, level + 1)
		next_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		next_label.add_theme_font_size_override("font_size", 12)
		_apply_label_color(next_label, POPUP_TEXT_SECONDARY)
		info.add_child(next_label)

	var action_area: VBoxContainer = VBoxContainer.new()
	action_area.custom_minimum_size = Vector2(132, 0)
	action_area.alignment = BoxContainer.ALIGNMENT_CENTER
	action_area.add_theme_constant_override("separation", 6)
	row.add_child(action_area)

	var cost_label: Label = Label.new()
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(cost_label, POPUP_TEXT_ACCENT)
	cost_label.text = LocalizationSystem.tr_key("ui.upgrade_max") if at_max else _format_upgrade_cost_text(next_cost)
	action_area.add_child(cost_label)

	var action_button: Button = _make_upgrade_action_button("ui.upgrade_upgrade" if level > 0 else "ui.upgrade_buy")
	action_button.disabled = at_max
	action_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if action_button.disabled else Control.CURSOR_POINTING_HAND
	action_button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.45, 0.45, 0.42, 0.75)))
	action_button.pressed.connect(func() -> void:
		_try_buy_upgrade(upgrade_id)
	)
	action_area.add_child(action_button)

	_make_scroll_safe(card)
	return card


func _upgrades_design_assets_available() -> bool:
	var paths: Array[String] = [
		UPGRADES_BG_PATH,
		_get_upgrades_title_path(),
		UPGRADES_ROW_BG_PATH,
		UPGRADES_PRICE_BADGE_PATH,
		_get_upgrades_buy_button_path(),
		UPGRADES_LEVEL_ICON_PATH,
		UPGRADES_CURRENT_ICON_PATH,
		UPGRADES_NEXT_ICON_PATH
	]
	var available: bool = true
	for path in paths:
		if not ResourceLoader.exists(path):
			push_warning("Upgrades design asset missing: " + path)
			available = false
	return available


func _get_upgrades_title_path() -> String:
	return UPGRADES_TITLE_EN_PATH if GameState.get_language() == "en" else UPGRADES_TITLE_PL_PATH


func _get_upgrades_buy_button_path() -> String:
	return UPGRADES_BUY_EN_PATH if GameState.get_language() == "en" else UPGRADES_BUY_PL_PATH


func _shop_design_assets_available() -> bool:
	var paths: Array[String] = [
		_get_shop_background_path(),
		SHOP_RESOURCE_CARD_BG_PATH,
		QUESTS_CARD_BG_PATH,
		SHOP_BUY_COMMON_BUTTON_PATH,
		SHOP_BUY_RARE_BUTTON_PATH,
		SHOP_FOOD_ICON_PATH,
		SHOP_WATER_ICON_PATH
	]
	var available: bool = true
	for path in paths:
		if AssetPaths.find_texture_path(path).is_empty():
			push_warning("Shop design asset missing: " + path)
			available = false
	return available


func _get_shop_background_path() -> String:
	return QUESTS_BG_PATH


func _get_shop_title_path() -> String:
	return SHOP_TITLE_EN_PATH if GameState.get_language() == "en" else SHOP_TITLE_PL_PATH


func _quests_design_assets_available() -> bool:
	var paths: Array[String] = [
		QUESTS_BG_PATH,
		_get_quests_title_path(),
		QUESTS_CARD_BG_PATH,
		_get_quests_claim_button_path()
	]
	for path in paths:
		if not ResourceLoader.exists(path):
			push_warning("Quests design asset missing: " + path)
			return false
	return true


func _get_quests_title_path() -> String:
	return QUESTS_TITLE_EN_PATH if GameState.get_language() == "en" else QUESTS_TITLE_PL_PATH


func _get_quests_claim_button_path() -> String:
	return QUESTS_CLAIM_EN_PATH if GameState.get_language() == "en" else QUESTS_CLAIM_PL_PATH


func _show_quests_view_fallback_content(parent: Control) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	parent.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("quests.title"), 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	header.add_child(title)

	var close_button: Button = Button.new()
	close_button.text = LocalizationSystem.tr_key("ui.close")
	close_button.custom_minimum_size = Vector2(96, 42)
	close_button.pressed.connect(_close_quests_view)
	_apply_button_text_color(close_button, POPUP_TEXT_PRIMARY)
	header.add_child(close_button)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.mouse_filter = Control.MOUSE_FILTER_PASS
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	_populate_quests_list(list)


func _make_shop_texture_background(path: String) -> TextureRect:
	var bg: TextureRect = TextureRect.new()
	bg.texture = AssetPaths.load_texture(path)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bg


func _position_shop_control(control: Control, center: Vector2, size: Vector2) -> void:
	control.anchor_left = center.x
	control.anchor_top = center.y
	control.anchor_right = center.x
	control.anchor_bottom = center.y
	control.offset_left = -size.x * 0.5
	control.offset_top = -size.y * 0.5
	control.offset_right = size.x * 0.5
	control.offset_bottom = size.y * 0.5
	control.custom_minimum_size = size


func _make_shop_section_label(text: String, font_size: int) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.38, 0.08, 0.92)
	style.border_color = Color(0.45, 0.30, 0.12, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)

	var label: Label = Label.new()
	label.text = text
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 8
	label.offset_right = -8
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", BUTTON_TEXT_COLOR)
	label.add_theme_color_override("font_shadow_color", Color(0.10, 0.05, 0.01, 0.90))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return panel


func _make_shop_value_box_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.83, 0.62, 0.35, 0.42)
	style.border_color = Color(0.47, 0.27, 0.10, 0.36)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style


func _make_shop_resource_card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.86, 0.56, 0.90)
	style.border_color = Color(0.62, 0.34, 0.10, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _get_shop_habitat_icon_path(preferred_type: String) -> String:
	if preferred_type.is_empty():
		return ""
	return ReptileSystem.get_habitat_texture_path(preferred_type, 1)


func _make_shop_reptile_income_row(reptile_id: String, base_income: float) -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_theme_constant_override("separation", 3)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var prefix: Label = _make_shop_compact_text(LocalizationSystem.tr_key("ui.base_income"), 10 + SHOP_REPTILE_TEXT_BONUS, POPUP_TEXT_SECONDARY, Vector2(250, 32))
	prefix.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	column.add_child(prefix)

	var value_row: HBoxContainer = HBoxContainer.new()
	value_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	value_row.add_theme_constant_override("separation", 10)
	value_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(value_row)

	_add_shop_income_variant_piece(value_row, reptile_id, "common", base_income)
	_add_shop_income_variant_piece(value_row, reptile_id, "rare", base_income)
	return column


func _add_shop_income_variant_piece(row: HBoxContainer, reptile_id: String, rarity: String, base_income: float) -> void:
	var variant: Dictionary = ReptileSystem.get_shop_variant_for_rarity(reptile_id, rarity)
	var icon_path: String = str(variant.get("rarity_icon_path", ReptileSystem.get_rarity_icon_path(rarity))) if not variant.is_empty() else ReptileSystem.get_rarity_icon_path(rarity)
	var icon: TextureRect = _make_rarity_icon(icon_path, SHOP_REPTILE_RARITY_ICON_SIZE)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var multiplier: float = ReptileSystem.get_variant_income_multiplier(variant) if not variant.is_empty() else ReptileSystem.get_rarity_income_multiplier(rarity)
	var income_text: String = _format_decimal(base_income * multiplier) + " " + LocalizationSystem.tr_key("currency.repticash") + LocalizationSystem.tr_key("ui.per_minute").replace(" ", "")
	row.add_child(_make_shop_compact_text(income_text, 10 + SHOP_REPTILE_TEXT_BONUS, POPUP_TEXT_SECONDARY, Vector2(104, 34)))


func _make_shop_compact_text(text: String, font_size: int, color: Color, min_size: Vector2) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.custom_minimum_size = min_size
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	_apply_label_color(label, color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_upgrade_info_line(icon_path: String, text: String, color: Color) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)

	var icon: TextureRect = _make_fixed_texture(icon_path, Vector2(UPGRADE_INFO_ICON_SIZE, UPGRADE_INFO_ICON_SIZE))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", UPGRADE_TEXT_INFO_SIZE)
	_apply_label_color(label, color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return row


func _make_upgrade_price_badge(text: String, at_max: bool) -> Control:
	var badge: Control = Control.new()
	badge.custom_minimum_size = Vector2(UPGRADE_PRICE_BADGE_W, UPGRADE_PRICE_BADGE_H)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg: TextureRect = TextureRect.new()
	bg.texture = AssetPaths.load_texture(UPGRADES_PRICE_BADGE_PATH)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if at_max:
		bg.modulate = Color(0.72, 0.72, 0.68, 0.95)
	badge.add_child(bg)

	var label: Label = Label.new()
	label.text = text
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UPGRADE_PRICE_TEXT_SIZE)
	label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.18, 0.08, 0.02, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)
	return badge


func _make_upgrade_buy_texture_button(upgrade_id: String) -> TextureButton:
	var button: TextureButton = TextureButton.new()
	button.name = "UpgradeBuyButton"
	button.custom_minimum_size = Vector2(UPGRADE_BUY_BTN_W, UPGRADE_BUY_BTN_H)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.texture_normal = AssetPaths.load_texture(_get_upgrades_buy_button_path())
	button.texture_hover = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.texture_disabled = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func() -> void:
		_try_buy_upgrade(upgrade_id)
	)
	return button


func _make_upgrade_max_state_label() -> Label:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(146, 52)
	label.text = LocalizationSystem.tr_key("ui.upgrade_max")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	_apply_label_color(label, POPUP_TEXT_SUCCESS)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _format_upgrade_cost_text(price: int) -> String:
	return LocalizationSystem.tr_key("ui.upgrade_cost") + ": " + LocalizationSystem.tr_key("currency.repticash") + " " + str(price)


func _format_upgrade_effect(upgrade: Dictionary, level: int) -> String:
	var effect_type: String = str(upgrade.get("effect_type", ""))
	var per_level: float = float(upgrade.get("effect_per_level", 0.0))
	var effect_value: float = float(max(0, level)) * per_level
	match effect_type:
		"reptile_income_multiplier":
			return LocalizationSystem.tr_key("ui.upgrade_reptile_income_effect").replace("{value}", _format_multiplier(1.0 + effect_value))
		"offline_cap_seconds":
			return LocalizationSystem.tr_key("ui.upgrade_offline_cap_effect").replace("{time}", _format_duration_compact(UpgradeSystem.BASE_OFFLINE_CAP_SECONDS + int(round(effect_value))))
		"play_reward_multiplier":
			return LocalizationSystem.tr_key("ui.upgrade_play_reward_effect").replace("{value}", _format_multiplier(1.0 + effect_value))
		"happiness_decay_multiplier":
			return LocalizationSystem.tr_key("ui.upgrade_happiness_decay_effect").replace("{value}", _format_multiplier(max(0.25, 1.0 - effect_value)))
		"worker_efficiency_multiplier":
			return LocalizationSystem.tr_key("ui.upgrade_worker_efficiency_effect").replace("{value}", _format_multiplier(1.0 + effect_value))
		"collection_bonus_multiplier":
			return LocalizationSystem.tr_key("ui.upgrade_collection_bonus_effect").replace("{value}", _format_multiplier(1.0 + effect_value))
		"food_cost_reduction":
			var food_pct: int = min(50, int(round(float(level) * per_level * 100.0)))
			return LocalizationSystem.tr_key("ui.upgrade_food_cost_reduction_effect").replace("{value}", str(food_pct) + "%")
		"water_cost_reduction":
			var water_pct: int = min(50, int(round(float(level) * per_level * 100.0)))
			return LocalizationSystem.tr_key("ui.upgrade_water_cost_reduction_effect").replace("{value}", str(water_pct) + "%")
		"food_max_increase":
			var food_max: int = 0
			if has_node("/root/ReptileSystem") and level > 0:
				food_max = ReptileSystem.get_biome_resource_max(biome_id, "food")
			else:
				food_max = 100
			return LocalizationSystem.tr_key("ui.upgrade_food_max_effect").replace("{value}", str(food_max))
		"water_max_increase":
			var water_max: int = 0
			if has_node("/root/ReptileSystem") and level > 0:
				water_max = ReptileSystem.get_biome_resource_max(biome_id, "water")
			else:
				water_max = 100
			return LocalizationSystem.tr_key("ui.upgrade_water_max_effect").replace("{value}", str(water_max))
		"clean_cooldown_reduction":
			var clean_pct: int = min(50, int(round(float(level) * per_level * 100.0)))
			return LocalizationSystem.tr_key("ui.upgrade_clean_cooldown_reduction_effect").replace("{value}", str(clean_pct) + "%")
		"play_cooldown_reduction":
			var play_pct: int = min(50, int(round(float(level) * per_level * 100.0)))
			return LocalizationSystem.tr_key("ui.upgrade_play_cooldown_reduction_effect").replace("{value}", str(play_pct) + "%")
		_:
			return _format_decimal(effect_value)


func _try_buy_upgrade(upgrade_id: String) -> void:
	if _upgrade_purchase_in_progress:
		return
	_upgrade_purchase_in_progress = true
	var result: Dictionary = UpgradeSystem.buy_upgrade(upgrade_id)
	if not bool(result.get("success", false)):
		_upgrade_purchase_in_progress = false
		_show_message_popup(str(result.get("message_key", "ui.not_enough_rs")))
		return

	_upgrade_purchase_in_progress = false
	_show_upgrades_view()


func _populate_workers_list(parent: VBoxContainer) -> void:
	if not has_node("/root/WorkerSystem"):
		parent.add_child(_make_popup_label(LocalizationSystem.tr_key("workers.unavailable"), 16))
		return

	var definitions: Array = WorkerSystem.get_worker_definitions(false)
	if definitions.is_empty():
		parent.add_child(_make_popup_label(LocalizationSystem.tr_key("workers.unavailable"), 16))
		return

	for worker_value in definitions:
		if typeof(worker_value) != TYPE_DICTIONARY:
			continue
		parent.add_child(_make_worker_card(worker_value as Dictionary))


func _make_worker_card(worker: Dictionary) -> Control:
	var worker_id: String = str(worker.get("id", ""))
	var level: int = WorkerSystem.get_worker_level(worker_id)
	var max_level: int = int(worker.get("max_level", 1))
	var next_cost: int = WorkerSystem.get_next_cost(worker_id)
	var at_max: bool = level >= max_level

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 196)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	var icon_column: CenterContainer = CenterContainer.new()
	icon_column.custom_minimum_size = Vector2(148, 148)
	icon_column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon_column)

	var worker_icon: TextureRect = _make_fixed_texture(str(worker.get("icon_path", "")), Vector2(136, 136))
	worker_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	worker_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_column.add_child(worker_icon)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var name_label: Label = Label.new()
	name_label.text = LocalizationSystem.tr_key(str(worker.get("name_key", worker_id)))
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 16)
	_apply_label_color(name_label, POPUP_TEXT_PRIMARY)
	info.add_child(name_label)

	var desc_label: Label = Label.new()
	desc_label.text = LocalizationSystem.tr_key(str(worker.get("description_key", worker_id)))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(desc_label, POPUP_TEXT_SECONDARY)
	info.add_child(desc_label)

	var status_label: Label = Label.new()
	status_label.text = _format_worker_status(worker_id, level)
	status_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(status_label, POPUP_TEXT_ACCENT)
	info.add_child(status_label)

	var effect_label: Label = Label.new()
	effect_label.text = _format_worker_effect_summary(worker_id, worker, level)
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(effect_label, POPUP_TEXT_SUCCESS if level > 0 else POPUP_TEXT_SECONDARY)
	info.add_child(effect_label)

	var action_area: VBoxContainer = VBoxContainer.new()
	action_area.custom_minimum_size = Vector2(128, 0)
	action_area.alignment = BoxContainer.ALIGNMENT_CENTER
	action_area.add_theme_constant_override("separation", 6)
	row.add_child(action_area)

	var cost_label: Label = Label.new()
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(cost_label, POPUP_TEXT_ACCENT)
	cost_label.text = LocalizationSystem.tr_key("ui.worker_max") if at_max else LocalizationSystem.tr_key("ui.worker_cost") + ": " + LocalizationSystem.tr_key("currency.repticash") + " " + str(next_cost)
	action_area.add_child(cost_label)

	var action_button: Button = _make_owned_card_action_button("ui.worker_upgrade" if level > 0 else "ui.worker_buy")
	action_button.disabled = at_max or (next_cost > 0 and not EconomySystem.can_afford("repticash", next_cost))
	action_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if action_button.disabled else Control.CURSOR_POINTING_HAND
	action_button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.45, 0.45, 0.42, 0.75)))
	action_button.pressed.connect(func() -> void:
		_try_buy_or_upgrade_worker(worker_id)
	)
	action_area.add_child(action_button)

	_make_scroll_safe(card)
	return card


func _format_worker_status(worker_id: String, level: int) -> String:
	var max_level: int = int(WorkerSystem.get_worker_definition(worker_id).get("max_level", 1))
	var level_text: String = LocalizationSystem.tr_key("ui.worker_level") + " " + str(level) + " / " + str(max_level)
	if level <= 0:
		return level_text + " - " + LocalizationSystem.tr_key("ui.worker_not_owned")
	return level_text + " - " + LocalizationSystem.tr_key("ui.worker_active")


func _format_worker_effect_summary(worker_id: String, worker: Dictionary, level: int) -> String:
	var worker_type: String = str(worker.get("type", ""))
	var display_level: int = max(1, level)
	var interval: int = WorkerSystem.get_worker_interval(worker_id, display_level)
	var effect_value: float = WorkerSystem.get_worker_effect_value(worker_id, display_level)
	var threshold: int = int(WorkerSystem.get_worker_threshold(worker_id))
	var prefix: String = LocalizationSystem.tr_key("ui.worker_effect") if level > 0 else LocalizationSystem.tr_key("ui.worker_next_effect")

	if worker_type == "manager":
		var multiplier: float = 1.0 + WorkerSystem.get_worker_effect_value(worker_id, display_level)
		return prefix + ": " + LocalizationSystem.tr_key("ui.worker_income_bonus") + " " + _format_multiplier(multiplier)

	var stat_key: String = "ui.happiness"
	match worker_type:
		"food":
			stat_key = "ui.satiety"
		"water":
			stat_key = "ui.hydration"
		"clean":
			stat_key = "ui.cleanliness"
		"play":
			stat_key = "ui.happiness"

	return prefix + ": +" + _format_decimal(effect_value) + " " + LocalizationSystem.tr_key(stat_key) + ", <" + str(threshold) + "%, " + str(interval) + "s"


func _try_buy_or_upgrade_worker(worker_id: String) -> void:
	var result: Dictionary = WorkerSystem.buy_or_upgrade_worker(worker_id)
	if not bool(result.get("success", false)):
		_show_message_popup(str(result.get("message_key", "ui.not_enough_currency")))
		return

	_show_workers_view()


func _populate_quests_list(parent: VBoxContainer) -> void:
	if not has_node("/root/QuestSystem"):
		parent.add_child(_make_popup_label(LocalizationSystem.tr_key("quests.no_quests"), 16))
		return

	var states: Array = QuestSystem.get_all_quests(false)
	if states.is_empty():
		parent.add_child(_make_popup_label(LocalizationSystem.tr_key("quests.no_quests"), 16))
		return

	for state_value in states:
		if typeof(state_value) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = state_value as Dictionary
		if not bool(state.get("is_active", true)) and not bool(state.get("claimed", false)):
			continue
		parent.add_child(_make_quest_card(state))


func _make_quest_card(state: Dictionary) -> Control:
	var card: Control = Control.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, QUEST_CARD_MIN_HEIGHT)

	var bg_tex: Texture2D = AssetPaths.load_texture(QUESTS_CARD_BG_PATH)
	if bg_tex != null:
		var background: TextureRect = TextureRect.new()
		background.name = "QuestCardBg"
		background.texture = bg_tex
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_SCALE
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(background)
	else:
		var bg_panel: PanelContainer = PanelContainer.new()
		bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_panel.add_theme_stylebox_override("panel", _make_card_style())
		bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(bg_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", QUEST_CARD_MARGIN)
	margin.add_theme_constant_override("margin_right", QUEST_CARD_MARGIN)
	margin.add_theme_constant_override("margin_top", QUEST_CARD_MARGIN)
	margin.add_theme_constant_override("margin_bottom", QUEST_CARD_MARGIN)
	card.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", QUEST_CARD_ROW_SEP)
	margin.add_child(row)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var title_label: Label = Label.new()
	title_label.text = LocalizationSystem.tr_key(str(state.get("title_key", "")))
	title_label.clip_text = true
	title_label.add_theme_font_size_override("font_size", QUEST_TEXT_TITLE_SIZE)
	_apply_label_color(title_label, POPUP_TEXT_PRIMARY)
	var title_wrap: MarginContainer = MarginContainer.new()
	title_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_wrap.add_theme_constant_override("margin_left", QUEST_CARD_TEXT_INDENT)
	title_wrap.add_child(title_label)
	info.add_child(title_wrap)

	var desc_label: Label = Label.new()
	desc_label.text = LocalizationSystem.tr_key(str(state.get("description_key", "")))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", QUEST_TEXT_DESC_SIZE)
	_apply_label_color(desc_label, POPUP_TEXT_SECONDARY)
	var desc_wrap: MarginContainer = MarginContainer.new()
	desc_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_wrap.add_theme_constant_override("margin_left", QUEST_CARD_TEXT_INDENT)
	desc_wrap.add_child(desc_label)
	info.add_child(desc_wrap)

	var current: int = int(state.get("current", 0))
	var target: int = max(1, int(state.get("target", 1)))
	var completed: bool = bool(state.get("completed", false))
	var displayed_current: int = target if completed else current

	var progress_label: Label = Label.new()
	progress_label.text = LocalizationSystem.tr_key("quests.progress") + ": " + str(displayed_current) + " / " + str(target)
	progress_label.add_theme_font_size_override("font_size", QUEST_TEXT_PROGRESS_SIZE)
	_apply_label_color(progress_label, POPUP_TEXT_ACCENT)
	var progress_label_wrap: MarginContainer = MarginContainer.new()
	progress_label_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_label_wrap.add_theme_constant_override("margin_left", QUEST_CARD_TEXT_INDENT)
	progress_label_wrap.add_child(progress_label)
	info.add_child(progress_label_wrap)

	var progress_bar: ProgressBar = ProgressBar.new()
	progress_bar.anchor_left = 0.0
	progress_bar.anchor_top = 0.0
	progress_bar.anchor_right = QUEST_PROGRESS_BAR_WIDTH_RATIO
	progress_bar.anchor_bottom = 1.0
	progress_bar.min_value = 0
	progress_bar.max_value = target
	progress_bar.value = displayed_current
	progress_bar.show_percentage = false
	if completed:
		progress_bar.add_theme_stylebox_override("fill", _make_progress_fill_style(Color(0.18, 0.68, 0.22, 1.0)))
		progress_bar.add_theme_stylebox_override("background", _make_progress_background_style(Color(0.13, 0.24, 0.12, 0.32)))
	var progress_bar_ctrl: Control = Control.new()
	progress_bar_ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar_ctrl.custom_minimum_size = Vector2(0, QUEST_PROGRESS_BAR_HEIGHT)
	progress_bar_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar_ctrl.add_child(progress_bar)
	var progress_bar_wrap: MarginContainer = MarginContainer.new()
	progress_bar_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar_wrap.add_theme_constant_override("margin_left", QUEST_CARD_TEXT_INDENT)
	progress_bar_wrap.add_child(progress_bar_ctrl)
	info.add_child(progress_bar_wrap)

	var reward_label: Label = Label.new()
	reward_label.text = _format_quest_reward(state)
	reward_label.add_theme_font_size_override("font_size", QUEST_TEXT_REWARD_SIZE)
	_apply_label_color(reward_label, POPUP_TEXT_SUCCESS)
	var reward_label_wrap: MarginContainer = MarginContainer.new()
	reward_label_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_label_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_label_wrap.add_theme_constant_override("margin_left", QUEST_CARD_TEXT_INDENT)
	reward_label_wrap.add_child(reward_label)
	info.add_child(reward_label_wrap)

	var action_area: VBoxContainer = VBoxContainer.new()
	action_area.custom_minimum_size = Vector2(QUEST_CLAIM_BTN_W + 8, 0)
	action_area.alignment = BoxContainer.ALIGNMENT_CENTER
	action_area.add_theme_constant_override("separation", 6)
	row.add_child(action_area)

	var action_right_spacer: Control = Control.new()
	action_right_spacer.custom_minimum_size = Vector2(QUEST_ACTION_RIGHT_PADDING, 0)
	action_right_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(action_right_spacer)

	var status_label: Label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", QUEST_TEXT_STATUS_SIZE)
	_apply_label_color(status_label, POPUP_TEXT_SECONDARY)
	action_area.add_child(status_label)

	if bool(state.get("claimed", false)):
		status_label.text = LocalizationSystem.tr_key("quests.claimed")
	elif bool(state.get("claimable", false)):
		status_label.text = LocalizationSystem.tr_key("quests.completed")
		var claim_tex: Texture2D = AssetPaths.load_texture(_get_quests_claim_button_path())
		if claim_tex != null:
			var claim_button: TextureButton = TextureButton.new()
			claim_button.name = "ClaimButton"
			claim_button.custom_minimum_size = Vector2(QUEST_CLAIM_BTN_W, QUEST_CLAIM_BTN_H)
			claim_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			claim_button.texture_normal = claim_tex
			claim_button.texture_hover = claim_tex
			claim_button.texture_pressed = claim_tex
			claim_button.texture_disabled = claim_tex
			claim_button.ignore_texture_size = true
			claim_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			claim_button.focus_mode = Control.FOCUS_NONE
			claim_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			claim_button.pressed.connect(func() -> void:
				_on_quest_claim_pressed(str(state.get("id", "")))
			)
			action_area.add_child(claim_button)
		else:
			var claim_button: Button = _make_owned_card_action_button("quests.claim")
			claim_button.pressed.connect(func() -> void:
				_on_quest_claim_pressed(str(state.get("id", "")))
			)
			action_area.add_child(claim_button)
	else:
		status_label.text = LocalizationSystem.tr_key("quests.in_progress")

	_make_scroll_safe(card)
	return card


func _make_owned_empty_state() -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("animals.empty_title"), 18)
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	column.add_child(title)

	var subtitle: Label = _make_popup_label(LocalizationSystem.tr_key("animals.empty_subtitle"), 14)
	_apply_label_color(subtitle, POPUP_TEXT_SECONDARY)
	column.add_child(subtitle)

	var open_shop: Button = _make_popup_button("animals.open_shop", func() -> void:
		_show_shop_view()
	)
	open_shop.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	open_shop.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	open_shop.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	_apply_button_text_color(open_shop, BUTTON_TEXT_COLOR)
	column.add_child(open_shop)

	_make_scroll_safe(card)
	return card


func _make_owned_reptile_card(instance: Dictionary) -> Control:
	var reptile_id: String = str(instance.get("reptile_id", ""))
	var reptile: Dictionary = ReptileSystem.get_reptile(reptile_id)
	var variant: Dictionary = ReptileSystem.get_owned_animal_variant(instance)
	var is_assigned: bool = _is_reptile_instance_assigned(instance)

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = _animals_card_bg_vec(0, 133)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_animals_single_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _animals_ui_size(12))
	margin.add_theme_constant_override("margin_right", _animals_ui_size(12))
	margin.add_theme_constant_override("margin_top", _animals_ui_size(12))
	margin.add_theme_constant_override("margin_bottom", _animals_ui_size(12))
	card.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", _animals_ui_size(12))
	margin.add_child(row)

	var _owned_icon: TextureRect = _make_fixed_texture(ReptileSystem.get_owned_animal_image_path(instance), _animals_image_vec(115, 115))
	_add_owned_reptile_level_badge(_owned_icon, instance)
	var _icon_shift: MarginContainer = MarginContainer.new()
	_icon_shift.add_theme_constant_override("margin_left", -_animals_ui_size(6))
	_icon_shift.add_theme_constant_override("margin_right", 0)
	_icon_shift.add_theme_constant_override("margin_top", 0)
	_icon_shift.add_theme_constant_override("margin_bottom", 0)
	_icon_shift.add_child(_owned_icon)
	row.add_child(_icon_shift)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", _animals_ui_size(4))
	row.add_child(info)

	var name_label: Label = Label.new()
	name_label.text = _get_reptile_display_name(instance, reptile)
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", _animals_text_size(16))
	_apply_label_color(name_label, POPUP_TEXT_PRIMARY)
	info.add_child(name_label)

	var species_label: Label = Label.new()
	species_label.text = LocalizationSystem.tr_key(str(reptile.get("name_key", reptile_id)))
	species_label.clip_text = true
	species_label.add_theme_font_size_override("font_size", _animals_text_size(12))
	_apply_label_color(species_label, POPUP_TEXT_SECONDARY)
	info.add_child(species_label)

	var owned_rarity: String = str(instance.get("rarity", str(variant.get("rarity", "common"))))
	var owned_rarity_icon: String = ReptileSystem.RARITY_ICON_PATHS.get(owned_rarity, str(variant.get("rarity_icon_path", "")))
	var rarity_row: HBoxContainer = _make_icon_text_row(owned_rarity_icon, LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(owned_rarity)), _animals_rarity_icon_size(28), _animals_text_size(12))
	info.add_child(rarity_row)

	var sex_icon_path: String = FEMALE_ICON_PATH if str(instance.get("sex", "male")) == "female" else MALE_ICON_PATH
	info.add_child(_make_icon_text_row(sex_icon_path, _get_localized_sex(str(instance.get("sex", "male"))), _animals_rarity_icon_size(28), _animals_text_size(12)))

	var status_icon_path: String = ASSIGNED_ICON_PATH if is_assigned else FREE_ICON_PATH
	var status_key: String = "animals.status.assigned" if is_assigned else "animals.status.free"
	info.add_child(_make_icon_text_row(status_icon_path, LocalizationSystem.tr_key(status_key), _animals_rarity_icon_size(28), _animals_text_size(12)))

	var action_offset: MarginContainer = MarginContainer.new()
	action_offset.add_theme_constant_override("margin_right", _animals_ui_size(112 * ANIMALS_CARD_ACTION_LEFT_SHIFT_RATIO))
	row.add_child(action_offset)

	var action_area: VBoxContainer = VBoxContainer.new()
	action_area.custom_minimum_size = _animals_ui_vec(112, 0)
	action_area.alignment = BoxContainer.ALIGNMENT_CENTER
	action_area.add_theme_constant_override("separation", _animals_ui_size(8))
	action_offset.add_child(action_area)

	var manage_button: Button = _make_owned_card_action_button("animals.manage")
	manage_button.pressed.connect(func() -> void:
		_close_animals_view()
		_show_management_for_instance_id(str(instance.get("instance_id", "")))
	)
	action_area.add_child(manage_button)

	if not is_assigned:
		var assign_button: Button = _make_owned_card_action_button("animals.assign")
		assign_button.pressed.connect(func() -> void:
			_show_assign_instance_to_habitat_popup(str(instance.get("instance_id", "")))
		)
		action_area.add_child(assign_button)

		var release_button: Button = _make_release_action_button("animals.release")
		var iid: String = str(instance.get("instance_id", ""))
		release_button.pressed.connect(func() -> void:
			_confirm_release_reptile(iid)
		)
		action_area.add_child(release_button)

	_make_scroll_safe(card)
	return card


func _add_owned_reptile_level_badge(parent: Control, instance: Dictionary) -> void:
	var level: int = ReptileSystem.get_reptile_level(instance)
	var badge_size: int = _animals_ui_size(43)
	var badge: PanelContainer = PanelContainer.new()
	badge.name = "ReptileLevelBadge"
	badge.custom_minimum_size = Vector2(badge_size, badge_size)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.position = Vector2(-_animals_ui_size(2), -_animals_ui_size(2))

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.78, 0.08, 0.06, 0.96)
	style.border_color = Color(1.0, 0.86, 0.62, 0.95)
	style.set_border_width_all(max(1, _animals_ui_size(1)))
	style.set_corner_radius_all(int(round(float(badge_size) * 0.5)))
	style.shadow_color = Color(0.10, 0.02, 0.01, 0.35)
	style.shadow_size = max(2, _animals_ui_size(3))
	badge.add_theme_stylebox_override("panel", style)
	parent.add_child(badge)

	var label: Label = Label.new()
	label.text = str(level)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", _animals_text_size(18))
	label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.18, 0.02, 0.01, 0.70))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)


func _populate_animals_gallery(parent: VBoxContainer) -> void:
	var discovered_count: int = _get_expected_gallery_discovered_count()
	var total_count: int = GALLERY_REPTILE_IDS.size() * GALLERY_RARITIES.size()
	var completion: int = int(round(float(discovered_count) / max(1.0, float(total_count)) * 100.0))

	var progress: Label = _make_popup_label(
		LocalizationSystem.tr_key("animals.gallery_progress") + "\n"
		+ LocalizationSystem.tr_key("animals.discovered") + ": " + str(discovered_count) + " / " + str(total_count) + "\n"
		+ LocalizationSystem.tr_key("animals.completion") + ": " + str(completion) + "%",
		_animals_gallery_content_size(_animals_text_size(14) + 5)
	)
	_apply_label_color(progress, POPUP_TEXT_ACCENT)
	_make_label_visually_bold(progress)
	parent.add_child(progress)

	for reptile_id_value in GALLERY_REPTILE_IDS:
		parent.add_child(_make_gallery_species_section(str(reptile_id_value)))


func _make_gallery_species_section(reptile_id: String) -> Control:
	var reptile: Dictionary = ReptileSystem.get_reptile(reptile_id)
	var section: PanelContainer = PanelContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_stylebox_override("panel", _make_animals_single_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _animals_ui_size(14))
	margin.add_theme_constant_override("margin_right", _animals_ui_size(14))
	margin.add_theme_constant_override("margin_top", _animals_ui_size(12))
	margin.add_theme_constant_override("margin_bottom", _animals_ui_size(12))
	section.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", _animals_ui_size(10))
	margin.add_child(column)

	var species_label: Label = Label.new()
	species_label.text = LocalizationSystem.tr_key(str(reptile.get("name_key", reptile_id)))
	species_label.clip_text = true
	species_label.add_theme_font_size_override("font_size", _animals_gallery_content_size(_animals_text_size(16)))
	_apply_label_color(species_label, POPUP_TEXT_PRIMARY)
	column.add_child(species_label)

	var slot_row: HBoxContainer = HBoxContainer.new()
	slot_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_row.add_theme_constant_override("separation", _animals_gallery_content_size(_animals_ui_size(8)))
	column.add_child(slot_row)

	for rarity_value in GALLERY_RARITIES:
		slot_row.add_child(_make_gallery_rarity_slot(reptile_id, str(rarity_value)))

	_make_scroll_safe(section)
	return section


func _make_gallery_rarity_slot(reptile_id: String, rarity: String) -> Control:
	var reptile: Dictionary = ReptileSystem.get_reptile(reptile_id)
	var variant: Dictionary = ReptileSystem.get_variant_for_reptile_rarity(reptile_id, rarity)
	var has_variant_data: bool = not variant.is_empty()
	var variant_id: String = str(variant.get("id", ""))
	var discovered: bool = has_variant_data and ReptileSystem.is_variant_discovered(variant_id)

	var slot: PanelContainer = PanelContainer.new()
	slot.custom_minimum_size = _animals_card_bg_vec(0, 168, ANIMALS_CARD_BACKGROUND_WIDTH_SCALE, ANIMALS_GALLERY_SLOT_BACKGROUND_HEIGHT_SCALE)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.add_theme_stylebox_override("panel", _make_gallery_slot_style(discovered))

	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margin.add_theme_constant_override("margin_left", _animals_gallery_content_size(_animals_ui_size(8)))
	margin.add_theme_constant_override("margin_right", _animals_gallery_content_size(_animals_ui_size(8)))
	margin.add_theme_constant_override("margin_top", _animals_ui_size(8))
	margin.add_theme_constant_override("margin_bottom", _animals_ui_size(8))
	slot.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", _animals_ui_size(4))
	margin.add_child(column)

	var image_path: String = _get_variant_image_path(reptile, variant, false) if discovered else _get_gallery_shadow_path(reptile_id, variant)
	var image: TextureRect = _make_fixed_texture(image_path, _animals_gallery_content_vec(_animals_image_vec(72, 72)))
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(image)

	var rarity_icon_path: String = str(variant.get("rarity_icon_path", ReptileSystem.get_rarity_icon_path(rarity))) if has_variant_data else ReptileSystem.get_rarity_icon_path(rarity)
	var rarity_row: HBoxContainer = HBoxContainer.new()
	rarity_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rarity_row.add_theme_constant_override("separation", _animals_ui_size(4))
	column.add_child(rarity_row)

	var rarity_icon_size: int = _animals_gallery_content_size(_animals_rarity_icon_size(22))
	var rarity_icon: TextureRect = _make_fixed_texture(rarity_icon_path, Vector2(rarity_icon_size, rarity_icon_size))
	rarity_row.add_child(rarity_icon)

	var rarity_label: Label = Label.new()
	rarity_label.text = LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(rarity))
	rarity_label.clip_text = true
	rarity_label.add_theme_font_size_override("font_size", _animals_gallery_content_size(_animals_text_size(11)))
	_apply_label_color(rarity_label, POPUP_TEXT_ACCENT)
	rarity_row.add_child(rarity_label)

	var state_key: String = "animals.discovered_state" if discovered else "animals.undiscovered_state"
	var state_label: Label = Label.new()
	state_label.text = LocalizationSystem.tr_key(state_key)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.clip_text = true
	state_label.add_theme_font_size_override("font_size", _animals_gallery_content_size(_animals_text_size(10)))
	_apply_label_color(state_label, POPUP_TEXT_SUCCESS if discovered else POPUP_TEXT_SECONDARY)
	column.add_child(state_label)

	_make_scroll_safe(slot)
	return slot


func _populate_animals_achievements(parent: VBoxContainer) -> void:
	if not has_node("/root/AchievementSystem"):
		var unavailable: Label = _make_popup_label(LocalizationSystem.tr_key("achievements.title"), 16)
		_apply_label_color(unavailable, POPUP_TEXT_SECONDARY)
		parent.add_child(unavailable)
		return

	var states: Array = AchievementSystem.get_achievement_states()
	for state_value in states:
		if typeof(state_value) != TYPE_DICTIONARY:
			continue

		parent.add_child(_make_achievement_card(state_value as Dictionary))


func _make_achievement_card(state: Dictionary) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = _animals_card_bg_vec(0, 142, ANIMALS_CARD_BACKGROUND_WIDTH_SCALE, ANIMALS_ACHIEVEMENT_CARD_BACKGROUND_HEIGHT_SCALE)
	card.add_theme_stylebox_override("panel", _make_animals_single_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margin.add_theme_constant_override("margin_left", _animals_ui_size(12))
	margin.add_theme_constant_override("margin_right", _animals_ui_size(12))
	margin.add_theme_constant_override("margin_top", _animals_ui_size(12))
	margin.add_theme_constant_override("margin_bottom", _animals_ui_size(12))
	card.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", _animals_ui_size(12))
	margin.add_child(row)

	var icon_path: String = str(state.get("icon_path", ""))
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		icon_path = "res://assets/art/ui/icons/achievements/buy_first_reptiles.png"
	var icon: TextureRect = _make_fixed_texture(icon_path, _animals_image_vec(72, 72))
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", _animals_ui_size(4))
	row.add_child(info)

	var title_label: Label = Label.new()
	title_label.text = LocalizationSystem.tr_key(str(state.get("title_key", "")))
	title_label.clip_text = true
	title_label.add_theme_font_size_override("font_size", _animals_text_size(16))
	_apply_label_color(title_label, POPUP_TEXT_PRIMARY)
	info.add_child(title_label)

	var desc_label: Label = Label.new()
	desc_label.text = LocalizationSystem.tr_key(str(state.get("description_key", "")))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", _animals_text_size(12))
	_apply_label_color(desc_label, POPUP_TEXT_SECONDARY)
	info.add_child(desc_label)

	var current: int = int(state.get("current", 0))
	var target: int = max(1, int(state.get("target", 1)))
	var completed: bool = bool(state.get("completed", false))
	var displayed_current: int = target if completed else current
	var progress_text: Label = Label.new()
	progress_text.text = LocalizationSystem.tr_key("achievements.progress") + ": " + str(displayed_current) + " / " + str(target)
	progress_text.add_theme_font_size_override("font_size", _animals_text_size(12))
	_apply_label_color(progress_text, POPUP_TEXT_ACCENT)
	info.add_child(progress_text)

	var progress_bar: ProgressBar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = target
	progress_bar.value = displayed_current
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = _animals_ui_vec(0, 16)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if completed:
		progress_bar.add_theme_stylebox_override("fill", _make_progress_fill_style(Color(0.18, 0.68, 0.22, 1.0)))
		progress_bar.add_theme_stylebox_override("background", _make_progress_background_style(Color(0.13, 0.24, 0.12, 0.32)))
	info.add_child(progress_bar)

	var reward_label: Label = Label.new()
	reward_label.text = _format_achievement_reward(state)
	reward_label.add_theme_font_size_override("font_size", _animals_text_size(12))
	_apply_label_color(reward_label, POPUP_TEXT_SUCCESS)
	info.add_child(reward_label)

	var action_area: VBoxContainer = VBoxContainer.new()
	action_area.custom_minimum_size = _animals_ui_vec(112, 0)
	action_area.alignment = BoxContainer.ALIGNMENT_CENTER
	action_area.add_theme_constant_override("separation", _animals_ui_size(6))
	row.add_child(action_area)

	var status_label: Label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", _animals_text_size(12))
	_apply_label_color(status_label, POPUP_TEXT_SECONDARY)
	action_area.add_child(status_label)

	if bool(state.get("claimed", false)):
		status_label.text = LocalizationSystem.tr_key("achievements.claimed")
	elif bool(state.get("claimable", false)):
		status_label.text = LocalizationSystem.tr_key("achievements.completed")
		var claim_button: Button = _make_owned_card_action_button("achievements.claim")
		claim_button.pressed.connect(func() -> void:
			_on_achievement_claim_pressed(str(state.get("id", "")))
		)
		action_area.add_child(claim_button)
	else:
		status_label.text = LocalizationSystem.tr_key("achievements.in_progress")

	_make_scroll_safe(card)
	return card


func _on_achievement_claim_pressed(achievement_id: String) -> void:
	var result: Dictionary = AchievementSystem.claim_achievement(achievement_id)
	if not bool(result.get("success", false)):
		_show_message_popup(str(result.get("message_key", "achievements.in_progress")))
		return

	_show_animals_view("achievements")
	_show_toast_raw(_format_achievement_claim_feedback(result))


func _format_achievement_reward(state: Dictionary) -> String:
	var pieces: Array[String] = []
	var reward_amount: float = float(state.get("reward_amount", 0.0))
	var reward_type: String = str(state.get("reward_type", "repticash"))
	if reward_amount > 0.0:
		var reward_label: String = LocalizationSystem.tr_key("currency.repticash") if reward_type == "repticash" else reward_type
		pieces.append(reward_label + " " + _format_decimal(reward_amount))

	var reward_xp: float = float(state.get("reward_xp", 0.0))
	if reward_xp > 0.0:
		pieces.append(_format_decimal(reward_xp) + " XP")

	return LocalizationSystem.tr_key("achievements.reward") + ": " + _join_text_pieces(pieces, " + ")


func _format_achievement_claim_feedback(result: Dictionary) -> String:
	var pieces: Array[String] = []
	var reward_amount: float = float(result.get("reward_amount", 0.0))
	var reward_type: String = str(result.get("reward_type", "repticash"))
	if reward_amount > 0.0:
		var reward_label: String = LocalizationSystem.tr_key("currency.repticash") if reward_type == "repticash" else reward_type
		pieces.append("+" + reward_label + " " + _format_decimal(reward_amount))

	var reward_xp: float = float(result.get("reward_xp", 0.0))
	if reward_xp > 0.0:
		pieces.append("+" + _format_decimal(reward_xp) + " XP")

	return _join_text_pieces(pieces, "  ")


func _format_quest_reward(state: Dictionary) -> String:
	var pieces: Array[String] = []
	var reward_amount: float = float(state.get("reward_amount", 0.0))
	var reward_type: String = str(state.get("reward_type", "repticash"))
	if reward_amount > 0.0:
		var reward_label: String = LocalizationSystem.tr_key("currency.repticash") if reward_type == "repticash" else reward_type.to_upper()
		pieces.append(reward_label + " " + _format_decimal(reward_amount))
	var reward_xp: float = float(state.get("reward_xp", 0.0))
	if reward_xp > 0.0:
		pieces.append(_format_decimal(reward_xp) + " XP")
	return LocalizationSystem.tr_key("quests.reward") + ": " + _join_text_pieces(pieces, " + ")


func _on_quest_claim_pressed(quest_id: String) -> void:
	var result: Dictionary = QuestSystem.claim_quest_reward(quest_id)
	if not bool(result.get("success", false)):
		_show_message_popup(str(result.get("message_key", "quests.in_progress")))
		return

	_show_quests_view()
	_show_toast_raw(_format_quest_claim_feedback(result))


func _format_quest_claim_feedback(result: Dictionary) -> String:
	var pieces: Array[String] = []
	var reward_amount: float = float(result.get("reward_amount", 0.0))
	var reward_type: String = str(result.get("reward_type", "repticash"))
	if reward_amount > 0.0:
		var reward_label: String = LocalizationSystem.tr_key("currency.repticash") if reward_type == "repticash" else reward_type.to_upper()
		pieces.append("+" + reward_label + " " + _format_decimal(reward_amount))
	var reward_xp: float = float(result.get("reward_xp", 0.0))
	if reward_xp > 0.0:
		pieces.append("+" + _format_decimal(reward_xp) + " XP")
	return _join_text_pieces(pieces, "  ")


func _join_text_pieces(pieces: Array[String], separator: String) -> String:
	var text := ""
	for piece in pieces:
		if text.is_empty():
			text = piece
		else:
			text += separator + piece

	return text


func _notify_quest_event(event_type: String, payload: Dictionary = {}) -> void:
	if has_node("/root/QuestSystem"):
		var quest_system: Node = get_node("/root/QuestSystem")
		if quest_system.has_method("notify_event"):
			quest_system.call("notify_event", event_type, payload)
	_refresh_next_step_widget()
	if has_node("/root/AchievementSystem"):
		var achievement_system: Node = get_node("/root/AchievementSystem")
		if achievement_system.has_method("notify_progress_changed"):
			achievement_system.call("notify_progress_changed")


func _notify_biome_opened() -> void:
	_notify_quest_event("screen_opened", {"screen": "biome"})


func _on_quest_state_changed(_quest_id: String = "") -> void:
	_refresh_next_step_widget()
	_update_quest_badge()


func _update_quest_badge() -> void:
	var nav: Control = get_node_or_null("BottomNav")
	if nav == null or not nav.has_method("update_quest_badge"):
		return
	var has_claimable: bool = has_node("/root/QuestSystem") and \
		not QuestSystem.get_completed_unclaimed_quests().is_empty()
	nav.update_quest_badge(has_claimable)


func _try_shop_buy_reptile(reptile_id: String, rarity: String, sex: String) -> void:
	var result: Dictionary = ReptileSystem.purchase_reptile_from_shop(reptile_id, rarity, sex)
	if not bool(result.get("success", false)):
		_show_message_popup(str(result.get("message_key", "ui.not_enough_currency")))
		return

	_show_shop_view()
	_notify_quest_event("reptile_purchased", {"reptile_id": reptile_id, "rarity": rarity, "sex": sex})
	if bool(result.get("new_variant_discovered", false)):
		_notify_quest_event("variant_discovered", {"variant_id": str(result.get("variant_id", ""))})
		pending_name_instance_id = str(result.get("instance_id", ""))
		_show_variant_discovery_popup(str(result.get("variant_id", "")), str(result.get("instance_id", "")))
	else:
		_show_reptile_name_popup(str(result.get("instance_id", "")), false)


func _close_shop_view() -> void:
	if shop_view == null:
		return

	shop_view.queue_free()
	shop_view = null


func _close_animals_view() -> void:
	if animals_view == null:
		return

	animals_view.queue_free()
	animals_view = null


func _close_quests_view() -> void:
	if quests_view == null:
		return

	quests_view.queue_free()
	quests_view = null


func _close_workers_view() -> void:
	if workers_view == null:
		return

	workers_view.queue_free()
	workers_view = null


func _close_upgrades_view() -> void:
	if upgrades_view == null:
		return

	upgrades_view.queue_free()
	upgrades_view = null


func _show_assign_instance_to_habitat_popup(instance_id: String) -> void:
	_close_reptile_selection_modal()

	reptile_selection_modal = Control.new()
	reptile_selection_modal.name = "AssignToHabitatModal"
	reptile_selection_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(reptile_selection_modal)

	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.04, 0.05, 0.04, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	reptile_selection_modal.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.5)
	reptile_selection_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 420)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("animals.assign"), 20)
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	column.add_child(title)

	var found_habitat: bool = false
	for habitat_value in habitat_data:
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue

		var habitat: Dictionary = habitat_value as Dictionary
		var habitat_id: String = str(habitat.get("id", ""))
		if _get_habitat_state(habitat_id) != STATE_PURCHASED_EMPTY:
			continue
		if _is_habitat_building(habitat_id):
			continue
		if _is_habitat_upgrading(habitat_id):
			continue

		found_habitat = true
		column.add_child(_make_assign_habitat_button(instance_id, habitat_id, int(habitat.get("slot_index", 0))))

	if not found_habitat:
		var empty_label: Label = _make_popup_label(LocalizationSystem.tr_key("animals.no_empty_habitats"), 14)
		_apply_label_color(empty_label, POPUP_TEXT_SECONDARY)
		column.add_child(empty_label)

	column.add_child(_make_popup_button("ui.cancel", func() -> void:
		_close_reptile_selection_modal()
	))


func _make_assign_habitat_button(instance_id: String, habitat_id: String, slot_index: int) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(0, 46)
	button.text = LocalizationSystem.tr_key("ui.habitat") + " " + str(slot_index + 1)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	_apply_button_text_color(button, BUTTON_TEXT_COLOR)
	button.pressed.connect(func() -> void:
		var result: Dictionary = ReptileSystem.assign_reptile_to_habitat(instance_id, habitat_id, biome_id)
		if not bool(result.get("success", false)):
			_show_message_popup(str(result.get("message_key", "ui.habitat_unavailable")))
			return

		_refresh_habitat_slots()
		_close_reptile_selection_modal()
		_notify_quest_event("reptile_assigned")
		_show_animals_view("owned")
	)
	return button


func _try_purchase_habitat(habitat_id: String, slot_index: int, habitat_type: String = "grass") -> void:
	var purchase_cost: int = EconomySystem.get_next_habitat_price(biome_id, habitat_data.size())
	if purchase_cost < 0:
		return

	if not EconomySystem.can_afford("repticash", purchase_cost):
		_show_message_popup("ui.not_enough_currency")
		return

	if not EconomySystem.spend_currency("repticash", purchase_cost):
		_show_message_popup("ui.not_enough_currency")
		return

	var now: int = Time.get_unix_time_from_system()
	var build_duration: int = ReptileSystem.get_habitat_build_duration_seconds(biome_id)
	var habitats: Dictionary = _get_habitats_state()
	habitats[habitat_id] = {
		"habitat_id": habitat_id,
		"biome_id": biome_id,
		"slot_index": slot_index,
		"purchased": true,
		"habitat_type": ReptileSystem.normalize_habitat_type(habitat_type),
		"habitat_level": 1,
		"is_building": true,
		"build_started_at": now,
		"build_finish_at": now + build_duration,
		"is_upgrading": false,
		"upgrade_target_level": 0,
		"upgrade_started_at": 0,
		"upgrade_finish_at": 0,
		"habitat_variant_id": "default",
		"habitat_skin_id": "default",
		"reptile_id": "",
		"reptile_instance_id": "",
		"animal_instance_id": ""
	}
	GameState.set_value("habitats", habitats)
	SaveSystem.save_game()
	_refresh_habitat_slots()
	_notify_quest_event("habitat_purchased")
	_close_habitat_purchase_modal()

	if action_popup != null:
		action_popup.hide()


func _ensure_ui_modal_layer() -> CanvasLayer:
	if ui_modal_layer != null and is_instance_valid(ui_modal_layer):
		return ui_modal_layer

	ui_modal_layer = CanvasLayer.new()
	ui_modal_layer.name = "UiModalLayer"
	ui_modal_layer.layer = UI_MODAL_CANVAS_LAYER
	add_child(ui_modal_layer)
	return ui_modal_layer


func _prepare_fullscreen_modal_root(modal: Control) -> void:
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.anchor_right = 1.0
	modal.anchor_bottom = 1.0
	modal.offset_left = 0.0
	modal.offset_top = 0.0
	modal.offset_right = 0.0
	modal.offset_bottom = 0.0
	modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	modal.mouse_filter = Control.MOUSE_FILTER_STOP


func _add_to_ui_modal_layer(modal: Control) -> void:
	_ensure_ui_modal_layer()
	_prepare_fullscreen_modal_root(modal)
	ui_modal_layer.add_child(modal)
	modal.move_to_front()


func _make_modal_dim_overlay(alpha: float = 0.34) -> ColorRect:
	var overlay: ColorRect = ColorRect.new()
	overlay.name = "DimOverlay"
	overlay.color = Color(0.04, 0.05, 0.04, alpha)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	return overlay


func _show_message_popup(message_key: String) -> void:
	_show_feedback_modal("", LocalizationSystem.tr_key(message_key), "ui.ok", false)


func _show_message_text_popup(message: String) -> void:
	_show_feedback_modal("", message, "ui.ok", false)


func _show_reward_claim_feedback_popup(reward_text: String, title_key: String) -> void:
	_show_feedback_modal(LocalizationSystem.tr_key(title_key), reward_text, "ui.ok", true)


func _show_upgrade_blocked_popup() -> void:
	_show_feedback_modal(LocalizationSystem.tr_key("habitat.upgrade_blocked_title"), LocalizationSystem.tr_key("habitat.remove_reptile_first"), "ui.ok", false, 1.5)


func _add_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.name = "BiomeToastPanel"
	_toast_panel.z_index = 200
	_toast_panel.anchor_left = 0.5
	_toast_panel.anchor_top = 0.0
	_toast_panel.anchor_right = 0.5
	_toast_panel.anchor_bottom = 0.0
	_toast_panel.offset_left = -326.0
	_toast_panel.offset_top = float(TOP_BAR_HEIGHT) + 8.0
	_toast_panel.offset_right = 326.0
	_toast_panel.offset_bottom = float(TOP_BAR_HEIGHT) + 88.0
	_toast_panel.custom_minimum_size = Vector2(652.0, 0.0)
	_toast_panel.grow_vertical = Control.GROW_DIRECTION_END
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.07, 0.04, 0.92)
	style.border_color = Color(0.80, 0.62, 0.25, 0.90)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 11.0
	style.content_margin_bottom = 11.0
	_toast_panel.add_theme_stylebox_override("panel", style)

	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 32)
	_toast_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.add_child(_toast_label)

	add_child(_toast_panel)


func _show_toast_raw(text: String) -> void:
	if _toast_panel == null or _toast_label == null:
		return
	_toast_label.text = text
	_toast_panel.visible = true
	_toast_panel.move_to_front()
	_toast_timer = get_tree().create_timer(3.5)
	_toast_timer.timeout.connect(func() -> void:
		if is_instance_valid(_toast_panel):
			_toast_panel.visible = false
		_toast_timer = null
	)


func _show_feedback_modal(title_text: String, message_text: String, ok_key: String = "ui.ok", reward_style: bool = false, ui_scale: float = 1.0) -> void:
	_close_feedback_modal()
	ui_scale = max(0.5, ui_scale)

	feedback_modal = Control.new()
	feedback_modal.name = "FeedbackModal"
	_add_to_ui_modal_layer(feedback_modal)

	var overlay: ColorRect = _make_modal_dim_overlay(0.34)
	feedback_modal.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 26
	center.offset_right = -26
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.35)
	feedback_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	var panel_height: float = 230.0 if reward_style else 210.0
	panel.custom_minimum_size = Vector2(410, panel_height) * ui_scale
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(round(22.0 * ui_scale)))
	margin.add_theme_constant_override("margin_right", int(round(22.0 * ui_scale)))
	margin.add_theme_constant_override("margin_top", int(round(20.0 * ui_scale)))
	margin.add_theme_constant_override("margin_bottom", int(round(20.0 * ui_scale)))
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", int(round(12.0 * ui_scale)))
	margin.add_child(column)

	if not title_text.is_empty():
		var title: Label = _make_popup_label(title_text, int(round(21.0 * ui_scale)))
		_apply_label_color(title, POPUP_TEXT_PRIMARY)
		column.add_child(title)

	var message_font_size: int = int(round((18.0 if reward_style else 16.0) * ui_scale))
	var message: Label = _make_popup_label(message_text, message_font_size)
	_apply_label_color(message, POPUP_TEXT_SUCCESS if reward_style else POPUP_TEXT_PRIMARY)
	column.add_child(message)

	var ok_button: Button = _make_popup_button(ok_key, func() -> void:
		_close_feedback_modal()
	)
	_style_primary_action_button(ok_button)
	ok_button.custom_minimum_size = Vector2(0, 44.0 * ui_scale)
	ok_button.add_theme_font_size_override("font_size", int(round(14.0 * ui_scale)))
	column.add_child(ok_button)


func _show_level_up_popup(levels: Array, reward_amount: float) -> void:
	if levels.is_empty():
		return

	_close_level_up_modal()
	level_up_modal = Control.new()
	level_up_modal.name = "LevelUpModal"
	_add_to_ui_modal_layer(level_up_modal)

	var overlay: ColorRect = _make_modal_dim_overlay(0.46)
	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			_close_level_up_modal()
	)
	level_up_modal.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.35)
	level_up_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 290)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var new_level: int = int(levels[levels.size() - 1])
	var title: Label = _make_popup_label(LocalizationSystem.tr_key("player.level_up_title"), 22)
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	column.add_child(title)

	var message: Label = _make_popup_label(LocalizationSystem.tr_key("player.level_up_message").replace("{level}", str(new_level)), 16)
	_apply_label_color(message, POPUP_TEXT_SECONDARY)
	column.add_child(message)

	var reward: Label = _make_popup_label(LocalizationSystem.tr_key("player.level_reward").replace("{amount}", _format_decimal(reward_amount)), 17)
	_apply_label_color(reward, POPUP_TEXT_SUCCESS)
	column.add_child(reward)

	var ok_button: Button = _make_popup_button("player.level_up_ok", func() -> void:
		_close_level_up_modal()
	)
	_style_primary_action_button(ok_button)
	column.add_child(ok_button)


func _show_confirmation_popup(message_key: String, confirm_key: String, callback: Callable) -> void:
	_show_styled_confirmation_popup("", message_key, confirm_key, "ui.cancel", callback)


func _show_styled_confirmation_popup(title_key: String, message_key: String, confirm_key: String, cancel_key: String, callback: Callable) -> void:
	_close_confirmation_modal()

	confirmation_modal = Control.new()
	confirmation_modal.name = "ConfirmationModal"
	_add_to_ui_modal_layer(confirmation_modal)

	var overlay: ColorRect = _make_modal_dim_overlay(0.46)
	confirmation_modal.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.35)
	confirmation_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 270)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	if not title_key.is_empty():
		var title: Label = _make_popup_label(LocalizationSystem.tr_key(title_key), 21)
		_apply_label_color(title, POPUP_TEXT_PRIMARY)
		column.add_child(title)

	var message: Label = _make_popup_label(LocalizationSystem.tr_key(message_key), 15)
	_apply_label_color(message, POPUP_TEXT_PRIMARY)
	column.add_child(message)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)

	var cancel_button: Button = _make_popup_button(cancel_key, func() -> void:
		_close_confirmation_modal()
	)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_text_color(cancel_button, POPUP_TEXT_PRIMARY)
	actions.add_child(cancel_button)

	var confirm_button: Button = _make_popup_button(confirm_key, func() -> void:
		_close_confirmation_modal()
		callback.call()
	)
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_primary_action_button(confirm_button)
	actions.add_child(confirm_button)


func _confirm_remove_reptile(habitat_id: String) -> void:
	_show_confirmation_popup("habitat.remove_reptile_confirm", "habitat.remove_reptile", func() -> void:
		_try_remove_reptile_from_habitat(habitat_id)
	)


func _confirm_release_reptile(instance_id: String) -> void:
	_show_styled_confirmation_popup(
		"animals.release_confirm_title",
		"animals.release_confirm",
		"animals.release",
		"ui.cancel",
		func() -> void: _try_release_reptile(instance_id)
	)


func _try_release_reptile(instance_id: String) -> void:
	var result: Dictionary = ReptileSystem.release_reptile_instance(instance_id)
	if not bool(result.get("success", false)):
		_show_message_popup(str(result.get("message_key", "ui.error")))
		return
	_show_animals_view("owned")
	_show_toast_raw(LocalizationSystem.tr_key("animals.released_toast"))


func _try_remove_reptile_from_habitat(habitat_id: String) -> void:
	var result: Dictionary = ReptileSystem.remove_reptile_from_habitat(habitat_id)
	if not bool(result.get("success", false)):
		_show_message_popup(str(result.get("message_key", "ui.habitat_unavailable")))
		return

	_refresh_habitat_slots()
	_close_management_modal()
	_show_habitat_management_popup(habitat_id)


func _confirm_habitat_upgrade(habitat_id: String) -> void:
	var habitat: Dictionary = _get_saved_habitat_state(habitat_id)
	if _habitat_has_assigned_reptile(habitat):
		_show_upgrade_blocked_popup()
		return

	_show_styled_confirmation_popup("habitat.upgrade_confirm_title", "habitat.upgrade_confirm_message", "habitat.upgrade_confirm_button", "ui.cancel", func() -> void:
		_try_start_habitat_upgrade(habitat_id)
	)


func _try_start_habitat_upgrade(habitat_id: String) -> void:
	var result: Dictionary = ReptileSystem.start_habitat_upgrade(habitat_id)
	if not bool(result.get("success", false)):
		if str(result.get("message_key", "")) == "habitat.remove_reptile_first":
			_show_upgrade_blocked_popup()
			return
		_show_message_popup(str(result.get("message_key", "ui.habitat_unavailable")))
		return

	_refresh_habitat_slots()
	_show_habitat_management_popup(habitat_id)
	if bool(result.get("animal_removed", false)):
		_show_message_popup("habitat.temporarily_removed_animal")


func _confirm_remove_habitat(habitat_id: String) -> void:
	_show_styled_confirmation_popup("habitat.remove_confirm_title", "habitat.remove_confirm_message", "habitat.remove_confirm_button", "ui.cancel", func() -> void:
		_try_remove_habitat(habitat_id)
	)


func _try_remove_habitat(habitat_id: String) -> void:
	var result: Dictionary = ReptileSystem.remove_habitat(habitat_id)
	if not bool(result.get("success", false)):
		_show_message_popup(str(result.get("message_key", "ui.habitat_unavailable")))
		return

	_refresh_habitat_slots()
	_close_management_modal()


func _show_variant_discovery_popup(variant_id: String, instance_id: String = "") -> void:
	_close_variant_discovery_modal()

	var variant: Dictionary = ReptileSystem.get_variant(variant_id)
	var reptile: Dictionary = ReptileSystem.get_reptile(str(variant.get("reptile_id", "")))
	var discovered_sex: String = _get_discovered_instance_sex(instance_id)

	variant_discovery_modal = Control.new()
	variant_discovery_modal.name = "VariantDiscoveryModal"
	_add_to_ui_modal_layer(variant_discovery_modal)

	var overlay: ColorRect = _make_modal_dim_overlay(0.66)
	variant_discovery_modal.add_child(overlay)

	var background_texture: Texture2D = AssetPaths.load_texture(DISCOVERY_POPUP_BG_PATH)
	if background_texture == null:
		push_warning("BiomeView: missing discovery popup background: " + DISCOVERY_POPUP_BG_PATH)
		_build_discovery_popup_legacy(variant, reptile, discovered_sex)
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var reference_scale: float = min(viewport_size.x / DISCOVERY_POPUP_REF_SIZE.x, viewport_size.y / DISCOVERY_POPUP_REF_SIZE.y) * DISCOVERY_POPUP_WINDOW_SCALE
	var reference_origin: Vector2 = (viewport_size - DISCOVERY_POPUP_REF_SIZE * reference_scale) * 0.5

	var background: TextureRect = TextureRect.new()
	background.texture = background_texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	variant_discovery_modal.add_child(background)
	_position_reference_control(background, DISCOVERY_POPUP_REF_SIZE * 0.5, DISCOVERY_POPUP_REF_SIZE, reference_origin, reference_scale)

	var rarity_icon_tex: Texture2D = AssetPaths.load_texture(str(variant.get("rarity_icon_path", "")))
	if rarity_icon_tex != null:
		var rarity_icon: TextureRect = TextureRect.new()
		rarity_icon.texture = rarity_icon_tex
		rarity_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rarity_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rarity_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		variant_discovery_modal.add_child(rarity_icon)
		_position_reference_control(rarity_icon, DISCOVERY_POPUP_ICON_CENTER, DISCOVERY_POPUP_ICON_REF_SIZE, reference_origin, reference_scale)

	_add_habitat_options_label(variant_discovery_modal, LocalizationSystem.tr_key("ui.new_rarity_discovered"), DISCOVERY_POPUP_TITLE_CENTER, DISCOVERY_POPUP_TITLE_REF_SIZE, 39, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER, reference_origin, reference_scale, true)

	var portrait_tex: Texture2D = AssetPaths.load_texture(_get_variant_image_path(reptile, variant, false))
	if portrait_tex != null:
		var portrait: TextureRect = TextureRect.new()
		portrait.texture = portrait_tex
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		variant_discovery_modal.add_child(portrait)
		_position_reference_control(portrait, DISCOVERY_POPUP_PORTRAIT_CENTER, DISCOVERY_POPUP_PORTRAIT_REF_SIZE, reference_origin, reference_scale)

	var species_text: String = LocalizationSystem.tr_key("reptile.species") + ": " + LocalizationSystem.tr_key(str(reptile.get("name_key", "")))
	_add_habitat_options_label(variant_discovery_modal, species_text, Vector2(DISCOVERY_POPUP_DETAIL_CENTER_X, DISCOVERY_POPUP_SPECIES_Y), DISCOVERY_POPUP_DETAIL_REF_SIZE, 31, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER, reference_origin, reference_scale, false)

	var variant_text: String = LocalizationSystem.tr_key("reptile.variant") + ": " + LocalizationSystem.tr_key(str(variant.get("name_key", "")))
	_add_habitat_options_label(variant_discovery_modal, variant_text, Vector2(DISCOVERY_POPUP_DETAIL_CENTER_X, DISCOVERY_POPUP_VARIANT_Y), DISCOVERY_POPUP_DETAIL_REF_SIZE, 31, POPUP_TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_CENTER, reference_origin, reference_scale, false)

	var sex_text: String = LocalizationSystem.tr_key("ui.sex") + ": " + _get_localized_sex(discovered_sex)
	_add_habitat_options_label(variant_discovery_modal, sex_text, Vector2(DISCOVERY_POPUP_DETAIL_CENTER_X, DISCOVERY_POPUP_SEX_Y), DISCOVERY_POPUP_DETAIL_REF_SIZE, 31, POPUP_TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_CENTER, reference_origin, reference_scale, false)

	var rarity_text: String = LocalizationSystem.tr_key("reptile.rarity") + ": " + LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(str(variant.get("rarity", "common"))))
	_add_habitat_options_label(variant_discovery_modal, rarity_text, Vector2(DISCOVERY_POPUP_DETAIL_CENTER_X, DISCOVERY_POPUP_RARITY_Y), DISCOVERY_POPUP_DETAIL_REF_SIZE, 31, POPUP_TEXT_ACCENT, HORIZONTAL_ALIGNMENT_CENTER, reference_origin, reference_scale, false)

	_add_habitat_options_button(variant_discovery_modal, LocalizationSystem.tr_key("ui.ok"), DISCOVERY_POPUP_OK_CENTER, DISCOVERY_POPUP_OK_REF_SIZE, 34, _close_variant_discovery_modal, reference_origin, reference_scale)


func _build_discovery_popup_legacy(variant: Dictionary, reptile: Dictionary, discovered_sex: String) -> void:
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.5)
	variant_discovery_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 580)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("ui.new_rarity_discovered"), 21)
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	column.add_child(title)

	var portrait_frame: PanelContainer = PanelContainer.new()
	portrait_frame.custom_minimum_size = DISCOVERY_PORTRAIT_SIZE
	portrait_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_frame.clip_contents = true
	portrait_frame.add_theme_stylebox_override("panel", _make_portrait_frame_style())
	column.add_child(portrait_frame)

	var portrait: TextureRect = TextureRect.new()
	portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.offset_left = 8
	portrait.offset_top = 8
	portrait.offset_right = -8
	portrait.offset_bottom = -8
	portrait.texture = AssetPaths.load_texture(_get_variant_image_path(reptile, variant, false))
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_frame.add_child(portrait)

	var reptile_label: Label = _make_popup_label(LocalizationSystem.tr_key(str(reptile.get("name_key", ""))), 15)
	_apply_label_color(reptile_label, POPUP_TEXT_SECONDARY)
	column.add_child(reptile_label)

	var sex_label: Label = _make_popup_label(LocalizationSystem.tr_key("ui.sex") + ": " + _get_localized_sex(discovered_sex), 15)
	_apply_label_color(sex_label, POPUP_TEXT_SECONDARY)
	column.add_child(sex_label)

	var rarity_block: VBoxContainer = VBoxContainer.new()
	rarity_block.alignment = BoxContainer.ALIGNMENT_CENTER
	rarity_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rarity_block.add_theme_constant_override("separation", 4)
	column.add_child(rarity_block)

	var rarity_icon: TextureRect = _make_rarity_icon(str(variant.get("rarity_icon_path", "")), DISCOVERY_RARITY_ICON_SIZE)
	rarity_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rarity_block.add_child(rarity_icon)

	var rarity_label: Label = _make_popup_label(LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(str(variant.get("rarity", "common")))), 14)
	rarity_label.custom_minimum_size = Vector2(180, 0)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	rarity_label.clip_text = false
	_apply_label_color(rarity_label, POPUP_TEXT_ACCENT)
	rarity_block.add_child(rarity_label)

	var ok_button: Button = _make_popup_button("ui.ok", _close_variant_discovery_modal)
	ok_button.custom_minimum_size = Vector2(0, 48)
	ok_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	ok_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	ok_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	_apply_button_text_color(ok_button, BUTTON_TEXT_COLOR)
	column.add_child(ok_button)


func _show_reptile_name_popup(instance_id: String, edit_mode: bool) -> void:
	_close_naming_modal()
	if instance_id.is_empty():
		return

	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var instance_value: Variant = instances.get(instance_id, {})
	if typeof(instance_value) != TYPE_DICTIONARY:
		return

	var instance: Dictionary = instance_value as Dictionary
	var reptile: Dictionary = ReptileSystem.get_reptile(str(instance.get("reptile_id", "")))

	naming_modal = Control.new()
	naming_modal.name = "ReptileNamingModal"
	_add_to_ui_modal_layer(naming_modal)
	_set_management_modal_input_blocked(true)

	var overlay: ColorRect = _make_modal_dim_overlay(0.66)
	naming_modal.add_child(overlay)

	var background_texture: Texture2D = AssetPaths.load_texture(NAME_POPUP_BG_PATH)
	if background_texture == null:
		push_warning("BiomeView: missing name popup background: " + NAME_POPUP_BG_PATH)
		_build_name_popup_legacy(instance_id, instance, reptile, edit_mode)
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var reference_scale: float = min(viewport_size.x / NAME_POPUP_REF_SIZE.x, viewport_size.y / NAME_POPUP_REF_SIZE.y) * NAME_POPUP_WINDOW_SCALE
	var reference_origin: Vector2 = (viewport_size - NAME_POPUP_REF_SIZE * reference_scale) * 0.5

	var background: TextureRect = TextureRect.new()
	background.texture = background_texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	naming_modal.add_child(background)
	_position_reference_control(background, NAME_POPUP_REF_SIZE * 0.5, NAME_POPUP_REF_SIZE, reference_origin, reference_scale)

	var title_key: String = "ui.rename_reptile" if edit_mode else "ui.name_reptile"
	_add_habitat_options_label(naming_modal, LocalizationSystem.tr_key(title_key), NAME_POPUP_TITLE_CENTER, NAME_POPUP_TITLE_REF_SIZE, NAME_POPUP_TITLE_FONT_SIZE, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER, reference_origin, reference_scale, true)

	var portrait_tex: Texture2D = AssetPaths.load_texture(ReptileSystem.get_owned_animal_image_path(instance))
	if portrait_tex != null:
		var portrait: TextureRect = TextureRect.new()
		portrait.texture = portrait_tex
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		naming_modal.add_child(portrait)
		_position_reference_control(portrait, NAME_POPUP_PORTRAIT_CENTER, NAME_POPUP_PORTRAIT_REF_SIZE, reference_origin, reference_scale)

	var species_name: String = LocalizationSystem.tr_key(str(reptile.get("name_key", "")))
	_add_habitat_options_label(naming_modal, species_name, NAME_POPUP_SPECIES_CENTER, NAME_POPUP_SPECIES_REF_SIZE, NAME_POPUP_SPECIES_FONT_SIZE, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_LEFT, reference_origin, reference_scale, false)

	_add_habitat_options_label(naming_modal, LocalizationSystem.tr_key("ui.reptile_name_prompt"), NAME_POPUP_PROMPT_CENTER, NAME_POPUP_PROMPT_REF_SIZE, NAME_POPUP_PROMPT_FONT_SIZE, POPUP_TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_CENTER, reference_origin, reference_scale, false)

	var input: LineEdit = LineEdit.new()
	input.name = "NameInput"
	input.placeholder_text = LocalizationSystem.tr_key("ui.reptile_name_placeholder")
	input.max_length = NAME_MAX_LENGTH
	input.text = str(instance.get("custom_name", "")) if edit_mode else ""
	input.add_theme_font_size_override("font_size", int(round(float(NAME_POPUP_INPUT_FONT_SIZE) * reference_scale)))
	input.add_theme_color_override("font_color", POPUP_TEXT_PRIMARY)
	input.add_theme_color_override("font_placeholder_color", Color(POPUP_TEXT_SECONDARY.r, POPUP_TEXT_SECONDARY.g, POPUP_TEXT_SECONDARY.b, 0.55))
	var input_style: StyleBoxFlat = StyleBoxFlat.new()
	input_style.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	input_style.draw_center = false
	input.add_theme_stylebox_override("normal", input_style)
	input.add_theme_stylebox_override("focus", input_style)
	naming_modal.add_child(input)
	_position_reference_control(input, NAME_POPUP_INPUT_CENTER, NAME_POPUP_INPUT_REF_SIZE, reference_origin, reference_scale)

	var validation_label: Label = Label.new()
	validation_label.name = "ValidationLabel"
	validation_label.visible = false
	validation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	validation_label.add_theme_font_size_override("font_size", int(round(float(NAME_POPUP_VALIDATION_FONT_SIZE) * reference_scale)))
	_apply_label_color(validation_label, Color(0.62, 0.12, 0.08, 1.0))
	naming_modal.add_child(validation_label)
	_position_reference_control(validation_label,
		Vector2(NAME_POPUP_INPUT_CENTER.x, NAME_POPUP_INPUT_CENTER.y + NAME_POPUP_INPUT_REF_SIZE.y * 0.5 + 22.0),
		Vector2(NAME_POPUP_INPUT_REF_SIZE.x, 36.0),
		reference_origin, reference_scale)

	var cancel_key: String = "ui.cancel" if edit_mode else "ui.skip"
	var cancel_btn: Button = _make_reference_hitbox_button(func() -> void:
		if not edit_mode:
			SaveSystem.save_game()
		_close_naming_modal()
	)
	naming_modal.add_child(cancel_btn)
	_position_reference_control(cancel_btn, NAME_POPUP_CANCEL_CENTER, NAME_POPUP_CANCEL_REF_SIZE, reference_origin, reference_scale)
	var cancel_lbl: Label = _make_reference_label(LocalizationSystem.tr_key(cancel_key), NAME_POPUP_CANCEL_FONT_SIZE, POPUP_TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER, reference_scale)
	cancel_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	cancel_btn.add_child(cancel_lbl)

	var save_btn: Button = _make_reference_hitbox_button(func() -> void:
		var normalized_name: String = _sanitize_reptile_name(input.text)
		if not edit_mode and normalized_name.is_empty():
			_show_name_validation(validation_label, "ui.name_required_or_skip")
			return
		if normalized_name.length() > NAME_MAX_LENGTH:
			_show_name_validation(validation_label, "ui.name_too_long")
			return
		if ReptileSystem.set_reptile_custom_name(instance_id, normalized_name):
			if not normalized_name.is_empty():
				_notify_quest_event("reptile_named", {"instance_id": instance_id})
			_refresh_habitat_slots()
			_close_naming_modal()
			if edit_mode:
				_show_management_for_instance_id(instance_id, false)
	)
	naming_modal.add_child(save_btn)
	_position_reference_control(save_btn, NAME_POPUP_SAVE_CENTER, NAME_POPUP_SAVE_REF_SIZE, reference_origin, reference_scale)
	var save_lbl: Label = _make_reference_label(LocalizationSystem.tr_key("ui.save"), NAME_POPUP_SAVE_FONT_SIZE, BUTTON_TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, reference_scale)
	save_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	save_btn.add_child(save_lbl)

	input.grab_focus()


func _build_name_popup_legacy(instance_id: String, instance: Dictionary, reptile: Dictionary, edit_mode: bool) -> void:
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.5)
	naming_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 390)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title_key: String = "ui.rename_reptile" if edit_mode else "ui.name_reptile"
	var title: Label = _make_popup_label(LocalizationSystem.tr_key(title_key), 21)
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	column.add_child(title)

	var context_row: HBoxContainer = HBoxContainer.new()
	context_row.add_theme_constant_override("separation", 12)
	column.add_child(context_row)

	var icon: TextureRect = _make_fixed_texture(ReptileSystem.get_owned_animal_image_path(instance), Vector2(76, 76))
	context_row.add_child(icon)

	var context_info: VBoxContainer = VBoxContainer.new()
	context_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	context_info.add_theme_constant_override("separation", 4)
	context_row.add_child(context_info)

	var species_label: Label = _make_popup_label(LocalizationSystem.tr_key(str(reptile.get("name_key", "ui.reptile_management_placeholder"))), 15)
	species_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	species_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	species_label.clip_text = true
	_apply_label_color(species_label, POPUP_TEXT_PRIMARY)
	context_info.add_child(species_label)

	var prompt: Label = _make_popup_label(LocalizationSystem.tr_key("ui.reptile_name_prompt"), 14)
	_apply_label_color(prompt, POPUP_TEXT_SECONDARY)
	column.add_child(prompt)

	var input: LineEdit = LineEdit.new()
	input.name = "NameInput"
	input.custom_minimum_size = Vector2(0, 44)
	input.placeholder_text = LocalizationSystem.tr_key("ui.reptile_name_placeholder")
	input.max_length = NAME_MAX_LENGTH
	input.text = str(instance.get("custom_name", "")) if edit_mode else ""
	column.add_child(input)

	var validation_label: Label = _make_popup_label("", 12)
	validation_label.name = "ValidationLabel"
	validation_label.visible = false
	_apply_label_color(validation_label, Color(0.62, 0.12, 0.08, 1.0))
	column.add_child(validation_label)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)

	var cancel_key: String = "ui.cancel" if edit_mode else "ui.skip"
	var cancel_button: Button = _make_popup_button(cancel_key, func() -> void:
		if not edit_mode:
			SaveSystem.save_game()
		_close_naming_modal()
	)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(cancel_button)

	var save_button: Button = _make_popup_button("ui.save", func() -> void:
		var normalized_name: String = _sanitize_reptile_name(input.text)
		if not edit_mode and normalized_name.is_empty():
			_show_name_validation(validation_label, "ui.name_required_or_skip")
			return
		if normalized_name.length() > NAME_MAX_LENGTH:
			_show_name_validation(validation_label, "ui.name_too_long")
			return
		if ReptileSystem.set_reptile_custom_name(instance_id, normalized_name):
			if not normalized_name.is_empty():
				_notify_quest_event("reptile_named", {"instance_id": instance_id})
			_refresh_habitat_slots()
			_close_naming_modal()
			if edit_mode:
				_show_management_for_instance_id(instance_id, false)
	)
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	save_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	save_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	_apply_button_text_color(save_button, BUTTON_TEXT_COLOR)
	buttons.add_child(save_button)

	input.grab_focus()


func _show_name_validation(label: Label, message_key: String) -> void:
	label.text = LocalizationSystem.tr_key(message_key)
	label.visible = true


func _sanitize_reptile_name(raw_name: String) -> String:
	var sanitized: String = raw_name.replace("\r", " ").replace("\n", " ").strip_edges()
	while sanitized.find("  ") != -1:
		sanitized = sanitized.replace("  ", " ")
	return sanitized


func _create_action_popup() -> PopupPanel:
	if action_popup != null:
		action_popup.queue_free()

	action_popup = PopupPanel.new()
	action_popup.name = "HabitatActionPopup"
	action_popup.add_theme_stylebox_override("panel", _make_modal_panel_style())
	add_child(action_popup)
	return action_popup


func _add_popup_column(popup: PopupPanel) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	popup.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	return column


func _make_popup_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	_apply_label_color(label, POPUP_TEXT_PRIMARY)
	return label


func _make_label_visually_bold(label: Label) -> void:
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_outline_color", label.get_theme_color("font_color"))


func _make_popup_button(key: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = LocalizationSystem.tr_key(key)
	button.custom_minimum_size = Vector2(0, 44)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_ALL
	_apply_button_text_color(button, POPUP_TEXT_PRIMARY)
	button.pressed.connect(callback)
	return button


func _close_reptile_selection_modal() -> void:
	if reptile_selection_modal == null:
		return

	reptile_selection_modal.queue_free()
	reptile_selection_modal = null


func _close_feedback_modal() -> void:
	if feedback_modal == null:
		return

	feedback_modal.queue_free()
	feedback_modal = null


func _close_confirmation_modal() -> void:
	if confirmation_modal == null:
		return

	confirmation_modal.queue_free()
	confirmation_modal = null


func _close_level_up_modal() -> void:
	if level_up_modal == null:
		return

	level_up_modal.queue_free()
	level_up_modal = null


func _close_management_modal() -> void:
	if management_modal == null:
		return

	management_modal.queue_free()
	management_modal = null
	management_modal_mouse_filter_backup.clear()
	current_management_instance_id = ""
	current_management_feedback_key = ""


func _close_habitat_purchase_modal() -> void:
	if habitat_purchase_modal == null:
		return

	habitat_purchase_modal.queue_free()
	habitat_purchase_modal = null


func _close_variant_discovery_modal() -> void:
	if variant_discovery_modal == null:
		return

	variant_discovery_modal.queue_free()
	variant_discovery_modal = null
	var name_instance_id: String = pending_name_instance_id
	pending_name_instance_id = ""
	if not name_instance_id.is_empty():
		_show_reptile_name_popup(name_instance_id, false)


func _close_naming_modal() -> void:
	if naming_modal == null:
		_set_management_modal_input_blocked(false)
		return

	naming_modal.queue_free()
	naming_modal = null
	_set_management_modal_input_blocked(false)


func _set_management_modal_input_blocked(blocked: bool) -> void:
	if blocked:
		management_modal_mouse_filter_backup.clear()
		if management_modal != null:
			_backup_and_set_mouse_filter(management_modal, Control.MOUSE_FILTER_IGNORE)
		return

	for entry in management_modal_mouse_filter_backup:
		var control: Control = entry.get("control", null) as Control
		if is_instance_valid(control):
			control.mouse_filter = int(entry.get("mouse_filter", Control.MOUSE_FILTER_PASS))
	management_modal_mouse_filter_backup.clear()


func _backup_and_set_mouse_filter(control: Control, mouse_filter: int) -> void:
	management_modal_mouse_filter_backup.append({
		"control": control,
		"mouse_filter": control.mouse_filter
	})
	control.mouse_filter = mouse_filter

	for child in control.get_children():
		if child is Control:
			_backup_and_set_mouse_filter(child as Control, mouse_filter)


func _make_modal_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.94, 0.88, 0.98)
	style.border_color = Color(0.32, 0.24, 0.16, 0.45)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 12
	return style


func _make_bottom_sheet_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _make_modal_panel_style()
	style.set_corner_radius(CORNER_BOTTOM_LEFT, 0)
	style.set_corner_radius(CORNER_BOTTOM_RIGHT, 0)
	style.shadow_size = 18
	return style


func _make_transparent_button_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	style.border_color = Color(1.0, 1.0, 1.0, 0.0)
	style.set_corner_radius_all(0)
	return style


func _make_card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.985, 0.93, 1.0)
	style.border_color = Color(0.36, 0.29, 0.18, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style


func _make_animals_single_card_style() -> StyleBox:
	var texture: Texture2D = AssetPaths.load_texture(ANIMALS_SINGLE_CARD_BG_PATH)
	if texture == null:
		return _make_card_style()

	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = texture
	style.draw_center = true
	style.texture_margin_left = 48.0
	style.texture_margin_right = 48.0
	style.texture_margin_top = 34.0
	style.texture_margin_bottom = 34.0
	return style


func _animals_ui_size(value: float) -> int:
	return max(1, int(round(value * ANIMALS_CARD_SCALE)))


func _animals_ui_vec(width: float, height: float) -> Vector2:
	return Vector2(float(_animals_ui_size(width)) if width > 0.0 else 0.0, float(_animals_ui_size(height)) if height > 0.0 else 0.0)


func _animals_text_size(value: float) -> int:
	return max(1, int(round(float(_animals_ui_size(value)) * ANIMALS_CARD_TEXT_SCALE)))


func _animals_image_vec(width: float, height: float) -> Vector2:
	var scaled_width: float = float(_animals_ui_size(width)) * ANIMALS_CARD_IMAGE_SCALE if width > 0.0 else 0.0
	var scaled_height: float = float(_animals_ui_size(height)) * ANIMALS_CARD_IMAGE_SCALE if height > 0.0 else 0.0
	return Vector2(scaled_width, scaled_height)


func _animals_rarity_icon_size(value: float) -> int:
	return max(1, int(round(float(_animals_ui_size(value)) * ANIMALS_RARITY_ICON_SCALE)))


func _animals_gallery_content_size(value: float) -> int:
	return max(1, int(round(value * ANIMALS_GALLERY_CONTENT_SCALE)))


func _animals_gallery_content_vec(value: Vector2) -> Vector2:
	return value * ANIMALS_GALLERY_CONTENT_SCALE


func _animals_card_bg_vec(
	width: float,
	height: float,
	width_scale: float = ANIMALS_CARD_BACKGROUND_WIDTH_SCALE,
	height_scale: float = ANIMALS_CARD_BACKGROUND_HEIGHT_SCALE
) -> Vector2:
	var scaled_width: float = float(_animals_ui_size(width)) * width_scale if width > 0.0 else 0.0
	var scaled_height: float = float(_animals_ui_size(height)) * height_scale if height > 0.0 else 0.0
	return Vector2(scaled_width, scaled_height)


func _make_owned_card_action_button(label_key: String) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = _animals_ui_vec(104, 44)
	button.text = LocalizationSystem.tr_key(label_key)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	button.add_theme_font_size_override("font_size", _animals_text_size(13))
	_apply_button_text_color(button, BUTTON_TEXT_COLOR)
	return button


func _make_release_action_button(label_key: String) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = _animals_ui_vec(104, 38)
	button.text = LocalizationSystem.tr_key(label_key)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.62, 0.18, 0.14, 0.90)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.74, 0.22, 0.17, 0.95)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.50, 0.14, 0.11, 0.95)))
	button.add_theme_font_size_override("font_size", _animals_text_size(13))
	_apply_button_text_color(button, BUTTON_TEXT_COLOR)
	return button


func _make_upgrade_action_button(label_key: String) -> Button:
	var button: Button = _make_owned_card_action_button(label_key)
	var texture: Texture2D = AssetPaths.load_texture(UPGRADE_BUTTON_ICON_PATH)
	if texture != null:
		button.icon = texture
		button.expand_icon = true
	return button


func _make_gallery_slot_style(discovered: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.86, 1.0) if discovered else Color(0.86, 0.82, 0.72, 0.92)
	style.border_color = Color(0.36, 0.29, 0.18, 0.20)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style


func _make_portrait_frame_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.90, 0.86, 0.76, 1.0)
	style.border_color = Color(0.36, 0.29, 0.18, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style


func _make_fixed_texture(path: String, texture_size: Vector2) -> TextureRect:
	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.custom_minimum_size = texture_size
	texture_rect.texture = AssetPaths.load_texture(path)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture_rect


func _make_icon_or_fallback(path: String, icon_size: Vector2, fallback_text: String) -> Control:
	var texture: Texture2D = AssetPaths.load_texture(path)
	if texture != null:
		var texture_rect: TextureRect = TextureRect.new()
		texture_rect.custom_minimum_size = icon_size
		texture_rect.texture = texture
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return texture_rect

	var fallback: Label = Label.new()
	fallback.custom_minimum_size = icon_size
	fallback.text = fallback_text
	fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback.add_theme_font_size_override("font_size", 24)
	_apply_label_color(fallback, POPUP_TEXT_ACCENT)
	return fallback


func _make_icon_text_row(icon_path: String, text: String, icon_size: int, font_size: int = 12) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	row.add_child(_make_fixed_texture(icon_path, Vector2(icon_size, icon_size)))

	var label: Label = Label.new()
	label.text = text
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	_apply_label_color(label, POPUP_TEXT_SECONDARY)
	row.add_child(label)

	return row


func _make_management_text_row(label_key: String, value: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)

	var label: Label = Label.new()
	label.text = LocalizationSystem.tr_key(label_key) + ":"
	label.custom_minimum_size = Vector2(92, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", 13)
	_apply_label_color(label, POPUP_TEXT_ACCENT)
	row.add_child(label)

	var value_label: Label = Label.new()
	value_label.text = value
	value_label.clip_text = true
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_font_size_override("font_size", 13)
	_apply_label_color(value_label, POPUP_TEXT_SECONDARY)
	row.add_child(value_label)

	return row


func _make_management_icon_row(label_key: String, icon_path: String, value: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)

	var label: Label = Label.new()
	label.text = LocalizationSystem.tr_key(label_key) + ":"
	label.custom_minimum_size = Vector2(92, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", 13)
	_apply_label_color(label, POPUP_TEXT_ACCENT)
	row.add_child(label)

	row.add_child(_make_fixed_texture(icon_path, Vector2(26, 26)))

	var value_label: Label = Label.new()
	value_label.text = value
	value_label.clip_text = true
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 13)
	_apply_label_color(value_label, POPUP_TEXT_SECONDARY)
	row.add_child(value_label)

	return row


func _get_percent_state(instance: Dictionary, key: String, fallback: int) -> int:
	return int(clamp(int(instance.get(key, fallback)), 0, 100))


func _format_repticash_per_min(value: float) -> String:
	return LocalizationSystem.tr_key("currency.repticash") + " " + _format_decimal(value) + " " + LocalizationSystem.tr_key("ui.per_minute")


func _format_multiplier(value: float) -> String:
	return "x%.2f" % value


func _format_decimal(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))

	return "%.1f" % value


func _make_need_bar_row(label_key: String, icon_path: String, value: int) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)

	var label: Label = Label.new()
	label.text = LocalizationSystem.tr_key(label_key) + ":"
	label.custom_minimum_size = Vector2(92, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", 13)
	_apply_label_color(label, POPUP_TEXT_ACCENT)
	row.add_child(label)

	row.add_child(_make_fixed_texture(icon_path, Vector2(24, 24)))

	var progress: ProgressBar = ProgressBar.new()
	progress.min_value = 0
	progress.max_value = 100
	progress.value = value
	progress.custom_minimum_size = Vector2(92, 18)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.show_percentage = false
	row.add_child(progress)

	var value_label: Label = Label.new()
	value_label.text = str(value) + "%"
	value_label.custom_minimum_size = Vector2(42, 0)
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 13)
	_apply_label_color(value_label, POPUP_TEXT_SECONDARY)
	row.add_child(value_label)

	return row


func _make_progress_fill_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style


func _make_progress_background_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style


func _make_care_action_button(action_id: String, label_key: String, icon_path: String, instance: Dictionary, is_assigned: bool) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(0, 58)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = ""
	var remaining: int = ReptileSystem.get_care_cooldown_remaining(instance, action_id)
	button.disabled = not is_assigned or remaining > 0
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW if button.disabled else Control.CURSOR_POINTING_HAND
	var normal_color: Color = Color(0.32, 0.58, 0.22, 0.96)
	var disabled_color: Color = Color(0.72, 0.64, 0.48, 0.42)
	button.add_theme_stylebox_override("normal", _make_button_style(normal_color))
	button.add_theme_stylebox_override("hover", _make_button_style(normal_color.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _make_button_style(normal_color.darkened(0.12)))
	button.add_theme_stylebox_override("disabled", _make_button_style(disabled_color))
	if not button.disabled:
		button.pressed.connect(func() -> void: _on_care_action_pressed(action_id))

	var content: VBoxContainer = VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 2)
	button.add_child(content)

	var display_icon_path: String = COOLDOWN_ICON_PATH if remaining > 0 else icon_path
	var icon: TextureRect = _make_fixed_texture(display_icon_path, Vector2(34, 34))
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(icon)

	var label: Label = Label.new()
	label.text = _format_cooldown(remaining) if remaining > 0 else LocalizationSystem.tr_key(label_key)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 10)
	_apply_label_color(label, POPUP_TEXT_SECONDARY if button.disabled else BUTTON_TEXT_COLOR)
	content.add_child(label)

	return button


func _on_care_action_pressed(action_id: String) -> void:
	if current_management_instance_id.is_empty():
		return

	var result: Dictionary = ReptileSystem.perform_care_action(current_management_instance_id, action_id)
	var feedback_text: String = LocalizationSystem.tr_key(str(result.get("message_key", "ui.feature_later")))
	current_management_feedback_key = ""
	if bool(result.get("success", false)):
		_notify_quest_event("care_action_success", {"action": action_id, "instance_id": current_management_instance_id})
		feedback_text = _format_care_success_feedback(result)
	_refresh_habitat_slots()
	_show_management_for_instance_id(current_management_instance_id, false)
	if not feedback_text.is_empty():
		_show_toast_raw(feedback_text)


func _format_care_success_feedback(result: Dictionary) -> String:
	var text: String = LocalizationSystem.tr_key(str(result.get("message_key", "")))
	text = text.replace("{xp}", _format_decimal(float(result.get("xp", 0.0))))
	text = text.replace("{money}", _format_decimal(float(result.get("money", 0.0))))
	return text


func _show_income_float(amount: float) -> void:
	var float_label: Label = Label.new()
	float_label.text = LocalizationSystem.tr_key("income.plus").replace("{amount}", _format_decimal(amount))
	float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	float_label.add_theme_color_override("font_color", Color(0.12, 0.55, 0.14, 1.0))
	float_label.add_theme_font_size_override("font_size", 22)
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(float_label)

	float_label.position = Vector2(22, TOP_BAR_HEIGHT + 8)
	var tween: Tween = create_tween()
	tween.tween_property(float_label, "position:y", float_label.position.y - 42.0, 1.4)
	tween.parallel().tween_property(float_label, "modulate:a", 0.0, 1.4)
	tween.tween_callback(float_label.queue_free)


func _format_cooldown(seconds: int) -> String:
	var safe_seconds: int = max(0, seconds)
	if safe_seconds >= 60:
		return str(int(ceil(float(safe_seconds) / 60.0))) + "m"

	return str(safe_seconds) + "s"


func _format_duration_compact(seconds: int) -> String:
	var safe_seconds: int = max(0, seconds)
	if safe_seconds < 60:
		return str(safe_seconds) + "s"
	var hours: int = int(safe_seconds / 3600)
	var minutes: int = int((safe_seconds % 3600) / 60)
	if hours > 0:
		return str(hours) + "h " + "%02dm" % minutes
	return str(minutes) + "m"


func _make_rarity_icon(path: String, icon_size: Vector2) -> TextureRect:
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = icon_size
	icon.texture = AssetPaths.load_texture(path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = icon.texture != null
	return icon


func _make_edit_icon_button(instance_id: String) -> Button:
	var button: Button = Button.new()
	button.name = "EditNameButton"
	button.tooltip_text = LocalizationSystem.tr_key("ui.edit_name")
	button.custom_minimum_size = Vector2(42, 42)
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	button.pressed.connect(func() -> void:
		_show_reptile_name_popup(instance_id, true)
	)

	var icon: TextureRect = TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 5
	icon.offset_top = 5
	icon.offset_right = -5
	icon.offset_bottom = -5
	icon.texture = AssetPaths.load_texture(EDIT_ICON_PATH)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)

	if icon.texture == null:
		push_warning("Edit name icon missing: " + EDIT_ICON_PATH)
		button.text = "..."

	return button


func _get_reptile_display_name(instance: Dictionary, reptile: Dictionary) -> String:
	var custom_name: String = str(instance.get("custom_name", "")).strip_edges()
	if not custom_name.is_empty():
		return custom_name

	var reptile_id: String = str(instance.get("reptile_id", ""))
	return LocalizationSystem.tr_key(str(reptile.get("name_key", reptile_id)))


func _get_sorted_owned_instances() -> Array:
	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var result: Array = []
	for instance_id in instances.keys():
		var instance_value: Variant = instances.get(instance_id)
		if typeof(instance_value) == TYPE_DICTIONARY:
			result.append(instance_value as Dictionary)

	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_assigned: bool = _is_reptile_instance_assigned(a)
		var b_assigned: bool = _is_reptile_instance_assigned(b)
		if a_assigned != b_assigned:
			return not a_assigned

		return int(a.get("created_at", 0)) < int(b.get("created_at", 0))
	)
	return result


func _is_reptile_instance_assigned(instance: Dictionary) -> bool:
	var habitat_value: Variant = instance.get("habitat_id", null)
	return habitat_value != null and not str(habitat_value).is_empty()


func _get_discovered_variant_count(variants: Array) -> int:
	var count: int = 0
	for variant_value in variants:
		if typeof(variant_value) != TYPE_DICTIONARY:
			continue

		var variant: Dictionary = variant_value as Dictionary
		if ReptileSystem.is_variant_discovered(str(variant.get("id", ""))):
			count += 1

	return count


func _get_expected_gallery_discovered_count() -> int:
	var count: int = 0
	for reptile_id_value in GALLERY_REPTILE_IDS:
		var reptile_id: String = str(reptile_id_value)
		for rarity_value in GALLERY_RARITIES:
			var variant: Dictionary = ReptileSystem.get_variant_for_reptile_rarity(reptile_id, str(rarity_value))
			if variant.is_empty():
				continue
			if ReptileSystem.is_variant_discovered(str(variant.get("id", ""))):
				count += 1

	return count


func _get_gallery_shadow_path(reptile_id: String, variant: Dictionary) -> String:
	var configured_path: String = str(variant.get("gallery_shadow_path", ""))
	if not configured_path.is_empty():
		return configured_path

	return "res://assets/art/reptiles/gallery/" + reptile_id + "_shadow.png"


func _get_habitat_display_name(habitat_id: String) -> String:
	for habitat_value in habitat_data:
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue

		var habitat: Dictionary = habitat_value as Dictionary
		if str(habitat.get("id", "")) == habitat_id:
			return LocalizationSystem.tr_key("ui.habitat") + " " + str(int(habitat.get("slot_index", 0)) + 1)

	return habitat_id


func _get_variant_image_path(reptile: Dictionary, variant: Dictionary, prefer_icon: bool) -> String:
	var icon_path: String = str(variant.get("icon_path", ""))
	var portrait_path: String = str(variant.get("portrait_path", ""))
	if prefer_icon and not icon_path.is_empty():
		return icon_path
	if not portrait_path.is_empty():
		return portrait_path
	if not icon_path.is_empty():
		return icon_path

	return str(reptile.get("icon_path", reptile.get("portrait_path", "")))


func _make_button_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _apply_label_color(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)


func _apply_button_text_color(button: Button, color: Color) -> void:
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color)
	button.add_theme_color_override("font_pressed_color", color)
	button.add_theme_color_override("font_disabled_color", Color(color.r, color.g, color.b, 0.65))


func _make_scroll_safe(root: Control) -> void:
	if root is Button or root is TextureButton or root is OptionButton or root is CheckButton or root is HSlider or root is VSlider:
		return
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in root.get_children():
		if child is Control:
			_make_scroll_safe(child as Control)


func _get_discovered_instance_sex(instance_id: String) -> String:
	if instance_id.is_empty():
		return "male"

	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var instance_value: Variant = instances.get(instance_id, {})
	if typeof(instance_value) != TYPE_DICTIONARY:
		return "male"

	var instance: Dictionary = instance_value as Dictionary
	return str(instance.get("sex", "male"))


func _get_selected_sex(selector: OptionButton) -> String:
	if selector.get_selected_id() == 1:
		return "female"

	return "male"


func _get_localized_sex(sex: String) -> String:
	if sex == "female":
		return LocalizationSystem.tr_key("sex.female")

	return LocalizationSystem.tr_key("sex.male")


func _refresh_habitat_slots() -> void:
	for habitat in habitat_data:
		var habitat_dict: Dictionary = habitat as Dictionary
		var habitat_id: String = str(habitat_dict.get("id", ""))
		if habitat_slots.has(habitat_id):
			var slot: Node = habitat_slots[habitat_id] as Node
			var state: String = _get_habitat_state(habitat_id)
			slot.call("set_state", state)
			if slot.has_method("set_habitat_texture"):
				slot.call("set_habitat_texture", _get_habitat_texture_path(habitat_id))
			if slot.has_method("set_upgrade_status"):
				slot.call("set_upgrade_status", _is_habitat_in_progress(habitat_id), _get_habitat_in_progress_status_text(habitat_id))
			slot.call("set_occupied_icon", _get_habitat_reptile_icon_path(habitat_id) if state == STATE_OCCUPIED else "")
			if slot.has_method("set_needs_attention"):
				slot.call("set_needs_attention", _habitat_needs_attention(habitat_id) if state == STATE_OCCUPIED else false)
			if slot.has_method("set_income_progress"):
				slot.call("set_income_progress", EconomySystem.get_income_progress() if state == STATE_OCCUPIED else 0.0)


func _refresh_habitat_income_progress() -> void:
	for habitat_id in habitat_slots.keys():
		var slot: Node = habitat_slots[habitat_id] as Node
		if not slot.has_method("set_income_progress"):
			continue

		var state: String = _get_habitat_state(str(habitat_id))
		slot.call("set_income_progress", EconomySystem.get_income_progress() if state == STATE_OCCUPIED else 0.0)


func _get_habitat_state(habitat_id: String) -> String:
	var saved: Dictionary = _get_saved_habitat_state(habitat_id)
	if saved.is_empty():
		return STATE_NOT_PURCHASED
	if not bool(saved.get("purchased", false)):
		return STATE_NOT_PURCHASED
	if bool(saved.get("is_upgrading", false)):
		return STATE_PURCHASED_EMPTY

	if (
		not str(saved.get("reptile_id", "")).is_empty()
		or not str(saved.get("reptile_instance_id", "")).is_empty()
		or _id_or_empty(saved.get("animal_instance_id", null)) != ""
	):
		return STATE_OCCUPIED

	return STATE_PURCHASED_EMPTY


func _habitat_has_assigned_reptile(habitat: Dictionary) -> bool:
	if habitat.is_empty():
		return false
	return (
		not str(habitat.get("reptile_id", "")).is_empty()
		or not str(habitat.get("reptile_instance_id", "")).is_empty()
		or _id_or_empty(habitat.get("animal_instance_id", null)) != ""
	)


func _get_habitats_state() -> Dictionary:
	var value: Variant = GameState.get_value("habitats", {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return value as Dictionary


func _id_or_empty(value: Variant) -> String:
	if value == null:
		return ""
	var text: String = str(value).strip_edges()
	if text.is_empty() or text == "<null>" or text.to_lower() == "null":
		return ""
	return text


func _get_saved_habitat_state(habitat_id: String) -> Dictionary:
	if ReptileSystem.has_method("get_habitat_state"):
		return ReptileSystem.get_habitat_state(habitat_id)

	var habitats: Dictionary = _get_habitats_state()
	var value: Variant = habitats.get(habitat_id, {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return value as Dictionary


func _get_habitat_texture_path(habitat_id: String) -> String:
	var habitat: Dictionary = _get_saved_habitat_state(habitat_id)
	if habitat.is_empty() or not bool(habitat.get("purchased", false)):
		return ""
	if bool(habitat.get("is_building", false)) or bool(habitat.get("is_upgrading", false)):
		return str(_biome_config.get("habitat_in_progress_path", HABITAT_IN_PROGRESS_PATH))

	var folder: String = str(_biome_config.get("habitat_art_folder", "res://assets/art/habitats/"))
	var habitat_type: String = ReptileSystem.normalize_habitat_type(str(habitat.get("habitat_type", "grass")))
	var level: int = ReptileSystem.normalize_habitat_level(habitat.get("habitat_level", 1))
	var suffix: String = "basic"
	match level:
		2: suffix = "middle"
		3: suffix = "top"
	return folder + habitat_type + "_" + suffix + ".png"


func _is_habitat_building(habitat_id: String) -> bool:
	var habitat: Dictionary = _get_saved_habitat_state(habitat_id)
	return bool(habitat.get("is_building", false))


func _is_habitat_upgrading(habitat_id: String) -> bool:
	var habitat: Dictionary = _get_saved_habitat_state(habitat_id)
	return bool(habitat.get("is_upgrading", false))


func _is_habitat_in_progress(habitat_id: String) -> bool:
	return _is_habitat_building(habitat_id) or _is_habitat_upgrading(habitat_id)


func _get_habitat_in_progress_status_text(habitat_id: String) -> String:
	if _is_habitat_building(habitat_id):
		var build_remaining: int = ReptileSystem.get_habitat_build_remaining_seconds(habitat_id)
		return LocalizationSystem.tr_key("habitat.building_in_progress") + "\n" + LocalizationSystem.tr_key("habitat.build_time_remaining").replace("{time}", _format_duration_compact(build_remaining))
	if not _is_habitat_upgrading(habitat_id):
		return ""

	var remaining: int = ReptileSystem.get_habitat_upgrade_remaining_seconds(habitat_id)
	return LocalizationSystem.tr_key("habitat.upgrade_in_progress") + "\n" + LocalizationSystem.tr_key("habitat.upgrade_time_remaining").replace("{time}", _format_duration_compact(remaining))


func _get_habitat_data(habitat_id: String) -> Dictionary:
	for habitat in habitat_data:
		var habitat_dict: Dictionary = habitat as Dictionary
		if str(habitat_dict.get("id", "")) == habitat_id:
			return habitat_dict
	return {}


func _get_habitat_reptile_icon_path(habitat_id: String) -> String:
	var instance: Dictionary = ReptileSystem.get_reptile_for_habitat(habitat_id)
	if instance.is_empty():
		return ""

	return ReptileSystem.get_owned_animal_image_path(instance)


func _habitat_needs_attention(habitat_id: String) -> bool:
	var instance: Dictionary = ReptileSystem.get_reptile_for_habitat(habitat_id)
	if instance.is_empty():
		return false

	return ReptileSystem.reptile_needs_attention(instance)


func _load_habitats() -> Array:
	var file: FileAccess = FileAccess.open(HABITATS_PATH, FileAccess.READ)
	if file == null:
		return []

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return []

	var result: Array = []
	var parsed_array: Array = parsed as Array
	for item in parsed_array:
		if typeof(item) == TYPE_DICTIONARY:
			var item_dict: Dictionary = item as Dictionary
			if str(item_dict.get("biome_id", "")) == biome_id:
				result.append(item_dict)

	result.sort_custom(_sort_habitats_by_slot)
	return result


func _sort_habitats_by_slot(a: Variant, b: Variant) -> bool:
	var habitat_a: Dictionary = a as Dictionary
	var habitat_b: Dictionary = b as Dictionary
	return int(habitat_a.get("slot_index", 0)) < int(habitat_b.get("slot_index", 0))
