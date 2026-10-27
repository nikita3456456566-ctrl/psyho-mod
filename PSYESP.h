#import <UIKit/UIKit.h>

@interface AudioSession : UIView
+ (instancetype)shared;
- (void)start;
- (void)stop;
@end
