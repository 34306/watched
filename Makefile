export THEOS = /Users/huynguyen/Desktop/theos
#change your theos path if needed
#TARGET := iphone:clang:latest:16.5
INSTALL_TARGET_PROCESSES = SpringBoard
#THEOS_PACKAGE_SCHEME = rootless
THEOS_PACKAGE_SCHEME = roothide
#also added roothide if needed
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = watched

$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
