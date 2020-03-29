################################################################################
#
# apparmor
#
################################################################################

# When updating the version here, please also update the libapparmor package
APPARMOR_VERSION_MAJOR = 2.13
APPARMOR_VERSION = $(APPARMOR_VERSION_MAJOR).3
APPARMOR_SITE = https://launchpad.net/apparmor/$(APPARMOR_VERSION_MAJOR)/$(APPARMOR_VERSION)/+download
APPARMOR_DL_SUBDIR = libapparmor
APPARMOR_LICENSE = GPL-2.0
APPARMOR_LICENSE_FILES = LICENSE parser/COPYING.GPL

APPARMOR_DEPENDENCIES = libapparmor

APPARMOR_TOOLS = parser
APPARMOR_MAKE_OPTS = USE_SYSTEM=1

ifeq ($(BR2_PACKAGE_APPARMOR_BINUTILS),y)
APPARMOR_TOOLS += binutils
endif

ifeq ($(BR2_PACKAGE_APPARMOR_UTILS),y)
APPARMOR_DEPENDENCIES += host-python3 python3
APPARMOR_TOOLS += utils
APPARMOR_MAKE_OPTS += PYTHON=$(HOST_DIR)/bin/python3

ifeq ($(BR2_PACKAGE_APPARMOR_UTILS_EXTRA),)
define APPARMOR_UTILS_NO_EXTRA
	$(Q)rm -f $(addprefix $(TARGET_DIR)/usr/sbin/,aa-decode aa-notify aa-remove-unknown)
endef
APPARMOR_POST_INSTALL_TARGET_HOOKS += APPARMOR_UTILS_NO_EXTRA
endif # BR2_PACKAGE_APPARMOR_UTILS_EXTRA

endif # BR2_PACKAGE_APPARMOR_UTILS

define APPARMOR_BUILD_CMDS
	$(foreach tool,$(APPARMOR_TOOLS),\
		$(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) \
		$(MAKE) -C $(@D)/$(tool) $(APPARMOR_MAKE_OPTS)
	)
endef

define APPARMOR_INSTALL_TARGET_CMDS
	$(foreach tool,$(APPARMOR_TOOLS),\
		$(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) \
		$(MAKE) -C $(@D)/$(tool) $(APPARMOR_MAKE_OPTS) \
			DESTDIR=$(TARGET_DIR) install
	)
endef

# Despite its name, apparmor.systemd is a sysv-init compatible startup script
define APPARMOR_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(@D)/parser/apparmor.systemd \
		$(TARGET_DIR)/etc/init.d/S00apparmor
endef

define APPARMOR_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0755 $(@D)/parser/apparmor.systemd \
		$(TARGET_DIR)/lib/apparmor/apparmor.systemd
	$(INSTALL) -D -m 0755 $(@D)/parser/apparmor.service \
		$(TARGET_DIR)/usr/lib/systemd/system/apparmor.service
endef

$(eval $(generic-package))
