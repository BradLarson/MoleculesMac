#import "SLSMoleculeWindowController.h"
#import "SLSMoleculeOverlayWindowController.h"
#import "TransparentWindow.h"
#import "SLSAtomColorView.h"

NSString *const kSLSMoleculeControlPanelNotification = @"MoleculeControlPanelNotification";
NSString *const kSLSMoleculeColorKeyPanelNotification = @"MoleculeColorKeyPanelNotification";

#pragma mark -
#pragma mark Core Video callback function

static CVReturn renderCallback(CVDisplayLinkRef displayLink,
							   const CVTimeStamp *inNow,
							   const CVTimeStamp *inOutputTime,
							   CVOptionFlags flagsIn,
							   CVOptionFlags *flagsOut,
							   void *displayLinkContext)
{
    return [(__bridge SLSMoleculeWindowController *)displayLinkContext handleAutorotationTimer:inOutputTime];
}

@implementation SLSMoleculeWindowController

@synthesize glView = _glView;
@synthesize overlayWindowController = _overlayWindowController;
@synthesize glWindow = _glWindow;
@synthesize rotationInstructionView = _rotationInstructionView, scalingInstructionView = _scalingInstructionView, translationInstructionView = _translationInstructionView, stopInstructionView = _stopInstructionView;
@synthesize mouseRotationInstructionView = _mouseRotationInstructionView, mouseScalingInstructionView = _mouseScalingInstructionView, mouseTranslationInstructionView = _mouseTranslationInstructionView;
@synthesize applicationControlSplitView = _applicationControlSplitView, colorCodeSplitView = _colorCodeSplitView;
@synthesize controlsView = _controlsView, colorCodeView = _colorCodeView;
@synthesize leapMotionConnectedView = _leapMotionConnectedView, leapMotionDisconnectedView = _leapMotionDisconnectedView;
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

- (id)init
{
    self = [super init];
    if (self) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		
		[nc addObserver:self selector:@selector(showScanningIndicator:) name:@"FileLoadingStarted" object:nil];
		[nc addObserver:self selector:@selector(updateScanningIndicator:) name:@"FileLoadingUpdate" object:nil];
		[nc addObserver:self selector:@selector(hideScanningIndicator:) name:@"FileLoadingEnded" object:nil];
        
        hasConnectedToLeap = NO;
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"SLSMoleculeWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    currentAutorotationType = LEFTTORIGHTAUTOROTATION;
    
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

    isShowingControlPanel = YES;
    isShowingColorKey = YES;

    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0)]; //RGB plus Alpha Channel
    [_colorCodeView setLayer:viewLayer];
    [_colorCodeView setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
    
    _glView.renderingDelegate = self;
    
    if (molecule == nil)
    {
        NSString *lastLoadedMolecule = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastLoadedMolecule"];
        NSData *storedSecureBookmark = [[NSUserDefaults standardUserDefaults] objectForKey:@"previousMoleculeBookmark"];
        if (storedSecureBookmark != nil)
        {
            NSError *error;
            NSURL *bookmarkURL = [NSURL URLByResolvingBookmarkData:storedSecureBookmark
                                                      options:NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
                                                relativeToURL:nil
                                          bookmarkDataIsStale:nil
                                                        error:&error];
            if([bookmarkURL respondsToSelector:@selector(startAccessingSecurityScopedResource)])
            {
                [bookmarkURL startAccessingSecurityScopedResource];
            }
            
            [self openFileWithPath:lastLoadedMolecule extension:[[lastLoadedMolecule pathExtension] lowercaseString]];
            
            if([bookmarkURL respondsToSelector:@selector(stopAccessingSecurityScopedResource)])
            {
                [bookmarkURL stopAccessingSecurityScopedResource];
            }
        }
        else if (lastLoadedMolecule == nil)
        {
            [self openFileWithPath:[[NSBundle mainBundle] pathForResource:@"DNA" ofType:@"pdb"] extension:@"pdb"];
        }
        else
        {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:lastLoadedMolecule])
            {
                [self openFileWithPath:lastLoadedMolecule extension:[[lastLoadedMolecule pathExtension] lowercaseString]];
            }
            else
            {
                [self openFileWithPath:[[NSBundle mainBundle] pathForResource:@"DNA" ofType:@"pdb"] extension:@"pdb"];
            }
        }
    }
    else
    {
        [self.glWindow setTitle:filenameFromLoad];
    }

    controller = [[LeapController alloc] init];
    [controller addListener:self];

    openGLRenderer = [[SLSOpenGLRenderer alloc] initWithContext:[_glView openGLContext]];
    
    [openGLRenderer createFramebuffersForView:_glView];
    [openGLRenderer resizeFramebuffersToMatchView:_glView];
    
    [molecule switchToDefaultVisualizationMode];
    molecule.isBeingDisplayed = YES;
    [molecule performSelectorInBackground:@selector(renderMolecule:) withObject:openGLRenderer];    
}

