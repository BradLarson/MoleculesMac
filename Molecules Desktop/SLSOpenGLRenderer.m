#import "SLSOpenGLRenderer.h"
#import "GLProgram.h"

NSString *const kSLSMoleculeShadowCalculationStartedNotification = @"MoleculeShadowCalculationStarted";
NSString *const kSLSMoleculeShadowCalculationUpdateNotification = @"MoleculeShadowCalculationUpdate";
NSString *const kSLSMoleculeShadowCalculationEndedNotification = @"MoleculeShadowCalculationEnded";

@implementation SLSOpenGLRenderer

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(NSOpenGLContext *)newContext;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    self.openGLContext = newContext;
    backingWidth = 576;
    backingHeight = 1024;
    
    isSceneReady = NO;
    
    // Set up the initial model view matrix for the rendering
    isFirstDrawingOfMolecule = YES;
    isFrameRenderingFinished = YES;
    totalNumberOfVertices = 0;
	totalNumberOfTriangles = 0;
    currentModelScaleFactor = 1.0;

    GLfloat currentModelViewMatrix[16]  = {0.402560,0.094840,0.910469,0.000000, 0.913984,-0.096835,-0.394028,0.000000, 0.050796,0.990772,-0.125664,0.000000, 0.000000,0.000000,0.000000,1.000000};
    
    //		GLfloat currentModelViewMatrix[16]  = {1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0};
    
    [self convertMatrix:currentModelViewMatrix to3DTransform:&currentCalculatedMatrix];

    openGLESContextQueue = dispatch_queue_create("com.sunsetlakesoftware.openGLESContextQueue", NULL);;
    frameRenderingSemaphore = dispatch_semaphore_create(1);

//    [self clearScreen];		

    //  0.312757, 0.248372, 0.916785
    // 0.0, -0.7071, 0.7071
    
	[[self openGLContext] makeCurrentContext];
    GLint maxTextureSize;
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
//    NSLog(@"Max texture size: %d", maxTextureSize);
    
    // Use higher-resolution textures on the A5 and higher GPUs, because they can support it
    ambientOcclusionTextureWidth = 1024;
    ambientOcclusionLookupTextureWidth = 128;
    sphereDepthTextureWidth = 1024;
    
    currentViewportSize = CGSizeZero;
    
    lightDirection[0] = 0.312757;
	lightDirection[1] = 0.248372;
	lightDirection[2] = 0.916785;
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glBindRenderbuffer(GL_RENDERBUFFER, 0);
    
	glDisable(GL_ALPHA_TEST);
	glDisable(GL_DEPTH_TEST);
	glDisable(GL_SCISSOR_TEST);
	glEnable(GL_BLEND);
    //	glEnable(GL_REPLACE);
	glDisable(GL_DITHER);
	glDisable(GL_CULL_FACE);
//	glEnable(GL_TEXTURE_RECTANGLE_EXT);
    
	glDisable(GL_LIGHTING);
	
	glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
	
	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	
    [self initializeDepthShaders];
    [self initializeAmbientOcclusionShaders];
    [self initializeRaytracingShaders];
    
    return self;
}

- (void)dealloc 
{
    //	// Read the current modelview matrix from OpenGL and save it in the user's preferences for recovery on next startup
    //	// TODO: save index, vertex, and normal buffers for quick reload later
    //	float currentModelViewMatrix[16];
    //	glMatrixMode(GL_MODELVIEW);
    //	glGetFloatv(GL_MODELVIEW_MATRIX, currentModelViewMatrix);	
    //	NSData *matrixData = [NSData dataWithBytes:currentModelViewMatrix length:(16 * sizeof(float))];	
    //	[[NSUserDefaults standardUserDefaults] setObject:matrixData forKey:@"matrixData"];	
    //	
//	if ([EAGLContext currentContext] == context) 
//	{
//		[EAGLContext setCurrentContext:nil];
//	}
	
    [self freeVertexBuffers];
    
    dispatch_sync(openGLESContextQueue, ^{
        [[self openGLContext] makeCurrentContext];

        if (ambientOcclusionFramebuffer)
        {
            glDeleteFramebuffers(1, &ambientOcclusionFramebuffer);
            ambientOcclusionFramebuffer = 0;
        }
        
        if (ambientOcclusionTexture)
        {
            glDeleteTextures(1, &ambientOcclusionTexture);
            ambientOcclusionTexture = 0;
        }
        
        if (sphereAOLookupFramebuffer)
        {
            glDeleteFramebuffers(1, &sphereAOLookupFramebuffer);
            sphereAOLookupFramebuffer = 0;
        }
        
        if (sphereAOLookupTexture)
        {
            glDeleteTextures(1, &sphereAOLookupTexture);
            sphereAOLookupTexture = 0;
        }
    });
//    dispatch_release(openGLESContextQueue);
//    dispatch_release(frameRenderingSemaphore);
}

#pragma mark -
#pragma mark OpenGL matrix helper methods

- (void)convertMatrix:(GLfloat *)matrix to3DTransform:(CATransform3D *)transform3D;
{
	transform3D->m11 = (CGFloat)matrix[0];
	transform3D->m12 = (CGFloat)matrix[1];
	transform3D->m13 = (CGFloat)matrix[2];
	transform3D->m14 = (CGFloat)matrix[3];
	transform3D->m21 = (CGFloat)matrix[4];
	transform3D->m22 = (CGFloat)matrix[5];
	transform3D->m23 = (CGFloat)matrix[6];
	transform3D->m24 = (CGFloat)matrix[7];
	transform3D->m31 = (CGFloat)matrix[8];
	transform3D->m32 = (CGFloat)matrix[9];
	transform3D->m33 = (CGFloat)matrix[10];
	transform3D->m34 = (CGFloat)matrix[11];
	transform3D->m41 = (CGFloat)matrix[12];
	transform3D->m42 = (CGFloat)matrix[13];
	transform3D->m43 = (CGFloat)matrix[14];
	transform3D->m44 = (CGFloat)matrix[15];
}

- (void)convert3DTransform:(CATransform3D *)transform3D toMatrix:(GLfloat *)matrix;
{
	//	struct CATransform3D
	//	{
	//		CGFloat m11, m12, m13, m14;
	//		CGFloat m21, m22, m23, m24;
	//		CGFloat m31, m32, m33, m34;
	//		CGFloat m41, m42, m43, m44;
	//	};
	
	matrix[0] = (GLfloat)transform3D->m11;
	matrix[1] = (GLfloat)transform3D->m12;
	matrix[2] = (GLfloat)transform3D->m13;
	matrix[3] = (GLfloat)transform3D->m14;
	matrix[4] = (GLfloat)transform3D->m21;
	matrix[5] = (GLfloat)transform3D->m22;
	matrix[6] = (GLfloat)transform3D->m23;
	matrix[7] = (GLfloat)transform3D->m24;
	matrix[8] = (GLfloat)transform3D->m31;
	matrix[9] = (GLfloat)transform3D->m32;
	matrix[10] = (GLfloat)transform3D->m33;
	matrix[11] = (GLfloat)transform3D->m34;
	matrix[12] = (GLfloat)transform3D->m41;
	matrix[13] = (GLfloat)transform3D->m42;
	matrix[14] = (GLfloat)transform3D->m43;
	matrix[15] = (GLfloat)transform3D->m44;
}

- (void)convert3DTransform:(CATransform3D *)transform3D to3x3Matrix:(GLfloat *)matrix;
{
	matrix[0] = (GLfloat)transform3D->m11;
	matrix[1] = (GLfloat)transform3D->m12;
	matrix[2] = (GLfloat)transform3D->m13;
	matrix[3] = (GLfloat)transform3D->m21;
	matrix[4] = (GLfloat)transform3D->m22;
	matrix[5] = (GLfloat)transform3D->m23;
	matrix[6] = (GLfloat)transform3D->m31;
	matrix[7] = (GLfloat)transform3D->m32;
	matrix[8] = (GLfloat)transform3D->m33;
}

- (void)print3DTransform:(CATransform3D *)transform3D;
{
	NSLog(@"___________________________");
	NSLog(@"|%f,%f,%f,%f|", transform3D->m11, transform3D->m12, transform3D->m13, transform3D->m14);
	NSLog(@"|%f,%f,%f,%f|", transform3D->m21, transform3D->m22, transform3D->m23, transform3D->m24);
	NSLog(@"|%f,%f,%f,%f|", transform3D->m31, transform3D->m32, transform3D->m33, transform3D->m34);
	NSLog(@"|%f,%f,%f,%f|", transform3D->m41, transform3D->m42, transform3D->m43, transform3D->m44);
	NSLog(@"___________________________");			
}

- (void)printMatrix:(GLfloat *)matrix;
{
	NSLog(@"___________________________");
	NSLog(@"|%f,%f,%f,%f|", matrix[0], matrix[1], matrix[2], matrix[3]);
	NSLog(@"|%f,%f,%f,%f|", matrix[4], matrix[5], matrix[6], matrix[7]);
	NSLog(@"|%f,%f,%f,%f|", matrix[8], matrix[9], matrix[10], matrix[11]);
	NSLog(@"|%f,%f,%f,%f|", matrix[12], matrix[13], matrix[14], matrix[15]);
	NSLog(@"___________________________");			
}

- (void)apply3DTransform:(CATransform3D *)transform3D toPoint:(GLfloat *)sourcePoint result:(GLfloat *)resultingPoint;
{
//        | A B C D |
//    M = | E F G H |
//        | I J K L |
//        | M N O P |
    
//    A.x1+B.y1+C.z1+D
//    E.x1+F.y1+G.z1+H
//    I.x1+J.y1+K.z1+L
//    M.x1+N.y1+O.z1+P

    resultingPoint[0] = sourcePoint[0] * transform3D->m11 + sourcePoint[1] * transform3D->m12 + sourcePoint[2] * transform3D->m13 + transform3D->m14;
    resultingPoint[1] = sourcePoint[0] * transform3D->m21 + sourcePoint[1] * transform3D->m22 + sourcePoint[2] * transform3D->m23 + transform3D->m24;
    resultingPoint[2] = sourcePoint[0] * transform3D->m31 + sourcePoint[1] * transform3D->m32 + sourcePoint[2] * transform3D->m33 + transform3D->m34;
}

#pragma mark -
#pragma mark Model manipulation

- (void)rotateModelFromScreenDisplacementInX:(float)xRotation inY:(float)yRotation;
{
	// Perform incremental rotation based on current angles in X and Y
	GLfloat totalRotation = sqrt(xRotation*xRotation + yRotation*yRotation);
	
	CATransform3D temporaryMatrix = CATransform3DRotate(currentCalculatedMatrix, totalRotation * M_PI / 180.0,
														((-xRotation/totalRotation) * currentCalculatedMatrix.m12 + (-yRotation/totalRotation) * currentCalculatedMatrix.m11),
														((-xRotation/totalRotation) * currentCalculatedMatrix.m22 + (-yRotation/totalRotation) * currentCalculatedMatrix.m21),
														((-xRotation/totalRotation) * currentCalculatedMatrix.m32 + (-yRotation/totalRotation) * currentCalculatedMatrix.m31));
    
	if ((temporaryMatrix.m11 >= -100.0) && (temporaryMatrix.m11 <= 100.0))
    {
        //        currentCalculatedMatrix = CATransform3DMakeRotation(M_PI, 0.0, 0.0, 1.0);
        
		currentCalculatedMatrix = temporaryMatrix;
    }    
}

- (void)scaleModelByFactor:(float)scaleFactor;
{
    // Scale the view to fit current multitouch scaling
	CATransform3D temporaryMatrix = CATransform3DScale(currentCalculatedMatrix, scaleFactor, scaleFactor, scaleFactor);
	
	if ((temporaryMatrix.m11 >= -100.0) && (temporaryMatrix.m11 <= 100.0))
    {
		currentCalculatedMatrix = temporaryMatrix;
        currentModelScaleFactor = currentModelScaleFactor * scaleFactor;
    }
}

- (void)translateModelByScreenDisplacementInX:(float)xTranslation inY:(float)yTranslation;
{
    // Translate the model by the accumulated amount
	float currentScaleFactor = sqrt(pow(currentCalculatedMatrix.m11, 2.0f) + pow(currentCalculatedMatrix.m12, 2.0f) + pow(currentCalculatedMatrix.m13, 2.0f));

    
    // TODO: Account for Retina Mac display
    xTranslation = xTranslation * 1.0 / (currentScaleFactor * currentScaleFactor * backingWidth * 0.5);
	yTranslation = yTranslation * 1.0 / (currentScaleFactor * currentScaleFactor * backingWidth * 0.5);

//	xTranslation = xTranslation * [[UIScreen mainScreen] scale] / (currentScaleFactor * currentScaleFactor * backingWidth * 0.5);
//	yTranslation = yTranslation * [[UIScreen mainScreen] scale] / (currentScaleFactor * currentScaleFactor * backingWidth * 0.5);
    
	// Use the (0,4,8) components to figure the eye's X axis in the model coordinate system, translate along that
	// Use the (1,5,9) components to figure the eye's Y axis in the model coordinate system, translate along that
	
    accumulatedModelTranslation[0] += xTranslation * currentCalculatedMatrix.m11 + yTranslation * currentCalculatedMatrix.m12;
    accumulatedModelTranslation[1] += xTranslation * currentCalculatedMatrix.m21 + yTranslation * currentCalculatedMatrix.m22;
    accumulatedModelTranslation[2] += xTranslation * currentCalculatedMatrix.m31 + yTranslation * currentCalculatedMatrix.m32;
}

- (void)resetModelViewMatrix;
{
 	GLfloat currentModelViewMatrix[16]  = {0.402560,0.094840,0.910469,0.000000, 0.913984,-0.096835,-0.394028,0.000000, 0.050796,0.990772,-0.125664,0.000000, 0.000000,0.000000,0.000000,1.000000};
	[self convertMatrix:currentModelViewMatrix to3DTransform:&currentCalculatedMatrix];   
    currentModelScaleFactor = 1.0;
    
    isFirstDrawingOfMolecule = YES;
    
    
    accumulatedModelTranslation[0] = 0.0;
    accumulatedModelTranslation[1] = 0.0;
    accumulatedModelTranslation[2] = 0.0;
}

