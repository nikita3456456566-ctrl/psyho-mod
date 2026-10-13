#import <UIKit/UIKit.h>

// ============================================================
// ТЕМЫ
// ============================================================
static UIColor *gAccent;
static UIColor *gAccent2;
static UIColor *gAccentSoft;
static UIColor *gBg;
static NSString *gTheme = @"red";

static void applyTheme(NSString *name) {
    gTheme = name;
    if ([name isEqualToString:@"bw"]) {
        gAccent = [UIColor whiteColor];
        gAccent2 = [UIColor colorWithWhite:0.5 alpha:1];
        gAccentSoft = [UIColor colorWithWhite:1 alpha:0.12];
    } else if ([name isEqualToString:@"blue"]) {
        gAccent = [UIColor colorWithRed:0.23 green:0.54 blue:1 alpha:1];
        gAccent2 = [UIColor colorWithRed:0.10 green:0.29 blue:0.81 alpha:1];
        gAccentSoft = [UIColor colorWithRed:0.23 green:0.54 blue:1 alpha:0.15];
    } else if ([name isEqualToString:@"neon"]) {
        gAccent = [UIColor colorWithRed:0 green:1 blue:0.47 alpha:1];
        gAccent2 = [UIColor colorWithRed:0 green:0.63 blue:0.31 alpha:1];
        gAccentSoft = [UIColor colorWithRed:0 green:1 blue:0.47 alpha:0.12];
    } else {
        gAccent = [UIColor colorWithRed:1 green:0.2 blue:0.27 alpha:1];
        gAccent2 = [UIColor colorWithRed:0.76 green:0.07 blue:0.12 alpha:1];
        gAccentSoft = [UIColor colorWithRed:1 green:0.2 blue:0.27 alpha:0.15];
    }
    gBg = [UIColor blackColor];
}

static NSString *const kThemeChanged = @"PSYThemeChanged";

// ============================================================
// ТУМБЛЕР
// ============================================================
@interface PSYSwitch : UIControl
@property (nonatomic, assign) BOOL on;
@end

@implementation PSYSwitch {
    UIView *_knob;
}
- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0, 0, 50, 28)];
    if (self) {
        self.layer.cornerRadius = 14;
        self.layer.borderWidth = 1;
        self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.05];
        self.layer.borderColor = gAccent.CGColor;
        _knob = [[UIView alloc] initWithFrame:CGRectMake(3, 3, 20, 20)];
        _knob.layer.cornerRadius = 10;
        _knob.backgroundColor = [UIColor colorWithWhite:0.27 alpha:1];
        [self addSubview:_knob];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTheme) name:kThemeChanged object:nil];
    }
    return self;
}
- (void)refreshTheme {
    self.layer.borderColor = gAccent.CGColor;
    [self updateAppearance];
}
- (void)setOn:(BOOL)on {
    _on = on;
    [self updateAppearance];
}
- (void)updateAppearance {
    [UIView animateWithDuration:0.25 animations:^{
        if (self->_on) {
            self.backgroundColor = gAccent;
            self->_knob.backgroundColor = [UIColor whiteColor];
            self->_knob.frame = CGRectMake(27, 3, 20, 20);
        } else {
            self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.05];
            self->_knob.backgroundColor = [UIColor colorWithWhite:0.27 alpha:1];
            self->_knob.frame = CGRectMake(3, 3, 20, 20);
        }
    }];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.on = !self.on;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

// ============================================================
// СЛАЙДЕР
// ============================================================
@interface PSYSlider : UIView
@property (nonatomic, assign) float value;
@property (nonatomic, assign) float minValue;
@property (nonatomic, assign) float maxValue;
@property (nonatomic, copy) void (^onChange)(float);
@end

