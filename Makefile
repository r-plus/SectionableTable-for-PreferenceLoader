include theos/makefiles/common.mk

BUNDLE_NAME = SleipnizerSettings
SleipnizerSettings_FILES = Preference.m
SleipnizerSettings_INSTALL_PATH = /Library/PreferenceBundles
SleipnizerSettings_FRAMEWORKS = UIKit CoreGraphics
SleipnizerSettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SleipnizerforSafari.plist$(ECHO_END)
