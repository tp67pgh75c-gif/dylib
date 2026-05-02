#import "menu.h"

#pragma mark - Helpers

static UIColor *RGB(CGFloat r, CGFloat g, CGFloat b) {
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}
static UIColor *RGBA(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a];
}

#pragma mark - State store (persists across tab switches)

@interface MenuState : NSObject
+ (instancetype)shared;
- (BOOL)boolFor:(NSString *)key def:(BOOL)def;
- (void)setBool:(BOOL)v for:(NSString *)key;
- (float)floatFor:(NSString *)key def:(float)def;
- (void)setFloat:(float)v for:(NSString *)key;
- (NSString *)stringFor:(NSString *)key def:(NSString *)def;
- (void)setString:(NSString *)v for:(NSString *)key;
@end

@implementation MenuState {
    NSMutableDictionary *_store;
}
+ (instancetype)shared {
    static MenuState *s; static dispatch_once_t o;
    dispatch_once(&o, ^{ s = [MenuState new]; });
    return s;
}
- (instancetype)init { if ((self = [super init])) { _store = [NSMutableDictionary new]; } return self; }
- (BOOL)boolFor:(NSString *)key def:(BOOL)def {
    NSNumber *n = _store[key]; return n ? n.boolValue : def;
}
- (void)setBool:(BOOL)v for:(NSString *)key { _store[key] = @(v); }
- (float)floatFor:(NSString *)key def:(float)def {
    NSNumber *n = _store[key]; return n ? n.floatValue : def;
}
- (void)setFloat:(float)v for:(NSString *)key { _store[key] = @(v); }
- (NSString *)stringFor:(NSString *)key def:(NSString *)def {
    NSString *s = _store[key]; return s ?: def;
}
- (void)setString:(NSString *)v for:(NSString *)key { if (v) _store[key] = v; }
@end

#pragma mark - OrangeCheckbox

@class OrangeCheckbox;
@protocol OrangeCheckboxDelegate <NSObject>
- (void)checkboxChanged:(OrangeCheckbox *)cb;
@end

@interface OrangeCheckbox : UIControl
@property (nonatomic, assign) BOOL checked;
@property (nonatomic, copy)   NSString *stateKey;
@property (nonatomic, weak)   id<OrangeCheckboxDelegate> cbDelegate;
@end

@implementation OrangeCheckbox
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.layer.cornerRadius = 4.0;
        self.layer.borderWidth  = 1.5;
        [self addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
        [self refresh];
    }
    return self;
}
- (void)toggle {
    self.checked = !self.checked;
    if (self.stateKey) [[MenuState shared] setBool:self.checked for:self.stateKey];
    [self.cbDelegate checkboxChanged:self];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
- (void)setChecked:(BOOL)checked { _checked = checked; [self refresh]; }
- (void)refresh {
    if (_checked) {
        self.backgroundColor   = [MenuViewController accentOrangeColor];
        self.layer.borderColor = [MenuViewController accentOrangeColor].CGColor;
    } else {
        self.backgroundColor   = [UIColor clearColor];
        self.layer.borderColor = RGB(90, 96, 110).CGColor;
    }
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    if (!_checked) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextMoveToPoint(ctx,    rect.size.width * 0.22, rect.size.height * 0.52);
    CGContextAddLineToPoint(ctx, rect.size.width * 0.44, rect.size.height * 0.72);
    CGContextAddLineToPoint(ctx, rect.size.width * 0.78, rect.size.height * 0.32);
    CGContextStrokePath(ctx);
}
@end

#pragma mark - OrangeSlider

@interface OrangeSlider : UISlider
@property (nonatomic, copy) NSString *stateKey;
@property (nonatomic, copy) void (^onChange)(float v);
@end
@implementation OrangeSlider
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.minimumTrackTintColor = [MenuViewController accentOrangeColor];
        self.maximumTrackTintColor = [MenuViewController trackInactiveColor];
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 18), NO, 0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(ctx, [MenuViewController accentOrangeColor].CGColor);
        CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, 18, 18));
        UIImage *thumb = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self setThumbImage:thumb forState:UIControlStateNormal];
        [self setThumbImage:thumb forState:UIControlStateHighlighted];
        [self addTarget:self action:@selector(onSliderChanged) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}
- (void)onSliderChanged {
    if (self.stateKey) [[MenuState shared] setFloat:self.value for:self.stateKey];
    if (self.onChange)  self.onChange(self.value);
}
@end

