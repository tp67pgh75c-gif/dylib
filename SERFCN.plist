#import "src/menu.h"

%ctor {
    dispatch_async(dispatch_get_main_queue(), ^{
        MenuViewController *menu = [[MenuViewController alloc] init];
        [menu showMenuAnimated:YES];
    });
}