#pragma mark -
#pragma mark OpenGL drawing support

- (void)loadOrthoMatrix:(GLfloat *)matrix left:(GLfloat)left right:(GLfloat)right bottom:(GLfloat)bottom top:(GLfloat)top near:(GLfloat)near far:(GLfloat)far;
{
    GLfloat r_l = right - left;
    GLfloat t_b = top - bottom;
    GLfloat f_n = far - near;
    
    matrix[0] = 2.0f / r_l;
    matrix[1] = 0.0f;
    matrix[2] = 0.0f;
    
    matrix[3] = 0.0f;
    matrix[4] = 2.0f / t_b;
    matrix[5] = 0.0f;
    
    matrix[6] = 0.0f;
    matrix[7] = 0.0f;
    matrix[8] = 2.0f / f_n;
    
    [sphereDepthProgram use];
    glUniformMatrix3fv(sphereDepthOrthographicMatrix, 1, 0, orthographicMatrix);
    
    [sphereDepthWriteProgram use];
    glUniformMatrix3fv(sphereDepthWriteOrthographicMatrix, 1, 0, orthographicMatrix);
    
    [cylinderDepthProgram use];
    glUniformMatrix3fv(cylinderDepthOrthographicMatrix, 1, 0, orthographicMatrix);
    
    [sphereRaytracingProgram use];
    glUniformMatrix3fv(sphereRaytracingOrthographicMatrix, 1, 0, orthographicMatrix);
    
    [cylinderRaytracingProgram use];
    glUniformMatrix3fv(cylinderRaytracingOrthographicMatrix, 1, 0, orthographicMatrix);
    
    [sphereAmbientOcclusionProgram use];
    glUniformMatrix3fv(sphereAmbientOcclusionOrthographicMatrix, 1, 0, orthographicMatrix);
    
    [cylinderAmbientOcclusionProgram use];
    glUniformMatrix3fv(cylinderAmbientOcclusionOrthographicMatrix, 1, 0, orthographicMatrix);
    
}

- (BOOL)createFramebuffersForView:(NSView *)glView;
{
    dispatch_async(openGLESContextQueue, ^{
        [[self openGLContext] makeCurrentContext];
        
        // Need this to make the layer dimensions an even multiple of 32 for performance reasons
        // Also, the 4.2 Simulator will not display the frame otherwise
        /*	CGRect layerBounds = glLayer.bounds;
         CGFloat newWidth = (CGFloat)((int)layerBounds.size.width / 32) * 32.0f;
         CGFloat newHeight = (CGFloat)((int)layerBounds.size.height / 32) * 32.0f;
         
         NSLog(@"Bounds before: %@", NSStringFromCGRect(glLayer.bounds));
         
         glLayer.bounds = CGRectMake(layerBounds.origin.x, layerBounds.origin.y, newWidth, newHeight);
         
         NSLog(@"Bounds after: %@", NSStringFromCGRect(glLayer.bounds));
         */
        glEnable(GL_TEXTURE_2D);
        
        NSRect backingBounds = [glView convertRectToBacking:[glView bounds]];
        
        backingWidth = backingBounds.size.width;
        backingHeight = backingBounds.size.height;
        
//        [self createFramebuffer:&viewFramebuffer size:CGSizeZero renderBuffer:&viewRenderbuffer depthBuffer:&viewDepthBuffer texture:NULL layer:glLayer];
//        [self createFramebuffer:&depthPassFramebuffer size:CGSizeMake(backingWidth, backingHeight) renderBuffer:NULL depthBuffer:&depthPassDepthBuffer texture:&depthPassTexture];
        [self createFramebuffer:&depthPassFramebuffer size:CGSizeMake(ambientOcclusionTextureWidth, ambientOcclusionTextureWidth) renderBuffer:NULL depthBuffer:&depthPassDepthBuffer texture:&depthPassTexture];
        
        if (!ambientOcclusionFramebuffer)
        {
            [self createFramebuffer:&ambientOcclusionFramebuffer size:CGSizeMake(ambientOcclusionTextureWidth, ambientOcclusionTextureWidth) renderBuffer:NULL depthBuffer:NULL texture:&ambientOcclusionTexture];
        }
        
        if (!sphereAOLookupFramebuffer)
        {
            [self createFramebuffer:&sphereAOLookupFramebuffer size:CGSizeMake(ambientOcclusionLookupTextureWidth, ambientOcclusionLookupTextureWidth) renderBuffer:NULL depthBuffer:NULL texture:&sphereAOLookupTexture];
        }
        
        [self switchToDisplayFramebuffer];
        glViewport(0, 0, backingWidth, backingHeight);
        
        currentViewportSize = CGSizeMake(backingWidth, backingHeight);
        
        //    [self loadOrthoMatrix:orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) top:(1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) near:-3.0 far:3.0];
        //    [self loadOrthoMatrix:orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) top:(1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) near:-2.0 far:2.0];
        //    [self loadOrthoMatrix:orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) top:(1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) near:-0.5 far:0.5];
        [self loadOrthoMatrix:orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) top:(1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) near:-4.0 far:4.0];
        
        // 0 - Depth pass texture
        // 1 - Ambient occlusion texture
        // 2 - AO lookup texture
        // 3 - Sphere depth precalculation texture
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, depthPassTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, ambientOcclusionTexture);
        
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, sphereAOLookupTexture);
        
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, sphereDepthMappingTexture);
    });
    
    return YES;
}

- (void)resizeFramebuffersToMatchView:(NSView *)glView;
{
    dispatch_async(openGLESContextQueue, ^{
        [[self openGLContext] makeCurrentContext];
        glEnable(GL_TEXTURE_2D);
        
        NSRect backingBounds = [glView convertRectToBacking:[glView bounds]];
        
        backingWidth = backingBounds.size.width;
        backingHeight = backingBounds.size.height;
        
        [self switchToDisplayFramebuffer];
        glViewport(0, 0, backingWidth, backingHeight);
        currentViewportSize = CGSizeMake(backingWidth, backingHeight);
        [self loadOrthoMatrix:orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) top:(1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) near:-4.0 far:4.0];

        glClearColor(0.0f, 0.0f, 0.0f, 1.0f); // Black Background
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        [[self openGLContext] flushBuffer];
    });
    
//    dispatch_async(openGLESContextQueue, ^{
//        [[self openGLContext] makeCurrentContext];
//
//        if (viewFramebuffer)
//        {
//            glDeleteFramebuffers(1, &viewFramebuffer);
//            viewFramebuffer = 0;
//        }
//        
//        if (viewRenderbuffer)
//        {
//            glDeleteRenderbuffers(1, &viewRenderbuffer);
//            viewRenderbuffer = 0;
//        }
//        
//        if (viewDepthBuffer)
//        {
//            glDeleteRenderbuffers(1, &viewDepthBuffer);
//            viewDepthBuffer = 0;
//        }
//        
//        if (depthPassFramebuffer)
//        {
//            glDeleteFramebuffers(1, &depthPassFramebuffer);
//            depthPassFramebuffer = 0;
//        }
//        
//        if (depthPassDepthBuffer)
//        {
//            glDeleteRenderbuffers(1, &depthPassDepthBuffer);
//            depthPassDepthBuffer = 0;
//        }
//        
//        if (depthPassTexture)
//        {
//            glDeleteTextures(1, &depthPassTexture);
//            depthPassTexture = 0;
//        }
//
//        backingWidth = glView.frame.size.width;
//        backingHeight = glView.frame.size.height;
//
//        [self createFramebuffer:&depthPassFramebuffer size:CGSizeMake(backingWidth, backingHeight) renderBuffer:NULL depthBuffer:&depthPassDepthBuffer texture:&depthPassTexture];
//
//        glActiveTexture(GL_TEXTURE0);
//        glBindTexture(GL_TEXTURE_2D, depthPassTexture);
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
//
//        [self switchToDisplayFramebuffer];
//        glViewport(0, 0, backingWidth, backingHeight);
//        
//        currentViewportSize = CGSizeMake(backingWidth, backingHeight);
//        
//        //    [self loadOrthoMatrix:orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) top:(1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) near:-3.0 far:3.0];
//        //    [self loadOrthoMatrix:orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) top:(1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) near:-2.0 far:2.0];
//        //    [self loadOrthoMatrix:orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) top:(1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) near:-0.5 far:0.5];
//        [self loadOrthoMatrix:orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) top:(1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) near:-1.0 far:1.0];
//
//    });

}

- (BOOL)createFramebuffer:(GLuint *)framebufferPointer size:(CGSize)bufferSize renderBuffer:(GLuint *)renderbufferPointer depthBuffer:(GLuint *)depthbufferPointer texture:(GLuint *)backingTexturePointer;
{
    glGenFramebuffers(1, framebufferPointer);
    glBindFramebuffer(GL_FRAMEBUFFER, *framebufferPointer);
	
    if (renderbufferPointer != NULL)
    {
        glGenRenderbuffers(1, renderbufferPointer);
        glBindRenderbuffer(GL_RENDERBUFFER, *renderbufferPointer);
        
        if (backingTexturePointer == NULL)
        {
//            [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
//            glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
//            glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
//            bufferSize = CGSizeMake(backingWidth, backingHeight);
        }
        else
        {
            glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, bufferSize.width, bufferSize.height);
        }
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, *renderbufferPointer);
    }
    
    if (depthbufferPointer != NULL)
    {
        glGenRenderbuffers(1, depthbufferPointer);
        glBindRenderbuffer(GL_RENDERBUFFER, *depthbufferPointer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, bufferSize.width, bufferSize.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, *depthbufferPointer);
    }
	
    if (backingTexturePointer != NULL)
    {
        if ( (ambientOcclusionTexture == 0) || (*backingTexturePointer != ambientOcclusionTexture))
        {
            if (*backingTexturePointer != 0)
            {
                glDeleteTextures(1, backingTexturePointer);
            }
            
            glGenTextures(1, backingTexturePointer);
            
            glBindTexture(GL_TEXTURE_2D, *backingTexturePointer);
            if (*backingTexturePointer == ambientOcclusionTexture)
            {
                //                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
                //                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);
                //                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
                
                
                
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferSize.width, bufferSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
                //                glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, bufferSize.width, bufferSize.height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0);
            }
            else if (*backingTexturePointer == sphereAOLookupTexture)
            {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
                //                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
                //                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);
                
                
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferSize.width, bufferSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
            }
            else
            {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
                //                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
                //                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);
                
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferSize.width, bufferSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
            }
        }
        else
        {
            glBindTexture(GL_TEXTURE_2D, *backingTexturePointer);
        }
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *backingTexturePointer, 0);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) 
	{
		NSLog(@"Incomplete FBO: %d", status);
    }
    
    return YES;
}

