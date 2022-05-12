#import "DynatraceFlutterPlugin.h"

@implementation DynatraceFlutterPlugin

NSMutableDictionary *actionDict;
NSMutableDictionary *webTimingsDict;

int const PLATFORM_IOS = 1;
int const DATA_COLLECTION_OFF = 0;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    actionDict = [[NSMutableDictionary alloc] init];
    webTimingsDict = [[NSMutableDictionary alloc] init];
    DynatraceFlutterPlugin* instance = [[DynatraceFlutterPlugin alloc] init];

    FlutterMethodChannel* channel =
        [FlutterMethodChannel methodChannelWithName:@"dynatrace_flutter_plugin/dynatrace"
                                  binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"enterAction" isEqualToString:call.method]) {
        if(call.arguments[@"parent"] != nil){
            [self enterActionWithParent: call.arguments[@"name"] key: call.arguments[@"key"] parentKey: call.arguments[@"parent"] platform: call.arguments[@"platform"]];
        }else{
            [self enterAction: call.arguments[@"name"] key: call.arguments[@"key"] platform: call.arguments[@"platform"]];
        }
    }else if([@"leaveAction" isEqualToString:call.method]){
        [self leaveAction:call.arguments[@"key"]];
    }else if([@"cancelAction" isEqualToString:call.method]){
        [self cancelAction:call.arguments[@"key"]];
    }else if([@"endVisit" isEqualToString:call.method]){
        [self endVisit:call.arguments[@"platform"]];
    }else if([@"reportError" isEqualToString:call.method]){
        [self reportError:call.arguments[@"errorName"] errorCode:call.arguments[@"errorCode"] platform:call.arguments[@"platform"]];
    }else if([@"reportErrorStacktrace" isEqualToString:call.method]){
        [self reportErrorStacktrace:call.arguments[@"errorName"] errorValue:call.arguments[@"errorValue"] errorReason:call.arguments[@"reason"] stacktrace:call.arguments[@"stacktrace"] platform:call.arguments[@"platform"]];
    }else if([@"reportCrash" isEqualToString:call.method]){
        [self reportCrash:call.arguments[@"errorValue"] errorReason:call.arguments[@"reason"] stacktrace:call.arguments[@"stacktrace"] platform:call.arguments[@"platform"]];
    }else if([@"reportCrashWithException" isEqualToString:call.method]){
        [self reportCrashWithException:call.arguments[@"crashName"] errorReason:call.arguments[@"reason"] stacktrace:call.arguments[@"stacktrace"] platform:call.arguments[@"platform"]];
    }else if([@"reportErrorInAction" isEqualToString:call.method]){
        [self reportErrorInAction:call.arguments[@"key"] errorName:call.arguments[@"errorName"] errorCode:call.arguments[@"errorCode"] platform:call.arguments[@"platform"]];
    }else if([@"identifyUser" isEqualToString:call.method]){
        [self identifyUser:call.arguments[@"user"] platform:call.arguments[@"platform"]];
    }else if([@"reportEventInAction" isEqualToString:call.method]){
        [self reportEventInAction:call.arguments[@"key"] withName:call.arguments[@"name"] platform:call.arguments[@"platform"]];
    }else if([@"reportStringValueInAction" isEqualToString:call.method]){
        [self reportStringValueInAction:call.arguments[@"key"] withName:call.arguments[@"name"] value:call.arguments[@"value"] platform:call.arguments[@"platform"]];
    }else if([@"reportIntValueInAction" isEqualToString:call.method]){
        [self reportIntValueInAction:call.arguments[@"key"] withName:call.arguments[@"name"] value:call.arguments[@"value"] platform:call.arguments[@"platform"]];
    }else if([@"reportDoubleValueInAction" isEqualToString:call.method]){
        [self reportDoubleValueInAction:call.arguments[@"key"] withName:call.arguments[@"name"] value:call.arguments[@"value"] platform:call.arguments[@"platform"]];
    }else if([@"setGPSLocation" isEqualToString:call.method]){
        [self setGPSLocation:[call.arguments[@"latitude"] doubleValue] andLongitude:[call.arguments[@"longitude"] doubleValue] platform:call.arguments[@"platform"]];
    }else if([@"flushEvents" isEqualToString:call.method]){
        [self flushEvents:call.arguments[@"platform"]];
    }else if([@"applyUserPrivacyOptions" isEqualToString:call.method]){
        [self applyUserPrivacyOptions:[call.arguments[@"dataCollectionLevel"] intValue] crashReporting:[call.arguments[@"crashReportingOptedIn"] boolValue] platform:call.arguments[@"platform"]];
    }else if([@"getUserPrivacyOptions" isEqualToString:call.method]){
        result([self getUserPrivacyOptions:call.arguments[@"platform"]]);
    }else if([@"getRequestTag" isEqualToString:call.method]){
        result([self getRequestTagWithUrl:call.arguments[@"key"] url:call.arguments[@"url"]]);
    }else if([@"getRequestTagForInterceptor" isEqualToString:call.method]){
        result([self getRequestTagWithUrlForInterceptor:call.arguments[@"url"]]);
    }else if([@"startWebRequestTiming" isEqualToString:call.method]){
        [self startWebRequestTiming:call.arguments[@"requestTag"] url:call.arguments[@"url"]];
    }else if([@"stopWebRequestTiming" isEqualToString:call.method]){
        [self stopWebRequestTiming:call.arguments[@"requestTag"] responseCode: call.arguments[@"responseCode"]];
    }else if([@"start" isEqualToString:call.method]){
        [self start:call.arguments];
    }else if([@"getAutoStartConfiguration" isEqualToString:call.method]){
        NSMutableDictionary<NSString*, NSNumber*> *properties = [[NSMutableDictionary alloc] init];

        NSNumber* obj = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"DTXAutoStart"];
        properties[@"autoStart"] = obj != nil ? obj : [NSNumber numberWithBool:YES];

        obj = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"DTXWebRequestTiming"];
        properties[@"webRequest"] = obj != nil ? obj : [NSNumber numberWithBool:YES];

        obj = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"DTXCrashReporting"];
        properties[@"crashReporting"] = obj != nil ? obj : [NSNumber numberWithBool:YES];

        NSString* log = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"DTXLogLevel"];
        if(log != nil && [log isEqualToString:@"ALL"]){
            properties[@"logLevel"] = [NSNumber numberWithBool:YES];
        }else{
            properties[@"logLevel"] = [NSNumber numberWithBool:NO];
        }

        result(properties);
    }else{
        result(FlutterMethodNotImplemented);
    }
}

