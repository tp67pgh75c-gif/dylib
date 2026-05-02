//
//  APIClient.h
//  ZombiModeAPI
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface APIClient : NSObject

- (void)paid:(void (^)(void))execute;
- (void)start:(void (^)(void))onStart init:(void (^)(void))init;
- (void)setUDID:(NSString *)uid;
- (void)setLanguage:(NSString *)language;
- (void)hideUI:(bool)isHide;
- (void)strictMode:(bool)_isStrictMode;
- (void)silentMode:(bool)_isSilentMode;
- (id)getPackageDataWithKey:(NSString *)key;
- (NSString *)getKey;
- (NSString *)getExpiryDate;
- (NSString *)getExpiredAt;
- (NSString *)getUDID;
- (NSString *)getDeviceModel;
- (NSString *)getLoginIP;
- (NSString *)getPackageName;
- (void)onCheckPackage:(void (^)(NSDictionary *header))success onFailure:(void (^)(NSDictionary *error))failure;
- (void)onCheckDevice:(void (^)(NSDictionary *data))success onFailure:(void (^)(NSDictionary *error))failure;
- (void)onLogin:(NSString *)inputKey onSuccess:(void (^)(NSDictionary *data))success onFailure:(void (^)(NSDictionary *error))failure;

+ (instancetype)sharedAPIClient;

@end

NS_ASSUME_NONNULL_END
