#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>

#import "SLSMolecule.h"

#define ENABLETEXTUREDISPLAYDEBUGGING 1

extern NSString *const kSLSMoleculeShadowCalculationStartedNotification;
extern NSString *const kSLSMoleculeShadowCalculationUpdateNotification;
extern NSString *const kSLSMoleculeShadowCalculationEndedNotification;

@class GLProgram;

#define MAX_BOND_VBOS 2

// OpenGL helper functions
void normalize(GLfloat *v);

typedef struct { 
    GLubyte redComponent;
    GLubyte greenComponent;
    GLubyte blueComponent;
    GLfloat atomRadius; 
} SLSAtomProperties;

// van der Waals radius used here
// http://www.umass.edu/microbio/rasmol/rasbonds.htm

static const SLSAtomProperties atomProperties[NUM_ATOMTYPES] = {
    {120, 120, 120, 1.55f}, // CARBON
    {230, 230, 230, 1.10f}, // HYDROGEN
    {240,  40,  40, 1.35f}, // OXYGEN
    { 48,  80, 248, 1.40f}, // NITROGEN
    {255, 255,  48, 1.81f}, // SULFUR
    {255, 128,   0, 1.88f}, // PHOSPHOROUS
    {224, 102,  51, 1.95f}, // IRON
    {  0, 255,   0, 1.50f}, // UNKNOWN
    {200, 200,  90, 1.50f}, // SILICON
    {144, 224,  80, 1.47f}, // FLUORINE
    { 31, 240,  31, 1.75f}, // CHLORINE
    {166,  41,  41, 1.85f}, // BROMINE
    {148,   0, 148, 1.75f}, // IODINE
    { 61, 255,   0, 1.95f}, // CALCIUM
    {125, 128, 176, 1.15f}, // ZINC
    {255, 217, 143, 1.75f}, // CADMIUM
    {171,  92, 242, 1.02f}, // SODIUM
    {138, 255,   0, 0.72f}, // MAGNESIUM
};

@interface SLSOpenGLRenderer : NSObject 
{
 	GLint backingWidth;
	GLint backingHeight;
	
    CATransform3D currentCalculatedMatrix;
	BOOL isFirstDrawingOfMolecule, isFrameRenderingFinished, isSceneReady, isRenderingCancelled;

    float atomRadiusScaleFactor, bondRadiusScaleFactor, overallMoleculeScaleFactor;
    float currentModelScaleFactor;
    
	NSOpenGLContext *openGLContext;
    
    GLuint viewRenderbuffer, viewFramebuffer, viewDepthBuffer;	
    
	// OpenGL performance tuning statistics
	NSInteger totalNumberOfVertices, totalNumberOfTriangles;
    
    // Binned atom types
    // 16384 atoms per indexed VBO per atom type
    // 16384 bonds per indexed VBO
    NSMutableData *atomVBOs[NUM_ATOMTYPES], *atomIndexBuffers[NUM_ATOMTYPES];
    GLuint atomVertexBufferHandles[NUM_ATOMTYPES], atomIndexBufferHandle[NUM_ATOMTYPES], numberOfIndicesInBuffer[NUM_ATOMTYPES];
    GLuint bondVertexBufferHandle[MAX_BOND_VBOS], bondIndexBufferHandle[MAX_BOND_VBOS], numberOfBondIndicesInBuffer[MAX_BOND_VBOS];
    unsigned int numberOfAtomVertices[NUM_ATOMTYPES], numberOfBondVertices[MAX_BOND_VBOS], numberOfAtomIndices[NUM_ATOMTYPES], numberOfBondIndices[MAX_BOND_VBOS];

    NSMutableData *bondVBOs[MAX_BOND_VBOS], *bondIndexBuffers[MAX_BOND_VBOS];
    unsigned int currentBondVBO, currentAtomVBO;
    
    dispatch_queue_t openGLESContextQueue;
    dispatch_semaphore_t frameRenderingSemaphore;
    
