#import "SLSMoleculeDocument.h"
#import "SLSMoleculeOverlayWindowController.h"

#pragma mark -
#pragma mark Core Video callback function

static CVReturn renderCallback(CVDisplayLinkRef displayLink,
							   const CVTimeStamp *inNow,
							   const CVTimeStamp *inOutputTime,
							   CVOptionFlags flagsIn,
							   CVOptionFlags *flagsOut,
							   void *displayLinkContext)
{
    return [(__bridge SLSMoleculeDocument *)displayLinkContext handleAutorotationTimer:inOutputTime];
}

@implementation SLSMoleculeDocument

@synthesize glView = _glView;
@synthesize overlayWindowController = _overlayWindowController;
@synthesize glWindow = _glWindow;

- (id)init
{
    self = [super init];
    if (self) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		
		[nc addObserver:self selector:@selector(showScanningIndicator:) name:@"FileLoadingStarted" object:nil];
		[nc addObserver:self selector:@selector(updateScanningIndicator:) name:@"FileLoadingUpdate" object:nil];
		[nc addObserver:self selector:@selector(hideScanningIndicator:) name:@"FileLoadingEnded" object:nil];
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"SLSMoleculeDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];

    _glView.renderingDelegate = self;

    openGLRenderer = [[SLSOpenGLRenderer alloc] initWithContext:[_glView openGLContext]];
    
    [openGLRenderer createFramebuffersForView:_glView];
    [openGLRenderer clearScreen];
    
    [molecule switchToDefaultVisualizationMode];
    molecule.isBeingDisplayed = YES;
    [molecule performSelectorInBackground:@selector(renderMolecule:) withObject:openGLRenderer];
    
    controller = [[LeapController alloc] init];
    [controller addListener:self];
    
    // Create and place the overlay window above the rendering view
	NSRect overlayRect = [self.glView frame];
	NSPoint originOnScreen = [self.glWindow convertBaseToScreen:overlayRect.origin];
	overlayRect.origin = originOnScreen;
	
	[self.overlayWindowController.window setFrame:overlayRect display:YES];
	[self.glWindow addChildWindow:self.overlayWindowController.window ordered:NSWindowAbove];
}

- (void)windowDidResize:(NSNotification *)notification
{
	NSRect overlayRect = [self.glView frame];
	NSPoint originOnScreen = [self.glWindow convertBaseToScreen:overlayRect.origin];
	overlayRect.origin = originOnScreen;
	[self.overlayWindowController.window setFrame:overlayRect display:YES];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    molecule = [[SLSMolecule alloc] initWithData:data extension:typeName renderingDelegate:self];
    
    // Start rendering after callback
    
    return YES;
}

#pragma mark -
#pragma mark Rendering status control

- (void)showScanningIndicator:(NSNotification *)note;
{
}

- (void)updateScanningIndicator:(NSNotification *)note;
{
}

- (void)hideScanningIndicator:(NSNotification *)note;
{
}

#pragma mark -
#pragma mark Autorotation

- (IBAction)toggleAutorotation:(id)sender;
{
    if (isAutorotating)
	{
        CVDisplayLinkStop(displayLink);
        CVDisplayLinkRelease(displayLink);
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleRotationSelected" object:[NSNumber numberWithBool:NO]];
	}
	else
	{
		previousTimestamp = 0;
		CGDirectDisplayID   displayID = CGMainDisplayID();
		CVReturn            error = kCVReturnSuccess;
		error = CVDisplayLinkCreateWithCGDisplay(displayID, &displayLink);
		if (error)
		{
			NSLog(@"DisplayLink created with error:%d", error);
			displayLink = NULL;
		}
		CVDisplayLinkSetOutputCallback(displayLink, renderCallback, (__bridge void *)self);
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleRotationSelected" object:[NSNumber numberWithBool:YES]];
        CVDisplayLinkStart(displayLink);

	}
	isAutorotating = !isAutorotating;
}

