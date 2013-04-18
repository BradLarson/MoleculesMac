#import <Foundation/Foundation.h>

@class SLSPreferencesWindowController;
@class SLSInitialHelpWindowController;

@interface SLSApplicationDelegate : NSObject

@property(readonly, strong) SLSPreferencesWindowController *preferencesWindowController;
@property(readonly, strong) SLSInitialHelpWindowController *initialHelpWindowController;

- (IBAction)showPreferences:(id)sender;
- (void)showInitialHelp;

@end
