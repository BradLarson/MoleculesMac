#import "SLSApplicationDelegate.h"
#import "SLSPreferencesWindowController.h"
#import "SLSInitialHelpWindowController.h"
#import "SLSColorKeyWindowController.h"

@implementation SLSApplicationDelegate

@synthesize preferencesWindowController = _preferencesWindowController;
@synthesize initialHelpWindowController = _initialHelpWindowController;
@synthesize colorKeyWindowController = _colorKeyWindowController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSNumber numberWithInt:3], @"leapControlStyle",
															 nil]];
    
    // This is a bit of a hack to get the initial panel to open on startup if no documents are loaded
    double delayInSeconds = 0.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([[[NSDocumentController sharedDocumentController] documents] count] < 1)
        {
            [self.initialHelpWindowController showWindow:self];
        }        
    });
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return YES;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication
{
    [self showInitialHelp];
    
    return YES;
}

- (IBAction)showPreferences:(id)sender;
{
	[self.preferencesWindowController showWindow:self];
}

- (IBAction)showColorKey:(id)sender;
{
	[self.colorKeyWindowController showWindow:self];
}

- (void)showInitialHelp;
{
    [self.initialHelpWindowController showWindow:self];
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

- (SLSColorKeyWindowController *)colorKeyWindowController;
{
	if (_colorKeyWindowController == nil)
	{
		_colorKeyWindowController = [[SLSColorKeyWindowController alloc] initWithWindowNibName:@"SLSColorKeyWindowController"];
	}
	
	return _colorKeyWindowController;
}

@end