#pragma mark - ColorSwatch

@interface ColorSwatch : UIControl
@property (nonatomic, strong) UIColor *swatchColor;
@end
@implementation ColorSwatch
- (instancetype)initWithColor:(UIColor *)c {
    if ((self = [super initWithFrame:CGRectMake(0, 0, 22, 14)])) {
        _swatchColor = c;
        self.backgroundColor = c;
        self.layer.cornerRadius = 2.0;
    }
    return self;
}
@end

#pragma mark - DropdownField

@class DropdownField;
@protocol DropdownDelegate <NSObject>
- (void)dropdownTapped:(DropdownField *)dd;
@end

@interface DropdownField : UIControl
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UIImageView *chevron;
@property (nonatomic, copy) NSString *stateKey;
@property (nonatomic, strong) NSArray<NSString *> *options;
@property (nonatomic, weak) id<DropdownDelegate> ddDelegate;
- (instancetype)initWithText:(NSString *)text;
@end
@implementation DropdownField
- (instancetype)initWithText:(NSString *)text {
    if ((self = [super initWithFrame:CGRectZero])) {
        self.backgroundColor = [MenuViewController dropdownBackgroundColor];
        self.layer.cornerRadius = 4.0;

        _valueLabel = [[UILabel alloc] init];
        _valueLabel.text = text;
        _valueLabel.font = [UIFont systemFontOfSize:13.0];
        _valueLabel.textColor = [UIColor whiteColor];
        [self addSubview:_valueLabel];

        _chevron = [[UIImageView alloc] init];
        _chevron.contentMode = UIViewContentModeScaleAspectFit;
        _chevron.tintColor = RGB(150, 158, 172);
        if (@available(iOS 13.0, *)) {
            _chevron.image = [[UIImage systemImageNamed:@"chevron.down"]
                              imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        [self addSubview:_chevron];

        [self addTarget:self action:@selector(onTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}
- (void)onTap { [self.ddDelegate dropdownTapped:self]; }
- (void)layoutSubviews {
    [super layoutSubviews];
    _valueLabel.frame = CGRectMake(12, 0, self.bounds.size.width - 36, self.bounds.size.height);
    _chevron.frame    = CGRectMake(self.bounds.size.width - 24, (self.bounds.size.height - 10)/2.0, 12, 10);
}
@end

#pragma mark - MenuViewController

@interface MenuViewController () <DropdownDelegate>
@property (nonatomic, strong, readwrite) UIView *panelView;
@property (nonatomic, strong) UIView      *sidebarView;
@property (nonatomic, strong) UIView      *contentView;
@property (nonatomic, strong) UIScrollView *contentScroll;
@property (nonatomic, strong) UIView      *headerView;
@property (nonatomic, strong) UIImageView *headerIcon;
@property (nonatomic, strong) UILabel     *headerTitle;
@property (nonatomic, strong) UILabel     *headerSubtitle;
@property (nonatomic, strong) UIView      *headerDivider;
@property (nonatomic, strong) UIButton    *closeButton;
@property (nonatomic, strong) UIView      *dragHandle;
@property (nonatomic, strong) NSArray<UIButton *> *tabButtons;
@property (nonatomic, strong) NSArray<UIView   *> *tabIndicators;
@end

@implementation MenuViewController {
    NSArray<NSString *> *_tabTitles;
    NSArray<NSString *> *_tabSymbols;
    CGPoint _dragStartCenter;
    UIWindow *_overlayWindow;
}

+ (UIColor *)panelBackgroundColor    { return RGB(26, 32, 48);  }
+ (UIColor *)sidebarBackgroundColor  { return RGB(20, 25, 35);  }
+ (UIColor *)accentOrangeColor       { return RGB(255, 90, 31); }
+ (UIColor *)mutedTextColor          { return RGB(138, 147, 166); }
+ (UIColor *)dropdownBackgroundColor { return RGB(35, 42, 56);  }
+ (UIColor *)trackInactiveColor      { return RGB(58, 65, 80);  }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = RGBA(0, 0, 0, 0.35);

    _tabTitles  = @[@"Aimbot", @"Visuals", @"Misc", @"Settings"];
    _tabSymbols = @[@"scope", @"eye", @"shippingbox", @"gearshape"];

    [self buildPanel];
    [self buildSidebar];
    [self buildContentArea];
    [self buildCloseButton];
    [self installPanelDrag];

    self.activeTab = MenuTabAimbot;
    [self renderActiveTab];

    // tap on dim backdrop = dismiss (must NOT swallow touches to subviews)
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(backdropTapped:)];
    tap.cancelsTouchesInView = NO;
    tap.delaysTouchesBegan   = NO;
    tap.delaysTouchesEnded   = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)backdropTapped:(UITapGestureRecognizer *)g {
    CGPoint p = [g locationInView:self.view];
    if (!CGRectContainsPoint(_panelView.frame, p) &&
        !CGRectContainsPoint(_closeButton.frame, p)) {
        [self dismissMenuAnimated:YES];
    }
}

#pragma mark Build

- (void)buildPanel {
    CGFloat panelW = 540, panelH = 446; // +16 for drag bar
    CGFloat px = (self.view.bounds.size.width  - panelW) / 2.0;
    CGFloat py = (self.view.bounds.size.height - panelH) / 2.0;

    _panelView = [[UIView alloc] initWithFrame:CGRectMake(px, py, panelW, panelH)];
    _panelView.backgroundColor = [MenuViewController panelBackgroundColor];
    _panelView.layer.cornerRadius = 6.0;
    _panelView.clipsToBounds = YES;
    _panelView.userInteractionEnabled = YES;
    [self.view addSubview:_panelView];

    // Visible drag bar across the top
    _dragHandle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, panelW, 16)];
    _dragHandle.backgroundColor = RGB(20, 25, 35);
    _dragHandle.userInteractionEnabled = YES;
    [_panelView addSubview:_dragHandle];

    // grip dots
    for (int i = 0; i < 3; i++) {
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(panelW/2.0 - 14 + i*12, 6, 4, 4)];
        dot.backgroundColor = RGB(90, 96, 110);
        dot.layer.cornerRadius = 2.0;
        dot.userInteractionEnabled = NO;
        [_dragHandle addSubview:dot];
    }
}

