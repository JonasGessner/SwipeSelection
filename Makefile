ARCHS=armv7
SDKVERSION=5.1

include /opt/theos/makefiles/common.mk

TWEAK_NAME = SwipeSelection
SwipeSelection_FILES = Tweak.xm
SwipeSelection_FRAMEWORKS = UIKit Foundation 

include $(THEOS_MAKE_PATH)/tweak.mk
