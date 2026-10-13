#import <UIKit/UIKit.h>

// ============================================================
// ЦВЕТА (монохром)
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
    C_card  = [UIColor colorWithWhite:0.11 alpha:0.9];
    C_line  = [UIColor colorWithWhite:1 alpha:0.11];
    C_txt   = [UIColor colorWithWhite:0.96 alpha:1];
    C_muted = [UIColor colorWithWhite:0.65 alpha:1];
    C_white = [UIColor whiteColor];
    C_grey  = [UIColor colorWithWhite:0.74 alpha:1];
}

// ============================================================
// КАСТОМНЫЙ ТУМБЛЕР (монохромный квадрат как в HTML)
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
// СЛАЙДЕР
// ============================================================
@interface PSYSlider : UIView
@property (nonatomic, assign) float value;
@end

@implementation PSYSlider {
    UIView *_track;
    UIView *_fill;
    UIView *_thumb;
    float _min;
    float _max;
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
        _thumb.layer.borderWidth = 2;
        _thumb.layer.borderColor = [UIColor whiteColor].CGColor;
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
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    _track.frame = CGRectMake(0, 9, w, 4);
    [self update];
}
@end

// ============================================================
// КРУГ С ФОТО (не трогаем)
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
- (void)toggle {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PSYToggle" object:nil];
}
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

        // Контейнер с тёмным фоном
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

        // Разделительная линия снизу хедера
        UIView *hline = [[UIView alloc] initWithFrame:CGRectMake(0, 49, w, 1)];
        hline.backgroundColor = [UIColor colorWithWhite:1 alpha:0.11];
        [_header addSubview:hline];

        // Логотип "A"
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

        // Текст "awvvl" + "OVERLAY CONTROL CENTER"
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

        // "ONLINE" справа
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

        // Крестик
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

        // Панель вкладок слева
        _tabbar = [[UIView alloc] initWithFrame:CGRectMake(0, 50, 70, h - 50)];
        _tabbar.backgroundColor = [UIColor colorWithWhite:0.02 alpha:0.4];
        _tabbar.layer.borderWidth = 1;
        _tabbar.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.08].CGColor;
        [_container addSubview:_tabbar];

        // Правая разделительная линия
        UIView *vline = [[UIView alloc] initWithFrame:CGRectMake(69, 0, 1, h - 50)];
        vline.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
        [_tabbar addSubview:vline];

        // Контент
        _content = [[UIView alloc] initWithFrame:CGRectMake(70, 50, w - 70, h - 50)];
        _content.backgroundColor = [UIColor clearColor];
        [_container addSubview:_content];

        // Вкладки
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
            t.contentEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
            t.backgroundColor = [UIColor clearColor];
            t.layer.cornerRadius = 8;
            t.tag = i;
            [t addTarget:self action:@selector(tabTap:) forControlEvents:UIControlEventTouchUpInside];
            [_tabbar addSubview:t];
            [_tabs addObject:t];

            // Страница
            UIView *page = [[UIView alloc] initWithFrame:_content.bounds];
            page.hidden = (i != 0);
            [_content addSubview:page];
            [_pages addObject:page];

            ty += 34;
        }

        // Строим страницы
        [self buildHome:_pages[0]];
        [self buildESP:_pages[1]];
        [self buildAIM:_pages[2]];
        [self buildPerf:_pages[3]];
        [self buildConfig:_pages[4]];

        _curTab = 0;
        [self updateTabStyles];

        // Драг за хедер
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragHeader:)];
        [_header addGestureRecognizer:pan];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleMenu) name:@"PSYToggle" object:nil];

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

- (UIView *)cardRow:(NSString *)label y:(CGFloat)y in:(UIView *)parent toggle:(BOOL)toggle {
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
        [card addSubview:chk];
    }
    return card;
}

- (void)statBox:(NSString *)title value:(NSString *)value x:(CGFloat)x y:(CGFloat)y w:(CGFloat)w in:(UIView *)parent {
    UIView *b = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, 46)];
    b.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.85];
    b.layer.cornerRadius = 8;
    b.layer.borderWidth = 1;
    b.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.1].CGColor;
    [parent addSubview:b];

    UILabel *k = [[UILabel alloc] initWithFrame:CGRectMake(8, 6, w - 16, 12)];
    k.text = title;
    k.textColor = C_muted;
    k.font = [UIFont systemFontOfSize:6];
    [b addSubview:k];

    UILabel *v = [[UILabel alloc] initWithFrame:CGRectMake(8, 22, w - 16, 18)];
    v.text = value;
    v.textColor = [UIColor whiteColor];
    v.font = [UIFont boldSystemFontOfSize:14];
    [b addSubview:v];
}

- (void)colorSquare:(UIColor *)color x:(CGFloat)x y:(CGFloat)y in:(UIView *)parent active:(BOOL)active {
    UIView *sq = [[UIView alloc] initWithFrame:CGRectMake(x, y, 16, 16)];
    sq.backgroundColor = color;
    sq.layer.cornerRadius = 6;
    sq.layer.borderWidth = active ? 2 : 1;
    sq.layer.borderColor = active ? [UIColor whiteColor].CGColor : [UIColor colorWithWhite:1 alpha:0.1].CGColor;
    if (active) {
        sq.layer.shadowColor = [UIColor whiteColor].CGColor;
        sq.layer.shadowRadius = 6;
        sq.layer.shadowOpacity = 0.5;
        sq.layer.shadowOffset = CGSizeZero;
    }
    [parent addSubview:sq];
}