- (void)buildSidebar {
    CGFloat sbW = 110;
    CGFloat topOff = 16; // below drag bar
    _sidebarView = [[UIView alloc] initWithFrame:CGRectMake(0, topOff, sbW, _panelView.bounds.size.height - topOff)];
    _sidebarView.backgroundColor = [MenuViewController sidebarBackgroundColor];
    _sidebarView.userInteractionEnabled = YES;
    [_panelView addSubview:_sidebarView];

    NSMutableArray *btns = [NSMutableArray array];
    NSMutableArray *inds = [NSMutableArray array];

    CGFloat tabH = 78, startY = 18;

    for (NSInteger i = 0; i < _tabTitles.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(0, startY + i * tabH, sbW, tabH);
        b.tag = i;
        b.userInteractionEnabled = YES;
        [b addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_sidebarView addSubview:b];

        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake((sbW - 22)/2.0, 14, 22, 22)];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        iv.tag = 1001;
        iv.userInteractionEnabled = NO;
        if (@available(iOS 13.0, *)) {
            iv.image = [[UIImage systemImageNamed:_tabSymbols[i]]
                        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        iv.tintColor = [MenuViewController mutedTextColor];
        [b addSubview:iv];

        UILabel *lb = [[UILabel alloc] initWithFrame:CGRectMake(0, 42, sbW, 18)];
        lb.tag = 1002;
        lb.text = _tabTitles[i];
        lb.textAlignment = NSTextAlignmentCenter;
        lb.font = [UIFont systemFontOfSize:13.0];
        lb.textColor = [MenuViewController mutedTextColor];
        lb.userInteractionEnabled = NO;
        [b addSubview:lb];

        UIView *ind = [[UIView alloc] initWithFrame:CGRectMake(sbW - 3, startY + i * tabH + 12, 3, tabH - 24)];
        ind.backgroundColor = [MenuViewController accentOrangeColor];
        ind.hidden = YES;
        ind.userInteractionEnabled = NO;
        [_sidebarView addSubview:ind];

        [btns addObject:b];
        [inds addObject:ind];
    }
    _tabButtons    = btns;
    _tabIndicators = inds;
}

- (void)buildContentArea {
    CGFloat sbW = _sidebarView.bounds.size.width;
    CGFloat topOff = 16;
    CGRect r = CGRectMake(sbW, topOff,
                          _panelView.bounds.size.width - sbW,
                          _panelView.bounds.size.height - topOff);
    _contentView = [[UIView alloc] initWithFrame:r];
    _contentView.backgroundColor = [MenuViewController panelBackgroundColor];
    [_panelView addSubview:_contentView];

    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, r.size.width, 56)];
    _headerView.userInteractionEnabled = NO;
    [_contentView addSubview:_headerView];

    _headerIcon = [[UIImageView alloc] initWithFrame:CGRectMake(18, 18, 18, 18)];
    _headerIcon.contentMode = UIViewContentModeScaleAspectFit;
    _headerIcon.tintColor = [MenuViewController accentOrangeColor];
    [_headerView addSubview:_headerIcon];

    _headerTitle = [[UILabel alloc] initWithFrame:CGRectMake(42, 16, 100, 22)];
    _headerTitle.font = [UIFont boldSystemFontOfSize:14.0];
    _headerTitle.textColor = [MenuViewController accentOrangeColor];
    [_headerView addSubview:_headerTitle];

    _headerDivider = [[UIView alloc] initWithFrame:CGRectMake(120, 20, 1, 16)];
    _headerDivider.backgroundColor = RGB(60, 66, 80);
    [_headerView addSubview:_headerDivider];

    _headerSubtitle = [[UILabel alloc] initWithFrame:CGRectMake(132, 16, r.size.width - 150, 22)];
    _headerSubtitle.font = [UIFont systemFontOfSize:13.5];
    _headerSubtitle.textColor = [UIColor whiteColor];
    [_headerView addSubview:_headerSubtitle];

    _contentScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 56, r.size.width, r.size.height - 56)];
    _contentScroll.alwaysBounceVertical = YES;
    [_contentView addSubview:_contentScroll];
}

