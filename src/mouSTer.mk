# Mouster Driver settings to keep track of versions and builds.

MOUSTER_DRIVER_VER_MAJOR = 0
MOUSTER_DRIVER_VER_MINOR = 8
MOUSTER_DRIVER_VER_BUILD = 300

MOUSTER_DRIVER_VER_BUILD_INC = 1

LAST_RELEASE = 300

MOUSTER_VERSION_STRING=${MOUSTER_DRIVER_VER_MAJOR}.${MOUSTER_DRIVER_VER_MINOR}.$$(($(MOUSTER_DRIVER_VER_BUILD) + $(MOUSTER_DRIVER_VER_BUILD_INC)))