- (void)windowDidResize:(NSNotification *)notification
{
	NSRect overlayRect = [self.applicationControlSplitView convertRect:[self.glView frame] fromView:self.glView];
	NSPoint originOnScreen = [self.glWindow convertBaseToScreen:overlayRect.origin];
	overlayRect.origin = originOnScreen;
	[self.overlayWindowController.window setFrame:overlayRect display:YES];
    
    if (currentTutorialInstructionPopup != nil)
    {
        NSSize popupSize = [currentTutorialInstructionPopup frame].size;
        NSPoint popupOrigin = NSMakePoint(round( self.glWindow.frame.origin.x + self.glWindow.frame.size.width / 2.0 - popupSize.width / 2.0), self.glWindow.frame.origin.y + self.glWindow.frame.size.height - popupSize.height - 30.0);
        [currentTutorialInstructionPopup setFrame:NSMakeRect(popupOrigin.x, popupOrigin.y, popupSize.width, popupSize.height) display:YES];
    }

    if (currentLeapConnectionPopup != nil)
    {
        NSSize popupSize = [currentLeapConnectionPopup frame].size;
        NSPoint popupOrigin = NSMakePoint(round( self.glWindow.frame.origin.x + self.glWindow.frame.size.width / 2.0 - popupSize.width / 2.0), self.glWindow.frame.origin.y + 30.0);
        [currentLeapConnectionPopup setFrame:NSMakeRect(popupOrigin.x, popupOrigin.y, popupSize.width, popupSize.height) display:YES];
    }
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    if (molecule == nil)
    {
        molecule = [[SLSMolecule alloc] initWithData:data extension:typeName renderingDelegate:self];
    }
    else
    {
        if (isAutorotating)
        {
            [self toggleAutorotation:self];
        }

        if (!molecule.isDoneRendering)
        {
            molecule.isRenderingCancelled = YES;
            [NSThread sleepForTimeInterval:0.1];
        }
        else
        {
            [openGLRenderer freeVertexBuffers];
        }

        [openGLRenderer clearScreen];

        molecule = [[SLSMolecule alloc] initWithData:data extension:typeName renderingDelegate:self];
        [molecule switchToDefaultVisualizationMode];
        molecule.isBeingDisplayed = YES;
        [molecule performSelectorInBackground:@selector(renderMolecule:) withObject:openGLRenderer];
    }

    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ( (!isRunningRotationTutorial) && (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasShownTutorial"]) )
        {
            if (hasConnectedToLeap)
            {
                [self displayTutorialPanel:ROTATIONINSTRUCTIONVIEW];
                isRunningRotationTutorial = YES;
                isRunningScalingTutorial = NO;
                isRunningTranslationTutorial = NO;
                totalMovementSinceStartOfTutorial = 0.0;
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasShownTutorial"];
            }
            else
            {
                [self displayTutorialPanel:MOUSEROTATIONINSTRUCTIONVIEW];
                isRunningMouseRotationTutorial = YES;
                isRunningMouseScalingTutorial = NO;
                isRunningMouseTranslationTutorial = NO;
                totalMovementSinceStartOfTutorial = 0.0;
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasShownTutorial"];
            }
        }
    });

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
    if (currentTutorialInstructionPopup)
    {
        [self.glWindow removeChildWindow:currentTutorialInstructionPopup];
        [currentTutorialInstructionPopup setReleasedWhenClosed:NO];
        [currentTutorialInstructionPopup close];
        currentTutorialInstructionPopup = nil;
    }
    
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
	
//	NSPoint popupOrigin = NSMakePoint(round( self.glWindow.frame.origin.x + self.glWindow.frame.size.width / 2.0 - popupSize.width / 2.0), round(self.glWindow.frame.origin.y + self.glWindow.frame.size.height / 2.0 - popupSize.height / 2.0));
	NSPoint popupOrigin = NSMakePoint(round( self.glWindow.frame.origin.x + self.glWindow.frame.size.width / 2.0 - popupSize.width / 2.0), self.glWindow.frame.origin.y + self.glWindow.frame.size.height - popupSize.height - 30.0);
	
	currentTutorialInstructionPopup = [[TransparentWindow alloc] initWithContentRect:NSMakeRect(popupOrigin.x, popupOrigin.y, popupSize.width, popupSize.height) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	[currentTutorialInstructionPopup setContentView:tutorialInstructionView];
	
	[currentTutorialInstructionPopup setAlphaValue:0.0];
	[currentTutorialInstructionPopup makeKeyAndOrderFront:self];
	[currentTutorialInstructionPopup.animator setAlphaValue:1.0];
    
    [self.glWindow addChildWindow:currentTutorialInstructionPopup ordered:NSWindowAbove];
}

- (void)displayLeapConnectionPanel:(SLSLeapConnectionViewType)leapConnectionType;
{
	NSView *leapConnectionTypeView = nil;
	
	switch (leapConnectionType)
	{
		case LEAPCONNECTEDVIEW:
		{
			leapConnectionTypeView = _leapMotionConnectedView;
		}; break;
		case LEAPDISCONNECTEDVIEW:
		{
			leapConnectionTypeView = _leapMotionDisconnectedView;
		}; break;
	}
	
	NSSize popupSize = [leapConnectionTypeView frame].size;
	
    //	NSArray *screensAttachedToSystem = [NSScreen screens];
    //	NSRect primaryScreenFrame = [(NSScreen *)[screensAttachedToSystem objectAtIndex:0] frame];
	
    //	NSPoint popupOrigin = NSMakePoint(round( self.glWindow.frame.origin.x + self.glWindow.frame.size.width / 2.0 - popupSize.width / 2.0), round(self.glWindow.frame.origin.y + self.glWindow.frame.size.height / 2.0 - popupSize.height / 2.0));
	NSPoint popupOrigin = NSMakePoint(round( self.glWindow.frame.origin.x + self.glWindow.frame.size.width / 2.0 - popupSize.width / 2.0), self.glWindow.frame.origin.y + 30.0);
	
	currentLeapConnectionPopup = [[TransparentWindow alloc] initWithContentRect:NSMakeRect(popupOrigin.x, popupOrigin.y, popupSize.width, popupSize.height) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	[currentLeapConnectionPopup setContentView:leapConnectionTypeView];
	
	[currentLeapConnectionPopup setAlphaValue:0.0];
	[currentLeapConnectionPopup makeKeyAndOrderFront:self];
	[currentLeapConnectionPopup.animator setAlphaValue:1.0];
    
    [self.glWindow addChildWindow:currentLeapConnectionPopup ordered:NSWindowAbove];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [currentLeapConnectionPopup.animator setAlphaValue:0.0];
    });

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
#pragma mark Side panel visibility

- (IBAction)showOrHideColorKey:(id)sender;
{
    if ([self.applicationControlSplitView isSubviewCollapsed:self.colorCodeView])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSLSMoleculeColorKeyPanelNotification object:[NSNumber numberWithBool:YES]];

        // NSSplitView hides the collapsed subview
        self.colorCodeView.hidden = NO;
        
        NSMutableDictionary *expandMainAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [expandMainAnimationDict setObject:self.colorCodeSplitView forKey:NSViewAnimationTargetKey];
        NSRect newMainFrame = self.colorCodeSplitView.frame;
        newMainFrame.size.width =  self.colorCodeSplitView.frame.size.width;
        [expandMainAnimationDict setObject:[NSValue valueWithRect:newMainFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSMutableDictionary *expandInspectorAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [expandInspectorAnimationDict setObject:self.colorCodeView forKey:NSViewAnimationTargetKey];
        NSRect newInspectorFrame = self.colorCodeView.frame;
        newInspectorFrame.size.width = 170.0;
        newInspectorFrame.origin.x = self.colorCodeSplitView.frame.size.width - 170.0f;
        [expandInspectorAnimationDict setObject:[NSValue valueWithRect:newInspectorFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSViewAnimation *expandAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:expandMainAnimationDict, expandInspectorAnimationDict, nil]];
        [expandAnimation setDuration:0.25f];
        [expandAnimation startAnimation];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            isShowingColorKey = YES;
        });
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSLSMoleculeColorKeyPanelNotification object:[NSNumber numberWithBool:NO]];

        isShowingColorKey = NO;
        
        NSMutableDictionary *collapseMainAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [collapseMainAnimationDict setObject:self.colorCodeSplitView forKey:NSViewAnimationTargetKey];
        NSRect newMainFrame = self.colorCodeSplitView.frame;
        newMainFrame.size.width =  self.colorCodeSplitView.frame.size.width;
        [collapseMainAnimationDict setObject:[NSValue valueWithRect:newMainFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSMutableDictionary *collapseInspectorAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [collapseInspectorAnimationDict setObject:self.colorCodeView forKey:NSViewAnimationTargetKey];
        NSRect newInspectorFrame = self.colorCodeView.frame;
        newInspectorFrame.size.width = 0.0f;
        newInspectorFrame.origin.x = self.colorCodeSplitView.frame.size.width;
        [collapseInspectorAnimationDict setObject:[NSValue valueWithRect:newInspectorFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSViewAnimation *collapseAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:collapseMainAnimationDict, collapseInspectorAnimationDict, nil]];
        [collapseAnimation setDuration:0.25f];
        [collapseAnimation startAnimation];
    }

}

