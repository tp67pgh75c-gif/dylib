//
//  APIClient.m
//  ZombiModeAPI
//

#import "APIClient.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

// ─── CHANGE THIS TO YOUR API URL ───────────────────────────────────────────
static NSString *const kBaseURL = @"https://58fc7533-71e7-4649-b98c-88d5e4c5cd56-00-xzscuttd3sdz.janeway.replit.dev/api";
// ───────────────────────────────────────────────────────────────────────────

@interface APIClient ()
@property (nonatomic, strong) NSString *udid;
@property (nonatomic, strong) NSString *language;
@property (nonatomic, strong) NSString *currentKey;
@property (nonatomic, strong) NSString *expiryDate;
@property (nonatomic, strong) NSString *expiredAt;
@property (nonatomic, strong) NSString *loginIP;
@property (nonatomic, strong) NSString *packageName;
@property (nonatomic, assign) bool hideUIFlag;
@property (nonatomic, assign) bool isStrictMode;
@property (nonatomic, assign) bool isSilentMode;
@property (nonatomic, strong) NSDictionary *packageData;
@end

@implementation APIClient

+ (instancetype)sharedAPIClient {
    static APIClient *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _language = @"en";
        _hideUIFlag = false;
        _isStrictMode = false;
        _isSilentMode = false;
        _udid = [[[UIDevice currentDevice] identifierForVendor] UUIDString] ?: @"";
    }
    return self;
}

// ─── SETTERS ────────────────────────────────────────────────────────────────

- (void)setUDID:(NSString *)uid {
    self.udid = uid;
}

- (void)setLanguage:(NSString *)language {
    self.language = language;
}

- (void)hideUI:(bool)isHide {
    self.hideUIFlag = isHide;
}

- (void)strictMode:(bool)_isStrictMode {
    self.isStrictMode = _isStrictMode;
}

- (void)silentMode:(bool)_isSilentMode {
    self.isSilentMode = _isSilentMode;
}

// ─── GETTERS ────────────────────────────────────────────────────────────────

- (NSString *)getKey {
    return self.currentKey ?: @"";
}

- (NSString *)getExpiryDate {
    return self.expiryDate ?: @"";
}

- (NSString *)getExpiredAt {
    return self.expiredAt ?: @"";
}

- (NSString *)getUDID {
    return self.udid ?: @"";
}

- (NSString *)getDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding] ?: @"Unknown";
}

- (NSString *)getLoginIP {
    return self.loginIP ?: @"";
}

- (NSString *)getPackageName {
    return self.packageName ?: @"";
}

- (id)getPackageDataWithKey:(NSString *)key {
    return self.packageData[key] ?: [NSNull null];
}

// ─── LIFECYCLE ──────────────────────────────────────────────────────────────

- (void)paid:(void (^)(void))execute {
    if (execute) execute();
}

- (void)start:(void (^)(void))onStart init:(void (^)(void))init {
    if (onStart) onStart();
    if (init) init();
}

// ─── API CALLS ──────────────────────────────────────────────────────────────

- (void)onLogin:(NSString *)inputKey
      onSuccess:(void (^)(NSDictionary *data))success
      onFailure:(void (^)(NSDictionary *error))failure {

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/client/login", kBaseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *body = @{
        @"key": inputKey ?: @"",
        @"udid": self.udid ?: @"",
        @"device_model": [self getDeviceModel],
        @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0",
        @"language": self.language ?: @"en"
    };

    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];

    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                if (failure) failure(@{ @"message": error.localizedDescription ?: @"Connection error" });
                return;
            }

            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (!json) {
                if (failure) failure(@{ @"message": @"Invalid server response" });
                return;
            }

            BOOL isSuccess = [json[@"success"] boolValue];
            if (isSuccess) {
                NSDictionary *responseData = json[@"data"];
                self.currentKey     = responseData[@"key"] ?: inputKey;
                self.expiryDate     = responseData[@"expiry_date"] ?: @"";
                self.expiredAt      = responseData[@"expired_at"] ?: @"";
                self.loginIP        = responseData[@"login_ip"] ?: @"";
                self.packageName    = responseData[@"package_name"] ?: @"";
                self.packageData    = responseData ?: @{};

                if (success) success(responseData);
            } else {
                if (failure) failure(@{ @"message": json[@"message"] ?: @"Login failed" });
            }
        });
    }] resume];
}

- (void)onCheckPackage:(void (^)(NSDictionary *header))success
             onFailure:(void (^)(NSDictionary *error))failure {

    if (!self.currentKey || self.currentKey.length == 0) {
        if (failure) failure(@{ @"message": @"No key set. Call onLogin first." });
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/client/check-package", kBaseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *body = @{ @"key": self.currentKey };
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];

    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                if (failure) failure(@{ @"message": error.localizedDescription ?: @"Connection error" });
                return;
            }

            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            BOOL isSuccess = json ? [json[@"success"] boolValue] : NO;

            if (isSuccess) {
                if (success) success(json[@"data"] ?: @{});
            } else {
                if (failure) failure(@{ @"message": json[@"message"] ?: @"Package check failed" });
            }
        });
    }] resume];
}

- (void)onCheckDevice:(void (^)(NSDictionary *data))success
            onFailure:(void (^)(NSDictionary *error))failure {

    if (!self.currentKey || self.currentKey.length == 0) {
        if (failure) failure(@{ @"message": @"No key set. Call onLogin first." });
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/client/check-device", kBaseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *body = @{
        @"key": self.currentKey,
        @"udid": self.udid ?: @"",
        @"device_model": [self getDeviceModel]
    };
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];

    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                if (failure) failure(@{ @"message": error.localizedDescription ?: @"Connection error" });
                return;
            }

            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            BOOL isSuccess = json ? [json[@"success"] boolValue] : NO;

            if (isSuccess) {
                if (success) success(json[@"data"] ?: @{});
            } else {
                if (failure) failure(@{ @"message": json[@"message"] ?: @"Device check failed" });
            }
        });
    }] resume];
}

@end
