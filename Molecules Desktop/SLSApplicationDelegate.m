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
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasStartedOnce"])
    {
        NSLog(@"Doing initialization");
        [self.initialHelpWindowController showWindow:self];
        NSDocumentController *controller = [NSDocumentController sharedDocumentController];
        
        NSError *error = nil;
        [controller openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"DNA" ofType:@"pdb"]] display:YES error:&error];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasStartedOnce"];
    }
    
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return YES;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication
{
    [self.initialHelpWindowController showWindow:self];
    
    return NO;
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
