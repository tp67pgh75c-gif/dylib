#import <UIKit/UIKit.h>

@interface FloatingSwitch : UIWindow
+ (instancetype)shared;
- (void)show;
- (void)hide;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, copy) void (^onToggle)(BOOL isOn);
@end
