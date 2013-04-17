#import "SLSMoleculeDocument.h"
#import "SLSMoleculeOverlayWindowController.h"
#import "TransparentWindow.h"

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
@synthesize rotationInstructionView = _rotationInstructionView, scalingInstructionView = _scalingInstructionView, translationInstructionView = _translationInstructionView, stopInstructionView = _stopInstructionView;
@synthesize mouseRotationInstructionView = _mouseRotationInstructionView, mouseScalingInstructionView = _mouseScalingInstructionView, mouseTranslationInstructionView = _mouseTranslationInstructionView;

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
    currentAutorotationType = LEFTTORIGHTAUTOROTATION;
    
    _glView.renderingDelegate = self;

    openGLRenderer = [[SLSOpenGLRenderer alloc] initWithContext:[_glView openGLContext]];
    
    [openGLRenderer createFramebuffersForView:_glView];
    [openGLRenderer resizeFramebuffersToMatchView:_glView];
    
    [molecule switchToDefaultVisualizationMode];
    molecule.isBeingDisplayed = YES;
    [molecule performSelectorInBackground:@selector(renderMolecule:) withObject:openGLRenderer];
    
    controller = [[LeapController alloc] init];
    [controller addListener:self];
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ( (!isRunningRotationTutorial) && (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasShownTutorial"]) )
        {
            [self displayTutorialPanel:MOUSEROTATIONINSTRUCTIONVIEW];
            isRunningMouseRotationTutorial = YES;
            isRunningMouseScalingTutorial = NO;
            isRunningMouseTranslationTutorial = NO;
            totalMovementSinceStartOfTutorial = 0.0;
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasShownTutorial"];
        }
    });

}

