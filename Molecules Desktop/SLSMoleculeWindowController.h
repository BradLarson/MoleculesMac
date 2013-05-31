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

typedef enum {LEFTTORIGHTAUTOROTATION, RIGHTTOLEFTAUTOROTATION, TOPTOBOTTOMAUTOROTATION, BOTTOMTOTOPAUTOROTATION } SLSAutorotationType;
typedef enum {ROTATIONINSTRUCTIONVIEW, SCALINGINSTRUCTIONVIEW, TRANSLATIONINSTRUCTIONVIEW, STOPINSTRUCTIONVIEW, MOUSEROTATIONINSTRUCTIONVIEW, MOUSESCALINGINSTRUCTIONVIEW, MOUSETRANSLATIONINSTRUCTIONVIEW} SLSInstructionViewType;

@interface SLSMoleculeDocument : NSDocument<SLSGLViewDelegate, LeapListener, SLSMoleculeRenderingDelegate>
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
    NSWindow *currentTutorialInstructionPopup;
    CGFloat totalMovementSinceStartOfTutorial;
    
    SLSAutorotationType currentAutorotationType;
}

@property(readwrite, weak) IBOutlet SLSMoleculeGLView *glView;
@property(readonly, retain) SLSMoleculeOverlayWindowController *overlayWindowController;
@property(readwrite, retain) IBOutlet NSWindow *glWindow;
@property(readwrite, strong, nonatomic) IBOutlet NSView *rotationInstructionView, *scalingInstructionView, *translationInstructionView, *stopInstructionView;
@property(readwrite, strong, nonatomic) IBOutlet NSView *mouseRotationInstructionView, *mouseScalingInstructionView, *mouseTranslationInstructionView;

// Autorotation
- (IBAction)toggleAutorotation:(id)sender;
- (CVReturn)handleAutorotationTimer:(const CVTimeStamp *)currentTimeStamp;

// Tutorial
- (void)displayTutorialPanel:(SLSInstructionViewType)tutorialInstructionType;

// Visualization modes
- (IBAction)switchToSpacefillingMode:(id)sender;
- (IBAction)switchToBallAndStickMode:(id)sender;

// Leap gesture interaction styles
- (void)useOpenHandToScaleAndRotate:(LeapFrame *)currentLeapFrame;

@end