- (CVReturn)handleAutorotationTimer:(const CVTimeStamp *)currentTimeStamp;
{
//	NSLog(@"Display link refresh period: %f", CVDisplayLinkGetActualOutputVideoRefreshPeriod(displayLink));
//	NSLog(@"videoTime: %d, hostTime: %lld, rateScalar: %f, videoRefreshPeriod: %lld", currentTimeStamp->videoTimeScale, currentTimeStamp->videoTime, currentTimeStamp->rateScalar, currentTimeStamp->videoRefreshPeriod);

	if (previousTimestamp == 0)
	{
        [self rotateModelFromScreenDisplacementInX:1.0f inY:0.0f];
	}
	else
	{
//        [self rotateModelFromScreenDisplacementInX:(30.0f * (displayLink.timestamp - previousTimestamp)) inY:0.0f];
	}
    
    [openGLRenderer renderFrameForMolecule:molecule];

//	previousTimestamp = displayLink.timestamp;
    
    return kCVReturnSuccess;
}

#pragma mark -
#pragma mark Leap gesture interaction styles

- (void)useFingersToRotateLikeOniOS:(LeapFrame *)currentLeapFrame;
{
    if ([[currentLeapFrame hands] count] != 0)
    {
        // Zoom gesture
        if ([[currentLeapFrame hands] count] > 1)
        {
            NSLog(@"Two hands");
            isRotating = NO;
            LeapHand *firstHand = [[currentLeapFrame hands] objectAtIndex:0];
            NSArray *firstHandFingers = [firstHand fingers];
            if ([firstHandFingers count] > 0)
            {
                // Try averaging the fingers on the hand to clean things up
                LeapVector *avgFirstFingerPosition = [[LeapVector alloc] init];
                for (LeapFinger *finger in firstHandFingers)
                {
                    avgFirstFingerPosition = [avgFirstFingerPosition plus:[finger tipPosition]];
                }
                avgFirstFingerPosition = [avgFirstFingerPosition divide:[firstHandFingers count]];
                LeapVector *tipPosition1 = avgFirstFingerPosition;
                
                //                LeapFinger *firstIndexFinger = [firstHandFingers objectAtIndex:0];
                //                LeapVector *tipPosition1 = [firstIndexFinger tipPosition];
                
                LeapHand *secondHand = [[currentLeapFrame hands] objectAtIndex:1];
                NSArray *secondHandFingers = [secondHand fingers];
                if ([[secondHand fingers] count] > 0)
                {
                    LeapVector *avgSecondFingerPosition = [[LeapVector alloc] init];
                    for (LeapFinger *finger in secondHandFingers)
                    {
                        avgSecondFingerPosition = [avgSecondFingerPosition plus:[finger tipPosition]];
                    }
                    avgSecondFingerPosition = [avgSecondFingerPosition divide:[firstHandFingers count]];
                    LeapVector *tipPosition2 = avgSecondFingerPosition;
                    
                    //                    LeapFinger *secondIndexFinger = [secondHandFingers objectAtIndex:0];
                    //                    LeapVector *tipPosition2 = [secondIndexFinger tipPosition];
                    NSLog(@"Two index fingers");
                    
                    if (!isZooming)
                    {
                        startingZoomDistance = sqrt((tipPosition1.x - tipPosition2.x) * (tipPosition1.x - tipPosition2.x) + (tipPosition1.y - tipPosition2.y) * (tipPosition1.y - tipPosition2.y) + (tipPosition1.z - tipPosition2.z) * (tipPosition1.z - tipPosition2.z)) + 20;
                        previousScale = 1.0f;
                    }
                    else
                    {
                        CGFloat currentZoomDistance = sqrt((tipPosition1.x - tipPosition2.x) * (tipPosition1.x - tipPosition2.x) + (tipPosition1.y - tipPosition2.y) * (tipPosition1.y - tipPosition2.y) + (tipPosition1.z - tipPosition2.z) * (tipPosition1.z - tipPosition2.z)) + 20;
                        [self scaleModelByFactor:(currentZoomDistance / startingZoomDistance) / previousScale];
                        previousScale = (currentZoomDistance / startingZoomDistance);
                    }
                    
                    isZooming = YES;
                    
                    NSLog(@"Zoom gesture with points: %@, %@", tipPosition1, tipPosition2);
                }
            }
        }
        else
        {
            isZooming = NO;
            
            LeapHand *firstHand = [[currentLeapFrame hands] objectAtIndex:0];
            NSArray *firstHandFingers = [firstHand fingers];
            NSLog(@"One hand");
            
            if ([firstHandFingers count] > 0)
            {
                LeapVector *avgFirstFingerPosition = [[LeapVector alloc] init];
                for (LeapFinger *finger in firstHandFingers)
                {
                    avgFirstFingerPosition = [avgFirstFingerPosition plus:[finger tipPosition]];
                }
                avgFirstFingerPosition = [avgFirstFingerPosition divide:[firstHandFingers count]];
                LeapVector *tipPosition1 = avgFirstFingerPosition;
                
                //                LeapFinger *firstIndexFinger = [firstHandFingers objectAtIndex:0];
                //                LeapVector *tipPosition1 = [firstIndexFinger tipPosition];
                NSLog(@"Rotate gesture with point: %@", tipPosition1);
                
                if (!isRotating)
                {
                    lastFingerPoint = NSMakePoint(tipPosition1.x, tipPosition1.y);
                }
                else
                {
                    NSPoint currentFingerPoint = NSMakePoint(tipPosition1.x, tipPosition1.y);
                    [self rotateModelFromScreenDisplacementInX:(currentFingerPoint.x - lastFingerPoint.x) inY:(lastFingerPoint.y - currentFingerPoint.y)];
                    lastFingerPoint = currentFingerPoint;
                }
                isRotating = YES;
            }
        }
    }
    else
    {
        isZooming = NO;
        isRotating = NO;
    }
    
    NSArray *gestures = [currentLeapFrame gestures:nil];
    for (int g = 0; g < [gestures count]; g++) {
        LeapGesture *gesture = [gestures objectAtIndex:g];
        switch (gesture.type) {
            case LEAP_GESTURE_TYPE_CIRCLE: {
                LeapCircleGesture *circleGesture = (LeapCircleGesture *)gesture;
                // Calculate the angle swept since the last frame
                float sweptAngle = 0;
                if(circleGesture.state != LEAP_GESTURE_STATE_START) {
                    LeapCircleGesture *previousUpdate = (LeapCircleGesture *)[currentLeapFrame gesture:gesture.id];
                    sweptAngle = (circleGesture.progress - previousUpdate.progress) * 2 * LEAP_PI;
                }
                
                NSLog(@"Circle");
                break;
            }
            case LEAP_GESTURE_TYPE_SWIPE: {
                LeapSwipeGesture *swipeGesture = (LeapSwipeGesture *)gesture;
                NSLog(@"Swipe");
                break;
            }
            case LEAP_GESTURE_TYPE_KEY_TAP: {
                LeapKeyTapGesture *keyTapGesture = (LeapKeyTapGesture *)gesture;
                NSLog(@"Key Tap");
                break;
            }
            case LEAP_GESTURE_TYPE_SCREEN_TAP: {
                LeapScreenTapGesture *screenTapGesture = (LeapScreenTapGesture *)gesture;
                NSLog(@"Screen Tap");
                break;
            }
            default:
                NSLog(@"Unknown gesture type");
                break;
        }
    }    
}