- (void)initializeDepthShaders;
{
    if (sphereDepthProgram != nil)
    {
        return;
    }
    
	[[self openGLContext] makeCurrentContext];
    
    sphereDepthProgram = [[GLProgram alloc] initWithVertexShaderFilename:@"SphereDepth" fragmentShaderFilename:@"SphereDepth"];
	[sphereDepthProgram addAttribute:@"position"];
	[sphereDepthProgram addAttribute:@"inputImpostorSpaceCoordinate"];
	if (![sphereDepthProgram link])
	{
		NSLog(@"Raytracing shader link failed");
		NSString *progLog = [sphereDepthProgram programLog];
		NSLog(@"Program Log: %@", progLog);
		NSString *fragLog = [sphereDepthProgram fragmentShaderLog];
		NSLog(@"Frag Log: %@", fragLog);
		NSString *vertLog = [sphereDepthProgram vertexShaderLog];
		NSLog(@"Vert Log: %@", vertLog);
		sphereDepthProgram = nil;
	}
    
    sphereDepthPositionAttribute = [sphereDepthProgram attributeIndex:@"position"];
    sphereDepthImpostorSpaceAttribute = [sphereDepthProgram attributeIndex:@"inputImpostorSpaceCoordinate"];
	sphereDepthModelViewMatrix = [sphereDepthProgram uniformIndex:@"modelViewProjMatrix"];
    sphereDepthRadius = [sphereDepthProgram uniformIndex:@"sphereRadius"];
    sphereDepthOrthographicMatrix = [sphereDepthProgram uniformIndex:@"orthographicMatrix"];
    sphereDepthPrecalculatedDepthTexture = [sphereDepthProgram uniformIndex:@"precalculatedSphereDepthTexture"];
    sphereDepthTranslation = [sphereDepthProgram uniformIndex:@"translation"];
    sphereDepthMapTexture = [sphereDepthProgram uniformIndex:@"sphereDepthMap"];
    
    [sphereDepthProgram use];
    glEnableVertexAttribArray(sphereDepthPositionAttribute);
    glEnableVertexAttribArray(sphereDepthImpostorSpaceAttribute);
    
    cylinderDepthProgram = [[GLProgram alloc] initWithVertexShaderFilename:@"CylinderDepth" fragmentShaderFilename:@"CylinderDepth"];
	[cylinderDepthProgram addAttribute:@"position"];
	[cylinderDepthProgram addAttribute:@"direction"];
	[cylinderDepthProgram addAttribute:@"inputImpostorSpaceCoordinate"];
    
	if (![cylinderDepthProgram link])
	{
		NSLog(@"Raytracing shader link failed");
		NSString *progLog = [cylinderDepthProgram programLog];
		NSLog(@"Program Log: %@", progLog);
		NSString *fragLog = [cylinderDepthProgram fragmentShaderLog];
		NSLog(@"Frag Log: %@", fragLog);
		NSString *vertLog = [cylinderDepthProgram vertexShaderLog];
		NSLog(@"Vert Log: %@", vertLog);
		cylinderDepthProgram = nil;
	}
    
    cylinderDepthPositionAttribute = [cylinderDepthProgram attributeIndex:@"position"];
    cylinderDepthDirectionAttribute = [cylinderDepthProgram attributeIndex:@"direction"];
    cylinderDepthImpostorSpaceAttribute = [cylinderDepthProgram attributeIndex:@"inputImpostorSpaceCoordinate"];
	cylinderDepthModelViewMatrix = [cylinderDepthProgram uniformIndex:@"modelViewProjMatrix"];
    cylinderDepthRadius = [cylinderDepthProgram uniformIndex:@"cylinderRadius"];
    cylinderDepthOrthographicMatrix = [cylinderDepthProgram uniformIndex:@"orthographicMatrix"];
    cylinderDepthTranslation = [cylinderDepthProgram uniformIndex:@"translation"];
    
    [cylinderDepthProgram use];
    glEnableVertexAttribArray(cylinderDepthPositionAttribute);
    glEnableVertexAttribArray(cylinderDepthDirectionAttribute);
    glEnableVertexAttribArray(cylinderDepthImpostorSpaceAttribute);
    
    sphereDepthWriteProgram = [[GLProgram alloc] initWithVertexShaderFilename:@"SphereDepthWrite" fragmentShaderFilename:@"SphereDepthWrite"];
	[sphereDepthWriteProgram addAttribute:@"position"];
	[sphereDepthWriteProgram addAttribute:@"inputImpostorSpaceCoordinate"];
	if (![sphereDepthWriteProgram link])
	{
		NSLog(@"Raytracing shader link failed");
		NSString *progLog = [sphereDepthWriteProgram programLog];
		NSLog(@"Program Log: %@", progLog);
		NSString *fragLog = [sphereDepthWriteProgram fragmentShaderLog];
		NSLog(@"Frag Log: %@", fragLog);
		NSString *vertLog = [sphereDepthWriteProgram vertexShaderLog];
		NSLog(@"Vert Log: %@", vertLog);
		sphereDepthWriteProgram = nil;
	}
    
    sphereDepthWritePositionAttribute = [sphereDepthWriteProgram attributeIndex:@"position"];
    sphereDepthWriteImpostorSpaceAttribute = [sphereDepthWriteProgram attributeIndex:@"inputImpostorSpaceCoordinate"];
	sphereDepthWriteModelViewMatrix = [sphereDepthWriteProgram uniformIndex:@"modelViewProjMatrix"];
    sphereDepthWriteRadius = [sphereDepthWriteProgram uniformIndex:@"sphereRadius"];
    sphereDepthWriteOrthographicMatrix = [sphereDepthWriteProgram uniformIndex:@"orthographicMatrix"];
    sphereDepthWriteTranslation = [sphereDepthWriteProgram uniformIndex:@"translation"];
    
    [sphereDepthWriteProgram use];
    glEnableVertexAttribArray(sphereDepthWritePositionAttribute);
    glEnableVertexAttribArray(sphereDepthWriteImpostorSpaceAttribute);
}

- (void)initializeAmbientOcclusionShaders;
{
    if (sphereAmbientOcclusionProgram != nil)
    {
        return;
    }
    
	[[self openGLContext] makeCurrentContext];
    
    sphereAmbientOcclusionProgram = [[GLProgram alloc] initWithVertexShaderFilename:@"SphereAmbientOcclusion" fragmentShaderFilename:@"SphereAmbientOcclusion"];
	[sphereAmbientOcclusionProgram addAttribute:@"position"];
	[sphereAmbientOcclusionProgram addAttribute:@"inputImpostorSpaceCoordinate"];
    [sphereAmbientOcclusionProgram addAttribute:@"ambientOcclusionTextureOffset"];
	if (![sphereAmbientOcclusionProgram link])
	{
		NSLog(@"Raytracing shader link failed");
		NSString *progLog = [sphereAmbientOcclusionProgram programLog];
		NSLog(@"Program Log: %@", progLog);
		NSString *fragLog = [sphereAmbientOcclusionProgram fragmentShaderLog];
		NSLog(@"Frag Log: %@", fragLog);
		NSString *vertLog = [sphereAmbientOcclusionProgram vertexShaderLog];
		NSLog(@"Vert Log: %@", vertLog);
		sphereAmbientOcclusionProgram = nil;
	}
    
    sphereAmbientOcclusionPositionAttribute = [sphereAmbientOcclusionProgram attributeIndex:@"position"];
    sphereAmbientOcclusionImpostorSpaceAttribute = [sphereAmbientOcclusionProgram attributeIndex:@"inputImpostorSpaceCoordinate"];
    sphereAmbientOcclusionAOOffsetAttribute = [sphereAmbientOcclusionProgram attributeIndex:@"ambientOcclusionTextureOffset"];
	sphereAmbientOcclusionModelViewMatrix = [sphereAmbientOcclusionProgram uniformIndex:@"modelViewProjMatrix"];
    sphereAmbientOcclusionRadius = [sphereAmbientOcclusionProgram uniformIndex:@"sphereRadius"];
    sphereAmbientOcclusionDepthTexture = [sphereAmbientOcclusionProgram uniformIndex:@"depthTexture"];
    sphereAmbientOcclusionOrthographicMatrix = [sphereAmbientOcclusionProgram uniformIndex:@"orthographicMatrix"];
    sphereAmbientOcclusionPrecalculatedDepthTexture = [sphereAmbientOcclusionProgram uniformIndex:@"precalculatedSphereDepthTexture"];
    sphereAmbientOcclusionInverseModelViewMatrix = [sphereAmbientOcclusionProgram uniformIndex:@"inverseModelViewProjMatrix"];
    sphereAmbientOcclusionTexturePatchWidth = [sphereAmbientOcclusionProgram uniformIndex:@"ambientOcclusionTexturePatchWidth"];
    sphereAmbientOcclusionIntensityFactor = [sphereAmbientOcclusionProgram uniformIndex:@"intensityFactor"];
    
    [sphereAmbientOcclusionProgram use];
    glEnableVertexAttribArray(sphereAmbientOcclusionPositionAttribute);
    glEnableVertexAttribArray(sphereAmbientOcclusionImpostorSpaceAttribute);
    glEnableVertexAttribArray(sphereAmbientOcclusionAOOffsetAttribute);
    
    cylinderAmbientOcclusionProgram = [[GLProgram alloc] initWithVertexShaderFilename:@"CylinderAmbientOcclusion" fragmentShaderFilename:@"CylinderAmbientOcclusion"];
	[cylinderAmbientOcclusionProgram addAttribute:@"position"];
	[cylinderAmbientOcclusionProgram addAttribute:@"direction"];
	[cylinderAmbientOcclusionProgram addAttribute:@"inputImpostorSpaceCoordinate"];
    [cylinderAmbientOcclusionProgram addAttribute:@"ambientOcclusionTextureOffset"];
	if (![cylinderAmbientOcclusionProgram link])
	{
		NSLog(@"Raytracing shader link failed");
		NSString *progLog = [cylinderAmbientOcclusionProgram programLog];
		NSLog(@"Program Log: %@", progLog);
		NSString *fragLog = [cylinderAmbientOcclusionProgram fragmentShaderLog];
		NSLog(@"Frag Log: %@", fragLog);
		NSString *vertLog = [cylinderAmbientOcclusionProgram vertexShaderLog];
		NSLog(@"Vert Log: %@", vertLog);
		cylinderAmbientOcclusionProgram = nil;
	}
    
    cylinderAmbientOcclusionPositionAttribute = [cylinderAmbientOcclusionProgram attributeIndex:@"position"];
    cylinderAmbientOcclusionDirectionAttribute = [cylinderAmbientOcclusionProgram attributeIndex:@"direction"];
    cylinderAmbientOcclusionImpostorSpaceAttribute = [cylinderAmbientOcclusionProgram attributeIndex:@"inputImpostorSpaceCoordinate"];
    cylinderAmbientOcclusionAOOffsetAttribute = [cylinderAmbientOcclusionProgram attributeIndex:@"ambientOcclusionTextureOffset"];
	cylinderAmbientOcclusionModelViewMatrix = [cylinderAmbientOcclusionProgram uniformIndex:@"modelViewProjMatrix"];
    cylinderAmbientOcclusionRadius = [cylinderAmbientOcclusionProgram uniformIndex:@"cylinderRadius"];
    cylinderAmbientOcclusionDepthTexture = [cylinderAmbientOcclusionProgram uniformIndex:@"depthTexture"];
    cylinderAmbientOcclusionOrthographicMatrix = [cylinderAmbientOcclusionProgram uniformIndex:@"orthographicMatrix"];
    cylinderAmbientOcclusionInverseModelViewMatrix = [cylinderAmbientOcclusionProgram uniformIndex:@"inverseModelViewProjMatrix"];
    cylinderAmbientOcclusionTexturePatchWidth = [cylinderAmbientOcclusionProgram uniformIndex:@"ambientOcclusionTexturePatchWidth"];
    cylinderAmbientOcclusionIntensityFactor = [cylinderAmbientOcclusionProgram uniformIndex:@"intensityFactor"];
    
    [cylinderAmbientOcclusionProgram use];
    glEnableVertexAttribArray(cylinderAmbientOcclusionPositionAttribute);
    glEnableVertexAttribArray(cylinderAmbientOcclusionDirectionAttribute);
    glEnableVertexAttribArray(cylinderAmbientOcclusionImpostorSpaceAttribute);
    glEnableVertexAttribArray(cylinderAmbientOcclusionAOOffsetAttribute);
}