    GLProgram *sphereDepthWriteProgram;
	GLint sphereDepthWritePositionAttribute, sphereDepthWriteImpostorSpaceAttribute, sphereDepthWriteModelViewMatrix;
    GLint sphereDepthWriteRadius, sphereDepthWriteOrthographicMatrix, sphereDepthWriteTranslation;
    
    GLProgram *sphereDepthProgram;
	GLint sphereDepthPositionAttribute, sphereDepthImpostorSpaceAttribute, sphereDepthModelViewMatrix;
    GLint sphereDepthRadius, sphereDepthOrthographicMatrix, sphereDepthTranslation, sphereDepthMapTexture;
    GLint sphereDepthPrecalculatedDepthTexture;
    
    GLProgram *cylinderDepthProgram;
    GLint cylinderDepthPositionAttribute, cylinderDepthDirectionAttribute, cylinderDepthImpostorSpaceAttribute, cylinderDepthModelViewMatrix, cylinderDepthTranslation;
    GLint cylinderDepthRadius, cylinderDepthOrthographicMatrix;
    
    GLuint depthPassTexture;
    GLuint depthPassFramebuffer, depthPassDepthBuffer;
    
    GLProgram *sphereRaytracingProgram;
	GLint sphereRaytracingPositionAttribute, sphereRaytracingImpostorSpaceAttribute, sphereRaytracingAOOffsetAttribute, sphereRaytracingModelViewMatrix;
    GLint sphereRaytracingLightPosition, sphereRaytracingRadius, sphereRaytracingColor, sphereRaytracingOrthographicMatrix, sphereRaytracingInverseModelViewMatrix, sphereRaytracingTranslation;
    GLint sphereRaytracingDepthTexture, sphereRaytracingPrecalculatedDepthTexture, sphereRaytracingAOTexture, sphereRaytracingTexturePatchWidth, sphereRaytracingPrecalculatedAOLookupTexture, sphereRaytracingDepthMapTexture;
    
	GLProgram *cylinderRaytracingProgram;
    GLint cylinderRaytracingPositionAttribute, cylinderRaytracingDirectionAttribute, cylinderRaytracingImpostorSpaceAttribute, cylinderRaytracingAOOffsetAttribute, cylinderRaytracingModelViewMatrix, cylinderRaytracingTranslation;
    GLint cylinderRaytracingLightPosition, cylinderRaytracingRadius, cylinderRaytracingColor, cylinderRaytracingOrthographicMatrix;
    GLint cylinderRaytracingDepthTexture, cylinderRaytracingInverseModelViewMatrix, cylinderRaytracingAOTexture, cylinderRaytracingTexturePatchWidth;
    
    GLProgram *sphereAmbientOcclusionProgram;
	GLint sphereAmbientOcclusionPositionAttribute, sphereAmbientOcclusionImpostorSpaceAttribute, sphereAmbientOcclusionAOOffsetAttribute, sphereAmbientOcclusionModelViewMatrix;
    GLint sphereAmbientOcclusionRadius, sphereAmbientOcclusionOrthographicMatrix, sphereAmbientOcclusionInverseModelViewMatrix, sphereAmbientOcclusionTexturePatchWidth, sphereAmbientOcclusionIntensityFactor;
    GLint sphereAmbientOcclusionDepthTexture, sphereAmbientOcclusionPrecalculatedDepthTexture;
    
    GLProgram *cylinderAmbientOcclusionProgram;
    GLint cylinderAmbientOcclusionPositionAttribute, cylinderAmbientOcclusionDirectionAttribute, cylinderAmbientOcclusionImpostorSpaceAttribute, cylinderAmbientOcclusionAOOffsetAttribute, cylinderAmbientOcclusionModelViewMatrix;
    GLint cylinderAmbientOcclusionRadius, cylinderAmbientOcclusionOrthographicMatrix, cylinderAmbientOcclusionInverseModelViewMatrix, cylinderAmbientOcclusionTexturePatchWidth, cylinderAmbientOcclusionIntensityFactor;
    GLint cylinderAmbientOcclusionDepthTexture;
    
