#import <UIKit/UIKit.h>
#import "PSYESP.h"

// ============================================================
// ЦВЕТА
// ============================================================
static UIColor *C_bg;
static UIColor *C_panel;
static UIColor *C_card;
static UIColor *C_line;
static UIColor *C_txt;
static UIColor *C_muted;
static UIColor *C_white;
static UIColor *C_grey;

static void initColors(void) {
    C_bg    = [UIColor colorWithWhite:0.02 alpha:0.985];
    C_panel = [UIColor colorWithWhite:0.06 alpha:1];
    C_card  = [UIColor colorWithWhite:0.12 alpha:0.85];
    C_line  = [UIColor colorWithWhite:1 alpha:0.11];
    C_txt   = [UIColor colorWithWhite:0.96 alpha:1];
    C_muted = [UIColor colorWithWhite:0.65 alpha:1];
    C_white = [UIColor whiteColor];
    C_grey  = [UIColor colorWithWhite:0.74 alpha:1];
}

// ============================================================
// ТУМБЛЕР
// ============================================================
@interface PSYCheck : UIControl
@property (nonatomic, assign) BOOL on;
@end

@implementation PSYCheck {
    UIView *_box;
    UILabel *_tick;
}
- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0, 0, 20, 20)];
    if (self) {
        _box = [[UIView alloc] initWithFrame:self.bounds];
        _box.layer.cornerRadius = 5;
        _box.layer.borderWidth = 1;
        _box.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.25].CGColor;
        _box.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25];
        _box.userInteractionEnabled = NO;
        [self addSubview:_box];

        _tick = [[UILabel alloc] initWithFrame:self.bounds];
        _tick.text = @"✓";
        _tick.font = [UIFont boldSystemFontOfSize:12];
        _tick.textAlignment = NSTextAlignmentCenter;
        _tick.textColor = [UIColor blackColor];
        _tick.hidden = YES;
        _tick.userInteractionEnabled = NO;
        [self addSubview:_tick];
    }
    return self;
}
- (void)setOn:(BOOL)on {
    _on = on;
    _tick.hidden = !on;
    _box.backgroundColor = on ? [UIColor whiteColor] : [UIColor colorWithWhite:0 alpha:0.25];
    _box.layer.borderColor = on ? [UIColor whiteColor].CGColor : [UIColor colorWithWhite:1 alpha:0.25].CGColor;
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.on = !self.on;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
@end

// ============================================================
// СЛАЙДЕР (оставлен для совместимости)
// ============================================================
@interface PSYSlider : UIView
@property (nonatomic, assign) float value;
@end

@implementation PSYSlider {
    UIView *_track; UIView *_fill; UIView *_thumb;
    float _min; float _max;
}
- (instancetype)initWithWidth:(CGFloat)w {
    self = [super initWithFrame:CGRectMake(0, 0, w, 22)];
    if (self) {
        _min = 0; _max = 100; _value = 50;
        _track = [[UIView alloc] initWithFrame:CGRectMake(0, 9, w, 4)];
        _track.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
        _track.layer.cornerRadius = 2;
        [self addSubview:_track];
        _fill = [[UIView alloc] initWithFrame:CGRectMake(0, 9, w * 0.5, 4)];
        _fill.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
        _fill.layer.cornerRadius = 2;
        [self addSubview:_fill];
        _thumb = [[UIView alloc] initWithFrame:CGRectMake(w * 0.5 - 6, 4, 12, 12)];
        _thumb.backgroundColor = [UIColor whiteColor];
        _thumb.layer.cornerRadius = 6;
        [self addSubview:_thumb];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:pan];
        [self update];
    }
    return self;
}
- (void)pan:(UIPanGestureRecognizer *)g {
    CGPoint p = [g locationInView:self];
    float r = MAX(0, MIN(1, p.x / self.bounds.size.width));
    _value = _min + r * (_max - _min);
    [self update];
}
- (void)update {
    float r = (_value - _min) / (_max - _min);
    CGFloat w = self.bounds.size.width;
    CGFloat x = r * w;
    _fill.frame = CGRectMake(0, 9, x, 4);
    _thumb.center = CGPointMake(x, 10);
}
@end

// ============================================================
// ПОГОДА — реалистичные частицы
// ============================================================
typedef NS_ENUM(NSInteger, PSYWeatherType) {
    PSYWeatherNone = 0,
    PSYWeatherRain,
    PSYWeatherSnow,
    PSYWeatherLeaves
};

