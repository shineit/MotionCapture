#import <Foundation/Foundation.h>
#import "MSAINullability.h"

NS_ASSUME_NONNULL_BEGIN
/**
 *  Provides details about the crash that occured in the previous app session
 */
@interface MSAICrashDetails : NSObject

/**
 *  UUID for the crash report
 */
@property (nonatomic, readonly, copy) NSString *incidentIdentifier;

/**
 *  UUID for the app installation on the device
 */
@property (nonatomic, readonly, copy) NSString *reporterKey;

/**
 *  Signal that caused the crash
 */
@property (nonatomic, readonly, copy) NSString *signal;

/**
 *  Exception name that triggered the crash, nil if the crash was not caused by an exception
 */
@property (nonatomic, readonly, copy) NSString *exceptionName;

/**
 *  Exception reason, nil if the crash was not caused by an exception
 */
@property (nonatomic, readonly, copy) NSString *exceptionReason;

/**
 *  Date and time the app started, nil if unknown
 */
@property (nonatomic, readonly, strong) NSDate *appStartTime;

/**
 *  Date and time the crash occured, nil if unknown
 */
@property (nonatomic, readonly, strong) NSDate *crashTime;

/**
 *  Operation System version string the app was running on when it crashed.
 */
@property (nonatomic, readonly, copy) NSString *osVersion;

/**
 *  Operation System build string the app was running on when it crashed
 *
 *  This may be unavailable.
 */
@property (nonatomic, readonly, copy) NSString *osBuild;

/**
 *  CFBundleVersion value of the app that crashed
 */
@property (nonatomic, readonly, copy) NSString *appBuild;

/**
 Indicates if the app was killed while being in foreground from the iOS
 
 If `[MSAICrashManager appNotTerminatingCleanlyDetectionEnabled]` is enabled, use this on startup
 to check if the app starts the first time after it was killed by iOS in the previous session.
 
 This can happen if it consumed too much memory or the watchdog killed the app because it
 took too long to startup or blocks the main thread for too long, or other reasons. See Apple
 documentation: https://developer.apple.com/library/ios/qa/qa1693/_index.html
 
 See `[MSAICrashManager appNotTerminatingCleanlyDetectionEnabled]` for more details about which kind of kills can be detected.
 
 @warning This property only has a correct value, once `[MSAIApplicationInsights start]` was
 invoked! In addition, it is automatically disabled while a debugger session is active!
 
 @see `[MSAICrashManager appNotTerminatingCleanlyDetectionEnabled]`
 @see `[MSAICrashManager didReceiveMemoryWarningInLastSession]`
 
 @return YES if the details represent an app kill instead of a crash
 */
- (BOOL)isAppKill;

@end
NS_ASSUME_NONNULL_END