- (void)windowDidResize:(NSNotification *)notification
{
	NSRect overlayRect = [self.glView frame];
	NSPoint originOnScreen = [self.glWindow convertBaseToScreen:overlayRect.origin];
	overlayRect.origin = originOnScreen;
	[self.overlayWindowController.window setFrame:overlayRect display:YES];
    
    if (currentTutorialInstructionPopup != nil)
    {
        NSSize popupSize = [currentTutorialInstructionPopup frame].size;
        NSPoint popupOrigin = NSMakePoint(round( self.glWindow.frame.origin.x + self.glWindow.frame.size.width / 2.0 - popupSize.width / 2.0), round(self.glWindow.frame.origin.y + self.glWindow.frame.size.height / 2.0 - popupSize.height / 2.0));
        [currentTutorialInstructionPopup setFrame:NSMakeRect(popupOrigin.x, popupOrigin.y, popupSize.width, popupSize.height) display:YES];
    }
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
#pragma mark Tutorial

- (void)displayTutorialPanel:(SLSInstructionViewType)tutorialInstructionType;
{
	NSView *tutorialInstructionView = nil;
	
	switch (tutorialInstructionType)
	{
		case ROTATIONINSTRUCTIONVIEW:
		{
			tutorialInstructionView = _rotationInstructionView;
		}; break;
		case SCALINGINSTRUCTIONVIEW:
		{
			tutorialInstructionView = _scalingInstructionView;
		}; break;
		case TRANSLATIONINSTRUCTIONVIEW:
		{
			tutorialInstructionView = _translationInstructionView;
		}; break;
		case STOPINSTRUCTIONVIEW:
		{
			tutorialInstructionView = _stopInstructionView;
		}; break;
		case MOUSEROTATIONINSTRUCTIONVIEW:
		{
			tutorialInstructionView = _mouseRotationInstructionView;
		}; break;
		case MOUSESCALINGINSTRUCTIONVIEW:
		{
			tutorialInstructionView = _mouseScalingInstructionView;
		}; break;
		case MOUSETRANSLATIONINSTRUCTIONVIEW:
		{
			tutorialInstructionView = _mouseTranslationInstructionView;
		}; break;
	}
	
	NSSize popupSize = [tutorialInstructionView frame].size;
	
//	NSArray *screensAttachedToSystem = [NSScreen screens];
//	NSRect primaryScreenFrame = [(NSScreen *)[screensAttachedToSystem objectAtIndex:0] frame];
	
//	NSPoint popupOrigin = NSMakePoint(round(primaryScreenFrame.size.width / 2.0 - popupSize.width / 2.0), round(primaryScreenFrame.size.height / 2.0 - popupSize.height / 2.0));
	NSPoint popupOrigin = NSMakePoint(round( self.glWindow.frame.origin.x + self.glWindow.frame.size.width / 2.0 - popupSize.width / 2.0), round(self.glWindow.frame.origin.y + self.glWindow.frame.size.height / 2.0 - popupSize.height / 2.0));
	
	currentTutorialInstructionPopup = [[TransparentWindow alloc] initWithContentRect:NSMakeRect(popupOrigin.x, popupOrigin.y, popupSize.width, popupSize.height) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	[currentTutorialInstructionPopup setContentView:tutorialInstructionView];
	
	[currentTutorialInstructionPopup setAlphaValue:0.0];
	[currentTutorialInstructionPopup makeKeyAndOrderFront:self];
	[currentTutorialInstructionPopup.animator setAlphaValue:1.0];
    
    [self.glWindow addChildWindow:currentTutorialInstructionPopup ordered:NSWindowAbove];
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
        switch(currentAutorotationType)
        {
            case LEFTTORIGHTAUTOROTATION:[openGLRenderer rotateModelFromScreenDisplacementInX:1.0f inY:0.0f]; break;
            case RIGHTTOLEFTAUTOROTATION:[openGLRenderer rotateModelFromScreenDisplacementInX:-1.0f inY:0.0f]; break;
            case TOPTOBOTTOMAUTOROTATION:[openGLRenderer rotateModelFromScreenDisplacementInX:0.0f inY:1.0f]; break;
            case BOTTOMTOTOPAUTOROTATION:[openGLRenderer rotateModelFromScreenDisplacementInX:0.0f inY:-1.0f]; break;
        }
        [openGLRenderer renderFrameForMolecule:molecule];
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
#pragma mark Visualization modes

- (IBAction)switchToSpacefillingMode:(id)sender;
{
    if (molecule.currentVisualizationType == SPACEFILLING)
    {
        return;
    }
    
    molecule.currentVisualizationType = SPACEFILLING;
    [openGLRenderer freeVertexBuffers];
    [molecule performSelectorInBackground:@selector(renderMolecule:) withObject:openGLRenderer];
}

- (IBAction)switchToBallAndStickMode:(id)sender;
{
    if (molecule.currentVisualizationType == BALLANDSTICK)
    {
        return;
    }

    molecule.currentVisualizationType = BALLANDSTICK;
    [openGLRenderer freeVertexBuffers];
    [molecule performSelectorInBackground:@selector(renderMolecule:) withObject:openGLRenderer];
}

#pragma mark -
#pragma mark Leap gesture interaction styles

- (void)useOpenHandToScaleAndRotate:(LeapFrame *)currentLeapFrame;
{
    NSMutableArray *openHands = [[NSMutableArray alloc] initWithCapacity:3];
    for (LeapHand *currentHand in [currentLeapFrame hands])
    {
        if ([[currentHand fingers] count] > 1)
        {
            [openHands addObject:currentHand];
        }
    }
    
    
    // Only rotate, scale, or translate when an open hand is detected
    if ([openHands count] < 1)
    {
        previousLeapFrame = nil;
        return;
    }
    else if ([openHands count] < 2)
    {
        LeapHand *firstHand = [openHands objectAtIndex:0];
        
        if ([[firstHand fingers] count] > 2)
        {
            if (isAutorotating)
            {
                [self toggleAutorotation:self];
            }
            
            LeapVector *handTranslation = [firstHand translation:previousLeapFrame];
            
            if ((abs(handTranslation.x) > 40.0) || (abs(handTranslation.x) > 40.0) || (abs(handTranslation.z) > 40.0))
            {
                previousLeapFrame = nil;
                return;
            }
            
            if (isRunningRotationTutorial)
            {
                totalMovementSinceStartOfTutorial += abs(handTranslation.x) + abs(handTranslation.y);
//                NSLog(@"Total rotation movement: %f", totalMovementSinceStartOfTutorial);
                
                if (totalMovementSinceStartOfTutorial > 50)
                {
                    [currentTutorialInstructionPopup.animator setAlphaValue:0.0];
                    
                    [self displayTutorialPanel:SCALINGINSTRUCTIONVIEW];
                    isRunningRotationTutorial = NO;
                    isRunningScalingTutorial = YES;
                    isRunningTranslationTutorial = NO;
                    totalMovementSinceStartOfTutorial = 0.0;
                }
            }
            else if (isRunningScalingTutorial)
            {
                totalMovementSinceStartOfTutorial += abs(handTranslation.z);
//                NSLog(@"Total scaling movement: %f", totalMovementSinceStartOfTutorial);
                
                if (totalMovementSinceStartOfTutorial > 50)
                {
                    [currentTutorialInstructionPopup.animator setAlphaValue:0.0];
                    
                    [self displayTutorialPanel:TRANSLATIONINSTRUCTIONVIEW];
                    isRunningRotationTutorial = NO;
                    isRunningScalingTutorial = NO;
                    isRunningTranslationTutorial = YES;
                    totalMovementSinceStartOfTutorial = 0.0;
                }
            }
            
            [openGLRenderer scaleModelByFactor:1.0 + (handTranslation.z * 0.007)];
            [openGLRenderer rotateModelFromScreenDisplacementInX:handTranslation.x inY:-handTranslation.y];
            [openGLRenderer renderFrameForMolecule:molecule];
        }
        else
        {
//            LeapVector *verticalAxis = [[LeapVector alloc] initWithX:1.0 y:0.0 z:0.0];
//            CGFloat verticalAngle = [firstHand rotationAngle:previousLeapFrame axis:verticalAxis];
//            
//            LeapVector *horizontalAxis = [[LeapVector alloc] initWithX:0.0 y:1.0 z:0.0];
//            CGFloat horizontalAngle = [firstHand rotationAngle:previousLeapFrame axis:horizontalAxis];
//            if ( (abs(horizontalAngle) < 0.15) && (abs(verticalAngle) < 0.15) )
//            {
//                [openGLRenderer rotateModelFromScreenDisplacementInX:-horizontalAngle * 200.0 inY:-verticalAngle * 200.0];
//            }
//            //            [openGLRenderer rotateModelFromScreenDisplacementInX:handTranslation.x inY:-handTranslation.y];
//            [openGLRenderer renderFrameForMolecule:molecule];

            previousLeapFrame = nil;
        }
    }
    else
    {
        if (isAutorotating)
        {
            [self toggleAutorotation:self];
        }
//        LeapHand *firstHand = [openHands objectAtIndex:0];
//        LeapHand *secondHand = [openHands objectAtIndex:1];

        LeapVector *multiHandTranslation = [currentLeapFrame translation:previousLeapFrame];
        [openGLRenderer translateModelByScreenDisplacementInX:3.0 * multiHandTranslation.x inY:3.0 * multiHandTranslation.y];
        [openGLRenderer scaleModelByFactor:1.0 + (multiHandTranslation.z * 0.007)];
        [openGLRenderer renderFrameForMolecule:molecule];
        
        if (isRunningTranslationTutorial)
        {
            totalMovementSinceStartOfTutorial += abs(multiHandTranslation.x) + abs(multiHandTranslation.y) + abs(multiHandTranslation.z);
//                NSLog(@"Total translation movement: %f", totalMovementSinceStartOfTutorial);
            
            if (totalMovementSinceStartOfTutorial > 20)
            {
                [currentTutorialInstructionPopup.animator setAlphaValue:0.0];
                
                [self displayTutorialPanel:STOPINSTRUCTIONVIEW];
                isRunningRotationTutorial = NO;
                isRunningScalingTutorial = NO;
                isRunningTranslationTutorial = NO;
                totalMovementSinceStartOfTutorial = 0.0;
                double delayInSeconds = 2.5;
                
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [currentTutorialInstructionPopup.animator setAlphaValue:0.0];
                });

            }
        }
    }
}

#pragma mark -
#pragma mark SLSMoleculeRenderingDelegate methods

- (void)renderingStarted;
{
    // Create and place the overlay window above the rendering view
	NSRect overlayRect = [self.glView frame];
	NSPoint originOnScreen = [self.glWindow convertBaseToScreen:overlayRect.origin];
	overlayRect.origin = originOnScreen;
	
    [self.overlayWindowController showOverlay];
	[self.overlayWindowController.window setFrame:overlayRect display:YES];
	[self.glWindow addChildWindow:self.overlayWindowController.window ordered:NSWindowAbove];
    

//    [self switchToDisplayFramebuffer];
//    
//    [[self openGLContext] makeCurrentContext];
//    glViewport(0, 0, backingWidth, backingHeight);
//    glClearColor(0.0f, 0.0f, 0.0f, 1.0f); // Black Background
//	glClear(GL_COLOR_BUFFER_BIT);
//    CGLFlushDrawable([[self openGLContext] CGLContextObj]);

    
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
    [self toggleAutorotation:self];
    
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
    if ([molecule isDoneRendering])
    {
        [openGLRenderer waitForLastFrameToFinishRendering];
        [openGLRenderer renderFrameForMolecule:molecule];
    }
}

- (void)rotateModelFromScreenDisplacementInX:(float)xRotation inY:(float)yRotation;
{
    if (isAutorotating)
    {
        [self toggleAutorotation:self];
    }

    if (isRunningMouseRotationTutorial)
    {
        totalMovementSinceStartOfTutorial += abs(xRotation) + abs(yRotation);
        //                NSLog(@"Total rotation movement: %f", totalMovementSinceStartOfTutorial);
        
        if (totalMovementSinceStartOfTutorial > 50)
        {
            [currentTutorialInstructionPopup.animator setAlphaValue:0.0];
            
            [self displayTutorialPanel:MOUSESCALINGINSTRUCTIONVIEW];
            isRunningMouseRotationTutorial = NO;
            isRunningMouseScalingTutorial = YES;
            isRunningMouseTranslationTutorial = NO;
            totalMovementSinceStartOfTutorial = 0.0;
        }
    }

    [openGLRenderer rotateModelFromScreenDisplacementInX:xRotation inY:yRotation];
    [openGLRenderer renderFrameForMolecule:molecule];
}

- (void)scaleModelByFactor:(float)scaleFactor;
{
    if (isAutorotating)
    {
        [self toggleAutorotation:self];
    }

    if (isRunningMouseScalingTutorial)
    {
        totalMovementSinceStartOfTutorial += scaleFactor;
        //                NSLog(@"Total rotation movement: %f", totalMovementSinceStartOfTutorial);
        
        if (totalMovementSinceStartOfTutorial > 20)
        {
            [currentTutorialInstructionPopup.animator setAlphaValue:0.0];
            
            [self displayTutorialPanel:MOUSETRANSLATIONINSTRUCTIONVIEW];
            isRunningMouseRotationTutorial = NO;
            isRunningMouseScalingTutorial = NO;
            isRunningMouseTranslationTutorial = YES;
            totalMovementSinceStartOfTutorial = 0.0;
        }
    }

    [openGLRenderer scaleModelByFactor:scaleFactor];
    [openGLRenderer renderFrameForMolecule:molecule];
}

- (void)translateModelByScreenDisplacementInX:(float)xTranslation inY:(float)yTranslation;
{
    if (isAutorotating)
    {
        [self toggleAutorotation:self];
    }
    
    if (isRunningMouseTranslationTutorial)
    {
        totalMovementSinceStartOfTutorial += abs(xTranslation) + abs(yTranslation);
        //                NSLog(@"Total rotation movement: %f", totalMovementSinceStartOfTutorial);
        
        if (totalMovementSinceStartOfTutorial > 50)
        {
            [currentTutorialInstructionPopup.animator setAlphaValue:0.0];
            isRunningMouseRotationTutorial = NO;
            isRunningMouseScalingTutorial = NO;
            isRunningMouseTranslationTutorial = NO;
            totalMovementSinceStartOfTutorial = 0.0;
        }
    }


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
//    LeapController *aController = (LeapController *)[notification object];
//    [aController enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES];

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasShownTutorial"])
    {
        [self displayTutorialPanel:ROTATIONINSTRUCTIONVIEW];
        isRunningRotationTutorial = YES;
        isRunningScalingTutorial = NO;
        isRunningTranslationTutorial = NO;
        totalMovementSinceStartOfTutorial = 0.0;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasShownTutorial"];
    }
}


- (void)onDisconnect:(NSNotification *)notification;
{
    previousLeapFrame = nil;
}

- (void)onExit:(NSNotification *)notification;
{
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
        [self useOpenHandToScaleAndRotate:frame];
//        NSInteger leapControlStyle = [[NSUserDefaults standardUserDefaults] integerForKey:@"leapControlStyle"];
//        switch(leapControlStyle)
//        {
//            case 0: [self useFingersToRotateLikeOniOS:frame]; break;
//            case 1: [self useHandsToRotateLikeOniOS:frame]; break;
//            case 2: [self useGraspingMotionToScaleAndRotate:frame]; break;
//            case 3: [self useOpenHandToScaleAndRotate:frame]; break;
//            default: [self useFingersToRotateLikeOniOS:frame]; break;
//        }
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

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL theAction = [anItem action];
    
    if (theAction == @selector(switchToBallAndStickMode:))
    {
        if (molecule.numberOfBonds > 0)
        {
            return YES;
        }
        return NO;
    }
    else if (theAction == @selector(toggleAutorotation:))
    {
        NSMenuItem *currentMenuItem = (NSMenuItem *)anItem;
        if ([currentMenuItem respondsToSelector:@selector(setState:)])
        {
            if (isAutorotating)
            {
                [currentMenuItem setState:NSOnState];
            }
            else
            {
                [currentMenuItem setState:NSOffState];
            }
        }

    }
    return [super validateUserInterfaceItem:anItem];
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