- (void)buildCloseButton {
    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self repositionCloseButton];
    if (@available(iOS 13.0, *)) {
        UIImage *x = [[UIImage systemImageNamed:@"xmark"]
                      imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_closeButton setImage:x forState:UIControlStateNormal];
    }
    _closeButton.tintColor = [UIColor whiteColor];
    [_closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_closeButton];
}

- (void)repositionCloseButton {
    CGFloat cx = CGRectGetMaxX(_panelView.frame) + 14;
    CGFloat cy = CGRectGetMinY(_panelView.frame) + 14;
    _closeButton.frame = CGRectMake(cx, cy, 28, 28);
}

#pragma mark Drag the whole panel

- (void)installPanelDrag {
    // Single-finger drag on the visible top bar
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(handlePan:)];
    pan.maximumNumberOfTouches = 1;
    [_dragHandle addGestureRecognizer:pan];

    // 2-finger pan anywhere on the panel (doesn't conflict with sliders/buttons)
    UIPanGestureRecognizer *pan2 = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                           action:@selector(handlePan:)];
    pan2.minimumNumberOfTouches = 2;
    pan2.maximumNumberOfTouches = 2;
    [_panelView addGestureRecognizer:pan2];
}

- (void)handlePan:(UIPanGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateBegan) {
        _dragStartCenter = _panelView.center;
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGPoint t = [g translationInView:self.view];
        CGPoint c = CGPointMake(_dragStartCenter.x + t.x, _dragStartCenter.y + t.y);

        // Clamp inside view bounds
        CGSize  s = _panelView.bounds.size;
        CGSize  vs = self.view.bounds.size;
        CGFloat minX = s.width  / 2.0;
        CGFloat maxX = vs.width  - s.width  / 2.0;
        CGFloat minY = s.height / 2.0;
        CGFloat maxY = vs.height - s.height / 2.0;
        c.x = MAX(minX, MIN(maxX, c.x));
        c.y = MAX(minY, MIN(maxY, c.y));

        _panelView.center = c;
        [self repositionCloseButton];
    }
}

#pragma mark Tabs

- (void)tabTapped:(UIButton *)sender { [self selectTab:(MenuTab)sender.tag]; }

- (void)selectTab:(MenuTab)tab {
    _activeTab = tab;
    [self renderActiveTab];
}