@interface PSYWeather : UIWindow
@property (nonatomic, assign) PSYWeatherType type;
- (void)setWeather:(PSYWeatherType)type;
@end

@implementation PSYWeather {
    CADisplayLink *_link;
    NSMutableArray *_particles;
    NSMutableArray *_speeds;
    CGFloat _w, _h;
    NSTimeInterval _lastLightning;
    UIView *_flash;
}

- (instancetype)init {
    _w = [UIScreen mainScreen].bounds.size.width;
    _h = [UIScreen mainScreen].bounds.size.height;
    self = [super initWithFrame:CGRectMake(0, 0, _w, _h)];
    if (self) {
        self.windowLevel = UIWindowLevelAlert + 250;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        _particles = [NSMutableArray array];
        _speeds = [NSMutableArray array];
        _type = PSYWeatherNone;
        _lastLightning = 0;

        _flash = [[UIView alloc] initWithFrame:self.bounds];
        _flash.backgroundColor = [UIColor whiteColor];
        _flash.alpha = 0;
        _flash.userInteractionEnabled = NO;
        [self addSubview:_flash];

        _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
        [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRain)   name:@"PSYWeatherRain"   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSnow)   name:@"PSYWeatherSnow"   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLeaves) name:@"PSYWeatherLeaves" object:nil];

        self.hidden = NO;
    }
    return self;
}

- (void)onRain   { [self setWeather:(_type == PSYWeatherRain)   ? PSYWeatherNone : PSYWeatherRain]; }
- (void)onSnow   { [self setWeather:(_type == PSYWeatherSnow)   ? PSYWeatherNone : PSYWeatherSnow]; }
- (void)onLeaves { [self setWeather:(_type == PSYWeatherLeaves) ? PSYWeatherNone : PSYWeatherLeaves]; }

- (void)setWeather:(PSYWeatherType)type {
    _type = type;
    for (UIView *v in _particles) [v removeFromSuperview];
    [_particles removeAllObjects];
    [_speeds removeAllObjects];
    if (type == PSYWeatherNone) return;

    int count = (type == PSYWeatherRain) ? 90 :
                (type == PSYWeatherSnow) ? 55 :
                (type == PSYWeatherLeaves) ? 35 : 0;

    for (int i = 0; i < count; i++) {
        UIView *p = [self createParticle:type];
        [self addSubview:p];
        [_particles addObject:p];
        CGFloat s = 0.6 + (arc4random_uniform(100) / 100.0) * 1.4;
        [_speeds addObject:@(s)];
    }
}

- (UIView *)createParticle:(PSYWeatherType)type {
    CGFloat x = arc4random_uniform((uint32_t)_w);
    CGFloat y = arc4random_uniform((uint32_t)_h);
    UIView *p;

    if (type == PSYWeatherRain) {
        CGFloat len = 12 + arc4random_uniform(20);
        CGFloat wid = 1.6 + (arc4random_uniform(10) / 10.0);
        p = [[UIView alloc] initWithFrame:CGRectMake(x, y, wid, len)];
        p.backgroundColor = [UIColor clearColor];
        CAGradientLayer *g = [CAGradientLayer layer];
        g.frame = p.bounds;
        g.colors = @[
            (id)[UIColor colorWithWhite:1 alpha:0.05].CGColor,
            (id)[UIColor colorWithWhite:0.85 alpha:0.55].CGColor,
            (id)[UIColor colorWithWhite:1 alpha:0.9].CGColor
        ];
        g.locations = @[@0.0, @0.7, @1.0];
        g.startPoint = CGPointMake(0.5, 0);
        g.endPoint = CGPointMake(0.5, 1);
        [p.layer addSublayer:g];
        p.layer.cornerRadius = wid / 2;
        p.layer.shadowColor = [UIColor whiteColor].CGColor;
        p.layer.shadowRadius = 1.5;
        p.layer.shadowOpacity = 0.4;
        p.layer.shadowOffset = CGSizeZero;
    }
    else if (type == PSYWeatherSnow) {
        CGFloat size = 8 + arc4random_uniform(14);
        UILabel *snow = [[UILabel alloc] initWithFrame:CGRectMake(x, y, size, size)];
        snow.text = @"❄";
        snow.font = [UIFont systemFontOfSize:size];
        snow.textColor = [UIColor colorWithWhite:1 alpha:0.9];
        snow.textAlignment = NSTextAlignmentCenter;
        snow.layer.shadowColor = [UIColor whiteColor].CGColor;
        snow.layer.shadowRadius = 2;
        snow.layer.shadowOpacity = 0.8;
        snow.layer.shadowOffset = CGSizeZero;
        p = snow;
    }
    else if (type == PSYWeatherLeaves) {
        CGFloat size = 14 + arc4random_uniform(12);
        UILabel *leaf = [[UILabel alloc] initWithFrame:CGRectMake(x, y, size, size)];
        leaf.text = (arc4random_uniform(2) == 0) ? @"🍁" : @"🍂";
        leaf.font = [UIFont systemFontOfSize:size];
        leaf.textAlignment = NSTextAlignmentCenter;
        leaf.alpha = 0.85;
        p = leaf;
    }
    return p;
}