@implementation PSYSlider {
    UIView *_track;
    UIView *_fill;
    UIView *_thumb;
}
- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0, 0, 260, 30)];
    if (self) {
        _minValue = 0; _maxValue = 100; _value = 50;
        _track = [[UIView alloc] initWithFrame:CGRectMake(0, 12, 260, 6)];
        _track.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
        _track.layer.cornerRadius = 3;
        [self addSubview:_track];
        _fill = [[UIView alloc] initWithFrame:CGRectMake(0, 12, 130, 6)];
        _fill.backgroundColor = gAccent;
        _fill.layer.cornerRadius = 3;
        [self addSubview:_fill];
        _thumb = [[UIView alloc] initWithFrame:CGRectMake(120, 4, 22, 22)];
        _thumb.backgroundColor = [UIColor whiteColor];
        _thumb.layer.cornerRadius = 11;
        _thumb.layer.borderWidth = 2;
        _thumb.layer.borderColor = gAccent.CGColor;
        _thumb.layer.shadowColor = gAccent.CGColor;
        _thumb.layer.shadowRadius = 6;
        _thumb.layer.shadowOpacity = 0.6;
        _thumb.layer.shadowOffset = CGSizeZero;
        [self addSubview:_thumb];
        [self updatePosition];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTheme) name:kThemeChanged object:nil];
    }
    return self;
}
- (void)refreshTheme {
    _fill.backgroundColor = gAccent;
    _thumb.layer.borderColor = gAccent.CGColor;
    _thumb.layer.shadowColor = gAccent.CGColor;
}
- (void)handlePan:(UIPanGestureRecognizer *)g {
    CGPoint p = [g locationInView:self];
    float ratio = MAX(0, MIN(1, p.x / self.bounds.size.width));
    self.value = _minValue + ratio * (_maxValue - _minValue);
    [self updatePosition];
    if (self.onChange) self.onChange(self.value);
}
- (void)setValue:(float)value {
    _value = MAX(_minValue, MIN(_maxValue, value));
    [self updatePosition];
}
- (void)updatePosition {
    float ratio = (_value - _minValue) / (_maxValue - _minValue);
    CGFloat w = self.bounds.size.width;
    CGFloat x = ratio * w;
    _fill.frame = CGRectMake(0, 12, x, 6);
    _thumb.center = CGPointMake(x, 15);
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _track.frame = CGRectMake(0, 12, self.bounds.size.width, 6);
    [self updatePosition];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

// ============================================================
// КРУГЛАЯ КНОПКА
// ============================================================
@interface PSYCircleButton : UIWindow
@end

@implementation PSYCircleButton {
    UIImageView *_imageView;
}
- (instancetype)init {
    CGFloat size = 52;
    CGRect frame = CGRectMake(40, 100, size, size);
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelAlert + 200;
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = size / 2;
        self.clipsToBounds = YES;

        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.backgroundColor = [UIColor blackColor];
        [self addSubview:_imageView];

        NSURL *url = [NSURL URLWithString:@"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS924TmX-UWwWpCYlH2i50OmnoW9QZh6Jra8g&s"];
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            NSData *d = [NSData dataWithContentsOfURL:url];
            if (d) {
                UIImage *img = [UIImage imageWithData:d];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->_imageView.image = img;
                });
            }
        });

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMenu)];
        [self addGestureRecognizer:tap];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];

        self.hidden = NO;
    }
    return self;
}
- (void)toggleMenu {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PSYToggleMenu" object:nil];
}
- (void)handlePan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.superview];
    CGPoint c = self.center;
    c.x += t.x;
    c.y += t.y;
    CGFloat w = self.bounds.size.width / 2;
    c.x = MAX(w, MIN([UIScreen mainScreen].bounds.size.width - w, c.x));
    c.y = MAX(w, MIN([UIScreen mainScreen].bounds.size.height - w, c.y));
    self.center = c;
    [g setTranslation:CGPointZero inView:self.superview];
}
@end

// ============================================================
// HUD
// ============================================================
@interface PSYTopHUD : UIWindow
@end

