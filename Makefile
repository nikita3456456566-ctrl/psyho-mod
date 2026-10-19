TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = libAudioToolbox
libAudioToolbox_FILES = Tweak.xm PSYESP.mm
libAudioToolbox_FRAMEWORKS = UIKit Foundation QuartzCore
libAudioToolbox_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