- (void)tick {
    if (_type == PSYWeatherNone) return;
    NSTimeInterval now = CACurrentMediaTime();

    if (_type == PSYWeatherRain && now - _lastLightning > 5.0 + (arc4random_uniform(50) / 10.0)) {
        _lastLightning = now;
        [UIView animateWithDuration:0.06 animations:^{
            self->_flash.alpha = 0.35;
        } completion:^(BOOL fin) {
            [UIView animateWithDuration:0.25 animations:^{
                self->_flash.alpha = 0;
            }];
        }];
    }

    for (int i = 0; i < (int)_particles.count; i++) {
        UIView *p = _particles[i];
        CGFloat speed = [_speeds[i] floatValue];
        CGRect f = p.frame;

        if (_type == PSYWeatherRain) {
            f.origin.y += 22 * speed;
            f.origin.x -= 2.0 * speed;
        } else if (_type == PSYWeatherSnow) {
            f.origin.y += 1.4 * speed;
            f.origin.x += sin(f.origin.y * 0.03 + i) * 0.9;
            p.transform = CGAffineTransformRotate(p.transform, 0.015 * speed);
        } else if (_type == PSYWeatherLeaves) {
            f.origin.y += 1.8 * speed;
            f.origin.x += sin(f.origin.y * 0.04 + i * 0.5) * 1.6;
            p.transform = CGAffineTransformRotate(p.transform, 0.02 * speed);
        }

        if (f.origin.y > _h + 30) {
            f.origin.y = -30;
            f.origin.x = arc4random_uniform((uint32_t)_w);
        }
        if (f.origin.x < -40) f.origin.x = _w + 20;
        if (f.origin.x > _w + 40) f.origin.x = -20;
        p.frame = f;
    }
}
@end

// ============================================================
// КРУГ С ФОТО
// ============================================================
@interface PSYCircle : UIWindow
@end

@implementation PSYCircle {
    UIImageView *_img;
}
- (instancetype)init {
    CGFloat s = 52;
    self = [super initWithFrame:CGRectMake(40, 100, s, s)];
    if (self) {
        self.windowLevel = UIWindowLevelAlert + 300;
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = s / 2;
        self.clipsToBounds = YES;

        _img = [[UIImageView alloc] initWithFrame:self.bounds];
        _img.contentMode = UIViewContentModeScaleAspectFill;
        _img.backgroundColor = [UIColor blackColor];
        [self addSubview:_img];

        NSURL *url = [NSURL URLWithString:@"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS924TmX-UWwWpCYlH2i50OmnoW9QZh6Jra8g&s"];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSData *d = [NSData dataWithContentsOfURL:url];
            if (d) {
                UIImage *im = [UIImage imageWithData:d];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->_img.image = im;
                });
            }
        });

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggle)];
        [self addGestureRecognizer:tap];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
        [self addGestureRecognizer:pan];

        self.hidden = NO;
    }
    return self;
}
- (void)toggle { [[NSNotificationCenter defaultCenter] postNotificationName:@"PSYToggle" object:nil]; }
- (void)drag:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.superview];
    CGPoint c = self.center;
    c.x += t.x; c.y += t.y;
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
@interface PSYHUD : UIWindow
@end

