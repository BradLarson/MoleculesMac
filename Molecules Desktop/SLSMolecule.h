//
//  SLSMolecule.h
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/26/2008.
//
//  This is the model class for the molecule object.  It parses a PDB file, generates a vertex buffer object, and renders that object to the screen

#import <Foundation/Foundation.h>

@class SLSOpenGLRenderer;

// TODO: Convert enum to elemental number
typedef enum { CARBON, HYDROGEN, OXYGEN, NITROGEN, SULFUR, PHOSPHOROUS, IRON, UNKNOWN, SILICON, FLUORINE, CHLORINE, BROMINE, IODINE, CALCIUM, ZINC, CADMIUM, SODIUM, MAGNESIUM, NUM_ATOMTYPES } SLSAtomType;
typedef enum { BALLANDSTICK, SPACEFILLING, CYLINDRICAL, } SLSVisualizationType;
typedef enum { UNKNOWNRESIDUE, DEOXYADENINE, DEOXYCYTOSINE, DEOXYGUANINE, DEOXYTHYMINE, ADENINE, CYTOSINE, GUANINE, URACIL, GLYCINE, ALANINE, VALINE, 
				LEUCINE, ISOLEUCINE, SERINE, CYSTEINE, THREONINE, METHIONINE, PROLINE, PHENYLALANINE, TYROSINE, TRYPTOPHAN, HISTIDINE,
				LYSINE, ARGININE, ASPARTICACID, GLUTAMICACID, ASPARAGINE, GLUTAMINE, WATER, NUM_RESIDUETYPES } SLSResidueType;
typedef enum { MOLECULESOURCE, MOLECULEAUTHOR, JOURNALAUTHOR, JOURNALTITLE, JOURNALREFERENCE, MOLECULESEQUENCE } SLSMetadataType;
typedef enum { SINGLEBOND, DOUBLEBOND, TRIPLEBOND } SLSBondType;

typedef struct { 
	GLfloat x; 
	GLfloat y; 
	GLfloat z; 
} SLS3DPoint;

typedef struct {
	SLSAtomType atomType;
	SLS3DPoint center;
    NSInteger structureNumber;
    SLSResidueType residueKey;
} SLSAtomContainer;

typedef struct {
	SLS3DPoint startPoint;
	SLS3DPoint endPoint;
    SLSBondType bondType;
    NSInteger structureNumber;
    SLSResidueType residueKey;
} SLSBondContainer;


@protocol SLSMoleculeRenderingDelegate <NSObject>
- (void)renderingStarted;
- (void)renderingUpdated:(CGFloat)renderingProgress;
- (void)renderingEnded;
@end

@interface SLSMolecule : NSObject 
{
	// Metadata from the Protein Data Bank
	unsigned int numberOfAtoms, numberOfBonds, numberOfStructures;
	NSString *filename, *filenameWithoutExtension, *title, *keywords, *journalAuthor, *journalTitle, *journalReference, *sequence, *compound, *source, *author;

	// Status of the molecule
	BOOL isBeingDisplayed, isDoneRendering, isRenderingCancelled;
	SLSVisualizationType currentVisualizationType;
	unsigned int numberOfStructureBeingDisplayed;
	unsigned int totalNumberOfFeaturesToRender, currentFeatureBeingRendered;
	BOOL stillCountingAtomsInFirstStructure;

	// A holder for rendering connecting bonds
	NSValue *previousTerminalAtomValue;
	BOOL reverseChainDirection;
		
    // Molecule properties for scaling and translation
	float centerOfMassInX, centerOfMassInY, centerOfMassInZ;
	float minimumXPosition, maximumXPosition, minimumYPosition, maximumYPosition, minimumZPosition, maximumZPosition;
	float scaleAdjustmentForX, scaleAdjustmentForY, scaleAdjustmentForZ;

    NSMutableArray *atomArray, *bondArray;
    BOOL _elementsPresentInMolecule[NUM_ATOMTYPES];
    
    SLSOpenGLRenderer *currentRenderer;
}

@property (readonly) float centerOfMassInX, centerOfMassInY, centerOfMassInZ;
@property (readonly) NSString *filename, *filenameWithoutExtension, *title, *keywords, *journalAuthor, *journalTitle, *journalReference, *sequence, *compound, *source, *author;
@property (readwrite, nonatomic) BOOL isBeingDisplayed, isRenderingCancelled;
@property (readonly) BOOL isDoneRendering;
@property (readonly) unsigned int numberOfAtoms, numberOfBonds, numberOfStructures;
@property (readwrite, strong) NSValue *previousTerminalAtomValue;
@property (readwrite, nonatomic) SLSVisualizationType currentVisualizationType;
@property (readwrite) unsigned int numberOfStructureBeingDisplayed;
@property (readwrite, unsafe_unretained) id<SLSMoleculeRenderingDelegate> renderingDelegate;

- (id)initWithData:(NSData *)fileData extension:(NSString *)fileExtension renderingDelegate:(id<SLSMoleculeRenderingDelegate>)newRenderingDelegate;

+ (BOOL)isFiletypeSupportedForFile:(NSString *)filePath;
+ (void)setBondColor:(GLubyte *)bondColor forResidueType:(SLSResidueType)residueType;

// Database methods
- (void)addMetadataToDatabase:(NSString *)metadata type:(SLSMetadataType)metadataType;
- (NSInteger)addAtomToDatabase:(SLSAtomType)atomType atPoint:(SLS3DPoint)newPoint structureNumber:(NSInteger)structureNumber residueKey:(SLSResidueType)residueKey;
- (void)addBondToDatabaseWithStartPoint:(NSValue *)startValue endPoint:(NSValue *)endValue bondType:(SLSBondType)bondType structureNumber:(NSInteger)structureNumber residueKey:(NSInteger)residueKey;
- (BOOL *)elementsPresentInMolecule;

// Status notification methods
- (void)showStatusIndicator;
- (void)updateStatusIndicator;
- (void)hideStatusIndicator;

// Rendering
- (void)switchToDefaultVisualizationMode;
- (BOOL)renderMolecule:(SLSOpenGLRenderer *)openGLRenderer;
- (void)readAndRenderAtoms:(SLSOpenGLRenderer *)openGLRenderer;
- (void)readAndRenderBonds:(SLSOpenGLRenderer *)openGLRenderer;

@end