- (void) start:(id)arguments{
    if(arguments == NULL){
        return;
    }
    
    NSMutableDictionary<NSString*, id> *properties = [[NSMutableDictionary alloc] init];
    
    if(arguments[@"beaconUrl"] != NULL){
        properties[@"DTXBeaconURL"] = arguments[@"beaconUrl"];
    }
    
    if(arguments[@"applicationId"] != NULL){
        properties[@"DTXApplicationID"] = arguments[@"applicationId"];
    }
    
    if(arguments[@"logLevel"] != NULL && [((NSNumber *) arguments[@"logLevel"]) intValue] == 0){
        properties[@"DTXLogLevel"] = @"ALL";
    }
    
    if(arguments[@"crashReporting"] != NULL && !((BOOL) arguments[@"crashReporting"])){
        properties[@"DTXCrashReporting"] = @NO;
    }
    
    if(arguments[@"userOptIn"] != NULL && ((BOOL) arguments[@"userOptIn"])){
        properties[@"DTXUserOptIn"] = @YES;
    }
    
    if(arguments[@"certificateValidation"] != NULL && !((BOOL) arguments[@"certificateValidation"])){
        properties[@"DTXAllowAnyCert"] = @YES;
    }
    
    if(properties[@"DTXBeaconURL"] != NULL && properties[@"DTXApplicationID"] != NULL){
        [Dynatrace startupWithConfig:properties];
    }
}

- (NSString*) getRequestTagWithUrl:(NSNumber *) key url:(NSString*) url
{
    DTXAction* action = [self getAction:key];
    return [action getTagForURL:[NSURL URLWithString:url]];
}

- (NSString*) getRequestTagWithUrlForInterceptor:(NSString*) url
{
    return [Dynatrace getRequestTagValueForURL:[NSURL URLWithString:url]];
}

