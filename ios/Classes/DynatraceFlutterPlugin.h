#import <Flutter/Flutter.h>
@import Dynatrace;

@interface DynatraceFlutterPlugin : NSObject <FlutterPlugin>
@end

typedef enum : NSUInteger
{
    DTXActionPlatformJavaScript = 1,
    DTXActionPlatformXamarin,
    DTXActionPlatformFlutter
} DTXActionPlatformType;

@interface DTXAction (ExternalAgents)
@property int tagId;
+ (void)reportExternalCrashForPlatformType:(DTXActionPlatformType)platformType crashName:(NSString *)crashName reason:(NSString *)reason stacktrace:(NSString *)stacktrace;
+ (DTX_StatusCode)reportExternalErrorForPlatformType:(DTXActionPlatformType)platformType errorName:(NSString *)errorName errorValue:(NSString *)errorValue reason:(NSString *)reason stacktrace:(NSString *)stacktrace;
- (DTX_StatusCode)reportExternalErrorForPlatformType:(DTXActionPlatformType)platformType errorName:(NSString *)errorName errorValue:(NSString *)errorValue reason:(NSString *)reason stacktrace:(NSString *)stacktrace;
@end

@interface Dynatrace (ExternalAgents)
+ (DTX_StatusCode)endVisitWithEndEvent:(BOOL)hasEndEvent;
@end