- (UIButton *)actionBtn:(NSString *)title x:(CGFloat)x y:(CGFloat)y w:(CGFloat)w in:(UIView *)parent {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = CGRectMake(x, y, w, 26);
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:C_grey forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:7];
    b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.04];
    b.layer.cornerRadius = 7;
    b.layer.borderWidth = 1;
    b.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.13].CGColor;
    [parent addSubview:b];
    return b;
}

// ============ СТРАНИЦЫ ============

- (void)buildHome:(UIView *)page {
    [self sectionTitle:@"LIVE PERFORMANCE" y:8 in:page];
    CGFloat w = (page.bounds.size.width - 32) / 2;
    [self statBox:@"FPS" value:@"60" x:8 y:26 w:w in:page];
    [self statBox:@"FRAME TIME" value:@"16ms" x:16 + w y:26 w:w in:page];
    [self statBox:@"OVERLAY FPS" value:@"60" x:8 y:78 w:w in:page];
    [self statBox:@"UPTIME" value:@"0s" x:16 + w y:78 w:w in:page];

    [self sectionTitle:@"SYSTEM" y:136 in:page];
    [self cardRow:@"Resolution   390×844" y:154 in:page toggle:NO];
    [self cardRow:@"Orientation  LANDSCAPE" y:186 in:page toggle:NO];

    [self sectionTitle:@"QUICK PRESET" y:224 in:page];
    CGFloat bw = (page.bounds.size.width - 32) / 3;
    [self actionBtn:@"LOW" x:8 y:242 w:bw in:page];
    [self actionBtn:@"BALANCED" x:12 + bw y:242 w:bw in:page];
    [self actionBtn:@"QUALITY" x:16 + 2*bw y:242 w:bw in:page];
}

- (void)buildESP:(UIView *)page {
    [self sectionTitle:@"ESP MASTER" y:8 in:page];
    [self cardRow:@"Enable" y:26 in:page toggle:YES];
    [self cardRow:@"Box" y:58 in:page toggle:YES];
    [self cardRow:@"Line" y:90 in:page toggle:YES];
    [self cardRow:@"Distance" y:122 in:page toggle:YES];
    [self cardRow:@"HP Bar" y:154 in:page toggle:YES];

    [self sectionTitle:@"BOX COLOR" y:192 in:page];
    [self colorSquare:[UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1] x:12 y:210 in:page active:NO];
    [self colorSquare:[UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1] x:34 y:210 in:page active:NO];
    [self colorSquare:[UIColor colorWithRed:0.2 green:0.6 blue:1 alpha:1] x:56 y:210 in:page active:NO];
    [self colorSquare:[UIColor colorWithRed:1 green:0.8 blue:0.2 alpha:1] x:78 y:210 in:page active:NO];
    [self colorSquare:[UIColor whiteColor] x:100 y:210 in:page active:YES];
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
    CGFloat w = (page.bounds.size.width - 32) / 2;
    [self statBox:@"FPS" value:@"60" x:8 y:26 w:w in:page];
    [self statBox:@"FRAME TIME" value:@"16ms" x:16 + w y:26 w:w in:page];

    [self sectionTitle:@"LOAD REDUCTION" y:84 in:page];
    [self cardRow:@"Low Load Mode" y:102 in:page toggle:YES];

    [self sectionTitle:@"OVERLAY RATE" y:142 in:page];
    [self cardRow:@"Refresh 60 FPS" y:160 in:page toggle:NO];

    [self sectionTitle:@"ACTIONS" y:200 in:page];
    CGFloat bw = (page.bounds.size.width - 32) / 3;
    [self actionBtn:@"RECENTER" x:8 y:218 w:bw in:page];
    [self actionBtn:@"CLEAR" x:12 + bw y:218 w:bw in:page];
    [self actionBtn:@"SAVE" x:16 + 2*bw y:218 w:bw in:page];
}

- (void)buildConfig:(UIView *)page {
    [self sectionTitle:@"PROFILES" y:8 in:page];
    [self actionBtn:@"SAVE 1" x:12 y:26 w:80 in:page];
    [self actionBtn:@"LOAD 1" x:96 y:26 w:80 in:page];
    [self actionBtn:@"DEL 1" x:180 y:26 w:60 in:page];
    [self actionBtn:@"SAVE 2" x:12 y:58 w:80 in:page];
    [self actionBtn:@"LOAD 2" x:96 y:58 w:80 in:page];
    [self actionBtn:@"DEL 2" x:180 y:58 w:60 in:page];
    [self actionBtn:@"SAVE 3" x:12 y:90 w:80 in:page];
    [self actionBtn:@"LOAD 3" x:96 y:90 w:80 in:page];
    [self actionBtn:@"DEL 3" x:180 y:90 w:60 in:page];

    [self sectionTitle:@"UI" y:132 in:page];
    [self cardRow:@"Vibration" y:150 in:page toggle:YES];
    [self cardRow:@"Sound" y:182 in:page toggle:YES];
    [self cardRow:@"Hit Sound" y:214 in:page toggle:YES];

    [self actionBtn:@"SAVE ALL" x:12 y:252 w:page.bounds.size.width - 24 in:page];
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
        if (!circle) circle = [[PSYCircle alloc] init];
        if (!menu)   menu   = [[PSYMenu alloc] init];
        if (!hud)    hud    = [[PSYHUD alloc] init];
        (void)circle; (void)menu; (void)hud;
    });
}