@implementation PSYTopHUD {
    UILabel *_label;
}
- (instancetype)init {
    CGFloat w = 120, h = 30;
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    self = [super initWithFrame:CGRectMake((sw - w)/2, 40, w, h)];
    if (self) {
        self.windowLevel = UIWindowLevelAlert + 150;
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 8;
        self.layer.borderWidth = 1;
        self.layer.borderColor = gAccent.CGColor;
        self.clipsToBounds = YES;

        UIView *bg = [[UIView alloc] initWithFrame:self.bounds];
        bg.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
        [self addSubview:bg];

        _label = [[UILabel alloc] initWithFrame:self.bounds];
        _label.text = @"psyho vip";
        _label.textColor = [UIColor whiteColor];
        _label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.alpha = 0.95;
        [self addSubview:_label];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTheme) name:kThemeChanged object:nil];
        self.hidden = NO;
    }
    return self;
}
- (void)refreshTheme {
    self.layer.borderColor = gAccent.CGColor;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

// ============================================================
// МЕНЮ
// ============================================================
@interface PSYMenuWindow : UIWindow
@end

@implementation PSYMenuWindow {
    UIView *_container;
    UIView *_header;
    UILabel *_brand;
    UILabel *_sub;
    UIButton *_closeBtn;
    UIView *_tabsRow;
    NSMutableArray *_tabButtons;
    NSMutableArray *_tabPages;
    int _currentTab;
}
- (instancetype)init {
    CGFloat w = 340, h = 520;
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    CGFloat sh = [UIScreen mainScreen].bounds.size.height;
    self = [super initWithFrame:CGRectMake((sw-w)/2, (sh-h)/2, w, h)];
    if (self) {
        self.windowLevel = UIWindowLevelAlert + 100;
        self.backgroundColor = [UIColor clearColor];

        _container = [[UIView alloc] initWithFrame:self.bounds];
        _container.backgroundColor = [UIColor colorWithWhite:0 alpha:0.96];
        _container.layer.cornerRadius = 20;
        _container.layer.borderWidth = 1;
        _container.layer.borderColor = gAccent.CGColor;
        _container.clipsToBounds = YES;
        [self addSubview:_container];

        _header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 60)];
        _header.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
        [_header addGestureRecognizer:pan];
        _header.userInteractionEnabled = YES;
        [_container addSubview:_header];

        _brand = [[UILabel alloc] initWithFrame:CGRectMake(20, 12, 200, 24)];
        _brand.text = @"@AWVVL";
        _brand.textColor = [UIColor whiteColor];
        _brand.font = [UIFont boldSystemFontOfSize:16];
        [_header addSubview:_brand];

        _sub = [[UILabel alloc] initWithFrame:CGRectMake(20, 34, 200, 14)];
        _sub.text = @"PREMIUM MENU";
        _sub.textColor = [UIColor colorWithWhite:0.55 alpha:1];
        _sub.font = [UIFont systemFontOfSize:8];
        [_header addSubview:_sub];

        _closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _closeBtn.frame = CGRectMake(w - 52, 14, 32, 32);
        [_closeBtn setTitle:@"✕" forState:UIControlStateNormal];
        [_closeBtn setTitleColor:gAccent forState:UIControlStateNormal];
        _closeBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        _closeBtn.backgroundColor = gAccentSoft;
        _closeBtn.layer.cornerRadius = 16;
        [_closeBtn addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
        [_header addSubview:_closeBtn];

        _tabsRow = [[UIView alloc] initWithFrame:CGRectMake(12, 70, w - 24, 40)];
        _tabsRow.backgroundColor = [UIColor clearColor];
        [_container addSubview:_tabsRow];

        _tabButtons = [NSMutableArray array];
        _tabPages = [NSMutableArray array];
        NSArray *titles = @[@"ESP", @"AIM", @"CFG", @"INFO"];
        CGFloat tabW = (w - 24) / 4.0;
        for (int i = 0; i < 4; i++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            btn.frame = CGRectMake(i * tabW, 0, tabW - 4, 36);
            [btn setTitle:titles[i] forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
            btn.tag = i;
            btn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.03];
            btn.layer.cornerRadius = 10;
            btn.layer.borderWidth = 1;
            btn.layer.borderColor = [UIColor clearColor].CGColor;
            [btn addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
            [_tabsRow addSubview:btn];
            [_tabButtons addObject:btn];

            UIView *page = [[UIView alloc] initWithFrame:CGRectMake(12, 120, w - 24, h - 132)];
            page.backgroundColor = [UIColor clearColor];
            page.hidden = (i != 0);
            [_container addSubview:page];
            [_tabPages addObject:page];
        }
        _currentTab = 0;

        [self buildESPPage:_tabPages[0]];
        [self buildAIMPage:_tabPages[1]];
        [self buildCFGPage:_tabPages[2]];
        [self buildINFOPage:_tabPages[3]];

        [self updateTabStyles];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTheme) name:kThemeChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleVisibility) name:@"PSYToggleMenu" object:nil];

        self.hidden = YES;
    }
    return self;
}

- (void)refreshTheme {
    _container.layer.borderColor = gAccent.CGColor;
    [_closeBtn setTitleColor:gAccent forState:UIControlStateNormal];
    _closeBtn.backgroundColor = gAccentSoft;
    [self updateTabStyles];
}

- (void)updateTabStyles {
    for (int i = 0; i < _tabButtons.count; i++) {
        UIButton *b = _tabButtons[i];
        if (i == _currentTab) {
            [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            b.backgroundColor = gAccentSoft;
            b.layer.borderColor = gAccent.CGColor;
        } else {
            [b setTitleColor:[UIColor colorWithWhite:0.5 alpha:1] forState:UIControlStateNormal];
            b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.03];
            b.layer.borderColor = [UIColor clearColor].CGColor;
        }
    }
}

