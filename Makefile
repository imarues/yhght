ARCHS = arm64
TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = Telegram

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MultiTele
MultiTele_FILES = Manager.mm
MultiTele_FRAMEWORKS = UIKit Foundation
MultiTele_CFLAGS = -fobjc-arc -Wall -Wextra
MultiTele_CCFLAGS = -std=c++17

include $(THEOS_MAKE_PATH)/tweak.mk