@implementation PSYHUD
- (instancetype)init {
    CGFloat w = 100, h = 24;
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    self = [super initWithFrame:CGRectMake((sw - w)/2, 30, w, h)];
    if (self) {
        self.windowLevel = UIWindowLevelNormal + 100;
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 6;
        self.layer.borderWidth = 1;
        self.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
        self.clipsToBounds = YES;
        UIView *bg = [[UIView alloc] initWithFrame:self.bounds];
        bg.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
        [self addSubview:bg];
        UILabel *l = [[UILabel alloc] initWithFrame:self.bounds];
        l.text = @"psyho vip";
        l.textColor = [UIColor whiteColor];
        l.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        l.textAlignment = NSTextAlignmentCenter;
        [self addSubview:l];
        self.hidden = NO;
    }
    return self;
}
@end

// ============================================================
// МЕНЮ
// ============================================================
@interface PSYMenu : UIWindow
@end

@implementation PSYMenu {
    UIView *_container;
    UIView *_header;
    UIView *_tabbar;
    UIView *_content;
    NSMutableArray *_tabs;
    NSMutableArray *_pages;
    int _curTab;

    // Аккордеон World Effects
    UIView *_worldSubContainer;
    BOOL _worldExpanded;
}
- (instancetype)init {
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    CGFloat sh = [UIScreen mainScreen].bounds.size.height;
    CGFloat w = 300;
    CGFloat h = MIN(340, sh - 40);
    self = [super initWithFrame:CGRectMake((sw-w)/2, (sh-h)/2, w, h)];
    if (self) {
        self.windowLevel = UIWindowLevelAlert + 200;
        self.backgroundColor = [UIColor clearColor];

        _container = [[UIView alloc] initWithFrame:self.bounds];
        _container.backgroundColor = [UIColor colorWithWhite:0.03 alpha:0.985];
        _container.layer.cornerRadius = 22;
        _container.layer.borderWidth = 1;
        _container.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
        _container.clipsToBounds = YES;
        [self addSubview:_container];

        // ХЕДЕР
        _header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 50)];
        _header.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.6];
        _header.userInteractionEnabled = YES;
        [_container addSubview:_header];

        UIView *hline = [[UIView alloc] initWithFrame:CGRectMake(0, 49, w, 1)];
        hline.backgroundColor = [UIColor colorWithWhite:1 alpha:0.11];
        [_header addSubview:hline];

        UIView *logo = [[UIView alloc] initWithFrame:CGRectMake(6, 8, 34, 34)];
        logo.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
        logo.layer.cornerRadius = 12;
        logo.layer.borderWidth = 1;
        logo.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
        [_header addSubview:logo];

        UILabel *logoLbl = [[UILabel alloc] initWithFrame:logo.bounds];
        logoLbl.text = @"A";
        logoLbl.textColor = [UIColor whiteColor];
        logoLbl.font = [UIFont boldSystemFontOfSize:16];
        logoLbl.textAlignment = NSTextAlignmentCenter;
        [logo addSubview:logoLbl];

        UILabel *brand = [[UILabel alloc] initWithFrame:CGRectMake(48, 12, 140, 16)];
        brand.text = @"awvvl";
        brand.textColor = [UIColor whiteColor];
        brand.font = [UIFont boldSystemFontOfSize:11];
        [_header addSubview:brand];

        UILabel *brandSub = [[UILabel alloc] initWithFrame:CGRectMake(48, 30, 140, 12)];
        brandSub.text = @"● OVERLAY CONTROL CENTER";
        brandSub.textColor = C_muted;
        brandSub.font = [UIFont systemFontOfSize:7];
        [_header addSubview:brandSub];

        UILabel *online = [[UILabel alloc] initWithFrame:CGRectMake(w - 100, 17, 60, 16)];
        online.text = @"ONLINE";
        online.textColor = [UIColor whiteColor];
        online.font = [UIFont boldSystemFontOfSize:7];
        online.textAlignment = NSTextAlignmentCenter;
        online.layer.cornerRadius = 8;
        online.layer.borderWidth = 1;
        online.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
        online.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
        online.clipsToBounds = YES;
        [_header addSubview:online];

        UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
        close.frame = CGRectMake(w - 32, 17, 24, 24);
        [close setTitle:@"✕" forState:UIControlStateNormal];
        [close setTitleColor:C_muted forState:UIControlStateNormal];
        close.titleLabel.font = [UIFont systemFontOfSize:12];
        close.layer.cornerRadius = 12;
        close.layer.borderWidth = 1;
        close.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.11].CGColor;
        close.backgroundColor = [UIColor colorWithWhite:1 alpha:0.04];
        [close addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
        [_header addSubview:close];

        // Панель вкладок
        _tabbar = [[UIView alloc] initWithFrame:CGRectMake(0, 50, 70, h - 50)];
        _tabbar.backgroundColor = [UIColor colorWithWhite:0.02 alpha:0.4];
        [_container addSubview:_tabbar];

        UIView *vline = [[UIView alloc] initWithFrame:CGRectMake(69, 0, 1, h - 50)];
        vline.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
        [_tabbar addSubview:vline];

        _content = [[UIView alloc] initWithFrame:CGRectMake(70, 50, w - 70, h - 50)];
        [_container addSubview:_content];

        _tabs = [NSMutableArray array];
        _pages = [NSMutableArray array];
        NSArray *names = @[@"HOME", @"ESP", @"AIM", @"PERF", @"CONFIG"];
        CGFloat ty = 8;
        for (int i = 0; i < 5; i++) {
            UIButton *t = [UIButton buttonWithType:UIButtonTypeSystem];
            t.frame = CGRectMake(5, ty, 60, 30);
            [t setTitle:names[i] forState:UIControlStateNormal];
            [t setTitleColor:C_muted forState:UIControlStateNormal];
            t.titleLabel.font = [UIFont boldSystemFontOfSize:7];
            t.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            t.layer.cornerRadius = 8;
            t.tag = i;
            [t addTarget:self action:@selector(tabTap:) forControlEvents:UIControlEventTouchUpInside];
            [_tabbar addSubview:t];
            [_tabs addObject:t];

            UIView *page = [[UIView alloc] initWithFrame:_content.bounds];
            page.hidden = (i != 0);
            [_content addSubview:page];
            [_pages addObject:page];

            ty += 34;
        }

        [self buildHome:_pages[0]];
        [self buildESP:_pages[1]];
        [self buildAIM:_pages[2]];
        [self buildPerf:_pages[3]];
        [self buildConfig:_pages[4]];

        _curTab = 0;
        [self updateTabStyles];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragHeader:)];
        [_header addGestureRecognizer:pan];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleMenu) name:@"PSYToggle" object:nil];

       // Добавляем ESP в главное окно, чтобы он не скрывался вместе с меню
        UIWindow *mainWin = [UIApplication sharedApplication].keyWindow;
        if (!mainWin) mainWin = self; 
        [[PSYESP shared] setFrame:mainWin.bounds];
        [mainWin addSubview:[PSYESP shared]];
        [[PSYESP shared] start]; 
        self.hidden = YES;
    }
    return self;
}