- (void)useHandsToRotateLikeOniOS:(LeapFrame *)currentLeapFrame;
{
    // Ignore a closed fist
    if ([[currentLeapFrame fingers] count] < 1)
    {
        previousLeapFrame = nil;
        return;
    }
    
    if ([[currentLeapFrame hands] count] > 1)      // Zoom gesture
    {
//        NSLog(@"Two hands");
//        
        CGFloat differentialScaleFactor = [currentLeapFrame scaleFactor:previousLeapFrame];
        [self scaleModelByFactor:differentialScaleFactor];
    }
    else if ([[currentLeapFrame hands] count] > 0) // Rotate gesture
    {
//        NSLog(@"One hand");
        LeapHand *firstHand = [[currentLeapFrame hands] objectAtIndex:0];
        LeapVector *handTranslation = [firstHand translation:previousLeapFrame];
        [self rotateModelFromScreenDisplacementInX:handTranslation.x inY:-handTranslation.y];
    }
    else
    {
        previousLeapFrame = nil;
    }
}

- (void)useGraspingMotionToScaleAndRotate:(LeapFrame *)currentLeapFrame;
{
    // Only rotate, scale, or translate when a fist is clenched
    if ([[currentLeapFrame hands] count] != 1)
    {
        previousLeapFrame = nil;
        return;
    }
        
    if ([[currentLeapFrame fingers] count] < 2)
    {
        LeapHand *firstHand = [[currentLeapFrame hands] objectAtIndex:0];
        LeapVector *handTranslation = [firstHand translation:previousLeapFrame];
        
        LeapVector *palmPosition = [firstHand palmPosition];
        
        if (palmPosition.z > 180.0)
        {
            previousLeapFrame = nil;
            return;
        }
        
        NSLog(@"Hand position: %f, %f", palmPosition.x, palmPosition.y);
        
        [self scaleModelByFactor:1.0 + (handTranslation.z * 0.005)];
        [self rotateModelFromScreenDisplacementInX:handTranslation.x inY:-handTranslation.y];
    }
    else
    {
        previousLeapFrame = nil;
    }
}

