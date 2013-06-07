#import <Cocoa/Cocoa.h>
#import "SLSMolecule.h"
#import "SLSOpenGLRenderer.h"
#import "SLSMoleculeGLView.h"
#import "LeapObjectiveC.h"

static CVReturn renderCallback(CVDisplayLinkRef displayLink,
							   const CVTimeStamp *inNow,
							   const CVTimeStamp *inOutputTime,
							   CVOptionFlags flagsIn,
							   CVOptionFlags *flagsOut,
							   void *displayLinkContext);

@class SLSMoleculeOverlayWindowController;
@class SLSAtomColorView;

extern NSString *const kSLSMoleculeControlPanelNotification;
extern NSString *const kSLSMoleculeColorKeyPanelNotification;

typedef enum {LEFTTORIGHTAUTOROTATION, RIGHTTOLEFTAUTOROTATION, TOPTOBOTTOMAUTOROTATION, BOTTOMTOTOPAUTOROTATION } SLSAutorotationType;
typedef enum {ROTATIONINSTRUCTIONVIEW, SCALINGINSTRUCTIONVIEW, TRANSLATIONINSTRUCTIONVIEW, STOPINSTRUCTIONVIEW, MOUSEROTATIONINSTRUCTIONVIEW, MOUSESCALINGINSTRUCTIONVIEW, MOUSETRANSLATIONINSTRUCTIONVIEW} SLSInstructionViewType;
typedef enum {LEAPCONNECTEDVIEW, LEAPDISCONNECTEDVIEW} SLSLeapConnectionViewType;

@interface SLSMoleculeWindowController : NSWindowController<SLSGLViewDelegate, LeapListener, SLSMoleculeRenderingDelegate>
{
    SLSMolecule *molecule;
    SLSOpenGLRenderer *openGLRenderer;
    LeapController *controller;
    LeapFrame *previousLeapFrame;
    BOOL isRespondingToLeapInput;    
    
    BOOL isAutorotating;
	CVDisplayLinkRef displayLink;
    CFTimeInterval previousTimestamp;

    NSPoint lastFingerPoint;
    CGFloat startingZoomDistance, previousScale;
    BOOL isRotating;
    BOOL isZooming;
    
    BOOL isRunningRotationTutorial, isRunningScalingTutorial, isRunningTranslationTutorial;
    BOOL isRunningMouseRotationTutorial, isRunningMouseScalingTutorial, isRunningMouseTranslationTutorial;
    NSWindow *currentTutorialInstructionPopup, *currentLeapConnectionPopup;
    CGFloat totalMovementSinceStartOfTutorial;
    
    BOOL isShowingControlPanel, isShowingColorKey;
    
    NSString *filenameFromLoad;
    
    BOOL hasConnectedToLeap;
    
    SLSAutorotationType currentAutorotationType;
}

@property(readwrite, weak) IBOutlet SLSMoleculeGLView *glView;
@property(readonly, retain) SLSMoleculeOverlayWindowController *overlayWindowController;
@property(readwrite, retain) IBOutlet NSWindow *glWindow;
@property(readwrite, strong, nonatomic) IBOutlet NSView *rotationInstructionView, *scalingInstructionView, *translationInstructionView, *stopInstructionView;
@property(readwrite, strong, nonatomic) IBOutlet NSView *mouseRotationInstructionView, *mouseScalingInstructionView, *mouseTranslationInstructionView;
@property(readwrite, strong, nonatomic) IBOutlet NSView *leapMotionConnectedView, *leapMotionDisconnectedView;
@property(readwrite, weak) IBOutlet NSSplitView *applicationControlSplitView, *colorCodeSplitView;
@property(readwrite, weak) IBOutlet NSView *controlsView, *colorCodeView;
@property(readwrite, nonatomic) BOOL isDNAButtonPressed, isTRNAButtonPressed, isPumpButtonPressed, isCaffeineButtonPressed, isHemeButtonPressed, isNanotubeButtonPressed, isCholesterolButtonPressed, isInsulinButtonPressed, isTheoreticalBearingButtonPressed;

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

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError;

// Autorotation
- (IBAction)toggleAutorotation:(id)sender;
- (CVReturn)handleAutorotationTimer:(const CVTimeStamp *)currentTimeStamp;

// Tutorial
- (void)displayTutorialPanel:(SLSInstructionViewType)tutorialInstructionType;
- (void)displayLeapConnectionPanel:(SLSLeapConnectionViewType)leapConnectionType;

// Visualization modes
- (IBAction)switchToSpacefillingMode:(id)sender;
- (IBAction)switchToBallAndStickMode:(id)sender;

// Side panel visibility
- (IBAction)showOrHideColorKey:(id)sender;
- (IBAction)showOrHideControls:(id)sender;

// Sample molecule loading
- (void)openFileWithPath:(NSString *)filePath extension:(NSString *)fileExtension;
- (void)openPreloadedFileWithName:(NSString *)preloadedFileName ofType:(NSString *)fileType;
- (void)clearButtonPresses;
- (void)openDocument:(id)sender;
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

// Leap gesture interaction styles
- (void)useOpenHandToScaleAndRotate:(LeapFrame *)currentLeapFrame;

@end