- (IBAction)showOrHideControls:(id)sender;
{
    if ([self.applicationControlSplitView isSubviewCollapsed:self.controlsView])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSLSMoleculeControlPanelNotification object:[NSNumber numberWithBool:YES]];

        // NSSplitView hides the collapsed subview
        self.controlsView.hidden = NO;
        
        NSMutableDictionary *expandMainAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [expandMainAnimationDict setObject:self.applicationControlSplitView forKey:NSViewAnimationTargetKey];
        NSRect newMainFrame = self.applicationControlSplitView.frame;
        newMainFrame.size.width =  self.applicationControlSplitView.frame.size.width;
        [expandMainAnimationDict setObject:[NSValue valueWithRect:newMainFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSMutableDictionary *expandInspectorAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [expandInspectorAnimationDict setObject:self.controlsView forKey:NSViewAnimationTargetKey];
        NSRect newInspectorFrame = self.controlsView.frame;
        newInspectorFrame.size.width = 252.0;
        [expandInspectorAnimationDict setObject:[NSValue valueWithRect:newInspectorFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSViewAnimation *expandAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:expandMainAnimationDict, expandInspectorAnimationDict, nil]];
        [expandAnimation setDuration:0.25f];
        [expandAnimation startAnimation];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            isShowingControlPanel = YES;
        });
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSLSMoleculeControlPanelNotification object:[NSNumber numberWithBool:NO]];

        isShowingControlPanel = NO;
        
        NSMutableDictionary *collapseMainAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [collapseMainAnimationDict setObject:self.applicationControlSplitView forKey:NSViewAnimationTargetKey];
        NSRect newMainFrame = self.applicationControlSplitView.frame;
        newMainFrame.size.width =  self.applicationControlSplitView.frame.size.width;
        [collapseMainAnimationDict setObject:[NSValue valueWithRect:newMainFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSMutableDictionary *collapseInspectorAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [collapseInspectorAnimationDict setObject:self.controlsView forKey:NSViewAnimationTargetKey];
        NSRect newInspectorFrame = self.controlsView.frame;
        newInspectorFrame.size.width = 0.0f;
        [collapseInspectorAnimationDict setObject:[NSValue valueWithRect:newInspectorFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSViewAnimation *collapseAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:collapseMainAnimationDict, collapseInspectorAnimationDict, nil]];
        [collapseAnimation setDuration:0.25f];
        [collapseAnimation startAnimation];
    }
}