- (void)initializeRaytracingShaders;
{
    if (sphereRaytracingProgram != nil)
    {
        return;
    }
    
	[[self openGLContext] makeCurrentContext];
    
    sphereRaytracingProgram = [[GLProgram alloc] initWithVertexShaderFilename:@"SphereRaytracing" fragmentShaderFilename:@"SphereRaytracing"];
	[sphereRaytracingProgram addAttribute:@"position"];
	[sphereRaytracingProgram addAttribute:@"inputImpostorSpaceCoordinate"];
    [sphereRaytracingProgram addAttribute:@"ambientOcclusionTextureOffset"];
	if (![sphereRaytracingProgram link])
	{
		NSLog(@"Raytracing shader link failed");
		NSString *progLog = [sphereRaytracingProgram programLog];
		NSLog(@"Program Log: %@", progLog);
		NSString *fragLog = [sphereRaytracingProgram fragmentShaderLog];
		NSLog(@"Frag Log: %@", fragLog);
		NSString *vertLog = [sphereRaytracingProgram vertexShaderLog];
		NSLog(@"Vert Log: %@", vertLog);
		sphereRaytracingProgram = nil;
	}
    
    sphereRaytracingPositionAttribute = [sphereRaytracingProgram attributeIndex:@"position"];
    sphereRaytracingImpostorSpaceAttribute = [sphereRaytracingProgram attributeIndex:@"inputImpostorSpaceCoordinate"];
    sphereRaytracingAOOffsetAttribute = [sphereRaytracingProgram attributeIndex:@"ambientOcclusionTextureOffset"];
	sphereRaytracingModelViewMatrix = [sphereRaytracingProgram uniformIndex:@"modelViewProjMatrix"];
    sphereRaytracingLightPosition = [sphereRaytracingProgram uniformIndex:@"lightPosition"];
    sphereRaytracingRadius = [sphereRaytracingProgram uniformIndex:@"sphereRadius"];
    sphereRaytracingColor = [sphereRaytracingProgram uniformIndex:@"sphereColor"];
    sphereRaytracingDepthTexture = [sphereRaytracingProgram uniformIndex:@"depthTexture"];
    sphereRaytracingOrthographicMatrix = [sphereRaytracingProgram uniformIndex:@"orthographicMatrix"];
    sphereRaytracingPrecalculatedDepthTexture = [sphereRaytracingProgram uniformIndex:@"precalculatedSphereDepthTexture"];
    sphereRaytracingInverseModelViewMatrix = [sphereRaytracingProgram uniformIndex:@"inverseModelViewProjMatrix"];
    sphereRaytracingTexturePatchWidth = [sphereRaytracingProgram uniformIndex:@"ambientOcclusionTexturePatchWidth"];
    sphereRaytracingAOTexture = [sphereRaytracingProgram uniformIndex:@"ambientOcclusionTexture"];
    sphereRaytracingPrecalculatedAOLookupTexture = [sphereRaytracingProgram uniformIndex:@"precalculatedAOLookupTexture"];
    sphereRaytracingTranslation = [sphereRaytracingProgram uniformIndex:@"translation"];
    sphereRaytracingDepthMapTexture = [sphereRaytracingProgram uniformIndex:@"sphereDepthMap"];
    
    [sphereRaytracingProgram use];
    glEnableVertexAttribArray(sphereRaytracingPositionAttribute);
    glEnableVertexAttribArray(sphereRaytracingImpostorSpaceAttribute);
    glEnableVertexAttribArray(sphereRaytracingAOOffsetAttribute);
    
    cylinderRaytracingProgram = [[GLProgram alloc] initWithVertexShaderFilename:@"CylinderRaytracing" fragmentShaderFilename:@"CylinderRaytracing"];
	[cylinderRaytracingProgram addAttribute:@"position"];
	[cylinderRaytracingProgram addAttribute:@"direction"];
	[cylinderRaytracingProgram addAttribute:@"inputImpostorSpaceCoordinate"];
    [cylinderRaytracingProgram addAttribute:@"ambientOcclusionTextureOffset"];
    
	if (![cylinderRaytracingProgram link])
	{
		NSLog(@"Raytracing shader link failed");
		NSString *progLog = [cylinderRaytracingProgram programLog];
		NSLog(@"Program Log: %@", progLog);
		NSString *fragLog = [cylinderRaytracingProgram fragmentShaderLog];
		NSLog(@"Frag Log: %@", fragLog);
		NSString *vertLog = [cylinderRaytracingProgram vertexShaderLog];
		NSLog(@"Vert Log: %@", vertLog);
		cylinderRaytracingProgram = nil;
	}
    
    cylinderRaytracingPositionAttribute = [cylinderRaytracingProgram attributeIndex:@"position"];
    cylinderRaytracingDirectionAttribute = [cylinderRaytracingProgram attributeIndex:@"direction"];
    cylinderRaytracingImpostorSpaceAttribute = [cylinderRaytracingProgram attributeIndex:@"inputImpostorSpaceCoordinate"];
    cylinderRaytracingAOOffsetAttribute = [cylinderRaytracingProgram attributeIndex:@"ambientOcclusionTextureOffset"];
	cylinderRaytracingModelViewMatrix = [cylinderRaytracingProgram uniformIndex:@"modelViewProjMatrix"];
    cylinderRaytracingLightPosition = [cylinderRaytracingProgram uniformIndex:@"lightPosition"];
    cylinderRaytracingRadius = [cylinderRaytracingProgram uniformIndex:@"cylinderRadius"];
    cylinderRaytracingColor = [cylinderRaytracingProgram uniformIndex:@"cylinderColor"];
    cylinderRaytracingDepthTexture = [cylinderRaytracingProgram uniformIndex:@"depthTexture"];
    cylinderRaytracingOrthographicMatrix = [cylinderRaytracingProgram uniformIndex:@"orthographicMatrix"];
    cylinderRaytracingInverseModelViewMatrix = [cylinderRaytracingProgram uniformIndex:@"inverseModelViewProjMatrix"];
    cylinderRaytracingTexturePatchWidth = [cylinderRaytracingProgram uniformIndex:@"ambientOcclusionTexturePatchWidth"];
    cylinderRaytracingAOTexture = [cylinderRaytracingProgram uniformIndex:@"ambientOcclusionTexture"];
    cylinderRaytracingTranslation = [cylinderRaytracingProgram uniformIndex:@"translation"];
    
    [cylinderRaytracingProgram use];
    glEnableVertexAttribArray(cylinderRaytracingPositionAttribute);
    glEnableVertexAttribArray(cylinderRaytracingImpostorSpaceAttribute);
    glEnableVertexAttribArray(cylinderRaytracingAOOffsetAttribute);
    glEnableVertexAttribArray(cylinderRaytracingDirectionAttribute);
    
#ifdef ENABLETEXTUREDISPLAYDEBUGGING
    passthroughProgram = [[GLProgram alloc] initWithVertexShaderFilename:@"PlainDisplay" fragmentShaderFilename:@"PlainDisplay"];
	[passthroughProgram addAttribute:@"position"];
	[passthroughProgram addAttribute:@"inputTextureCoordinate"];
    
    if (![passthroughProgram link])
	{
		NSLog(@"Raytracing shader link failed");
		NSString *progLog = [passthroughProgram programLog];
		NSLog(@"Program Log: %@", progLog);
		NSString *fragLog = [passthroughProgram fragmentShaderLog];
		NSLog(@"Frag Log: %@", fragLog);
		NSString *vertLog = [passthroughProgram vertexShaderLog];
		NSLog(@"Vert Log: %@", vertLog);
		passthroughProgram = nil;
	}
    
    passthroughPositionAttribute = [passthroughProgram attributeIndex:@"position"];
    passthroughTextureCoordinateAttribute = [passthroughProgram attributeIndex:@"inputTextureCoordinate"];
    passthroughTexture = [passthroughProgram uniformIndex:@"texture"];
    
    [passthroughProgram use];
	glEnableVertexAttribArray(passthroughPositionAttribute);
	glEnableVertexAttribArray(passthroughTextureCoordinateAttribute);
    
#endif
    
    
    sphereAOLookupPrecalculationProgram = [[GLProgram alloc] initWithVertexShaderFilename:@"SphereAOLookup" fragmentShaderFilename:@"SphereAOLookup"];
	[sphereAOLookupPrecalculationProgram addAttribute:@"inputImpostorSpaceCoordinate"];
	if (![sphereAOLookupPrecalculationProgram link])
	{
		NSLog(@"Raytracing shader link failed");
		NSString *progLog = [sphereAOLookupPrecalculationProgram programLog];
		NSLog(@"Program Log: %@", progLog);
		NSString *fragLog = [sphereAOLookupPrecalculationProgram fragmentShaderLog];
		NSLog(@"Frag Log: %@", fragLog);
		NSString *vertLog = [sphereAOLookupPrecalculationProgram vertexShaderLog];
		NSLog(@"Vert Log: %@", vertLog);
		sphereAOLookupPrecalculationProgram = nil;
	}
    
    sphereAOLookupImpostorSpaceAttribute = [sphereAOLookupPrecalculationProgram attributeIndex:@"inputImpostorSpaceCoordinate"];
    sphereAOLookupPrecalculatedDepthTexture = [sphereAOLookupPrecalculationProgram uniformIndex:@"precalculatedSphereDepthTexture"];
    sphereAOLookupInverseModelViewMatrix = [sphereAOLookupPrecalculationProgram uniformIndex:@"inverseModelViewProjMatrix"];
    
    [sphereAOLookupPrecalculationProgram use];
    glEnableVertexAttribArray(sphereAOLookupImpostorSpaceAttribute);
    
//    [self generateSphereDepthMapTexture];
    
    //    glDisable(GL_DEPTH_TEST);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glDisable(GL_ALPHA_TEST);
    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_ONE, GL_ONE);
    
    glEnable(GL_CULL_FACE);
	glCullFace(GL_BACK);
    
    //    glAlphaFunc(GL_ALWAYS, 0);
    //    glDepthMask(GL_FALSE);
}

- (void)switchToDisplayFramebuffer;
{
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glBindRenderbuffer(GL_RENDERBUFFER, 0);
    
//	glUseProgram(0);
//    
//	glMatrixMode(GL_PROJECTION);
//    glLoadIdentity();
	
//    //	glActiveTexture(GL_TEXTURE0); // Texture 0 is the only unit used for direct drawing like this, idiot
//    
//    
//	glVertexPointer(2, GL_FLOAT, 0, squareVertices);
//	glTexCoordPointer(2, GL_FLOAT, 0, invertedTextureCoordinates);
//	
//	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

//	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
//    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    
    CGSize newViewportSize = CGSizeMake(backingWidth, backingHeight);
    
    if (!CGSizeEqualToSize(newViewportSize, currentViewportSize))
    {
        //    glViewport(0, 0, (GLfloat)self.bounds.size.width, (GLfloat)self.bounds.size.height);
        glViewport(0, 0, backingWidth, backingHeight);
        currentViewportSize = newViewportSize;
    }
}

- (void)switchToDepthPassFramebuffer;
{
	glBindFramebuffer(GL_FRAMEBUFFER, depthPassFramebuffer);
    CGSize newViewportSize = CGSizeMake(ambientOcclusionTextureWidth, ambientOcclusionTextureWidth);
    glViewport(0, 0, newViewportSize.width, newViewportSize.height);
    currentViewportSize = newViewportSize;    
}

- (void)switchToAmbientOcclusionFramebuffer;
{
	glBindFramebuffer(GL_FRAMEBUFFER, ambientOcclusionFramebuffer);
    
    CGSize newViewportSize = CGSizeMake(ambientOcclusionTextureWidth, ambientOcclusionTextureWidth);
    
    if (!CGSizeEqualToSize(newViewportSize, currentViewportSize))
    {
        glViewport(0, 0, ambientOcclusionTextureWidth, ambientOcclusionTextureWidth);
        currentViewportSize = newViewportSize;
    }
}

- (void)switchToAOLookupFramebuffer;
{
	glBindFramebuffer(GL_FRAMEBUFFER, sphereAOLookupFramebuffer);
    
    CGSize newViewportSize = CGSizeMake(ambientOcclusionLookupTextureWidth, ambientOcclusionLookupTextureWidth);
    
    if (!CGSizeEqualToSize(newViewportSize, currentViewportSize))
    {
        glViewport(0, 0, ambientOcclusionLookupTextureWidth, ambientOcclusionLookupTextureWidth);
        currentViewportSize = newViewportSize;
    }
}

- (void)generateSphereDepthMapTexture;
{
    //    CFTimeInterval previousTimestamp = CFAbsoluteTimeGetCurrent();
    
    // Luminance for depth: This takes only 95 ms on an iPad 1, so it's worth it for the 8% - 18% per-frame speedup
    // Full lighting precalculation: This only takes 264 ms on an iPad 1
    
    unsigned char *sphereDepthTextureData = (unsigned char *)malloc(sphereDepthTextureWidth * sphereDepthTextureWidth * 4);
    
    glGenTextures(1, &sphereDepthMappingTexture);
    
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, sphereDepthMappingTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    //    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    //	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    //	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    //    glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
    
    for (unsigned int currentColumnInTexture = 0; currentColumnInTexture < sphereDepthTextureWidth; currentColumnInTexture++)
    {
        float normalizedYLocation = -1.0 + 2.0 * (float)currentColumnInTexture / (float)sphereDepthTextureWidth;
        for (unsigned int currentRowInTexture = 0; currentRowInTexture < sphereDepthTextureWidth; currentRowInTexture++)
        {
            float normalizedXLocation = -1.0 + 2.0 * (float)currentRowInTexture / (float)sphereDepthTextureWidth;
            unsigned char currentDepthByte = 0, currentAmbientLightingByte = 0, currentSpecularLightingByte = 0, alphaByte = 0;
            
            float distanceFromCenter = sqrt(normalizedXLocation * normalizedXLocation + normalizedYLocation * normalizedYLocation);
            float currentSphereDepth = 0.0;
            float lightingNormalX = normalizedXLocation, lightingNormalY = normalizedYLocation;
            
            if (distanceFromCenter <= 1.0)
            {
                // First, calculate the depth of the sphere at this point
                currentSphereDepth = sqrt(1.0 - distanceFromCenter * distanceFromCenter);
                currentDepthByte = round(255.0 * currentSphereDepth);
                
                alphaByte = 255;
            }
            else
            {
                float normalizationFactor = sqrt(normalizedXLocation * normalizedXLocation + normalizedYLocation * normalizedYLocation);
                lightingNormalX = lightingNormalX / normalizationFactor;
                lightingNormalY = lightingNormalY / normalizationFactor;
            }
            
            // Then, do the ambient lighting factor
            float dotProductForLighting = lightingNormalX * lightDirection[0] + lightingNormalY * lightDirection[1] + currentSphereDepth * lightDirection[2];
            if (dotProductForLighting < 0.0)
            {
                dotProductForLighting = 0.0;
            }
            else if (dotProductForLighting > 1.0)
            {
                dotProductForLighting = 1.0;
            }
            
            //            float ambientLightingProduct = dotProductForLighting + 0.4;
            //            ambientLightingProduct = MIN(1.0, ambientLightingProduct);
            
            currentAmbientLightingByte = round(255.0 * dotProductForLighting);
            
            // Finally, do the specular lighting factor
            float specularIntensity = pow(dotProductForLighting, 40.0);
            //            currentSpecularLightingByte = round(255.0 * specularIntensity * 0.48);
            //            currentSpecularLightingByte = round(255.0 * specularIntensity * 0.6);
            currentSpecularLightingByte = round(255.0 * specularIntensity * 0.5);
            
            sphereDepthTextureData[currentColumnInTexture * sphereDepthTextureWidth * 4 + (currentRowInTexture * 4)] = currentDepthByte;
            sphereDepthTextureData[currentColumnInTexture * sphereDepthTextureWidth * 4 + (currentRowInTexture * 4) + 1] = currentAmbientLightingByte;
            sphereDepthTextureData[currentColumnInTexture * sphereDepthTextureWidth * 4 + (currentRowInTexture * 4) + 2] = currentSpecularLightingByte;
            sphereDepthTextureData[currentColumnInTexture * sphereDepthTextureWidth * 4 + (currentRowInTexture * 4) + 3] = alphaByte;
            /*
             float lightingIntensity = 0.2 + 1.3 * clamp(dot(lightPosition, normal), 0.0, 1.0) * ambientOcclusionIntensity.r;
             finalSphereColor *= lightingIntensity;
             
             // Per fragment specular lighting
             lightingIntensity  = clamp(dot(lightPosition, normal), 0.0, 1.0);
             lightingIntensity  = pow(lightingIntensity, 60.0) * ambientOcclusionIntensity.r * 1.2;
             finalSphereColor += vec3(0.4, 0.4, 0.4) * lightingIntensity + vec3(1.0, 1.0, 1.0) * 0.2 * ambientOcclusionIntensity.r;
             */
            
        }
    }
    
    //	glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, sphereDepthTextureWidth, sphereDepthTextureWidth, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, sphereDepthTextureData);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, sphereDepthTextureWidth, sphereDepthTextureWidth, 0, GL_RGBA, GL_UNSIGNED_BYTE, sphereDepthTextureData);
    glGenerateMipmap(GL_TEXTURE_2D);
    //    glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);
    
    free(sphereDepthTextureData);
    
    //    CFTimeInterval frameDuration = CFAbsoluteTimeGetCurrent() - previousTimestamp;
    
    //    NSLog(@"Texture generation duration: %f ms", frameDuration * 1000.0);
    
}

- (void)destroyFramebuffers;
{
    dispatch_sync(openGLESContextQueue, ^{
        [[self openGLContext] makeCurrentContext];
        
        if (viewFramebuffer)
        {
            glDeleteFramebuffers(1, &viewFramebuffer);
            viewFramebuffer = 0;
        }
        
        if (viewRenderbuffer)
        {
            glDeleteRenderbuffers(1, &viewRenderbuffer);
            viewRenderbuffer = 0;
        }
        
        if (viewDepthBuffer)
        {
            glDeleteRenderbuffers(1, &viewDepthBuffer);
            viewDepthBuffer = 0;
        }
        
        if (depthPassFramebuffer)
        {
            glDeleteFramebuffers(1, &depthPassFramebuffer);
            depthPassFramebuffer = 0;
        }
        
        if (depthPassDepthBuffer)
        {
            glDeleteRenderbuffers(1, &depthPassDepthBuffer);
            depthPassDepthBuffer = 0;
        }
        
        if (depthPassTexture)
        {
            glDeleteTextures(1, &depthPassTexture);
            depthPassTexture = 0;
        }
        
    });   
}