- (void)useOpenHandToScaleAndRotate:(LeapFrame *)currentLeapFrame;
{
    // Only rotate, scale, or translate when an open hand is detected
    if ([[currentLeapFrame hands] count] != 1)
    {
        previousLeapFrame = nil;
        return;
    }
    
    if ([[currentLeapFrame fingers] count] > 0)
    {
        LeapHand *firstHand = [[currentLeapFrame hands] objectAtIndex:0];
        LeapVector *handTranslation = [firstHand translation:previousLeapFrame];
        
        [self scaleModelByFactor:1.0 + (handTranslation.z * 0.005)];
        [self rotateModelFromScreenDisplacementInX:handTranslation.x inY:-handTranslation.y];
    }
    else
    {
        previousLeapFrame = nil;
    }
}

#pragma mark -
#pragma mark SLSMoleculeRenderingDelegate methods

- (void)renderingStarted;
{
    NSLog(@"Rendering started");
//    [self switchToDisplayFramebuffer];
//    
//    [[self openGLContext] makeCurrentContext];
//    NSLog(@"Awaking view");
//    glBindFramebuffer(GL_FRAMEBUFFER, 0);
//    glBindRenderbuffer(GL_RENDERBUFFER, 0);
//    glViewport(0, 0, backingWidth, backingHeight);
//    glClearColor(0.0f, 0.0f, 0.0f, 1.0f); // Black Background
//    glClear(GL_COLOR_BUFFER_BIT);
//    [[self openGLContext] flushBuffer];
//    glClearColor(0.0f, 0.0f, 0.0f, 1.0f); // Black Background
//    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//    [[self openGLContext] flushBuffer];
}

- (void)renderingUpdated:(CGFloat)renderingProgress;
{
    [self.overlayWindowController updateProgressIndicator:renderingProgress * 100.0];
}

- (void)renderingEnded;
{
    [self.overlayWindowController hideOverlay];

    NSLog(@"Finishing rendering");
	[openGLRenderer clearScreen];
	[NSThread sleepForTimeInterval:0.1];
    
    [openGLRenderer resetModelViewMatrix];
	
#ifdef RUN_OPENGL_BENCHMARKS
    
    [self.displayLink invalidate];
    self.displayLink = nil;
    
    //    [[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleRotationSelected" object:[NSNumber numberWithBool:NO]];
	[NSThread sleepForTimeInterval:0.2];
    
    
    [self runOpenGLBenchmarks];
#else
    
    [openGLRenderer renderFrameForMolecule:molecule];
    
    //    if (!isAutorotating)
    //    {
    //        [self startOrStopAutorotation:self];
    //    }
#endif
}

#pragma mark -
#pragma mark SLSGLViewDelegate methods

- (void)resizeView;
{
    [openGLRenderer resizeFramebuffersToMatchView:self.glView];
    [openGLRenderer renderFrameForMolecule:molecule];
}