#pragma mark -
#pragma mark Sample molecule loading

- (void)openDocument:(id)sender;
{
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    // TODO: find better way to update this with additional filetypes
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"sdf", @"pdb", @"xyz", nil]];

    if ([openPanel runModal] == NSOKButton)
    {
        NSString *selectedFileName = [openPanel filename];

//        NSString *selectedFileName = [NSString stringWithFormat:@"%@", [openPanel URL]];
        [self openFileWithPath:selectedFileName extension:[[selectedFileName pathExtension] lowercaseString]];

        NSURL *fileURL = [openPanel URL];
        if([fileURL respondsToSelector:@selector(startAccessingSecurityScopedResource)])
        {
            [fileURL startAccessingSecurityScopedResource];
        }
        
        NSError *error = nil;
        NSData *bookmark = [[openPanel URL] bookmarkDataWithOptions:NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
        [[NSUserDefaults standardUserDefaults] setObject:bookmark forKey:@"previousMoleculeBookmark"];
        
        if([fileURL respondsToSelector:@selector(stopAccessingSecurityScopedResource)])
        {
            [fileURL stopAccessingSecurityScopedResource];
        }
    }
}

- (void)openFileWithPath:(NSString *)filePath extension:(NSString *)fileExtension;
{
    NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
    [documentController noteNewRecentDocumentURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@", filePath]]];
    
    [[NSUserDefaults standardUserDefaults] setObject:filePath forKey:@"lastLoadedMolecule"];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];

    NSError *error = nil;
    [self readFromData:fileData ofType:fileExtension error:&error];
    
    filenameFromLoad = [filePath lastPathComponent];
    [self.glWindow setTitle:[filePath lastPathComponent]];
}

