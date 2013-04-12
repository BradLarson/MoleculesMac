//
//  SLSInitialHelpWindowController.h
//  Molecules Desktop
//
//  Created by Brad Larson on 3/31/2013.
//  Copyright (c) 2013 Sunset Lake Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SLSInitialHelpWindowController : NSWindowController

- (IBAction)dismissWindow:(id)sender;
- (IBAction)openDNA:(id)sender;
- (IBAction)openTRNA:(id)sender;
- (IBAction)openPump:(id)sender;
- (IBAction)openCaffeine:(id)sender;
- (IBAction)openOther:(id)sender;
- (IBAction)visitPDB:(id)sender;
- (IBAction)visitPubChem:(id)sender;

@end
