#import "SLSPreferencesWindowController.h"

@interface SLSPreferencesWindowController ()

@end

@implementation SLSPreferencesWindowController

@synthesize leapControlsView = _leapControlsView;
@synthesize preferencesToolbar = _preferencesToolbar;

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
    
	previouslyDisplayedView = _leapControlsView;
	[self.window.contentView addSubview:_leapControlsView];
	[_preferencesToolbar setSelectedItemIdentifier:@"LeapControls"];
	
	// Determine the index of the currently selected deck layout
	
//	NSInteger leapControlsStyle = [[NSUserDefaults standardUserDefaults] integerForKey:@"leapControlsStyle"];
}

#pragma mark -
#pragma mark Tab switching and animation

- (IBAction)switchView:(id)sender
{
	NSInteger tagOfSelectedTab = [sender tag];
	NSView *viewForSelectedTab = nil;
    
	switch (tagOfSelectedTab)
	{
		case 0: viewForSelectedTab = _leapControlsView; break;
		default: viewForSelectedTab = _leapControlsView; break;
	}
	
	[self.window setTitle:[sender label]];
	
	NSRect newFrameRect = [self.window frameRectForContentRect:[viewForSelectedTab frame]];
    NSRect oldFrameRect = [self.window frame];
    NSSize newSize = newFrameRect.size;
    NSSize oldSize = oldFrameRect.size;
    NSRect newFrame = [self.window frame];
    newFrame.size = newSize;
    newFrame.origin.y -= (newSize.height - oldSize.height);
	
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.25];
	
	if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
	{
	    [[NSAnimationContext currentContext] setDuration:1.0];
	}
	
	[[[self.window contentView] animator] replaceSubview:previouslyDisplayedView with:viewForSelectedTab];
	[[self.window animator] setFrame:newFrame display:YES];
	
	[NSAnimationContext endGrouping];
	
	
	previouslyDisplayedView = viewForSelectedTab;
}

@end
