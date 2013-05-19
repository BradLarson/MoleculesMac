#import <Cocoa/Cocoa.h>

@interface SLSInitialHelpWindowController : NSWindowController

- (IBAction)dismissWindow:(id)sender;

- (void)openFileWithPath:(NSString *)filePath;
- (IBAction)openDNA:(id)sender;
- (IBAction)openTRNA:(id)sender;
- (IBAction)openPump:(id)sender;
- (IBAction)openCaffeine:(id)sender;
- (IBAction)openHeme:(id)sender;
- (IBAction)openNanotube:(id)sender;
- (IBAction)openCholesterol:(id)sender;
- (IBAction)openInsulin:(id)sender;
- (IBAction)openTheoreticalBearing:(id)sender;
- (IBAction)openOther:(id)sender;
- (IBAction)visitPDB:(id)sender;
- (IBAction)visitPubChem:(id)sender;

@end