- (void) startWebRequestTiming:(NSString*) requestTag url:(NSString*) url{
    if(requestTag != NULL && url != NULL){
        DTXWebRequestTiming* timing = [DTXWebRequestTiming getDTXWebRequestTiming:requestTag requestUrl:[NSURL URLWithString:url]];
        if (timing != NULL) {
            [webTimingsDict setObject:timing forKey:[NSString stringWithString:requestTag]];
            [timing startWebRequestTiming];
        }
    }
}

- (void) stopWebRequestTiming:(NSString*) requestTag responseCode: (NSNumber*) responseCode
{
    if(requestTag != NULL){
        DTXWebRequestTiming* timing = [webTimingsDict objectForKey:requestTag];
        if(timing){
            [timing stopWebRequestTiming:[responseCode stringValue]];
            [webTimingsDict removeObjectForKey:requestTag];
        }
    }
}

- (void) enterAction:(NSString *)name key:(nonnull NSNumber *)key platform: (NSNumber*) platform
{
  if ([self shouldWorkOnIosWithPlatform: platform])
  {
    DTXAction *action = [DTXAction enterActionWithName:name];
    
    if (action){
        [actionDict setObject:action forKey:key];
    }
  }
}

- (void) enterActionWithParent:(NSString *)name key:(nonnull NSNumber *)key parentKey:(nonnull NSNumber *)parentKey platform: (NSNumber*) platform
{
    if ([self shouldWorkOnIosWithPlatform: platform])
    {
        DTXAction *parentAction = [self getAction:parentKey];
        if (parentAction){
            DTXAction* action = [DTXAction enterActionWithName:name parentAction:parentAction];
            
            if (action){
                [actionDict setObject:action forKey:key];
            }
        }else{
            [self enterAction:name key:key platform:platform];
        }
    }
}

- (void) leaveAction:(nonnull NSNumber *)key
{
    DTXAction *action = [self getAction:key];
    if (action == nil) return;
    [actionDict removeObjectForKey:key];
    [action leaveAction];
}

- (void) cancelAction:(nonnull NSNumber *)key
{
    DTXAction *action = [self getAction:key];
    if (action == nil) return;
    [actionDict removeObjectForKey:key];
    [action cancelAction];
}

- (void) endVisit: (NSNumber*) platform
{
    if ([self shouldWorkOnIosWithPlatform: platform])
    {
        [Dynatrace endVisit];
    }
}

- (void) reportError:(NSString *)errorName errorCode:(nonnull NSNumber *)errorCode platform: (NSNumber*) platform
{
    if ([self shouldWorkOnIosWithPlatform: platform])
    {
        DTXAction *action = [DTXAction enterActionWithName:@"Error"];
        if (action == nil) return;
        [action reportErrorWithName:errorName errorValue:[errorCode intValue]];
        [action leaveAction];
    }
}

- (void) reportErrorStacktrace:(NSString *)errorName errorValue:(NSString *)errorValue errorReason:(NSString *)errorReason stacktrace:(NSString *)stacktrace platform: (NSNumber*) platform
{
    if ([self shouldWorkOnIosWithPlatform: platform])
    {
        [DTXAction reportExternalErrorForPlatformType:0 errorName:errorName errorValue:errorValue reason:errorReason stacktrace:stacktrace];
    }
}

- (void) reportCrash:(NSString *)errorName errorReason:(NSString *)errorReason stacktrace:(NSString *)stacktrace platform: (NSNumber*) platform
{
    if ([self shouldWorkOnIosWithPlatform: platform])
    {
        [DTXAction reportExternalCrashForPlatformType:0 crashName:errorName reason:errorReason stacktrace:stacktrace];
        [Dynatrace endVisit];
    }
}

- (void) reportCrashWithException:(NSString *)crashName errorReason:(NSString *)errorReason stacktrace:(NSString *)stacktrace platform: (NSNumber*) platform
{
    if ([self shouldWorkOnIosWithPlatform: platform])
    {
        [DTXAction reportExternalCrashForPlatformType:DTXActionPlatformFlutter crashName:crashName reason:errorReason stacktrace:stacktrace];
        [Dynatrace endVisit];
    }
}

