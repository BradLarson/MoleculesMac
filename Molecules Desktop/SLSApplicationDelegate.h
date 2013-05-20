#import <Foundation/Foundation.h>

@class SLSPreferencesWindowController;
@class SLSInitialHelpWindowController;
@class SLSColorKeyWindowController;

@interface SLSApplicationDelegate : NSObject

@property(readonly, strong) SLSPreferencesWindowController *preferencesWindowController;
@property(readonly, strong) SLSInitialHelpWindowController *initialHelpWindowController;
@property(readonly, strong) SLSColorKeyWindowController *colorKeyWindowController;

- (IBAction)showPreferences:(id)sender;
- (IBAction)showColorKey:(id)sender;
- (void)showInitialHelp;

@end