- (void)openPreloadedFileWithName:(NSString *)preloadedFileName ofType:(NSString *)fileType;
{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"previousMoleculeBookmark"];
    [self openFileWithPath:[[NSBundle mainBundle] pathForResource:preloadedFileName ofType:fileType] extension:fileType];
}

- (IBAction)openDNA:(id)sender;
{
    [self openPreloadedFileWithName:@"DNA" ofType:@"pdb"];
}

- (IBAction)openTRNA:(id)sender;
{
    [self openPreloadedFileWithName:@"TransferRNA" ofType:@"pdb"];
}

- (IBAction)openPump:(id)sender;
{
    [self openPreloadedFileWithName:@"TheoreticalAtomicPump" ofType:@"pdb"];
}

- (IBAction)openCaffeine:(id)sender;
{
    [self openPreloadedFileWithName:@"Caffeine" ofType:@"pdb"];
}

- (IBAction)openHeme:(id)sender;
{
    [self openPreloadedFileWithName:@"Heme" ofType:@"sdf"];
}

- (IBAction)openNanotube:(id)sender;
{
    [self openPreloadedFileWithName:@"Nanotube" ofType:@"pdb"];
}

- (IBAction)openCholesterol:(id)sender;
{
    [self openPreloadedFileWithName:@"Cholesterol" ofType:@"pdb"];
}

- (IBAction)openInsulin:(id)sender;
{
    [self openPreloadedFileWithName:@"Insulin" ofType:@"pdb"];
}

- (IBAction)openTheoreticalBearing:(id)sender;
{
    [self openPreloadedFileWithName:@"TheoreticalBearing" ofType:@"pdb"];
}

- (IBAction)openOther:(id)sender;
{
    [self openDocument:sender];
}

- (IBAction)visitPDB:(id)sender;
{
    NSURL *pdbURL = [NSURL URLWithString:@"http://www.rcsb.org/pdb"];
    if ([[NSWorkspace sharedWorkspace] openURL:pdbURL])
    {
    }
}

- (IBAction)visitPubChem:(id)sender;
{
    NSURL *pubchemURL = [NSURL URLWithString:@"http://pubchem.ncbi.nlm.nih.gov"];
    if ([[NSWorkspace sharedWorkspace] openURL:pubchemURL])
    {
        
    }    
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
	NSRect overlayRect = [self.applicationControlSplitView convertRect:[self.glView frame] fromView:self.glView];
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
    hasConnectedToLeap = YES;
    [self displayLeapConnectionPanel:LEAPCONNECTEDVIEW];

}

