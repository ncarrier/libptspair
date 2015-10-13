LOCAL_PATH := $(call my-dir)

###############################################################################
# libptspair
###############################################################################

include $(CLEAR_VARS)

LOCAL_MODULE := libptspair
LOCAL_DESCRIPTION := Event-loop friendly small library for creating a pair of \
	connected pts.
LOCAL_CATEGORY_PATH := libs

LOCAL_EXPORT_C_INCLUDES  := $(LOCAL_PATH)/include

LOCAL_SRC_FILES := \
	$(call all-c-files-under,src) \

LOCAL_CFLAGS := -fvisibility=hidden

include $(BUILD_LIBRARY)