    GLProgram *sphereAOLookupPrecalculationProgram;
	GLint sphereAOLookupImpostorSpaceAttribute, sphereAOLookupInverseModelViewMatrix;
    GLint sphereAOLookupPrecalculatedDepthTexture;
    
    GLuint sphereAOLookupTexture;
    GLuint sphereAOLookupFramebuffer;
    
#ifdef ENABLETEXTUREDISPLAYDEBUGGING
    GLProgram *passthroughProgram;
    GLint passthroughPositionAttribute, passthroughTextureCoordinateAttribute;
    GLint passthroughTexture;
#endif
    
    GLuint ambientOcclusionTexture;
    GLuint ambientOcclusionFramebuffer;
    
    GLuint sphereDepthMappingTexture;
    
    GLfloat previousAmbientOcclusionOffset[2];
    GLfloat lightDirection[3];
    GLfloat orthographicMatrix[9];
    GLfloat accumulatedModelTranslation[3];
    
    CGSize currentViewportSize;
    
    unsigned int widthOfAtomAOTexturePatch;
    GLfloat normalizedAOTexturePatchWidth;
    
    unsigned int ambientOcclusionTextureWidth, ambientOcclusionLookupTextureWidth, sphereDepthTextureWidth;
    
    BOOL shouldDrawBonds;
}

@property(readwrite, strong, nonatomic) NSOpenGLContext *openGLContext;
@property(readonly) BOOL isFrameRenderingFinished, isSceneReady;
@property(readonly) NSInteger totalNumberOfVertices, totalNumberOfTriangles;
@property(readwrite, nonatomic) float atomRadiusScaleFactor, bondRadiusScaleFactor, overallMoleculeScaleFactor;
@property(readonly) dispatch_queue_t openGLESContextQueue;

// Initialization and teardown
- (id)initWithContext:(NSOpenGLContext *)newContext;

// OpenGL matrix helper methods
- (void)convertMatrix:(GLfloat *)matrix to3DTransform:(CATransform3D *)transform3D;
- (void)convert3DTransform:(CATransform3D *)transform3D toMatrix:(GLfloat *)matrix;
- (void)convert3DTransform:(CATransform3D *)transform3D to3x3Matrix:(GLfloat *)matrix;
- (void)print3DTransform:(CATransform3D *)transform3D;
- (void)printMatrix:(GLfloat *)fixedPointMatrix;
- (void)apply3DTransform:(CATransform3D *)transform3D toPoint:(GLfloat *)sourcePoint result:(GLfloat *)resultingPoint;

// Model manipulation
- (void)rotateModelFromScreenDisplacementInX:(float)xRotation inY:(float)yRotation;
- (void)scaleModelByFactor:(float)scaleFactor;
- (void)translateModelByScreenDisplacementInX:(float)xTranslation inY:(float)yTranslation;
- (void)resetModelViewMatrix;

// OpenGL drawing support
- (BOOL)createFramebuffersForView:(NSView *)glView;
- (void)destroyFramebuffers;
- (void)resizeFramebuffersToMatchView:(NSView *)glView;
- (void)clearScreen;
- (void)configureProjection;
- (void)presentRenderBuffer;
- (void)suspendRenderingDuringRotation;
- (void)resumeRenderingDuringRotation;

// Actual OpenGL rendering
- (void)renderFrameForMolecule:(SLSMolecule *)molecule;

