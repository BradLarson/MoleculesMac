//
//  SLSInitialHelpWindowController.m
//  Molecules Desktop
//
//  Created by Brad Larson on 3/31/2013.
//  Copyright (c) 2013 Sunset Lake Software LLC. All rights reserved.
//

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

- (IBAction)openDNA:(id)sender;
{
    NSDocumentController *controller = [NSDocumentController sharedDocumentController];
    
    NSError *error = nil;
    [controller openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"DNA" ofType:@"pdb"]] display:YES error:&error];
    [self close];
}

- (IBAction)openTRNA:(id)sender;
{
    NSDocumentController *controller = [NSDocumentController sharedDocumentController];
    
    NSError *error = nil;
    [controller openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"TransferRNA" ofType:@"pdb"]] display:YES error:&error];
    [self close];
}

- (IBAction)openPump:(id)sender;
{
    NSDocumentController *controller = [NSDocumentController sharedDocumentController];
    
    NSError *error = nil;
    [controller openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"TheoreticalAtomicPump" ofType:@"pdb"]] display:YES error:&error];    
    [self close];
}

- (IBAction)openCaffeine:(id)sender;
{
    NSDocumentController *controller = [NSDocumentController sharedDocumentController];
    
    NSError *error = nil;
    [controller openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Caffeine" ofType:@"pdb"]] display:YES error:&error];
    [self close];
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
