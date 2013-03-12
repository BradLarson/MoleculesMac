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

@end