- (void)renderActiveTab {
    for (NSInteger i = 0; i < _tabButtons.count; i++) {
        UIButton    *b   = _tabButtons[i];
        UIImageView *iv  = (UIImageView *)[b viewWithTag:1001];
        UILabel     *lb  = (UILabel *)[b viewWithTag:1002];
        UIView      *ind = _tabIndicators[i];
        BOOL active = (i == self.activeTab);

        b.backgroundColor = active ? [MenuViewController panelBackgroundColor] : [UIColor clearColor];
        iv.tintColor = active ? [UIColor whiteColor] : [MenuViewController mutedTextColor];
        lb.textColor = active ? [UIColor whiteColor] : [MenuViewController mutedTextColor];
        ind.hidden = !active;
    }

    for (UIView *v in [_contentScroll.subviews copy]) [v removeFromSuperview];
    _contentScroll.contentOffset = CGPointZero;

    switch (self.activeTab) {
        case MenuTabAimbot:   [self renderAimbot];   break;
        case MenuTabVisuals:  [self renderVisuals];  break;
        case MenuTabMisc:     [self renderMisc];     break;
        case MenuTabSettings: [self renderSettings]; break;
    }
}

#pragma mark Header

- (void)setHeaderSymbol:(NSString *)symbol title:(NSString *)title subtitle:(NSString *)subtitle {
    if (@available(iOS 13.0, *)) {
        _headerIcon.image = [[UIImage systemImageNamed:symbol]
                             imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    _headerTitle.text = title;
    [_headerTitle sizeToFit];
    CGRect tf = _headerTitle.frame;
    tf.origin = CGPointMake(42, 16); tf.size.height = 22;
    _headerTitle.frame = tf;

    _headerDivider.frame = CGRectMake(CGRectGetMaxX(tf) + 12, 20, 1, 16);
    _headerSubtitle.text = subtitle;
    _headerSubtitle.frame = CGRectMake(CGRectGetMaxX(_headerDivider.frame) + 12, 16,
                                       _headerView.bounds.size.width - CGRectGetMaxX(_headerDivider.frame) - 24, 22);
}

#pragma mark Row factories (with state binding)

- (CGFloat)contentInsetX { return 22; }
- (CGFloat)contentWidth  { return _contentScroll.bounds.size.width - 2*[self contentInsetX]; }

- (UIView *)checkRow:(NSString *)title key:(NSString *)key def:(BOOL)def
       rightAccessory:(UIView *)acc width:(CGFloat)w {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 28)];

    OrangeCheckbox *box = [[OrangeCheckbox alloc] initWithFrame:CGRectMake(0, 6, 16, 16)];
    box.stateKey = key;
    box.checked = [[MenuState shared] boolFor:key def:def];
    [row addSubview:box];

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(28, 4, w - 80, 20)];
    lbl.text = title;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:14.0];
    [row addSubview:lbl];

    if (acc) {
        CGRect f = acc.frame;
        f.origin.x = w - f.size.width - 4;
        f.origin.y = (28 - f.size.height) / 2.0;
        acc.frame = f;
        [row addSubview:acc];
    }
    return row;
}

- (UIView *)labelRow:(NSString *)title rightAccessory:(UIView *)acc width:(CGFloat)w {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 24)];
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, w - 80, 20)];
    lbl.text = title;
    lbl.textColor = [MenuViewController mutedTextColor];
    lbl.font = [UIFont systemFontOfSize:13.0];
    [row addSubview:lbl];
    if (acc) {
        CGRect f = acc.frame;
        f.origin.x = w - f.size.width - 4;
        f.origin.y = (24 - f.size.height) / 2.0;
        acc.frame = f;
        [row addSubview:acc];
    }
    return row;
}

- (UIView *)dropdownRow:(NSString *)title key:(NSString *)key def:(NSString *)def
                options:(NSArray<NSString *> *)opts width:(CGFloat)w {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 56)];
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, w, 18)];
    lbl.text = title;
    lbl.textColor = [MenuViewController mutedTextColor];
    lbl.font = [UIFont systemFontOfSize:12.5];
    [row addSubview:lbl];

    NSString *cur = [[MenuState shared] stringFor:key def:def];
    DropdownField *dd = [[DropdownField alloc] initWithText:cur];
    dd.frame = CGRectMake(0, 22, w, 32);
    dd.stateKey = key;
    dd.options = opts;
    dd.ddDelegate = self;
    [row addSubview:dd];
    return row;
}

