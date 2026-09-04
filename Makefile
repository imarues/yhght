ARCHS = arm64
TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = Telegram

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TelegramMultiManager
TelegramMultiManager_FILES = Manager.mm
TelegramMultiManager_FRAMEWORKS = UIKit Foundation
TelegramMultiManager_CFLAGS = -fobjc-arc -Wall -Wextra
TelegramMultiManager_CCFLAGS = -std=c++17

include $(THEOS_MAKE_PATH)/tweak.mk
