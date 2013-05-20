#import <Cocoa/Cocoa.h>

void dataProviderReleaseCallback (void *info, const void *data, size_t size);

@interface SLSAtomColorView : NSImageView

- (void)setAtomColorRed:(CGFloat)redComponent green:(CGFloat)greenComponent blue:(CGFloat)blueComponent;

@end
