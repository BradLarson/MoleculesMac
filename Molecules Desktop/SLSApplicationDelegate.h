#import <Foundation/Foundation.h>

@class SLSPreferencesWindowController;

@interface SLSApplicationDelegate : NSObject

@property(readonly, strong) SLSPreferencesWindowController *preferencesWindowController;

- (IBAction)showPreferences:(id)sender;

@end
