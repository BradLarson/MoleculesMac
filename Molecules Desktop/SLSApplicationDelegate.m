#import "SLSApplicationDelegate.h"
#import "SLSPreferencesWindowController.h"

@implementation SLSApplicationDelegate

@synthesize preferencesWindowController = _preferencesWindowController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSNumber numberWithInt:3], @"leapControlStyle",
															 nil]];
    
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

@end
