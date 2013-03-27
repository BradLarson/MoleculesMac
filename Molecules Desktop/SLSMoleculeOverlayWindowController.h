#import <Cocoa/Cocoa.h>

@interface SLSMoleculeOverlayWindowController : NSWindowController

@property(readwrite, weak) IBOutlet NSProgressIndicator *progressIndicator;

// Overlay display
- (void)hideOverlay;
- (void)showOverlay;

// Progress controls
- (void)hideProgressIndicator;
- (void)updateProgressIndicator:(CGFloat)currentProgress;
- (void)showProgressIndicator;

@end
