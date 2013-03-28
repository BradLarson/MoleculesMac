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
    
    SLSAutorotationType currentAutorotationType;
}

@property(readwrite, weak) IBOutlet SLSMoleculeGLView *glView;
@property(readonly, retain) SLSMoleculeOverlayWindowController *overlayWindowController;
@property(readwrite, retain) IBOutlet NSWindow *glWindow;

// Autorotation
- (IBAction)toggleAutorotation:(id)sender;
- (CVReturn)handleAutorotationTimer:(const CVTimeStamp *)currentTimeStamp;

// Leap gesture interaction styles
- (void)useFingersToRotateLikeOniOS:(LeapFrame *)currentLeapFrame;
- (void)useHandsToRotateLikeOniOS:(LeapFrame *)currentLeapFrame;
- (void)useGraspingMotionToScaleAndRotate:(LeapFrame *)currentLeapFrame;
- (void)useOpenHandToScaleAndRotate:(LeapFrame *)currentLeapFrame;

@end