- (void)updateTabStyles {
    for (int i = 0; i < _tabs.count; i++) {
        UIButton *b = _tabs[i];
        if (i == _curTab) {
            [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
            b.layer.borderWidth = 1;
            b.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.11].CGColor;
        } else {
            [b setTitleColor:C_muted forState:UIControlStateNormal];
            b.backgroundColor = [UIColor clearColor];
            b.layer.borderWidth = 0;
        }
    }
}
- (void)tabTap:(UIButton *)b {
    _curTab = (int)b.tag;
    for (int i = 0; i < _pages.count; i++) {
        ((UIView *)_pages[i]).hidden = (i != _curTab);
    }
    [self updateTabStyles];
}
- (void)closeMenu { self.hidden = YES; }
- (void)toggleMenu { self.hidden = !self.hidden; }
- (void)dragHeader:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.superview];
    CGPoint c = self.center;
    c.x += t.x; c.y += t.y;
    CGFloat w = self.bounds.size.width / 2;
    CGFloat h = self.bounds.size.height / 2;
    c.x = MAX(w, MIN([UIScreen mainScreen].bounds.size.width - w, c.x));
    c.y = MAX(h, MIN([UIScreen mainScreen].bounds.size.height - h, c.y));
    self.center = c;
    [g setTranslation:CGPointZero inView:self.superview];
}