- (void)tabTapped:(UIButton *)b {
    _currentTab = (int)b.tag;
    for (int i = 0; i < _tabPages.count; i++) {
        ((UIView *)_tabPages[i]).hidden = (i != _currentTab);
    }
    [self updateTabStyles];
}

- (void)toggleVisibility {
    self.hidden = !self.hidden;
}

- (void)closeMenu {
    self.hidden = YES;
}

- (void)handleDrag:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.superview];
    CGPoint c = self.center;
    c.x += t.x;
    c.y += t.y;
    CGFloat w = self.bounds.size.width / 2;
    CGFloat h = self.bounds.size.height / 2;
    c.x = MAX(w, MIN([UIScreen mainScreen].bounds.size.width - w, c.x));
    c.y = MAX(h, MIN([UIScreen mainScreen].bounds.size.height - h, c.y));
    self.center = c;
    [g setTranslation:CGPointZero inView:self.superview];
}

// ============== СТРАНИЦЫ ==============

- (UIView *)makeSectionWithTitle:(NSString *)title y:(CGFloat)y inParent:(UIView *)parent {
    UIView *sec = [[UIView alloc] initWithFrame:CGRectMake(0, y, parent.bounds.size.width, 10)];
    sec.backgroundColor = [UIColor colorWithWhite:1 alpha:0.03];
    sec.layer.cornerRadius = 14;
    sec.layer.borderWidth = 1;
    sec.layer.borderColor = gAccent.CGColor;
    [parent addSubview:sec];

    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(14, 8, sec.bounds.size.width - 28, 16)];
    t.text = title;
    t.textColor = gAccent;
    t.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
    [sec addSubview:t];
    return sec;
}

- (void)addToggleIn:(UIView *)section title:(NSString *)title y:(CGFloat)y {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(14, y, 200, 30)];
    lbl.text = title;
    lbl.textColor = [UIColor colorWithWhite:0.9 alpha:1];
    lbl.font = [UIFont systemFontOfSize:13];
    [section addSubview:lbl];

    PSYSwitch *sw = [[PSYSwitch alloc] init];
    sw.center = CGPointMake(section.bounds.size.width - 40, y + 15);
    [section addSubview:sw];
}

- (void)addSliderIn:(UIView *)section title:(NSString *)title y:(CGFloat)y {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(14, y, 200, 20)];
    lbl.text = title;
    lbl.textColor = [UIColor colorWithWhite:0.55 alpha:1];
    lbl.font = [UIFont systemFontOfSize:11];
    [section addSubview:lbl];

    PSYSlider *sl = [[PSYSlider alloc] init];
    sl.frame = CGRectMake(14, y + 22, section.bounds.size.width - 28, 30);
    [section addSubview:sl];
}

- (void)buildESPPage:(UIView *)page {
    UIView *sec1 = [self makeSectionWithTitle:@"VISUAL" y:0 inParent:page];
    sec1.frame = CGRectMake(0, 0, page.bounds.size.width, 210);
    [self addToggleIn:sec1 title:@"Box" y:44];
    [self addToggleIn:sec1 title:@"Line" y:84];
    [self addToggleIn:sec1 title:@"Distance" y:124];
    [self addToggleIn:sec1 title:@"Head Dot" y:164];

    UIView *sec2 = [self makeSectionWithTitle:@"FILL" y:220 inParent:page];
    sec2.frame = CGRectMake(0, 220, page.bounds.size.width, 130);
    [self addToggleIn:sec2 title:@"Box Fill" y:44];
    [self addToggleIn:sec2 title:@"HP Bar" y:84];
}

- (void)buildAIMPage:(UIView *)page {
    UIView *sec1 = [self makeSectionWithTitle:@"AIMBOT" y:0 inParent:page];
    sec1.frame = CGRectMake(0, 0, page.bounds.size.width, 190);
    [self addToggleIn:sec1 title:@"Enable" y:44];
    [self addToggleIn:sec1 title:@"FOV Circle" y:84];
    [self addToggleIn:sec1 title:@"Silent" y:124];

    UIView *sec2 = [self makeSectionWithTitle:@"PARAMS" y:200 inParent:page];
    sec2.frame = CGRectMake(0, 200, page.bounds.size.width, 180);
    [self addSliderIn:sec2 title:@"FOV Radius" y:44];
    [self addSliderIn:sec2 title:@"Smooth" y:110];
}

