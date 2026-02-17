#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "AppIconImage" asset catalog image resource.
static NSString * const ACImageNameAppIconImage AC_SWIFT_PRIVATE = @"AppIconImage";

/// The "albaTime-splash-1024x1024-2" asset catalog image resource.
static NSString * const ACImageNameAlbaTimeSplash1024X10242 AC_SWIFT_PRIVATE = @"albaTime-splash-1024x1024-2";

#undef AC_SWIFT_PRIVATE
