TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PsyhotropMenu
PsyhotropMenu_FILES = Tweak.xm
PsyhotropMenu_FRAMEWORKS = UIKit Foundation
PsyhotropMenu_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
