#import "SLSMoleculeDocument.h"

@implementation SLSMoleculeDocument

@synthesize glView = _glView;

- (id)init
{
    self = [super init];
    if (self) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(showRenderingIndicator:) name:kSLSMoleculeRenderingStartedNotification object:nil];
		[nc addObserver:self selector:@selector(updateRenderingIndicator:) name:kSLSMoleculeRenderingUpdateNotification object:nil];
		[nc addObserver:self selector:@selector(hideRenderingIndicator:) name:kSLSMoleculeRenderingEndedNotification object:nil];
		
		[nc addObserver:self selector:@selector(showScanningIndicator:) name:@"FileLoadingStarted" object:nil];
		[nc addObserver:self selector:@selector(updateScanningIndicator:) name:@"FileLoadingUpdate" object:nil];
		[nc addObserver:self selector:@selector(hideScanningIndicator:) name:@"FileLoadingEnded" object:nil];
        
        [nc addObserver:self selector:@selector(handleFinishOfMoleculeRendering:) name:@"MoleculeRenderingEnded" object:nil];
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

    NSLog(@"Assign renderer");
    _glView.renderingDelegate = self;

    openGLRenderer = [[SLSOpenGLRenderer alloc] initWithContext:[_glView openGLContext]];
    
    [openGLRenderer createFramebuffersForView:_glView];
    [openGLRenderer clearScreen];
    
    [molecule switchToDefaultVisualizationMode];
    molecule.isBeingDisplayed = YES;
    [molecule performSelectorInBackground:@selector(renderMolecule:) withObject:openGLRenderer];
    
    controller = [[LeapController alloc] init];
    [controller addListener:self];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.

    NSLog(@"Data type: %@", typeName);
    
    molecule = [[SLSMolecule alloc] initWithData:data extension:typeName];

    NSLog(@"Read molecule data");
    
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

- (void)showRenderingIndicator:(NSNotification *)note;
{
	[openGLRenderer clearScreen];
    
    NSLog(@"Clearing screen");
}

- (void)updateRenderingIndicator:(NSNotification *)note;
{
}

- (void)hideRenderingIndicator:(NSNotification *)note;
{
}

- (void)handleFinishOfMoleculeRendering:(NSNotification *)note;
{
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
    NSLog(@"Initialized Leap");
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
}

- (void)onExit:(NSNotification *)notification;
{
    NSLog(@"Exited");
}

- (void)onFrame:(NSNotification *)notification;
{
    LeapController *aController = (LeapController *)[notification object];
    
    // Get the most recent frame and report some basic information
    LeapFrame *frame = [aController frame:0];
//    NSLog(@"Frame id: %lld, timestamp: %lld, hands: %ld, fingers: %ld, tools: %ld, gestures: %ld",
//          [frame id], [frame timestamp], [[frame hands] count],
//          [[frame fingers] count], [[frame tools] count], [[frame gestures:nil] count]);
    
    if ([[frame hands] count] != 0)
    {
        // Zoom gesture
        if ([[frame hands] count] > 1)
        {
            NSLog(@"Two hands");
            isRotating = NO;
            LeapHand *firstHand = [[frame hands] objectAtIndex:0];
            NSArray *firstHandFingers = [firstHand fingers];
            if ([firstHandFingers count] > 0)
            {
                LeapFinger *firstIndexFinger = [firstHandFingers objectAtIndex:0];
                LeapVector *tipPosition1 = [firstIndexFinger tipPosition];
                
                LeapHand *secondHand = [[frame hands] objectAtIndex:1];
                NSArray *secondHandFingers = [secondHand fingers];
                if ([[secondHand fingers] count] > 0)
                {
                    LeapFinger *secondIndexFinger = [secondHandFingers objectAtIndex:0];
                    LeapVector *tipPosition2 = [secondIndexFinger tipPosition];
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
            
            LeapHand *firstHand = [[frame hands] objectAtIndex:0];
            NSArray *firstHandFingers = [firstHand fingers];
            NSLog(@"One hand");
            
            if ([firstHandFingers count] > 0)
            {
                LeapFinger *firstIndexFinger = [firstHandFingers objectAtIndex:0];
                LeapVector *tipPosition1 = [firstIndexFinger tipPosition];
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
    
    NSArray *gestures = [frame gestures:nil];
    for (int g = 0; g < [gestures count]; g++) {
        LeapGesture *gesture = [gestures objectAtIndex:g];
        switch (gesture.type) {
            case LEAP_GESTURE_TYPE_CIRCLE: {
                LeapCircleGesture *circleGesture = (LeapCircleGesture *)gesture;
                // Calculate the angle swept since the last frame
                float sweptAngle = 0;
                if(circleGesture.state != LEAP_GESTURE_STATE_START) {
                    LeapCircleGesture *previousUpdate = (LeapCircleGesture *)[[aController frame:1] gesture:gesture.id];
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

@end
