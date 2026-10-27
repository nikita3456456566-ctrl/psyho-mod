#import <UIKit/UIKit.h>

@interface AudioSession : UIView
+ (instancetype)shared;
- (void)startAudio;
- (void)stop;
@end
