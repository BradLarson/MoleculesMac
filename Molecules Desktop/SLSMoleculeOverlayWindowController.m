#import "SLSMoleculeOverlayWindowController.h"

@interface SLSMoleculeOverlayWindowController ()

@end

@implementation SLSMoleculeOverlayWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark -
#pragma mark Overlay display

- (void)hideOverlay;
{
    [self.window setAlphaValue:0.0];
}

- (void)showOverlay;
{
    [self.window setAlphaValue:1.0];
}

#pragma mark -
#pragma mark Progress controls

- (void)hideProgressIndicator;
{
    [self.progressIndicator setHidden:YES];
}

- (void)updateProgressIndicator:(CGFloat)currentProgress;
{
    [self.progressIndicator setDoubleValue:currentProgress];
}

- (void)showProgressIndicator;
{
    [self.progressIndicator setHidden:NO];
}

@end
