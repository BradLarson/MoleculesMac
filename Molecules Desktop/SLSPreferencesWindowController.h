#import <Cocoa/Cocoa.h>

@interface SLSPreferencesWindowController : NSWindowController
{
    NSView *previouslyDisplayedView;
}

@property(readwrite, strong, nonatomic) IBOutlet NSView *leapControlsView;
@property(readwrite, weak, nonatomic) IBOutlet NSToolbar *preferencesToolbar;

// Tab switching and animation
- (IBAction)switchView:(id)sender;

@end
