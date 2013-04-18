#import "SLSApplicationDelegate.h"
#import "SLSPreferencesWindowController.h"
#import "SLSInitialHelpWindowController.h"

@implementation SLSApplicationDelegate

@synthesize preferencesWindowController = _preferencesWindowController;
@synthesize initialHelpWindowController = _initialHelpWindowController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSNumber numberWithInt:3], @"leapControlStyle",
															 nil]];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    NSLog(@"Should open untitled");
    return YES;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication
{
    NSLog(@"Open untitled");

    [self.initialHelpWindowController showWindow:self];
    
    return YES;
}

- (IBAction)showPreferences:(id)sender;
{
	[self.preferencesWindowController showWindow:self];
}

- (SLSPreferencesWindowController *)preferencesWindowController;
{
	if (_preferencesWindowController == nil)
	{
		_preferencesWindowController = [[SLSPreferencesWindowController alloc] initWithWindowNibName:@"SLSPreferencesWindowController"];
	}
	
	return _preferencesWindowController;
}

- (SLSInitialHelpWindowController *)initialHelpWindowController;
{
	if (_initialHelpWindowController == nil)
	{
		_initialHelpWindowController = [[SLSInitialHelpWindowController alloc] initWithWindowNibName:@"SLSInitialHelpWindowController2"];
	}
	
	return _initialHelpWindowController;
}

@end