- (void)configureProjection;
{
    [self loadOrthoMatrix:orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) top:(1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) near:-4.0 far:4.0];
}

- (void)clearScreen;
{
    dispatch_async(openGLESContextQueue, ^{
        [[self openGLContext] makeCurrentContext];
        
        [self switchToDisplayFramebuffer];
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        [self presentRenderBuffer];
    });
}

- (void)presentRenderBuffer;
{
    [[self openGLContext] flushBuffer];
//    [context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)suspendRenderingDuringRotation;
{
    dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)resumeRenderingDuringRotation;
{
    dispatch_semaphore_signal(frameRenderingSemaphore);
}

#pragma mark -
#pragma mark Actual OpenGL rendering

- (void)renderFrameForMolecule:(SLSMolecule *)molecule;
{
    if (!isSceneReady)
    {
        return;
    }
    
    // In order to prevent frames to be rendered from building up indefinitely, we use a dispatch semaphore to keep at most two frames in the queue
    
    if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return;
    }
    
    dispatch_async(openGLESContextQueue, ^{
        
        [[self openGLContext] makeCurrentContext];
        
//        CFTimeInterval previousTimestamp = CFAbsoluteTimeGetCurrent();
        
        GLfloat currentModelViewMatrix[9];
        [self convert3DTransform:&currentCalculatedMatrix to3x3Matrix:currentModelViewMatrix];
        
        CATransform3D inverseMatrix = CATransform3DInvert(currentCalculatedMatrix);
        GLfloat inverseModelViewMatrix[9];
        [self convert3DTransform:&inverseMatrix to3x3Matrix:inverseModelViewMatrix];
        
        // Load these once here so that they don't go out of sync between rendering passes during user gestures
        GLfloat currentTranslation[3];
        currentTranslation[0] = accumulatedModelTranslation[0];
        currentTranslation[1] = accumulatedModelTranslation[1];
        currentTranslation[2] = accumulatedModelTranslation[2];
        
        GLfloat currentScaleFactor = currentModelScaleFactor;
        
//        [self precalculateAOLookupTextureForInverseMatrix:inverseModelViewMatrix];
//        [self renderDepthTextureForModelViewMatrix:currentModelViewMatrix translation:currentTranslation scale:currentScaleFactor];
        //        [self displayTextureToScreen:sphereAOLookupTexture];
        //        [self displayTextureToScreen:depthPassTexture];
        //        [self displayTextureToScreen:ambientOcclusionTexture];
        [self renderRaytracedSceneForModelViewMatrix:currentModelViewMatrix inverseMatrix:inverseModelViewMatrix translation:currentTranslation scale:currentScaleFactor];
        
//        const GLenum discards[]  = {GL_DEPTH_ATTACHMENT};
//        glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards);
        
        [self presentRenderBuffer];
        
//        CFTimeInterval frameDuration = CFAbsoluteTimeGetCurrent() - previousTimestamp;
//
//        NSLog(@"Frame duration: %f ms at %d x %d", frameDuration * 1000.0, backingWidth, backingHeight);
        
        dispatch_semaphore_signal(frameRenderingSemaphore);
    });
}

#pragma mark -
#pragma mark Molecule 3-D geometry generation

- (void)configureBasedOnNumberOfAtoms:(unsigned int)numberOfAtoms numberOfBonds:(unsigned int)numberOfBonds;
{
    widthOfAtomAOTexturePatch = (GLfloat)ambientOcclusionTextureWidth / (ceil(sqrt((GLfloat)numberOfAtoms + (GLfloat)numberOfBonds)));
    normalizedAOTexturePatchWidth = (GLfloat)widthOfAtomAOTexturePatch / (GLfloat)ambientOcclusionTextureWidth;
    
    previousAmbientOcclusionOffset[0] = normalizedAOTexturePatchWidth / 2.0;
    previousAmbientOcclusionOffset[1] = normalizedAOTexturePatchWidth / 2.0;
    
    shouldDrawBonds = (numberOfBonds > 0);
}

- (void)addIndex:(GLushort *)newIndex forAtomType:(SLSAtomType)atomType;
{
    if (atomIndexBuffers[atomType] == nil)
    {
        atomIndexBuffers[atomType] = [[NSMutableData alloc] init];
    }
    
	[atomIndexBuffers[atomType] appendBytes:newIndex length:sizeof(GLushort)];
	numberOfAtomIndices[atomType]++;
}

- (void)addIndices:(GLushort *)newIndices size:(unsigned int)numIndices forAtomType:(SLSAtomType)atomType;
{
    if (atomIndexBuffers[atomType] == nil)
    {
        atomIndexBuffers[atomType] = [[NSMutableData alloc] init];
    }

    [atomIndexBuffers[atomType] appendBytes:newIndices length:(sizeof(GLushort) * numIndices)];
	numberOfAtomIndices[atomType] += numIndices;
}

- (void)addBondIndex:(GLushort *)newIndex;
{
    if (bondIndexBuffers[currentBondVBO] == nil)
    {
        bondIndexBuffers[currentBondVBO] = [[NSMutableData alloc] init];
    }
    
	[bondIndexBuffers[currentBondVBO] appendBytes:newIndex length:sizeof(GLushort)];
	numberOfBondIndices[currentBondVBO]++;
}

- (void)addBondIndices:(GLushort *)newIndices size:(unsigned int)numIndices;
{
    if (bondIndexBuffers[currentBondVBO] == nil)
    {
        bondIndexBuffers[currentBondVBO] = [[NSMutableData alloc] init];
    }
    
	[bondIndexBuffers[currentBondVBO] appendBytes:newIndices length:(sizeof(GLushort) * numIndices)];
	numberOfBondIndices[currentBondVBO] += numIndices;
}

- (void)addAtomToVertexBuffers:(SLSAtomType)atomType atPoint:(SLS3DPoint)newPoint;
{
    GLushort baseToAddToIndices = numberOfAtomVertices[atomType];
    
    GLfloat newVertex[3];
    //    newVertex[0] = newPoint.x;
    newVertex[0] = -newPoint.x;
    newVertex[1] = newPoint.y;
    newVertex[2] = newPoint.z;
    
    /*
     // Square coordinate generation
     
     GLfloat lowerLeftTexture[2] = {-1.0, -1.0};
     GLfloat lowerRightTexture[2] = {1.0, -1.0};
     GLfloat upperLeftTexture[2] = {-1.0, 1.0};
     GLfloat upperRightTexture[2] = {1.0, 1.0};
     
     // Add four copies of this vertex, that will be translated in the vertex shader into the billboard
     // Interleave texture coordinates in VBO
     [self addVertex:newVertex forAtomType:atomType];
     [self addTextureCoordinate:lowerLeftTexture forAtomType:atomType];
     [self addAmbientOcclusionTextureOffset:previousAmbientOcclusionOffset forAtomType:atomType];
     [self addVertex:newVertex forAtomType:atomType];
     [self addTextureCoordinate:lowerRightTexture forAtomType:atomType];
     [self addAmbientOcclusionTextureOffset:previousAmbientOcclusionOffset forAtomType:atomType];
     [self addVertex:newVertex forAtomType:atomType];
     [self addTextureCoordinate:upperLeftTexture forAtomType:atomType];
     [self addAmbientOcclusionTextureOffset:previousAmbientOcclusionOffset forAtomType:atomType];
     [self addVertex:newVertex forAtomType:atomType];
     [self addTextureCoordinate:upperRightTexture forAtomType:atomType];
     [self addAmbientOcclusionTextureOffset:previousAmbientOcclusionOffset forAtomType:atomType];
     
     //    123324
     GLushort newIndices[6];
     newIndices[0] = baseToAddToIndices;
     newIndices[1] = baseToAddToIndices + 1;
     newIndices[2] = baseToAddToIndices + 2;
     newIndices[3] = baseToAddToIndices + 2;
     newIndices[4] = baseToAddToIndices + 1;
     newIndices[5] = baseToAddToIndices + 3;
     
     
     [self addIndices:newIndices size:6 forAtomType:atomType];
     */
    
    
    /*
     // Hexagonal coordinate generation, using raster-optimized layout
     
     GLfloat positiveSideComponent = 2.0 / sqrt(3);
     GLfloat negativeSideComponent = -2.0 / sqrt(3);
     
     GLfloat hexagonPoints[6][2] = {
     {negativeSideComponent, 1.0},
     {negativeSideComponent, -1.0},
     {1.0, 0.0},
     {positiveSideComponent, 1.0},
     {-1.0, 0.0},
     {positiveSideComponent, -1.0}
     };
     
     for (unsigned int currentTextureCoordinate = 0; currentTextureCoordinate < 6; currentTextureCoordinate++)
     {
     [self addVertex:newVertex forAtomType:atomType];
     [self addTextureCoordinate:hexagonPoints[currentTextureCoordinate] forAtomType:atomType];
     [self addAmbientOcclusionTextureOffset:previousAmbientOcclusionOffset forAtomType:atomType];
     }
     
     // 123,341,152,263
     GLushort newIndices[12];
     newIndices[0] = baseToAddToIndices;
     newIndices[1] = baseToAddToIndices + 1;
     newIndices[2] = baseToAddToIndices + 2;
     
     newIndices[3] = baseToAddToIndices + 2;
     newIndices[4] = baseToAddToIndices + 3;
     newIndices[5] = baseToAddToIndices;
     
     newIndices[6] = baseToAddToIndices + 0;
     newIndices[7] = baseToAddToIndices + 4;
     newIndices[8] = baseToAddToIndices + 1;
     
     newIndices[9] = baseToAddToIndices + 1;
     newIndices[10] = baseToAddToIndices + 5;
     newIndices[11] = baseToAddToIndices + 2;
     
     [self addIndices:newIndices size:12 forAtomType:atomType];
     
     */
    
    
    // Octagonal coordinate generation, using raster-optimized layout
    GLfloat positiveSideComponent = 1.0 - 2.0 / (sqrt(2) + 2);
    GLfloat negativeSideComponent = -1.0 + 2.0 / (sqrt(2) + 2);
    
    GLfloat octagonPoints[8][2] = {
        {negativeSideComponent, 1.0},
        {-1.0, negativeSideComponent},
        {1.0, positiveSideComponent},
        {positiveSideComponent, -1.0},
        {1.0, negativeSideComponent},
        {positiveSideComponent, 1.0},
        {-1.0, positiveSideComponent},
        {negativeSideComponent, -1.0},
    };
    
    // Add eight copies of this vertex, that will be translated in the vertex shader into the billboard
    // Interleave texture coordinates in VBO
    
    for (unsigned int currentTextureCoordinate = 0; currentTextureCoordinate < 8; currentTextureCoordinate++)
    {
        [self addVertex:newVertex forAtomType:atomType];
        [self addTextureCoordinate:octagonPoints[currentTextureCoordinate] forAtomType:atomType];
        [self addAmbientOcclusionTextureOffset:previousAmbientOcclusionOffset forAtomType:atomType];
    }
    
    // 123, 324, 345, 136, 217, 428
    
    GLushort newIndices[18];
    newIndices[0] = baseToAddToIndices;
    newIndices[1] = baseToAddToIndices + 1;
    newIndices[2] = baseToAddToIndices + 2;
    
    newIndices[3] = baseToAddToIndices + 2;
    newIndices[4] = baseToAddToIndices + 1;
    newIndices[5] = baseToAddToIndices + 3;
    
    newIndices[6] = baseToAddToIndices + 2;
    newIndices[7] = baseToAddToIndices + 3;
    newIndices[8] = baseToAddToIndices + 4;
    
    newIndices[9] = baseToAddToIndices;
    newIndices[10] = baseToAddToIndices + 2;
    newIndices[11] = baseToAddToIndices + 5;
    
    newIndices[12] = baseToAddToIndices + 1;
    newIndices[13] = baseToAddToIndices;
    newIndices[14] = baseToAddToIndices + 6;
    
    newIndices[15] = baseToAddToIndices + 3;
    newIndices[16] = baseToAddToIndices + 1;
    newIndices[17] = baseToAddToIndices + 7;
    
    [self addIndices:newIndices size:18 forAtomType:atomType];
    
    
    previousAmbientOcclusionOffset[0] += normalizedAOTexturePatchWidth;
    if (previousAmbientOcclusionOffset[0] > (1.0 - normalizedAOTexturePatchWidth * 0.15))
    {
        previousAmbientOcclusionOffset[0] = normalizedAOTexturePatchWidth / 2.0;
        previousAmbientOcclusionOffset[1] += normalizedAOTexturePatchWidth;
    }    
}

