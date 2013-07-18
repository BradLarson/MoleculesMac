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
    
    NSMutableArray *allPossibleColorKeyValues;
    
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
@property(readwrite, weak, nonatomic) IBOutlet NSArrayController *colorKeyValueArrayController;

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
- (void)generateColorKeyValues;
- (void)updateColorKeyForMolecule;
- (NSImage *)imageForAtomColoredRed:(CGFloat)redComponent green:(CGFloat)greenComponent blue:(CGFloat)blueComponent atSize:(NSSize)imageSize;

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