- (UIView *)sliderRow:(NSString *)title key:(NSString *)key def:(float)def
                unit:(NSString *)unit minVal:(float)mn maxVal:(float)mx
                width:(CGFloat)w {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 44)];

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, w - 100, 18)];
    lbl.text = title;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:13.0];
    [row addSubview:lbl];

    float v = [[MenuState shared] floatFor:key def:def];

    UILabel *val = [[UILabel alloc] initWithFrame:CGRectZero];
    val.textColor = [MenuViewController accentOrangeColor];
    val.font = [UIFont systemFontOfSize:12.5];
    val.text = [self formatSliderValue:v unit:unit minVal:mn maxVal:mx];
    [val sizeToFit];
    CGSize titleSize = [lbl sizeThatFits:CGSizeMake(w, 18)];
    val.frame = CGRectMake(titleSize.width + 8, 0, val.frame.size.width + 4, 18);
    [row addSubview:val];

    OrangeSlider *sl = [[OrangeSlider alloc] initWithFrame:CGRectMake(0, 22, w, 20)];
    sl.minimumValue = 0; sl.maximumValue = 1; sl.value = v;
    sl.stateKey = key;
    __weak UILabel *wval = val;
    __weak typeof(self) wself = self;
    sl.onChange = ^(float nv) {
        wval.text = [wself formatSliderValue:nv unit:unit minVal:mn maxVal:mx];
        [wval sizeToFit];
        CGRect f = wval.frame; f.size.width += 4; f.origin.y = 0;
        f.origin.x = titleSize.width + 8;
        wval.frame = f;
    };
    [row addSubview:sl];
    return row;
}

- (NSString *)formatSliderValue:(float)v unit:(NSString *)unit minVal:(float)mn maxVal:(float)mx {
    float real = mn + (mx - mn) * v;
    if ([unit isEqualToString:@"Â°"])  return [NSString stringWithFormat:@"%.1fÂ°",  real];
    if ([unit isEqualToString:@"m"])  return [NSString stringWithFormat:@"%.1fm",  real];
    if ([unit isEqualToString:@"px"]) return [NSString stringWithFormat:@"%.1fpx", real];
    return [NSString stringWithFormat:@"%.3f", real];
}

#pragma mark Dropdown picker

- (void)dropdownTapped:(DropdownField *)dd {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:nil
                                                          preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *opt in dd.options) {
        [ac addAction:[UIAlertAction actionWithTitle:opt style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *a) {
            dd.valueLabel.text = opt;
            if (dd.stateKey) [[MenuState shared] setString:opt for:dd.stateKey];
        }]];
    }
    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    if (ac.popoverPresentationController) {
        ac.popoverPresentationController.sourceView = dd;
        ac.popoverPresentationController.sourceRect = dd.bounds;
    }
    [self presentViewController:ac animated:YES completion:nil];
}

#pragma mark Layout helper

- (void)layoutRows:(NSArray<UIView *> *)rows spacing:(CGFloat)spacing {
    CGFloat y = 12, x = [self contentInsetX], total = 0;
    for (UIView *r in rows) {
        CGRect f = r.frame; f.origin = CGPointMake(x, y); r.frame = f;
        [_contentScroll addSubview:r];
        y += f.size.height + spacing;
        total = y;
    }
    _contentScroll.contentSize = CGSizeMake(_contentScroll.bounds.size.width, total + 12);
}

#pragma mark Tab content

- (void)renderAimbot {
    [self setHeaderSymbol:@"scope" title:@"AIMBOT" subtitle:@"Automatically aim at enemies."];
    CGFloat w = [self contentWidth];

    NSMutableArray *rows = [NSMutableArray array];
    [rows addObject:[self checkRow:@"Master switch" key:@"aim.master" def:YES rightAccessory:nil width:w]];
    [rows addObject:[self dropdownRow:@"Aimbot config" key:@"aim.config" def:@"Global"
                              options:@[@"Global", @"Pistol", @"Rifle", @"Sniper"] width:w]];
    [rows addObject:[self checkRow:@"Enabled" key:@"aim.enabled" def:YES rightAccessory:nil width:w]];
    [rows addObject:[self dropdownRow:@"Aiming method" key:@"aim.method" def:@"Vectored"
                              options:@[@"Vectored", @"Linear", @"Smoothed"] width:w]];

    ColorSwatch *green = [[ColorSwatch alloc] initWithColor:RGB(50, 220, 80)];
    [rows addObject:[self checkRow:@"Show FOV circle" key:@"aim.fovshow" def:YES rightAccessory:green width:w]];

    [rows addObject:[self dropdownRow:@"Ignore types" key:@"aim.ignore" def:@"Invisible, Knocked"
                              options:@[@"None", @"Invisible", @"Knocked", @"Invisible, Knocked"] width:w]];
    [rows addObject:[self checkRow:@"Force lock" key:@"aim.flock" def:NO rightAccessory:nil width:w]];
    [rows addObject:[self dropdownRow:@"Hitbox" key:@"aim.hitbox" def:@"Neck"
                              options:@[@"Head", @"Neck", @"Chest", @"Stomach"] width:w]];
    [rows addObject:[self dropdownRow:@"Target priority" key:@"aim.target" def:@"Closest to crosshair"
                              options:@[@"Closest to crosshair", @"Closest to player", @"Lowest health"] width:w]];
    [rows addObject:[self dropdownRow:@"Trigger on" key:@"aim.trigger" def:@"Shooting or aiming"
                              options:@[@"Always", @"Shooting", @"Aiming", @"Shooting or aiming"] width:w]];
    [rows addObject:[self sliderRow:@"FOV"          key:@"aim.fov"   def:0.20 unit:@"Â°" minVal:0 maxVal:90  width:w]];
    [rows addObject:[self sliderRow:@"Max distance" key:@"aim.dist"  def:0.50 unit:@"m" minVal:0 maxVal:300 width:w]];
    [rows addObject:[self sliderRow:@"Lock-on speed" key:@"aim.speed" def:0.0  unit:@""  minVal:0 maxVal:1   width:w]];

    [self layoutRows:rows spacing:8];
}