- (void)addBondToVertexBuffersWithStartPoint:(SLS3DPoint)startPoint endPoint:(SLS3DPoint)endPoint bondColor:(GLubyte *)bondColor bondType:(SLSBondType)bondType;
{
    if (currentBondVBO >= MAX_BOND_VBOS)
    {
        return;
    }
    
    GLushort baseToAddToIndices = numberOfBondVertices[currentBondVBO];
    
    // Vertex positions, duplicated for later displacement at each end
    // Interleave the directions and texture coordinates for the VBO
    GLfloat newVertex[3], cylinderDirection[3];
    
    //    cylinderDirection[0] = endPoint.x - startPoint.x;
    cylinderDirection[0] = startPoint.x - endPoint.x;
    cylinderDirection[1] = endPoint.y - startPoint.y;
    cylinderDirection[2] = endPoint.z - startPoint.z;
    
    // Impostor space coordinates
    GLfloat lowerLeftTexture[2] = {-1.0, -1.0};
    GLfloat lowerRightTexture[2] = {1.0, -1.0};
    GLfloat upperLeftTexture[2] = {-1.0, 1.0};
    GLfloat upperRightTexture[2] = {1.0, 1.0};
    
    //    newVertex[0] = startPoint.x;
    newVertex[0] = -startPoint.x;
    newVertex[1] = startPoint.y;
    newVertex[2] = startPoint.z;
    
    [self addBondVertex:newVertex];
    [self addBondDirection:cylinderDirection];
    [self addBondTextureCoordinate:lowerLeftTexture];
    [self addBondAmbientOcclusionTextureOffset:previousAmbientOcclusionOffset];
    [self addBondVertex:newVertex];
    [self addBondDirection:cylinderDirection];
    [self addBondTextureCoordinate:lowerRightTexture];
    [self addBondAmbientOcclusionTextureOffset:previousAmbientOcclusionOffset];
    
    //    newVertex[0] = endPoint.x;
    newVertex[0] = -endPoint.x;
    newVertex[1] = endPoint.y;
    newVertex[2] = endPoint.z;
    
    [self addBondVertex:newVertex];
    [self addBondDirection:cylinderDirection];
    [self addBondTextureCoordinate:upperLeftTexture];
    [self addBondAmbientOcclusionTextureOffset:previousAmbientOcclusionOffset];
    [self addBondVertex:newVertex];
    [self addBondDirection:cylinderDirection];
    [self addBondTextureCoordinate:upperRightTexture];
    [self addBondAmbientOcclusionTextureOffset:previousAmbientOcclusionOffset];
    
    // Vertex indices
    //    123243
    GLushort newIndices[6];
    newIndices[0] = baseToAddToIndices;
    newIndices[1] = baseToAddToIndices + 1;
    newIndices[2] = baseToAddToIndices + 2;
    newIndices[3] = baseToAddToIndices + 1;
    newIndices[4] = baseToAddToIndices + 3;
    newIndices[5] = baseToAddToIndices + 2;
    
    [self addBondIndices:newIndices size:6];
    
    previousAmbientOcclusionOffset[0] += normalizedAOTexturePatchWidth;
    if (previousAmbientOcclusionOffset[0] > (1.0 - normalizedAOTexturePatchWidth * 0.15))
    {
        previousAmbientOcclusionOffset[0] = normalizedAOTexturePatchWidth / 2.0;
        previousAmbientOcclusionOffset[1] += normalizedAOTexturePatchWidth;
    }
}

- (void)addVertex:(GLfloat *)newVertex forAtomType:(SLSAtomType)atomType;
{
    if (atomVBOs[atomType] == nil)
    {
        atomVBOs[atomType] = [[NSMutableData alloc] init];
    }
    
	[atomVBOs[atomType] appendBytes:newVertex length:(sizeof(GLfloat) * 3)];
    
	numberOfAtomVertices[atomType]++;
	totalNumberOfVertices++;
}

- (void)addBondVertex:(GLfloat *)newVertex;
{
    if (bondVBOs[currentBondVBO] == nil)
    {
        bondVBOs[currentBondVBO] = [[NSMutableData alloc] init];
    }
    
	[bondVBOs[currentBondVBO] appendBytes:newVertex length:(sizeof(GLfloat) * 3)];
    
	numberOfBondVertices[currentBondVBO]++;
	totalNumberOfVertices++;
}

- (void)addTextureCoordinate:(GLfloat *)newTextureCoordinate forAtomType:(SLSAtomType)atomType;
{
    if (atomVBOs[atomType] == nil)
    {
        atomVBOs[atomType] = [[NSMutableData alloc] init];
    }
    
	[atomVBOs[atomType] appendBytes:newTextureCoordinate length:(sizeof(GLfloat) * 2)];
}

- (void)addAmbientOcclusionTextureOffset:(GLfloat *)ambientOcclusionOffset forAtomType:(SLSAtomType)atomType;
{
    if (atomVBOs[atomType] == nil)
    {
        atomVBOs[atomType] = [[NSMutableData alloc] init];
    }
    
	[atomVBOs[atomType] appendBytes:ambientOcclusionOffset length:(sizeof(GLfloat) * 2)];
}

- (void)addBondDirection:(GLfloat *)newDirection;
{
    if (bondVBOs[currentBondVBO] == nil)
    {
        bondVBOs[currentBondVBO] = [[NSMutableData alloc] init];
    }
    
	[bondVBOs[currentBondVBO] appendBytes:newDirection length:(sizeof(GLfloat) * 3)];
}

- (void)addBondTextureCoordinate:(GLfloat *)newTextureCoordinate;
{
    if (bondVBOs[currentBondVBO] == nil)
    {
        bondVBOs[currentBondVBO] = [[NSMutableData alloc] init];
    }
    
	[bondVBOs[currentBondVBO] appendBytes:newTextureCoordinate length:(sizeof(GLfloat) * 2)];
}

- (void)addBondAmbientOcclusionTextureOffset:(GLfloat *)ambientOcclusionOffset;
{
    if (bondVBOs[currentBondVBO] == nil)
    {
        bondVBOs[currentBondVBO] = [[NSMutableData alloc] init];
    }
    
	[bondVBOs[currentBondVBO] appendBytes:ambientOcclusionOffset length:(sizeof(GLfloat) * 2)];
}

#pragma mark -
#pragma mark OpenGL drawing routines

- (void)bindVertexBuffersForMolecule:(SLSMolecule *)molecule;
{
    dispatch_async(openGLESContextQueue, ^{
        [[self openGLContext] makeCurrentContext];

        [self resetModelViewMatrix];

        isRenderingCancelled = NO;
        
        for (unsigned int currentAtomIndexBufferIndex = 0; currentAtomIndexBufferIndex < NUM_ATOMTYPES; currentAtomIndexBufferIndex++)
        {            
            if (atomIndexBuffers[currentAtomIndexBufferIndex] != nil)
            {
                glGenBuffers(1, &atomIndexBufferHandle[currentAtomIndexBufferIndex]);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, atomIndexBufferHandle[currentAtomIndexBufferIndex]);
                glBufferData(GL_ELEMENT_ARRAY_BUFFER, [atomIndexBuffers[currentAtomIndexBufferIndex] length], (GLushort *)[atomIndexBuffers[currentAtomIndexBufferIndex] bytes], GL_STATIC_DRAW);
                
                numberOfIndicesInBuffer[currentAtomIndexBufferIndex] = ([atomIndexBuffers[currentAtomIndexBufferIndex] length] / sizeof(GLushort));
                
                // Now that the data are in the OpenGL buffer, can release the NSData
                atomIndexBuffers[currentAtomIndexBufferIndex] = nil;
            }
            else
            {
                atomIndexBufferHandle[currentAtomIndexBufferIndex] = 0;
            }
        }
        
        for (unsigned int currentAtomVBOIndex = 0; currentAtomVBOIndex < NUM_ATOMTYPES; currentAtomVBOIndex++)
        {
            if (atomVBOs[currentAtomVBOIndex] != nil)
            {
                glGenBuffers(1, &atomVertexBufferHandles[currentAtomVBOIndex]);

                glBindBuffer(GL_ARRAY_BUFFER, atomVertexBufferHandles[currentAtomVBOIndex]);
                glBufferData(GL_ARRAY_BUFFER, [atomVBOs[currentAtomVBOIndex] length], (void *)[atomVBOs[currentAtomVBOIndex] bytes], GL_STATIC_DRAW);
                
                atomVBOs[currentAtomVBOIndex] = nil;
            }
            else
            {
                atomVertexBufferHandles[currentAtomVBOIndex] = 0;
            }
        }
        
        for (unsigned int currentBondVBOIndex = 0; currentBondVBOIndex < MAX_BOND_VBOS; currentBondVBOIndex++)
        {
            if (bondVBOs[currentBondVBOIndex] != nil)
            {
                glGenBuffers(1, &bondIndexBufferHandle[currentBondVBOIndex]);

                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, bondIndexBufferHandle[currentBondVBOIndex]);
                glBufferData(GL_ELEMENT_ARRAY_BUFFER, [bondIndexBuffers[currentBondVBOIndex] length], (GLushort *)[bondIndexBuffers[currentBondVBOIndex] bytes], GL_STATIC_DRAW);    
                
                numberOfBondIndicesInBuffer[currentBondVBOIndex] = ([bondIndexBuffers[currentBondVBOIndex] length] / sizeof(GLushort));
                
                bondIndexBuffers[currentBondVBOIndex] = nil;
                
                glGenBuffers(1, &bondVertexBufferHandle[currentBondVBOIndex]);

                glBindBuffer(GL_ARRAY_BUFFER, bondVertexBufferHandle[currentBondVBOIndex]);
                glBufferData(GL_ARRAY_BUFFER, [bondVBOs[currentBondVBOIndex] length], (void *)[bondVBOs[currentBondVBOIndex] bytes], GL_STATIC_DRAW); 
                
                bondVBOs[currentBondVBOIndex] = nil;
            }
        }    
    });    

    [self prepareAmbientOcclusionMapForMolecule:molecule];
    
    isSceneReady = YES;
}

- (void)freeVertexBuffers;
{    
    dispatch_sync(openGLESContextQueue, ^{
        [[self openGLContext] makeCurrentContext];
        
        isSceneReady = NO;
        
        for (unsigned int currentAtomType = 0; currentAtomType < NUM_ATOMTYPES; currentAtomType++)
        {
            if (atomIndexBufferHandle[currentAtomType] != 0)
            {
                glDeleteBuffers(1, &atomIndexBufferHandle[currentAtomType]);
                glDeleteBuffers(1, &atomVertexBufferHandles[currentAtomType]);
                
                atomIndexBufferHandle[currentAtomType] = 0;
                atomVertexBufferHandles[currentAtomType] = 0;
            }
        }
        if (bondVertexBufferHandle != 0)
        {
            for (unsigned int currentBondVBOIndex = 0; currentBondVBOIndex < MAX_BOND_VBOS; currentBondVBOIndex++)
            {
                if (bondIndexBufferHandle[currentBondVBOIndex] != 0)
                {
                    glDeleteBuffers(1, &bondVertexBufferHandle[currentBondVBOIndex]);
                    glDeleteBuffers(1, &bondIndexBufferHandle[currentBondVBOIndex]);   
                }
                
                bondVertexBufferHandle[currentBondVBOIndex] = 0;
                bondIndexBufferHandle[currentBondVBOIndex] = 0;
            }
        }
        
        totalNumberOfTriangles = 0;
        totalNumberOfVertices = 0;
    });
}

- (void)initiateMoleculeRendering;
{
    for (unsigned int currentAtomTypeIndex = 0; currentAtomTypeIndex < NUM_ATOMTYPES; currentAtomTypeIndex++)
    {
        numberOfAtomVertices[currentAtomTypeIndex] = 0;
        numberOfAtomIndices[currentAtomTypeIndex] = 0;
    }
    
    for (unsigned int currentBondVBOIndex = 0; currentBondVBOIndex < MAX_BOND_VBOS; currentBondVBOIndex++)
    {
        numberOfBondVertices[currentBondVBOIndex] = 0;
        numberOfBondIndices[currentBondVBOIndex] = 0;
    }
    
    currentBondVBO = 0;
    currentAtomVBO = 0;    
}

- (void)terminateMoleculeRendering;
{
    // Release all the NSData arrays that were partially generated
    for (unsigned int currentVBOIndex = 0; currentVBOIndex < NUM_ATOMTYPES; currentVBOIndex++)
    {
        if (atomVBOs[currentVBOIndex] != nil)
        {
            atomVBOs[currentVBOIndex] = nil;
        }
    }
    
    for (unsigned int currentIndexBufferIndex = 0; currentIndexBufferIndex < NUM_ATOMTYPES; currentIndexBufferIndex++)
    {
        if (atomIndexBuffers[currentIndexBufferIndex] != nil)
        {
            atomIndexBuffers[currentIndexBufferIndex] = nil;
        }
    }
    
    for (unsigned int currentBondVBOIndex = 0; currentBondVBOIndex < MAX_BOND_VBOS; currentBondVBOIndex++)
    {
        bondVBOs[currentBondVBOIndex] = nil;
        
        bondIndexBuffers[currentBondVBOIndex] = nil;
    }    
}

- (void)cancelMoleculeRendering;
{
    isRenderingCancelled = YES;    
}

- (void)waitForLastFrameToFinishRendering;
{
    dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_signal(frameRenderingSemaphore);
}

