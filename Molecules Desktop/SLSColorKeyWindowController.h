#import <Cocoa/Cocoa.h>

@class SLSAtomColorView;

@interface SLSColorKeyWindowController : NSWindowController

@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *hydrogenColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *carbonColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *nitrogenColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *oxygenColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *fluorineColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *sodiumColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *magnesiumColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *siliconColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *phosphorousColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *sulfurColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *chlorineColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *calciumColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *ironColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *zincColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *bromineColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *cadmiumColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *iodineColorView;
@property(readwrite, nonatomic, weak) IBOutlet SLSAtomColorView *unknownColorView;

@end
