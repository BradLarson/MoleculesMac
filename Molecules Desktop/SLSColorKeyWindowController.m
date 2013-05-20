#import "SLSColorKeyWindowController.h"
#import "SLSAtomColorView.h"

@interface SLSColorKeyWindowController ()

@end

@implementation SLSColorKeyWindowController

@synthesize carbonColorView = _carbonColorView;
@synthesize hydrogenColorView = _hydrogenColorView;
@synthesize nitrogenColorView = _nitrogenColorView;
@synthesize oxygenColorView = _oxygenColorView;
@synthesize fluorineColorView = _fluorineColorView;
@synthesize sodiumColorView = _sodiumColorView;
@synthesize magnesiumColorView = _magnesiumColorView;
@synthesize siliconColorView = _siliconColorView;
@synthesize phosphorousColorView = _phosphorousColorView;
@synthesize sulfurColorView = _sulfurColorView;
@synthesize chlorineColorView = _chlorineColorView;
@synthesize calciumColorView = _calciumColorView;
@synthesize ironColorView =_ironColorView;
@synthesize zincColorView = _zincColorView;
@synthesize bromineColorView = _bromineColorView;
@synthesize cadmiumColorView = _cadmiumColorView;
@synthesize iodineColorView = _iodineColorView;
@synthesize unknownColorView = _unknownColorView;

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
    
    [_hydrogenColorView setAtomColorRed:0.902 green:0.902 blue:0.902];
    [_carbonColorView setAtomColorRed:0.4706 green:0.4706 blue:0.4706];
    [_nitrogenColorView setAtomColorRed:0.1882 green:0.3137 blue:0.9725];
    [_oxygenColorView setAtomColorRed:0.9412 green:0.1569 blue:0.1569];
    [_fluorineColorView setAtomColorRed:0.5647 green:0.8784 blue:0.3137];
    [_sodiumColorView setAtomColorRed:0.6706 green:0.3608 blue:0.9490];
    [_magnesiumColorView setAtomColorRed:0.5411 green:1.0 blue:0.0];
    [_siliconColorView setAtomColorRed:0.7843 green:0.7843 blue:0.3429];
    [_phosphorousColorView setAtomColorRed:1.0 green:0.5 blue:0.0];
    [_sulfurColorView setAtomColorRed:1.0 green:1.0 blue:0.1882];
    [_chlorineColorView setAtomColorRed:0.1216 green:0.9411 blue:0.1216];
    [_calciumColorView setAtomColorRed:0.2392 green:1.0 blue:0.0];
    [_ironColorView setAtomColorRed:0.8784 green:0.4 blue:0.2];
    [_zincColorView setAtomColorRed:0.4902 green:0.5 blue:0.6902];
    [_bromineColorView setAtomColorRed:0.6510 green:0.1608 blue:0.1608];
    [_cadmiumColorView setAtomColorRed:1.0 green:0.8510 blue:0.5608];
    [_iodineColorView setAtomColorRed:0.5804 green:0.0 blue:0.5804];
    [_unknownColorView setAtomColorRed:0.0 green:1.0 blue:0.0];
}

@end
