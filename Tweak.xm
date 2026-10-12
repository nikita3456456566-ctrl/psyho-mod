#import <UIKit/UIKit.h>

// ===== Объявление класса ДО его использования =====
@interface PSYMenu : NSObject
+ (instancetype)shared;
- (void)show;
- (void)hide;
@end

// ===== Точка входа (Logos) =====
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        [[PSYMenu shared] show];
    });
}

// ===== Реализация =====
@implementation PSYMenu {
    UIWindow *_window;
    BOOL _visible;
}

+ (instancetype)shared {
    static PSYMenu *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [PSYMenu new]; });
    return s;
}

- (void)show {
    if (_window) { _window.hidden = NO; _visible = YES; return; }

    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _window.windowLevel = UIWindowLevelAlert + 100;
    _window.backgroundColor = [UIColor clearColor];

    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.95];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, 320, 40)];
    title.text = @"PSYHOTROP";
    title.textColor = [UIColor colorWithRed:1 green:0.2 blue:0.27 alpha:1];
    title.font = [UIFont boldSystemFontOfSize:22];
    title.textAlignment = NSTextAlignmentCenter;
    [vc.view addSubview:title];

    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 320, 20)];
    sub.text = @"PREMIUM MENU";
    sub.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    sub.font = [UIFont systemFontOfSize:10];
    sub.textAlignment = NSTextAlignmentCenter;
    [vc.view addSubview:sub];

    _window.rootViewController = vc;
    _window.hidden = NO;
    _visible = YES;
}

- (void)hide {
    _window.hidden = YES;
    _visible = NO;
}

@end
