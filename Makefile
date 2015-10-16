export ARCHS = arm64 armv7s armv7
export TARGET = iphone:9.0:7.0

include theos/makefiles/common.mk

TWEAK_NAME = NCDateCustomizer
NCDateCustomizer_FILES = Tweak.xm
NCDateCustomizer_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

before-package::
	find _ -name "*.plist" -exec plutil -convert binary1 {} \;
	find _ -exec touch -r _/Library/MobileSubstrate/DynamicLibraries/NCDateCustomizer.dylib {} \;

after-package::
	rm -fr .theos/packages/*