- (void)renderVisuals {
    [self setHeaderSymbol:@"eye" title:@"VISUALS" subtitle:@"Visual improvements."];
    CGFloat w = [self contentWidth];

    NSMutableArray *rows = [NSMutableArray array];
    [rows addObject:[self checkRow:@"Enemy ESP" key:@"vis.esp" def:YES rightAccessory:nil width:w]];

    ColorSwatch *white = [[ColorSwatch alloc] initWithColor:[UIColor whiteColor]];
    [rows addObject:[self checkRow:@"Line" key:@"vis.line" def:YES rightAccessory:white width:w]];
    [rows addObject:[self checkRow:@"Line fire material" key:@"vis.linefire" def:NO rightAccessory:nil width:w]];

    [rows addObject:[self checkRow:@"Box" key:@"vis.box" def:YES
                     rightAccessory:[self pairRed:RGB(230,60,60) green:RGB(50,220,80)] width:w]];
    [rows addObject:[self checkRow:@"Health"   key:@"vis.health"   def:YES rightAccessory:nil width:w]];
    [rows addObject:[self checkRow:@"Nickname" key:@"vis.nickname" def:YES rightAccessory:nil width:w]];
    [rows addObject:[self checkRow:@"Distance" key:@"vis.distance" def:YES rightAccessory:nil width:w]];
    [rows addObject:[self checkRow:@"Skeleton" key:@"vis.skeleton" def:NO
                     rightAccessory:[self pairRed:RGB(230,60,60) green:RGB(50,220,80)] width:w]];
    [rows addObject:[self checkRow:@"Nearby enemies count" key:@"vis.nearby" def:YES rightAccessory:nil width:w]];

    ColorSwatch *red = [[ColorSwatch alloc] initWithColor:RGB(230,60,60)];
    [rows addObject:[self labelRow:@"Counter text color" rightAccessory:red width:w]];
    [rows addObject:[self sliderRow:@"Counter text size" key:@"vis.csize" def:0.85 unit:@"px" minVal:8 maxVal:30 width:w]];

    ColorSwatch *white2 = [[ColorSwatch alloc] initWithColor:[UIColor whiteColor]];
    [rows addObject:[self labelRow:@"Text color" rightAccessory:white2 width:w]];
    [rows addObject:[self sliderRow:@"Text size" key:@"vis.tsize" def:0.40 unit:@"px" minVal:8 maxVal:30 width:w]];

    [self layoutRows:rows spacing:8];
}

- (UIView *)pairRed:(UIColor *)red green:(UIColor *)green {
    UIView *pair = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 14)];
    ColorSwatch *r = [[ColorSwatch alloc] initWithColor:red];
    r.frame = CGRectMake(0, 0, 22, 14); [pair addSubview:r];
    ColorSwatch *g = [[ColorSwatch alloc] initWithColor:green];
    g.frame = CGRectMake(28, 0, 22, 14); [pair addSubview:g];
    return pair;
}