- (void)onDisconnect:(NSNotification *)notification;
{
    previousLeapFrame = nil;
    [self displayLeapConnectionPanel:LEAPDISCONNECTEDVIEW];
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
    [controller removeListener:self];
    controller = nil;

    if(isAutorotating)
    {
        CVDisplayLinkStop(displayLink);
        [openGLRenderer waitForLastFrameToFinishRendering];
        
        CVDisplayLinkRelease(displayLink);
    }
    
    molecule.renderingDelegate = nil;
    self.glView.renderingDelegate = nil;
    [self.overlayWindowController close];

    if (currentTutorialInstructionPopup)
    {
        [self.glWindow removeChildWindow:currentTutorialInstructionPopup];
        [currentTutorialInstructionPopup setReleasedWhenClosed:NO];
        [currentTutorialInstructionPopup close];
        currentTutorialInstructionPopup = nil;
    }
    
    if (currentLeapConnectionPopup)
    {
        [self.glWindow removeChildWindow:currentLeapConnectionPopup];
        [currentLeapConnectionPopup setReleasedWhenClosed:NO];
        [currentLeapConnectionPopup close];
        currentLeapConnectionPopup = nil;
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

    return YES;
}

#pragma mark -
#pragma mark NSSplitViewDelegate methods

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    BOOL result = NO;
    if (splitView == self.applicationControlSplitView && subview == self.controlsView)
    {
        result = YES;
    }
    return result;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
    BOOL result = NO;
    if (splitView == self.applicationControlSplitView && subview == self.controlsView)
    {
        result = YES;
    }
    return result;
}

- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize;
{
	float dividerThickness = [splitView dividerThickness];
	NSRect newFrame = [splitView frame];
    
	if (splitView == _applicationControlSplitView)
	{
        if (!isShowingControlPanel)
        {
            NSView *left = [[splitView subviews] objectAtIndex:0];
            NSView *right = [[splitView subviews] objectAtIndex:1];
            NSRect leftFrame = [left frame];
            NSRect rightFrame = [right frame];
            leftFrame.size.height = newFrame.size.height;
            leftFrame.origin = NSMakePoint(0,0);
            rightFrame.size.height = newFrame.size.height;
            rightFrame.origin.x = leftFrame.size.width + dividerThickness;
            rightFrame.size.width = newFrame.size.width - (leftFrame.size.width + dividerThickness);
            [left setFrame:leftFrame];
            [right setFrame:rightFrame];
        }
        else
        {
            // Code drawn from http://www.cocoadev.com/index.pl?SplitViewBasics
            // Have the split view resize the left view, but leave the right one static
            
            NSView *left = [[splitView subviews] objectAtIndex:0];
            NSView *right = [[splitView subviews] objectAtIndex:1];
            NSRect leftFrame = [left frame];
            NSRect rightFrame = [right frame];
            leftFrame.size.height = newFrame.size.height;
            leftFrame.size.width = 252.0;
            //		leftFrame.size.width = newFrame.size.width - rightFrame.size.width - dividerThickness;
            leftFrame.origin = NSMakePoint(0,0);
            rightFrame.size.height = newFrame.size.height;
            rightFrame.origin.x = leftFrame.size.width + dividerThickness;
            rightFrame.size.width = newFrame.size.width - (leftFrame.size.width + dividerThickness);
            [left setFrame:leftFrame];
            [right setFrame:rightFrame];
        }
	}
	else if (splitView == _colorCodeSplitView)
	{
        if (!isShowingColorKey)
        {
            NSView *left = [[splitView subviews] objectAtIndex:0];
            NSView *right = [[splitView subviews] objectAtIndex:1];
            NSRect leftFrame = [left frame];
            NSRect rightFrame = [right frame];
            leftFrame.size.height = newFrame.size.height;
            leftFrame.origin = NSMakePoint(0,0);
            rightFrame.size.height = newFrame.size.height;
            rightFrame.origin.x = leftFrame.size.width + dividerThickness;
            leftFrame.size.width = newFrame.size.width - (rightFrame.size.width + dividerThickness);
            [left setFrame:leftFrame];
            [right setFrame:rightFrame];
        }
        else
        {
            // Have the split view resize the bottom view, but leave the bottom one static
            
            NSView *left = [[splitView subviews] objectAtIndex:0];
            NSView *right = [[splitView subviews] objectAtIndex:1];
            NSRect leftFrame = [left frame];
            NSRect rightFrame = [right frame];
            leftFrame.size.height = newFrame.size.height;
            rightFrame.size.width = 170.0;            
            leftFrame.size.width = newFrame.size.width - rightFrame.size.width - dividerThickness;
            rightFrame.origin.x = leftFrame.size.width + dividerThickness;
            rightFrame.size.height = newFrame.size.height;
            leftFrame.origin = NSMakePoint(0,0);
            [left setFrame:leftFrame];
            [right setFrame:rightFrame];
        }
	}
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