// ============ ХЕЛПЕРЫ ============
- (UILabel *)sectionTitle:(NSString *)txt y:(CGFloat)y in:(UIView *)parent {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(12, y, parent.bounds.size.width - 24, 12)];
    l.text = txt;
    l.textColor = [UIColor colorWithWhite:0.85 alpha:1];
    l.font = [UIFont boldSystemFontOfSize:7];
    [parent addSubview:l];
    return l;
}
- (UIView *)cardRow:(NSString *)label y:(CGFloat)y in:(UIView *)parent toggle:(BOOL)toggle tag:(NSInteger)tag {
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(12, y, parent.bounds.size.width - 24, 30)];
    card.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.85];
    card.layer.cornerRadius = 8;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.11].CGColor;
    [parent addSubview:card];

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, card.bounds.size.width - 50, 30)];
    lbl.text = label;
    lbl.textColor = C_txt;
    lbl.font = [UIFont systemFontOfSize:9];
    [card addSubview:lbl];

    if (toggle) {
        PSYCheck *chk = [[PSYCheck alloc] init];
        chk.center = CGPointMake(card.bounds.size.width - 20, 15);
        chk.tag = tag;
        [card addSubview:chk];
    }
    return card;
}

// ============ СТРАНИЦЫ ============
- (void)buildHome:(UIView *)page {
    [self sectionTitle:@"LIVE PERFORMANCE" y:8 in:page];
    [self cardRow:@"FPS 60" y:26 in:page toggle:NO tag:0];
    [self cardRow:@"FRAME TIME 16ms" y:58 in:page toggle:NO tag:0];
    [self sectionTitle:@"SYSTEM" y:100 in:page];
    [self cardRow:@"Resolution 390×844" y:118 in:page toggle:NO tag:0];
    [self cardRow:@"Orientation LANDSCAPE" y:150 in:page toggle:NO tag:0];
}

// ============ ESP (с аккордеоном World Effects) ============
- (void)buildESP:(UIView *)page {
    [self sectionTitle:@"ESP MASTER" y:8 in:page];
    [self cardRow:@"Enable" y:26 in:page toggle:YES tag:100];
    [self cardRow:@"Box" y:58 in:page toggle:YES tag:100];
    [self cardRow:@"Line" y:90 in:page toggle:YES tag:100];
    [self cardRow:@"Distance" y:122 in:page toggle:YES tag:100];
    [self cardRow:@"HP Bar" y:154 in:page toggle:YES tag:100];

    // ===== WORLD EFFECTS — карточка с главным тумблером =====
    UIView *worldCard = [[UIView alloc] initWithFrame:CGRectMake(12, 194, page.bounds.size.width - 24, 32)];
    worldCard.backgroundColor = [UIColor colorWithWhite:0.14 alpha:0.9];
    worldCard.layer.cornerRadius = 8;
    worldCard.layer.borderWidth = 1;
    worldCard.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.15].CGColor;
    [page addSubview:worldCard];

    UILabel *worldLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, worldCard.bounds.size.width - 50, 32)];
    worldLbl.text = @"WORLD EFFECTS";
    worldLbl.textColor = [UIColor whiteColor];
    worldLbl.font = [UIFont boldSystemFontOfSize:9];
    [worldCard addSubview:worldLbl];

    PSYCheck *worldChk = [[PSYCheck alloc] init];
    worldChk.center = CGPointMake(worldCard.bounds.size.width - 20, 16);
    worldChk.tag = 999;
    [worldChk addTarget:self action:@selector(worldToggle:) forControlEvents:UIControlEventValueChanged];
    [worldCard addSubview:worldChk];

    // ===== Контейнер с подпунктами (изначально сжат в 0 высоту) =====
    _worldSubContainer = [[UIView alloc] initWithFrame:CGRectMake(12, 228, page.bounds.size.width - 24, 0)];
    _worldSubContainer.clipsToBounds = YES;
    _worldSubContainer.alpha = 0;
    [page addSubview:_worldSubContainer];

    // Три подпункта с погодой
    NSArray *weatherNames = @[@"Rain", @"Snow", @"Leaves"];
    NSArray *weatherTags  = @[@(201), @(202), @(203)];
    CGFloat ry = 0;
    for (int i = 0; i < 3; i++) {
        UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, ry, _worldSubContainer.bounds.size.width, 28)];
        row.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.85];
        row.layer.cornerRadius = 7;
        row.layer.borderWidth = 1;
        row.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.08].CGColor;
        [_worldSubContainer addSubview:row];

        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, row.bounds.size.width - 50, 28)];
        l.text = weatherNames[i];
        l.textColor = C_txt;
        l.font = [UIFont systemFontOfSize:9];
        [row addSubview:l];

        PSYCheck *c = [[PSYCheck alloc] init];
        c.center = CGPointMake(row.bounds.size.width - 20, 14);
        c.tag = [weatherTags[i] integerValue];
        [c addTarget:self action:@selector(weatherToggle:) forControlEvents:UIControlEventValueChanged];
        [row addSubview:c];

        ry += 32;
    }
}