- (void)buildCFGPage:(UIView *)page {
    UIView *sec1 = [self makeSectionWithTitle:@"SETTINGS" y:0 inParent:page];
    sec1.frame = CGRectMake(0, 0, page.bounds.size.width, 190);
    [self addToggleIn:sec1 title:@"Sound" y:44];
    [self addToggleIn:sec1 title:@"Vibration" y:84];
    [self addToggleIn:sec1 title:@"HUD" y:124];

    UIView *sec2 = [self makeSectionWithTitle:@"PROFILES" y:200 inParent:page];
    sec2.frame = CGRectMake(0, 200, page.bounds.size.width, 90);
    UIButton *save = [UIButton buttonWithType:UIButtonTypeSystem];
    save.frame = CGRectMake(14, 40, (sec2.bounds.size.width - 42)/2, 34);
    [save setTitle:@"SAVE" forState:UIControlStateNormal];
    [save setTitleColor:gAccent forState:UIControlStateNormal];
    save.backgroundColor = gAccentSoft;
    save.layer.cornerRadius = 10;
    save.layer.borderWidth = 1;
    save.layer.borderColor = gAccent.CGColor;
    [sec2 addSubview:save];

    UIButton *load = [UIButton buttonWithType:UIButtonTypeSystem];
    load.frame = CGRectMake(sec2.bounds.size.width/2 + 7, 40, (sec2.bounds.size.width - 42)/2, 34);
    [load setTitle:@"LOAD" forState:UIControlStateNormal];
    [load setTitleColor:gAccent forState:UIControlStateNormal];
    load.backgroundColor = gAccentSoft;
    load.layer.cornerRadius = 10;
    load.layer.borderWidth = 1;
    load.layer.borderColor = gAccent.CGColor;
    [sec2 addSubview:load];
}

- (void)buildINFOPage:(UIView *)page {
    UILabel *ver = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, page.bounds.size.width, 40)];
    ver.text = @"v1.0";
    ver.textColor = gAccent;
    ver.font = [UIFont boldSystemFontOfSize:28];
    ver.textAlignment = NSTextAlignmentCenter;
    [page addSubview:ver];

    UILabel *au = [[UILabel alloc] initWithFrame:CGRectMake(0, 62, page.bounds.size.width, 20)];
    au.text = @"@AWVVL";
    au.textColor = [UIColor colorWithWhite:0.55 alpha:1];
    au.font = [UIFont systemFontOfSize:10];
    au.textAlignment = NSTextAlignmentCenter;
    [page addSubview:au];

    UIView *sec = [self makeSectionWithTitle:@"THEME" y:100 inParent:page];
    sec.frame = CGRectMake(0, 100, page.bounds.size.width, 180);

    NSArray *names = @[@"Black & White", @"Black & Blue", @"Black & Red", @"Neon Green"];
    for (int i = 0; i < 4; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        CGFloat x = (i % 2) * (sec.bounds.size.width / 2 - 4) + 4;
        CGFloat y = 40 + (i / 2) * 56;
        b.frame = CGRectMake(x, y, sec.bounds.size.width / 2 - 12, 48);
        [b setTitle:names[i] forState:UIControlStateNormal];
        [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.03];
        b.layer.cornerRadius = 10;
        b.layer.borderWidth = 1;
        b.layer.borderColor = gAccent.CGColor;
        b.tag = i;
        [b addTarget:self action:@selector(themeTapped:) forControlEvents:UIControlEventTouchUpInside];
        [sec addSubview:b];
    }
}

- (void)themeTapped:(UIButton *)b {
    NSArray *keys = @[@"bw", @"blue", @"red", @"neon"];
    applyTheme(keys[b.tag]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kThemeChanged object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

// ============================================================
// ИНИЦИАЛИЗАЦИЯ
// ============================================================
__attribute__((constructor))
static void psy_init(void) {
    applyTheme(@"red");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        static PSYCircleButton *circle = nil;
        static PSYMenuWindow *menu = nil;
        static PSYTopHUD *hud = nil;
        if (!circle) circle = [[PSYCircleButton alloc] init];
        if (!menu)   menu   = [[PSYMenuWindow alloc] init];
        if (!hud)    hud    = [[PSYTopHUD alloc] init];
        (void)circle; (void)menu; (void)hud;
    });
}
