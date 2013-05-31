#import <Foundation/Foundation.h>

@class SLSPreferencesWindowController;
@class SLSMoleculeWindowController;

@interface SLSApplicationDelegate : NSObject

@property(readonly, strong) SLSPreferencesWindowController *preferencesWindowController;
@property(readonly, strong) SLSMoleculeWindowController *moleculeWindowController;
@property(readwrite, weak) IBOutlet NSMenuItem *controlPanelMenuItem, *colorKeyPanelMenuItem;

- (IBAction)showPreferences:(id)sender;

- (void)toggleControlPanelMenu:(NSNotification *)note;
- (void)toggleColorKeyPanelMenu:(NSNotification *)note;

@end