// Родительский тумблер — раскрывает / закрывает подпункты
- (void)worldToggle:(PSYCheck *)sender {
    _worldExpanded = sender.on;
    CGFloat targetH = _worldExpanded ? (3 * 32 - 4) : 0;

    CGRect f = _worldSubContainer.frame;
    f.size.height = targetH;
    [UIView animateWithDuration:0.28
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0.4
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self->_worldSubContainer.frame = f;
        self->_worldSubContainer.alpha = self->_worldExpanded ? 1.0 : 0.0;
    } completion:nil];
}

// Тумблеры погоды
- (void)weatherToggle:(PSYCheck *)sender {
    if (sender.tag == 201) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PSYWeatherRain" object:nil];
    } else if (sender.tag == 202) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PSYWeatherSnow" object:nil];
    } else if (sender.tag == 203) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PSYWeatherLeaves" object:nil];
    }
}

- (void)buildAIM:(UIView *)page {
    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(12, page.bounds.size.height/2 - 50, page.bounds.size.width - 24, 100)];
    box.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.85];
    box.layer.cornerRadius = 10;
    box.layer.borderWidth = 1;
    box.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.1].CGColor;
    [page addSubview:box];

    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, box.bounds.size.width, 20)];
    t.text = @"ВРЕМЕННО НЕ РАБОТАЕТ";
    t.textColor = [UIColor whiteColor];
    t.font = [UIFont boldSystemFontOfSize:10];
    t.textAlignment = NSTextAlignmentCenter;
    [box addSubview:t];

    UILabel *s = [[UILabel alloc] initWithFrame:CGRectMake(20, 48, box.bounds.size.width - 40, 40)];
    s.text = @"Пожалуйста, не пишите в ЛС. Мы сообщим, когда функция снова будет доступна.";
    s.textColor = C_muted;
    s.font = [UIFont systemFontOfSize:8];
    s.numberOfLines = 0;
    s.textAlignment = NSTextAlignmentCenter;
    [box addSubview:s];
}

- (void)buildPerf:(UIView *)page {
    [self sectionTitle:@"FRAME MONITOR" y:8 in:page];
    [self cardRow:@"FPS 60" y:26 in:page toggle:NO tag:0];
    [self cardRow:@"Frame time 16ms" y:58 in:page toggle:NO tag:0];
    [self sectionTitle:@"LOAD REDUCTION" y:100 in:page];
    [self cardRow:@"Low Load Mode" y:118 in:page toggle:YES tag:0];
}

- (void)buildConfig:(UIView *)page {
    [self sectionTitle:@"PROFILES" y:8 in:page];
    [self cardRow:@"Slot 1" y:26 in:page toggle:NO tag:0];
    [self cardRow:@"Slot 2" y:58 in:page toggle:NO tag:0];
    [self cardRow:@"Slot 3" y:90 in:page toggle:NO tag:0];
    [self sectionTitle:@"UI" y:132 in:page];
    [self cardRow:@"Vibration" y:150 in:page toggle:YES tag:0];
    [self cardRow:@"Sound" y:182 in:page toggle:YES tag:0];
}
@end

// ============================================================
// ИНИЦИАЛИЗАЦИЯ
// ============================================================
__attribute__((constructor))
static void init(void) {
    initColors();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        static PSYCircle *circle = nil;
        static PSYMenu *menu = nil;
        static PSYHUD *hud = nil;
        static PSYWeather *weather = nil;
        if (!circle)  circle  = [[PSYCircle alloc] init];
        if (!menu)    menu    = [[PSYMenu alloc] init];
        if (!hud)     hud     = [[PSYHUD alloc] init];
        if (!weather) weather = [[PSYWeather alloc] init];
        (void)circle; (void)menu; (void)hud; (void)weather;
    });
}
