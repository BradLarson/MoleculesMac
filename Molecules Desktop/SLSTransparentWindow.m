#import "SLSTransparentWindow.h"

@implementation SLSTransparentWindow

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag {
    // Using NSBorderlessWindowMask results in a window without a title bar.
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    if (self != nil) {
		
		[self setBackgroundColor:[NSColor colorWithCalibratedHue:0 saturation:0 brightness:0 alpha:1.0]];
        // Start with no transparency for all drawing into the window
        //        [self setAlphaValue:1.0];
        // Turn off opacity so that the parts of the window that are not drawn into are transparent.
        [self setOpaque:NO];
    }
    return self;
}

// Custom windows that use the NSBorderlessWindowMask can't become key by default. Override this method
// so that controls in this window will be enabled.

//- (BOOL)canBecomeKeyWindow {
//    return YES;
//}

@end
