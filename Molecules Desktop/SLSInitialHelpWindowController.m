#import "SLSInitialHelpWindowController.h"

@interface SLSInitialHelpWindowController ()

@end

@implementation SLSInitialHelpWindowController

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
    [self.window setLevel:NSFloatingWindowLevel];
}

- (IBAction)dismissWindow:(id)sender
{
    [self close];
}

- (void)openFileWithPath:(NSString *)filePath;
{
    NSDocumentController *controller = [NSDocumentController sharedDocumentController];
    
    NSError *error = nil;
    [controller openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filePath] display:YES error:&error];
    [self close];
}

- (IBAction)openDNA:(id)sender;
{
    [self openFileWithPath:[[NSBundle mainBundle] pathForResource:@"DNA" ofType:@"pdb"]];
}

- (IBAction)openTRNA:(id)sender;
{
    [self openFileWithPath:[[NSBundle mainBundle] pathForResource:@"TransferRNA" ofType:@"pdb"]];
}

- (IBAction)openPump:(id)sender;
{
    [self openFileWithPath:[[NSBundle mainBundle] pathForResource:@"TheoreticalAtomicPump" ofType:@"pdb"]];
}

- (IBAction)openCaffeine:(id)sender;
{
    [self openFileWithPath:[[NSBundle mainBundle] pathForResource:@"Caffeine" ofType:@"pdb"]];
}

- (IBAction)openHeme:(id)sender;
{
    [self openFileWithPath:[[NSBundle mainBundle] pathForResource:@"Heme" ofType:@"sdf"]];
}

- (IBAction)openNanotube:(id)sender;
{
    [self openFileWithPath:[[NSBundle mainBundle] pathForResource:@"Nanotube" ofType:@"pdb"]];
}

- (IBAction)openCholesterol:(id)sender;
{
    [self openFileWithPath:[[NSBundle mainBundle] pathForResource:@"Cholesterol" ofType:@"pdb"]];
}

- (IBAction)openInsulin:(id)sender;
{
    [self openFileWithPath:[[NSBundle mainBundle] pathForResource:@"Insulin" ofType:@"pdb"]];
}

- (IBAction)openTheoreticalBearing:(id)sender;
{
    [self openFileWithPath:[[NSBundle mainBundle] pathForResource:@"TheoreticalBearing" ofType:@"pdb"]];
}

- (IBAction)openOther:(id)sender;
{
    NSDocumentController *controller = [NSDocumentController sharedDocumentController];
    
    [controller openDocument:sender];
    [self close];
}

- (IBAction)visitPDB:(id)sender;
{
    NSURL *pdbURL = [NSURL URLWithString:@"http://www.rcsb.org/pdb"];
    if ([[NSWorkspace sharedWorkspace] openURL:pdbURL])
    {
    }
}

- (IBAction)visitPubChem:(id)sender;
{
    NSURL *pubchemURL = [NSURL URLWithString:@"http://pubchem.ncbi.nlm.nih.gov"];
    if ([[NSWorkspace sharedWorkspace] openURL:pubchemURL])
    {
    
    }
    
}

@end