- (void)rotateModelFromScreenDisplacementInX:(float)xRotation inY:(float)yRotation;
{
    [openGLRenderer rotateModelFromScreenDisplacementInX:xRotation inY:yRotation];
    [openGLRenderer renderFrameForMolecule:molecule];
}

- (void)scaleModelByFactor:(float)scaleFactor;
{
    [openGLRenderer scaleModelByFactor:scaleFactor];
    [openGLRenderer renderFrameForMolecule:molecule];
}

- (void)translateModelByScreenDisplacementInX:(float)xTranslation inY:(float)yTranslation;
{
    [openGLRenderer translateModelByScreenDisplacementInX:xTranslation inY:yTranslation];
    [openGLRenderer renderFrameForMolecule:molecule];
}

#pragma mark -
#pragma mark Leap Motion callbacks

- (void)onInit:(NSNotification *)notification
{
}

- (void)onConnect:(NSNotification *)notification;
{
    NSLog(@"Connected to Leap");
    LeapController *aController = (LeapController *)[notification object];
    [aController enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES];
}

- (void)onDisconnect:(NSNotification *)notification;
{
    NSLog(@"Disconnected from Leap");
    previousLeapFrame = nil;
}

- (void)onExit:(NSNotification *)notification;
{
    NSLog(@"Exited");
}

- (void)onFrame:(NSNotification *)notification;
{
    if (!isRespondingToLeapInput)
    {
        return;
    }
    
    LeapController *aController = (LeapController *)[notification object];
    
    // Get the most recent frame and report some basic information
    LeapFrame *frame = [aController frame:0];
//    NSLog(@"Frame id: %lld, timestamp: %lld, hands: %ld, fingers: %ld, tools: %ld, gestures: %ld",
//          [frame id], [frame timestamp], [[frame hands] count],
//          [[frame fingers] count], [[frame tools] count], [[frame gestures:nil] count]);
    
    if (previousLeapFrame != nil)
    {
//        [self useFingersToRotateLikeOniOS:frame];
        NSInteger leapControlStyle = [[NSUserDefaults standardUserDefaults] integerForKey:@"leapControlStyle"];
        switch(leapControlStyle)
        {
            case 0: [self useFingersToRotateLikeOniOS:frame]; break;
            case 1: [self useHandsToRotateLikeOniOS:frame]; break;
            case 2: [self useGraspingMotionToScaleAndRotate:frame]; break;
            case 3: [self useOpenHandToScaleAndRotate:frame]; break;
            default: [self useFingersToRotateLikeOniOS:frame]; break;
        }
    }
    previousLeapFrame = frame;
}

+ (NSString *)stringForState:(LeapGestureState)state
{
    switch (state) {
        case LEAP_GESTURE_STATE_INVALID:
            return @"STATE_INVALID";
        case LEAP_GESTURE_STATE_START:
            return @"STATE_START";
        case LEAP_GESTURE_STATE_UPDATE:
            return @"STATE_UPDATED";
        case LEAP_GESTURE_STATE_STOP:
            return @"STATE_STOP";
        default:
            return @"STATE_INVALID";
    }
}

#pragma mark -
#pragma mark NSWindowController delegate methods

- (void)windowWillClose:(NSNotification *)notification;
{
    if(isAutorotating)
    {
        CVDisplayLinkStop(displayLink);
        CVDisplayLinkRelease(displayLink);
    }
}

//- (void)windowDidBecomeMain:(NSNotification *)notification
- (void)windowDidBecomeKey:(NSNotification *)notification
{
    isRespondingToLeapInput = YES;
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    isRespondingToLeapInput = NO;
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification
{
    [openGLRenderer renderFrameForMolecule:molecule];

}

- (void)windowDidExitFullScreen:(NSNotification *)notification
{
    [openGLRenderer renderFrameForMolecule:molecule];
}

#pragma mark -
#pragma mark Accessors

- (SLSMoleculeOverlayWindowController *)overlayWindowController;
{
	if (_overlayWindowController == nil)
	{
		_overlayWindowController = [[SLSMoleculeOverlayWindowController alloc] initWithWindowNibName:@"SLSMoleculeOverlayWindowController"];
	}
	
	return _overlayWindowController;
}


@end