- (void) reportErrorInAction:(nonnull NSNumber *)key errorName:(NSString *)errorName errorCode:(nonnull NSNumber *)errorCode platform: (NSNumber*) platform
{
    if ([self shouldWorkOnIosWithPlatform: platform])
    {
        DTXAction *action = [self getAction:key];
        if (action == nil) return;
        [action reportErrorWithName:errorName errorValue:[errorCode intValue]];
    }
}

- (void) reportStringValueInAction:(nonnull NSNumber *)actionKey withName:(NSString *)name value: (NSString *)value platform: (NSNumber*) platform
{
  if ([self shouldWorkOnIosWithPlatform: platform])
  {
    DTXAction *action = [self getAction:actionKey];
    if (action == nil) return;
    [action reportValueWithName:name stringValue:value];
  }
}

- (void) reportIntValueInAction:(nonnull NSNumber *)actionKey withName:(NSString *)name value: (nonnull NSNumber *)value platform: (NSNumber*) platform
{
  if ([self shouldWorkOnIosWithPlatform: platform])
  {
    DTXAction *action = [self getAction:actionKey];
    if (action == nil) return;
    [action reportValueWithName:name intValue:value.intValue];
  }
}

- (void) reportDoubleValueInAction:(nonnull NSNumber *)actionKey withName:(NSString *)name value: (nonnull NSNumber *)value platform: (NSNumber*) platform
{
  if ([self shouldWorkOnIosWithPlatform: platform])
  {
    DTXAction *action = [self getAction:actionKey];
    if (action == nil) return;
    [action reportValueWithName:name doubleValue:value.doubleValue];
  }
}

- (void) identifyUser:(NSString *)user platform: (NSNumber*) platform
{
    if ([self shouldWorkOnIosWithPlatform: platform])
    {
        [Dynatrace identifyUser:user];
    }
}

- (void) reportEventInAction:(nonnull NSNumber *)actionKey withName: (NSString *)name platform: (NSNumber*) platform
{
    if ([self shouldWorkOnIosWithPlatform: platform])
    {
        DTXAction *action = [self getAction:actionKey];
        if (action == nil) return;
        [action reportEventWithName: name];
    }
}

- (void) setGPSLocation:(double)latitude andLongitude: (double)longitude platform: (NSNumber*) platform
{
    if ([self shouldWorkOnIosWithPlatform: platform])
    {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        [Dynatrace setGpsLocation:location];
    }
}

- (void) flushEvents:(NSNumber*) platform
{
    if ([self shouldWorkOnIosWithPlatform: platform])
    {
        [Dynatrace flushEvents];
    }
}

- (void) applyUserPrivacyOptions:(int) dataCollectionLevel crashReporting:(bool)crashReporting platform: (NSNumber*) platform
{
    if ([self shouldWorkOnIosWithPlatform: platform])
    {
        id<DTXUserPrivacyOptions> privacyConfig = [Dynatrace userPrivacyOptions];
        privacyConfig.dataCollectionLevel = dataCollectionLevel;
        privacyConfig.crashReportingOptedIn = crashReporting;
        
        [Dynatrace applyUserPrivacyOptions:privacyConfig completion:^(BOOL successful) {
            // do nothing with callback
        }];
    }
}

- (NSDictionary *) getUserPrivacyOptions:(NSNumber*) platform
{
    NSMutableDictionary *privacyDict = [[NSMutableDictionary alloc] init];
    
    if ([self shouldWorkOnIosWithPlatform: platform])
    {
        id<DTXUserPrivacyOptions> privacyConfig = [Dynatrace userPrivacyOptions];
        
        privacyDict[@"dataCollectionLevel"] = [NSNumber numberWithInt:privacyConfig.dataCollectionLevel];
        privacyDict[@"crashReportingOptedIn"] = [NSNumber numberWithBool: privacyConfig.crashReportingOptedIn];
    }
    
    return privacyDict;
}

- (DTXAction *) getAction:(nonnull NSNumber *)key
{
  return [actionDict objectForKey:key];
}

- (int) getActionTagId: (DTXAction *) action
{
    return action.tagId;
}

+ (BOOL) requiresMainQueueSetup
{
  return YES;
}

- (BOOL) shouldWorkOnIosWithPlatform: (NSNumber *) platform
{
    return platform == [NSNull null] || [platform intValue] == PLATFORM_IOS;
}

@end