- (void)renderDepthTextureForModelViewMatrix:(GLfloat *)depthModelViewMatrix translation:(GLfloat *)modelTranslation scale:(GLfloat)scaleFactor;
{
    [self switchToDepthPassFramebuffer];
    
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glBlendEquation(GL_MIN_EXT);
//    glDepthMask(GL_TRUE);
//    glDepthFunc(GL_LEQUAL);
    
    glDisable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
    glDepthMask(GL_TRUE);
    //

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
//    glDepthMask(GL_FALSE);
    
    // Draw the spheres
    [sphereDepthProgram use];
    
    glUniformMatrix3fv(sphereDepthModelViewMatrix, 1, 0, depthModelViewMatrix);
    glUniform3fv(sphereDepthTranslation, 1, modelTranslation);
    glUniform1i(sphereDepthMapTexture, 3);
    
    float sphereScaleFactor = overallMoleculeScaleFactor * scaleFactor * atomRadiusScaleFactor;
    GLsizei atomVBOStride = sizeof(GLfloat) * 3 + sizeof(GLfloat) * 2 + sizeof(GLfloat) * 2;
    
    for (unsigned int currentAtomType = 0; currentAtomType < NUM_ATOMTYPES; currentAtomType++)
    {
        if (atomIndexBufferHandle[currentAtomType] != 0)
        {
            glUniform1f(sphereDepthRadius, atomProperties[currentAtomType].atomRadius * sphereScaleFactor);
            
            // Bind the VBO and attach it to the program
            glBindBuffer(GL_ARRAY_BUFFER, atomVertexBufferHandles[currentAtomType]);
            glVertexAttribPointer(sphereDepthPositionAttribute, 3, GL_FLOAT, 0, atomVBOStride, (char *)NULL + 0);
            glVertexAttribPointer(sphereDepthImpostorSpaceAttribute, 2, GL_FLOAT, 0, atomVBOStride, (char *)NULL + (sizeof(GLfloat) * 3));
            
            // Bind the index buffer and draw to the screen
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, atomIndexBufferHandle[currentAtomType]);
            glDrawElements(GL_TRIANGLES, numberOfIndicesInBuffer[currentAtomType], GL_UNSIGNED_SHORT, NULL);
            
            // Unbind the buffers
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
        }
    }
    
    if (shouldDrawBonds)
    {
        // Draw the cylinders
        [cylinderDepthProgram use];
        
        float cylinderScaleFactor = overallMoleculeScaleFactor * scaleFactor * bondRadiusScaleFactor;
        GLsizei bondVBOStride = sizeof(GLfloat) * 3 + sizeof(GLfloat) * 3 + sizeof(GLfloat) * 2 + sizeof(GLfloat) * 2;
        GLfloat bondRadius = 1.0;
        
        glUniform1f(cylinderDepthRadius, bondRadius * cylinderScaleFactor);
        glUniformMatrix3fv(cylinderDepthModelViewMatrix, 1, 0, depthModelViewMatrix);
        glUniform3fv(cylinderDepthTranslation, 1, modelTranslation);
        
        for (unsigned int currentBondVBOIndex = 0; currentBondVBOIndex < MAX_BOND_VBOS; currentBondVBOIndex++)
        {
            // Draw bonds next
            if (bondVertexBufferHandle[currentBondVBOIndex] != 0)
            {
                // Bind the VBO and attach it to the program
                glBindBuffer(GL_ARRAY_BUFFER, bondVertexBufferHandle[currentBondVBOIndex]);
                glVertexAttribPointer(cylinderDepthPositionAttribute, 3, GL_FLOAT, 0, bondVBOStride, (char *)NULL + 0);
                glVertexAttribPointer(cylinderDepthDirectionAttribute, 3, GL_FLOAT, 0, bondVBOStride, (char *)NULL + (sizeof(GLfloat) * 3));
                glVertexAttribPointer(cylinderDepthImpostorSpaceAttribute, 2, GL_FLOAT, 0, bondVBOStride, (char *)NULL + (sizeof(GLfloat) * 3) + (sizeof(GLfloat) * 3));
                
                // Bind the index buffer and draw to the screen
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, bondIndexBufferHandle[currentBondVBOIndex]);
                glDrawElements(GL_TRIANGLES, numberOfBondIndicesInBuffer[currentBondVBOIndex], GL_UNSIGNED_SHORT, NULL);
                
                // Unbind the buffers
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
                glBindBuffer(GL_ARRAY_BUFFER, 0);
            }
        }
    }
    
    glEnable(GL_BLEND);
    glDisable(GL_DEPTH_TEST);

//    const GLenum discards[]  = {GL_DEPTH_ATTACHMENT};
//    glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards);
}

- (void)writeDepthValuesForOpaqueAreasForModelViewMatrix:(GLfloat *)depthModelViewMatrix translation:(GLfloat *)modelTranslation scale:(GLfloat)scaleFactor;
{
    glDisable(GL_BLEND);
    
    // Draw the spheres
    [sphereDepthWriteProgram use];
    
    glUniformMatrix3fv(sphereDepthWriteModelViewMatrix, 1, 0, depthModelViewMatrix);
    glUniform3fv(sphereDepthWriteTranslation, 1, modelTranslation);
    
    float sphereScaleFactor = overallMoleculeScaleFactor * scaleFactor * atomRadiusScaleFactor;
    GLsizei atomVBOStride = sizeof(GLfloat) * 3 + sizeof(GLfloat) * 2 + sizeof(GLfloat) * 2;
    
    for (unsigned int currentAtomType = 0; currentAtomType < NUM_ATOMTYPES; currentAtomType++)
    {
        if (atomIndexBufferHandle[currentAtomType] != 0)
        {
            glUniform1f(sphereDepthWriteRadius, atomProperties[currentAtomType].atomRadius * sphereScaleFactor);
            
            // Bind the VBO and attach it to the program
            glBindBuffer(GL_ARRAY_BUFFER, atomVertexBufferHandles[currentAtomType]);
            glVertexAttribPointer(sphereDepthWritePositionAttribute, 3, GL_FLOAT, 0, atomVBOStride, (char *)NULL + 0);
            glVertexAttribPointer(sphereDepthWriteImpostorSpaceAttribute, 2, GL_FLOAT, 0, atomVBOStride, (char *)NULL + (sizeof(GLfloat) * 3));
            
            // Bind the index buffer and draw to the screen
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, atomIndexBufferHandle[currentAtomType]);
            glDrawElements(GL_TRIANGLES, numberOfIndicesInBuffer[currentAtomType], GL_UNSIGNED_SHORT, NULL);
            
            // Unbind the buffers
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
        }
    }
    
    glEnable(GL_BLEND);
}

- (void)renderRaytracedSceneForModelViewMatrix:(GLfloat *)raytracingModelViewMatrix inverseMatrix:(GLfloat *)inverseMatrix translation:(GLfloat *)modelTranslation scale:(GLfloat)scaleFactor;
{
    [self switchToDisplayFramebuffer];

#ifdef USEWHITEBACKGROUND
    glBlendEquation(GL_MIN_EXT);
    
    //    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    
#else
    glBlendEquation(GL_MAX_EXT);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
#endif
    
    
    glDisable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
    glDepthMask(GL_TRUE);
//
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//
//    glColorMask(0.0, 0.0, 0.0, 0.0);
//    [self writeDepthValuesForOpaqueAreasForModelViewMatrix:raytracingModelViewMatrix translation:modelTranslation scale:scaleFactor];
//    glColorMask(1.0, 1.0, 1.0, 1.0);
    
    //    glClear(GL_COLOR_BUFFER_BIT);
    //
    // Draw the spheres
    [sphereRaytracingProgram use];
    
    glUniform3fv(sphereRaytracingLightPosition, 1, lightDirection);
    
    // Load in the depth texture from the previous pass
    glUniform1i(sphereRaytracingDepthTexture, 0);
    glUniform1i(sphereRaytracingAOTexture, 1);
    glUniform1i(sphereRaytracingPrecalculatedAOLookupTexture, 2);
    
    glUniformMatrix3fv(sphereRaytracingModelViewMatrix, 1, 0, raytracingModelViewMatrix);
    glUniformMatrix3fv(sphereRaytracingInverseModelViewMatrix, 1, 0, inverseMatrix);
    glUniform1f(sphereRaytracingTexturePatchWidth, (normalizedAOTexturePatchWidth - 2.0 / (GLfloat)ambientOcclusionTextureWidth) * 0.5);
    glUniform3fv(sphereRaytracingTranslation, 1, modelTranslation);
    glUniform1i(sphereRaytracingDepthMapTexture, 3);
    
    float sphereScaleFactor = overallMoleculeScaleFactor * scaleFactor * atomRadiusScaleFactor;
    GLsizei atomVBOStride = sizeof(GLfloat) * 3 + sizeof(GLfloat) * 2 + sizeof(GLfloat) * 2;
    
    for (unsigned int currentAtomType = 0; currentAtomType < NUM_ATOMTYPES; currentAtomType++)
    {
        if (atomIndexBufferHandle[currentAtomType] != 0)
        {
            glUniform1f(sphereRaytracingRadius, atomProperties[currentAtomType].atomRadius * sphereScaleFactor);
            glUniform3f(sphereRaytracingColor, (GLfloat)atomProperties[currentAtomType].redComponent / 255.0f , (GLfloat)atomProperties[currentAtomType].greenComponent / 255.0f, (GLfloat)atomProperties[currentAtomType].blueComponent / 255.0f);
            
            // Bind the VBO and attach it to the program
            glBindBuffer(GL_ARRAY_BUFFER, atomVertexBufferHandles[currentAtomType]);
            glVertexAttribPointer(sphereRaytracingPositionAttribute, 3, GL_FLOAT, 0, atomVBOStride, (char *)NULL + 0);
            glVertexAttribPointer(sphereRaytracingImpostorSpaceAttribute, 2, GL_FLOAT, 0, atomVBOStride, (char *)NULL + (sizeof(GLfloat) * 3));
            glVertexAttribPointer(sphereRaytracingAOOffsetAttribute, 2, GL_FLOAT, 0, atomVBOStride, (char *)NULL + (sizeof(GLfloat) * 3) + (sizeof(GLfloat) * 2));
            
            // Bind the index buffer and draw to the screen
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, atomIndexBufferHandle[currentAtomType]);
            glDrawElements(GL_TRIANGLES, numberOfIndicesInBuffer[currentAtomType], GL_UNSIGNED_SHORT, NULL);
            
            // Unbind the buffers
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
        }
    }
    
    if (shouldDrawBonds)
    {
        // Draw the cylinders
        [cylinderRaytracingProgram use];
        
        glUniform3fv(cylinderRaytracingLightPosition, 1, lightDirection);
        glUniform1i(cylinderRaytracingDepthTexture, 0);
        glUniform1i(cylinderRaytracingAOTexture, 1);
        glUniform1f(cylinderRaytracingTexturePatchWidth, normalizedAOTexturePatchWidth - 0.5 / (GLfloat)ambientOcclusionTextureWidth);
        
        float cylinderScaleFactor = overallMoleculeScaleFactor * scaleFactor * bondRadiusScaleFactor;
        GLsizei bondVBOStride = sizeof(GLfloat) * 3 + sizeof(GLfloat) * 3 + sizeof(GLfloat) * 2 + sizeof(GLfloat) * 2;
        GLfloat bondRadius = 1.0;
        
        glUniform1f(cylinderRaytracingRadius, bondRadius * cylinderScaleFactor);
        glUniform3f(cylinderRaytracingColor, 0.75, 0.75, 0.75);
        glUniformMatrix3fv(cylinderRaytracingModelViewMatrix, 1, 0, raytracingModelViewMatrix);
        glUniformMatrix3fv(cylinderRaytracingInverseModelViewMatrix, 1, 0, inverseMatrix);
        glUniform3fv(cylinderRaytracingTranslation, 1, modelTranslation);
        
        
        for (unsigned int currentBondVBOIndex = 0; currentBondVBOIndex < MAX_BOND_VBOS; currentBondVBOIndex++)
        {
            // Draw bonds next
            if (bondVertexBufferHandle[currentBondVBOIndex] != 0)
            {
                
                // Bind the VBO and attach it to the program
                glBindBuffer(GL_ARRAY_BUFFER, bondVertexBufferHandle[currentBondVBOIndex]);
                glVertexAttribPointer(cylinderRaytracingPositionAttribute, 3, GL_FLOAT, 0, bondVBOStride, (char *)NULL + 0);
                glVertexAttribPointer(cylinderRaytracingDirectionAttribute, 3, GL_FLOAT, 0, bondVBOStride, (char *)NULL + (sizeof(GLfloat) * 3));
                glVertexAttribPointer(cylinderRaytracingImpostorSpaceAttribute, 2, GL_FLOAT, 0, bondVBOStride, (char *)NULL + (sizeof(GLfloat) * 3) + (sizeof(GLfloat) * 3));
                glVertexAttribPointer(cylinderRaytracingAOOffsetAttribute, 2, GL_FLOAT, 0, bondVBOStride, (char *)NULL + (sizeof(GLfloat) * 3) + (sizeof(GLfloat) * 3) + (sizeof(GLfloat) * 2));
                
                // Bind the index buffer and draw to the screen
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, bondIndexBufferHandle[currentBondVBOIndex]);
                glDrawElements(GL_TRIANGLES, numberOfBondIndicesInBuffer[currentBondVBOIndex], GL_UNSIGNED_SHORT, NULL);
                
                // Unbind the buffers
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
                glBindBuffer(GL_ARRAY_BUFFER, 0);
            }
        }
    }
    
    glDepthMask(GL_FALSE);
    glEnable(GL_BLEND);    
}