// Molecule 3-D geometry generation
- (void)configureBasedOnNumberOfAtoms:(unsigned int)numberOfAtoms numberOfBonds:(unsigned int)numberOfBonds;
- (void)addVertex:(GLfloat *)newVertex forAtomType:(SLSAtomType)atomType;
- (void)addIndex:(GLushort *)newIndex forAtomType:(SLSAtomType)atomType;
- (void)addIndices:(GLushort *)newIndices size:(unsigned int)numIndices forAtomType:(SLSAtomType)atomType;
- (void)addBondVertex:(GLfloat *)newVertex;
- (void)addBondIndex:(GLushort *)newIndex;
- (void)addBondIndices:(GLushort *)newIndices size:(unsigned int)numIndices;
- (void)addAtomToVertexBuffers:(SLSAtomType)atomType atPoint:(SLS3DPoint)newPoint;
- (void)addBondToVertexBuffersWithStartPoint:(SLS3DPoint)startPoint endPoint:(SLS3DPoint)endPoint bondColor:(GLubyte *)bondColor bondType:(SLSBondType)bondType;

// OpenGL drawing routines
- (void)bindVertexBuffersForMolecule:(SLSMolecule *)molecule;
- (void)drawMolecule;
- (void)freeVertexBuffers;
- (void)initiateMoleculeRendering;
- (void)terminateMoleculeRendering;
- (void)cancelMoleculeRendering;
- (void)waitForLastFrameToFinishRendering;

// OpenGL drawing support
- (void)initializeDepthShaders;
- (void)initializeAmbientOcclusionShaders;
- (void)initializeRaytracingShaders;
- (void)loadOrthoMatrix:(GLfloat *)matrix left:(GLfloat)left right:(GLfloat)right bottom:(GLfloat)bottom top:(GLfloat)top near:(GLfloat)near far:(GLfloat)far;
- (BOOL)createFramebuffer:(GLuint *)framebufferPointer size:(CGSize)bufferSize renderBuffer:(GLuint *)renderbufferPointer depthBuffer:(GLuint *)depthbufferPointer texture:(GLuint *)backingTexturePointer;
- (void)switchToDisplayFramebuffer;
- (void)switchToDepthPassFramebuffer;
- (void)switchToAmbientOcclusionFramebuffer;
- (void)switchToAOLookupFramebuffer;
- (void)generateSphereDepthMapTexture;

// Molecule 3-D geometry generation
- (void)addTextureCoordinate:(GLfloat *)newTextureCoordinate forAtomType:(SLSAtomType)atomType;
- (void)addAmbientOcclusionTextureOffset:(GLfloat *)ambientOcclusionOffset forAtomType:(SLSAtomType)atomType;
- (void)addBondDirection:(GLfloat *)newDirection;
- (void)addBondTextureCoordinate:(GLfloat *)newTextureCoordinate;
- (void)addBondAmbientOcclusionTextureOffset:(GLfloat *)ambientOcclusionOffset;

// OpenGL drawing routines
- (void)renderDepthTextureForModelViewMatrix:(GLfloat *)depthModelViewMatrix translation:(GLfloat *)modelTranslation scale:(GLfloat)scaleFactor;
- (void)writeDepthValuesForOpaqueAreasForModelViewMatrix:(GLfloat *)depthModelViewMatrix translation:(GLfloat *)modelTranslation scale:(GLfloat)scaleFactor;
- (void)renderRaytracedSceneForModelViewMatrix:(GLfloat *)raytracingModelViewMatrix inverseMatrix:(GLfloat *)inverseMatrix translation:(GLfloat *)modelTranslation scale:(GLfloat)scaleFactor;
- (void)renderAmbientOcclusionTextureForModelViewMatrix:(GLfloat *)ambientOcclusionModelViewMatrix inverseMatrix:(GLfloat *)inverseMatrix fractionOfTotal:(GLfloat)fractionOfTotal;
- (void)prepareAmbientOcclusionMapForMolecule:(SLSMolecule *)molecule;
- (void)precalculateAOLookupTextureForInverseMatrix:(GLfloat *)inverseMatrix;
- (void)displayTextureToScreen:(GLuint)textureToDisplay;


@end