- (void)renderMisc {
    [self setHeaderSymbol:@"shippingbox" title:@"MISC" subtitle:@"Game enhancements."];
    CGFloat w = [self contentWidth];

    UILabel *warn1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, w, 20)];
    warn1.text = @"These features are only for fun and may be unsafe.";
    warn1.textColor = [UIColor whiteColor]; warn1.font = [UIFont systemFontOfSize:13.5];

    UILabel *warn2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, w, 20)];
    warn2.text = @"Use them at your own risk!";
    warn2.textColor = [UIColor whiteColor]; warn2.font = [UIFont systemFontOfSize:13.5];

    NSMutableArray *rows = [NSMutableArray array];
    [rows addObject:warn1];
    [rows addObject:warn2];
    [rows addObject:[self checkRow:@"No fog"                    key:@"misc.fog"     def:NO rightAccessory:nil width:w]];
    [rows addObject:[self checkRow:@"No weapon spread"          key:@"misc.spread"  def:NO rightAccessory:nil width:w]];
    [rows addObject:[self checkRow:@"Instant loot"              key:@"misc.loot"    def:NO rightAccessory:nil width:w]];
    [rows addObject:[self checkRow:@"Inverted IceWall rotation" key:@"misc.icewall" def:NO rightAccessory:nil width:w]];
    [rows addObject:[self checkRow:@"Aspect ratio"              key:@"misc.aspect"  def:NO rightAccessory:nil width:w]];
    [rows addObject:[self checkRow:@"Auto-fire"                 key:@"misc.autofire" def:NO rightAccessory:nil width:w]];
    [rows addObject:[self checkRow:@"FPS unlocker"              key:@"misc.fps"     def:NO rightAccessory:nil width:w]];
    [rows addObject:[self checkRow:@"Spinbot"                   key:@"misc.spin"    def:NO rightAccessory:nil width:w]];

    [self layoutRows:rows spacing:10];
}

- (void)renderSettings {
    [self setHeaderSymbol:@"gearshape" title:@"SETTINGS" subtitle:@"Menu preferences."];
    CGFloat w = [self contentWidth];
    NSMutableArray *rows = [NSMutableArray array];
    [rows addObject:[self dropdownRow:@"Language" key:@"set.lang" def:@"English"
                              options:@[@"English", @"à¹à¸à¸¢", @"ä¸­æ", @"EspaÃ±ol", @"PortuguÃªs"] width:w]];
    [rows addObject:[self sliderRow:@"Menu opacity" key:@"set.opacity" def:0.95 unit:@"" minVal:0 maxVal:1 width:w]];
    [rows addObject:[self checkRow:@"Hide on screenshot" key:@"set.hidess" def:YES rightAccessory:nil width:w]];
    [rows addObject:[self checkRow:@"Allow drag (2-finger anywhere on panel)" key:@"set.drag" def:YES rightAccessory:nil width:w]];
    [self layoutRows:rows spacing:10];
}

#pragma mark Show / Dismiss

- (void)showMenuAnimated:(BOOL)animated {
    if (!_overlayWindow) {
        UIWindow *keyWindow = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        keyWindow = [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
        if (!keyWindow) {
            if (@available(iOS 13.0, *)) {
                for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
                    if ([s isKindOfClass:[UIWindowScene class]] && s.activationState == UISceneActivationStateForegroundActive) {
                        UIWindowScene *ws = (UIWindowScene *)s;
                        keyWindow = ws.windows.firstObject;
                        break;
                    }
                }
            }
        }
        _overlayWindow = [[UIWindow alloc] initWithFrame:keyWindow.bounds];
        _overlayWindow.backgroundColor = [UIColor clearColor];
        _overlayWindow.windowLevel     = UIWindowLevelAlert + 100;
        _overlayWindow.rootViewController = self;
        _overlayWindow.hidden = NO;
        [_overlayWindow makeKeyAndVisible];
    } else {
        _overlayWindow.hidden = NO;
    }

    if (animated) {
        self.view.alpha = 0;
        [UIView animateWithDuration:0.18 animations:^{ self.view.alpha = 1; }];
    } else {
        self.view.alpha = 1;
    }
}

- (void)dismissMenuAnimated:(BOOL)animated {
    void (^teardown)(void) = ^{
        self->_overlayWindow.hidden = YES;
        self->_overlayWindow.rootViewController = nil;
        self->_overlayWindow = nil;
    };
    if (animated) {
        [UIView animateWithDuration:0.18 animations:^{ self.view.alpha = 0; }
                         completion:^(BOOL f){ teardown(); }];
    } else {
        teardown();
    }
}

- (void)closeTapped { [self dismissMenuAnimated:YES]; }

@end