- (void)renderAmbientOcclusionTextureForModelViewMatrix:(GLfloat *)ambientOcclusionModelViewMatrix inverseMatrix:(GLfloat *)inverseMatrix fractionOfTotal:(GLfloat)fractionOfTotal;
{
    [self switchToAmbientOcclusionFramebuffer];
    
    glBlendEquation(GL_FUNC_ADD);
    
    float sphereScaleFactor = overallMoleculeScaleFactor * currentModelScaleFactor * atomRadiusScaleFactor;
    GLsizei atomVBOStride = sizeof(GLfloat) * 3 + sizeof(GLfloat) * 2 + sizeof(GLfloat) * 2;
    
    // Draw the spheres
    [sphereAmbientOcclusionProgram use];
    
    glUniformMatrix3fv(sphereAmbientOcclusionInverseModelViewMatrix, 1, 0, inverseMatrix);
    
    glUniform1i(sphereAmbientOcclusionDepthTexture, 0);
    
    glUniformMatrix3fv(sphereAmbientOcclusionModelViewMatrix, 1, 0, ambientOcclusionModelViewMatrix);
    glUniform1f(sphereAmbientOcclusionTexturePatchWidth, normalizedAOTexturePatchWidth);
    glUniform1f(sphereAmbientOcclusionIntensityFactor, fractionOfTotal);
    
    for (unsigned int currentAtomType = 0; currentAtomType < NUM_ATOMTYPES; currentAtomType++)
    {
        if (atomIndexBufferHandle[currentAtomType] != 0)
        {
            glUniform1f(sphereAmbientOcclusionRadius, atomProperties[currentAtomType].atomRadius * sphereScaleFactor);
            
            // Bind the VBO and attach it to the program
            glBindBuffer(GL_ARRAY_BUFFER, atomVertexBufferHandles[currentAtomType]);
            glVertexAttribPointer(sphereAmbientOcclusionPositionAttribute, 3, GL_FLOAT, 0, atomVBOStride, (char *)NULL + 0);
            glVertexAttribPointer(sphereAmbientOcclusionImpostorSpaceAttribute, 2, GL_FLOAT, 0, atomVBOStride, (char *)NULL + (sizeof(GLfloat) * 3));
            glVertexAttribPointer(sphereAmbientOcclusionAOOffsetAttribute, 2, GL_FLOAT, 0, atomVBOStride, (char *)NULL + (sizeof(GLfloat) * 3) + (sizeof(GLfloat) * 2));
            
            // Bind the index buffer and draw to the screen
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, atomIndexBufferHandle[currentAtomType]);
            glDrawElements(GL_TRIANGLES, numberOfIndicesInBuffer[currentAtomType], GL_UNSIGNED_SHORT, NULL);
            
            // Unbind the buffers
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
        }
    }
    
    
    // Draw the cylinders
    [cylinderAmbientOcclusionProgram use];
    
    glUniformMatrix3fv(cylinderAmbientOcclusionInverseModelViewMatrix, 1, 0, inverseMatrix);
    
    glUniform1i(cylinderAmbientOcclusionDepthTexture, 0);
    
    float cylinderScaleFactor = overallMoleculeScaleFactor * currentModelScaleFactor * bondRadiusScaleFactor;
    GLsizei bondVBOStride = sizeof(GLfloat) * 3 + sizeof(GLfloat) * 3 + sizeof(GLfloat) * 2 + sizeof(GLfloat) * 2;
	GLfloat bondRadius = 1.0;
    
    glUniform1f(cylinderAmbientOcclusionRadius, bondRadius * cylinderScaleFactor);
    glUniformMatrix3fv(cylinderAmbientOcclusionModelViewMatrix, 1, 0, ambientOcclusionModelViewMatrix);
    glUniform1f(cylinderAmbientOcclusionTexturePatchWidth, normalizedAOTexturePatchWidth);
    glUniform1f(cylinderAmbientOcclusionIntensityFactor, fractionOfTotal);
    
    for (unsigned int currentBondVBOIndex = 0; currentBondVBOIndex < MAX_BOND_VBOS; currentBondVBOIndex++)
    {
        // Draw bonds next
        if (bondVertexBufferHandle[currentBondVBOIndex] != 0)
        {
            // Bind the VBO and attach it to the program
            glBindBuffer(GL_ARRAY_BUFFER, bondVertexBufferHandle[currentBondVBOIndex]);
            glVertexAttribPointer(cylinderAmbientOcclusionPositionAttribute, 3, GL_FLOAT, 0, bondVBOStride, (char *)NULL + 0);
            glVertexAttribPointer(cylinderAmbientOcclusionDirectionAttribute, 3, GL_FLOAT, 0, bondVBOStride, (char *)NULL + (sizeof(GLfloat) * 3));
            glVertexAttribPointer(cylinderAmbientOcclusionImpostorSpaceAttribute, 2, GL_FLOAT, 0, bondVBOStride, (char *)NULL + (sizeof(GLfloat) * 3) + (sizeof(GLfloat) * 3));
            glVertexAttribPointer(cylinderAmbientOcclusionAOOffsetAttribute, 2, GL_FLOAT, 0, bondVBOStride, (char *)NULL + (sizeof(GLfloat) * 3) + (sizeof(GLfloat) * 3) + (sizeof(GLfloat) * 2));
            
            // Bind the index buffer and draw to the screen
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, bondIndexBufferHandle[currentBondVBOIndex]);
            glDrawElements(GL_TRIANGLES, numberOfBondIndicesInBuffer[currentBondVBOIndex], GL_UNSIGNED_SHORT, NULL);
            
            // Unbind the buffers
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
        }
    }
}

/*
 #define AMBIENTOCCLUSIONSAMPLINGPOINTS 6
 
 static float ambientOcclusionRotationAngles[AMBIENTOCCLUSIONSAMPLINGPOINTS][2] =
 {
 {0.0, 0.0},
 {M_PI / 2.0, 0.0},
 {M_PI, 0.0},
 {3.0 * M_PI / 2.0, 0.0},
 {0.0, M_PI / 2.0},
 {0.0, 3.0 * M_PI / 2.0}
 };
 
 */

/*
 #define AMBIENTOCCLUSIONSAMPLINGPOINTS 14
 
 static float ambientOcclusionRotationAngles[AMBIENTOCCLUSIONSAMPLINGPOINTS][2] =
 {
 {0.0, 0.0},
 {M_PI / 2.0, 0.0},
 {M_PI, 0.0},
 {3.0 * M_PI / 2.0, 0.0},
 {0.0, M_PI / 2.0},
 {0.0, 3.0 * M_PI / 2.0},
 
 {M_PI / 4.0, M_PI / 4.0},
 {3.0 * M_PI / 4.0, M_PI / 4.0},
 {5.0 * M_PI / 4.0, M_PI / 4.0},
 {7.0 * M_PI / 4.0, M_PI / 4.0},
 
 {M_PI / 4.0, 7.0 * M_PI / 4.0},
 {3.0 * M_PI / 4.0, 7.0 * M_PI / 4.0},
 {5.0 * M_PI / 4.0, 7.0 * M_PI / 4.0},
 {7.0 * M_PI / 4.0, 7.0 * M_PI / 4.0},
 };
 */

#define AMBIENTOCCLUSIONSAMPLINGPOINTS 22

static float ambientOcclusionRotationAngles[AMBIENTOCCLUSIONSAMPLINGPOINTS][2] =
{
    {0.0, 0.0},
    {M_PI / 2.0, 0.0},
    {M_PI, 0.0},
    {3.0 * M_PI / 2.0, 0.0},
    {0.0, M_PI / 2.0},
    {0.0, 3.0 * M_PI / 2.0},
    
    {M_PI / 4.0, M_PI / 4.0},
    {3.0 * M_PI / 4.0, M_PI / 4.0},
    {5.0 * M_PI / 4.0, M_PI / 4.0},
    {7.0 * M_PI / 4.0, M_PI / 4.0},
    
    {M_PI / 4.0, 7.0 * M_PI / 4.0},
    {3.0 * M_PI / 4.0, 7.0 * M_PI / 4.0},
    {5.0 * M_PI / 4.0, 7.0 * M_PI / 4.0},
    {7.0 * M_PI / 4.0, 7.0 * M_PI / 4.0},
    
    {M_PI / 4.0, 0.0},
    {3.0 * M_PI / 4.0, 0.0},
    {5.0 * M_PI / 4.0, 0.0},
    {7.0 * M_PI / 4.0, 0.0},
    
    {0.0, M_PI / 4.0},
    {0.0, 3.0 * M_PI / 4.0},
    {0.0, 5.0 * M_PI / 4.0},
    {0.0, 7.0 * M_PI / 4.0},
};

/*
 #define AMBIENTOCCLUSIONSAMPLINGPOINTS 1
 
 static float ambientOcclusionRotationAngles[AMBIENTOCCLUSIONSAMPLINGPOINTS][2] =
 {
 {0.0, 0.0},
 };
 */

- (void)prepareAmbientOcclusionMapForMolecule:(SLSMolecule *)molecule;
{
    dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_FOREVER);
    
    dispatch_sync(openGLESContextQueue, ^{
        
//        CFAbsoluteTime elapsedTime, startTime = CFAbsoluteTimeGetCurrent();

        [[self openGLContext] makeCurrentContext];
        [self loadOrthoMatrix:orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) top:(1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) near:-1.0 far:1.0];
        
        if (isRenderingCancelled)
        {
            dispatch_semaphore_signal(frameRenderingSemaphore);
            return;
        }
        
        // Use bilinear filtering here to smooth out the ambient occlusion shadowing
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, depthPassTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
        
        GLfloat zeroTranslation[3] = {0.0, 0.0, 0.0};
        
        
        //        CFTimeInterval previousTimestamp = CFAbsoluteTimeGetCurrent();
        
        // Start fresh on the ambient texture
        [self switchToAmbientOcclusionFramebuffer];
        
        BOOL disableAOTextureGeneration = NO;
        
        if (disableAOTextureGeneration)
        {
            glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
        }
        else
        {
            //    glClearColor(0.0f, ambientOcclusionModelViewMatrix[0], 1.0f, 1.0f);
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            
            CATransform3D currentSamplingRotationMatrix;
            GLfloat currentModelViewMatrix[9];
            CATransform3D inverseMatrix;
            GLfloat inverseModelViewMatrix[9];
            
            for (unsigned int currentAOSamplingPoint = 0; currentAOSamplingPoint < AMBIENTOCCLUSIONSAMPLINGPOINTS; currentAOSamplingPoint++)
            {
                if (isRenderingCancelled)
                {
                    dispatch_semaphore_signal(frameRenderingSemaphore);
                    return;
                }
                
                float theta = ambientOcclusionRotationAngles[currentAOSamplingPoint][0];
                float phi = ambientOcclusionRotationAngles[currentAOSamplingPoint][1];
                
                currentSamplingRotationMatrix = CATransform3DMakeRotation(theta, 1.0, 0.0, 0.0);
                currentSamplingRotationMatrix = CATransform3DRotate(currentSamplingRotationMatrix, phi, 0.0, 1.0, 0.0);
                
                inverseMatrix = CATransform3DInvert(currentSamplingRotationMatrix);
                
                [self convert3DTransform:&inverseMatrix to3x3Matrix:inverseModelViewMatrix];
                [self convert3DTransform:&currentSamplingRotationMatrix to3x3Matrix:currentModelViewMatrix];
                
                [self renderDepthTextureForModelViewMatrix:currentModelViewMatrix translation:zeroTranslation scale:1.0];
                [self renderAmbientOcclusionTextureForModelViewMatrix:currentModelViewMatrix inverseMatrix:inverseModelViewMatrix fractionOfTotal:(0.5 / (GLfloat)AMBIENTOCCLUSIONSAMPLINGPOINTS)];
                //        [self renderAmbientOcclusionTextureForModelViewMatrix:currentModelViewMatrix inverseMatrix:inverseModelViewMatrix fractionOfTotal:(1.0 / (GLfloat)AMBIENTOCCLUSIONSAMPLINGPOINTS)];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [molecule.renderingDelegate renderingUpdated:((float)currentAOSamplingPoint * 2.0) / ((float)AMBIENTOCCLUSIONSAMPLINGPOINTS * 2.0)];
                });
                
                theta = theta + M_PI / 8.0;
                phi = phi + M_PI / 8.0;
                
                currentSamplingRotationMatrix = CATransform3DMakeRotation(theta, 1.0, 0.0, 0.0);
                currentSamplingRotationMatrix = CATransform3DRotate(currentSamplingRotationMatrix, phi, 0.0, 1.0, 0.0);
                
                inverseMatrix = CATransform3DInvert(currentSamplingRotationMatrix);
                
                [self convert3DTransform:&inverseMatrix to3x3Matrix:inverseModelViewMatrix];
                [self convert3DTransform:&currentSamplingRotationMatrix to3x3Matrix:currentModelViewMatrix];
                
                [self renderDepthTextureForModelViewMatrix:currentModelViewMatrix translation:zeroTranslation scale:1.0];
                [self renderAmbientOcclusionTextureForModelViewMatrix:currentModelViewMatrix inverseMatrix:inverseModelViewMatrix fractionOfTotal:(1.5 / (GLfloat)AMBIENTOCCLUSIONSAMPLINGPOINTS)];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [molecule.renderingDelegate renderingUpdated:((float)currentAOSamplingPoint * 2.0 + 1.0) / ((float)AMBIENTOCCLUSIONSAMPLINGPOINTS * 2.0)];
                });
            }
            
//            CFTimeInterval frameDuration = CFAbsoluteTimeGetCurrent() - startTime;
//
//            NSLog(@"Ambient occlusion calculation duration: %f s", frameDuration);
        }
        
        // Reset depth texture to nearest filtering to prevent some border transparency artifacts
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, depthPassTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );

        [self loadOrthoMatrix:orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) top:(1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) near:-4.0 far:4.0];

//        elapsedTime = CFAbsoluteTimeGetCurrent() - startTime;
//        NSLog(@"Total AO time: %f", elapsedTime);

        dispatch_semaphore_signal(frameRenderingSemaphore);
    });
}

- (void)precalculateAOLookupTextureForInverseMatrix:(GLfloat *)inverseMatrix;
{
    [self switchToAOLookupFramebuffer];
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
    glBlendEquation(GL_MAX_EXT);
    
    //    glBlendEquation(GL_FUNC_ADD);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Draw the spheres
    [sphereAOLookupPrecalculationProgram use];
    
    glUniformMatrix3fv(sphereAOLookupInverseModelViewMatrix, 1, 0, inverseMatrix);
    
    static const GLfloat textureCoordinates[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
	glVertexAttribPointer(sphereAOLookupImpostorSpaceAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glEnable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
}

- (void)displayTextureToScreen:(GLuint)textureToDisplay;
{
    [self switchToDisplayFramebuffer];
    glDisable(GL_DEPTH_TEST);
    glBlendEquation(GL_MAX_EXT);
    glDepthMask(GL_FALSE);
    glEnable(GL_BLEND);
    
    [passthroughProgram use];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat textureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f,  1.0f,
        1.0f,  1.0f,
    };
    
	glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, textureToDisplay);
	glUniform1i(passthroughTexture, 4);
    
    glVertexAttribPointer(passthroughPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
	glVertexAttribPointer(passthroughTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glEnable(GL_DEPTH_TEST);
}

#pragma mark -
#pragma mark Accessors

@synthesize openGLContext;
@synthesize isFrameRenderingFinished, isSceneReady;
@synthesize totalNumberOfVertices, totalNumberOfTriangles;
@synthesize atomRadiusScaleFactor, bondRadiusScaleFactor, overallMoleculeScaleFactor;
@synthesize openGLESContextQueue;

@end
