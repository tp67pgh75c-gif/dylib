#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MenuTab) {
    MenuTabAimbot = 0,
    MenuTabVisuals,
    MenuTabMisc,
    MenuTabSettings,
};

@interface MenuViewController : UIViewController

@property (nonatomic, strong, readonly) UIView *panelView;
@property (nonatomic, assign) MenuTab activeTab;

+ (UIColor *)panelBackgroundColor;
+ (UIColor *)sidebarBackgroundColor;
+ (UIColor *)accentOrangeColor;
+ (UIColor *)mutedTextColor;
+ (UIColor *)dropdownBackgroundColor;
+ (UIColor *)trackInactiveColor;

- (void)showMenuAnimated:(BOOL)animated;
- (void)dismissMenuAnimated:(BOOL)animated;
- (void)selectTab:(MenuTab)tab;

@end
