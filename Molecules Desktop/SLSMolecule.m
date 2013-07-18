//
//  SLSMolecule.m
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/26/2008.
//
//  This is the model class for the molecule object.  It parses a PDB file, generates a vertex buffer object, and renders that object to the screen

#import "SLSMolecule.h"
// Filetypes
#import "SLSMolecule+PDB.h"
#import "SLSMolecule+SDF.h"
#import "SLSMolecule+XYZ.h"

#import "SLSOpenGLRenderer.h"

#define BOND_LENGTH_LIMIT 3.0f

@implementation SLSMolecule

@synthesize renderingDelegate = _renderingDelegate;

#pragma mark -
#pragma mark Initialization and deallocation

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    atomArray = [[NSMutableArray alloc] init];
    bondArray = [[NSMutableArray alloc] init];

	numberOfStructures = 1;
	numberOfStructureBeingDisplayed = 1;
	
	filename = nil;
	filenameWithoutExtension = nil;
	title = nil;
	keywords = nil;
	sequence = nil;
	compound = nil;
	source = nil;
	journalTitle = nil;
	journalAuthor = nil;
	journalReference = nil;
	author = nil;
	
	isBeingDisplayed = NO;
	isRenderingCancelled = NO;
	
	previousTerminalAtomValue = nil;
	reverseChainDirection = NO;
	currentVisualizationType = BALLANDSTICK;
	
	isDoneRendering = NO;

	stillCountingAtomsInFirstStructure = YES;
	return self;
}

- (id)initWithData:(NSData *)fileData extension:(NSString *)fileExtension renderingDelegate:(id<SLSMoleculeRenderingDelegate>)newRenderingDelegate;
{
    if (!(self = [self init]))
    {
        return nil;
    }
    
    self.renderingDelegate = newRenderingDelegate;
    
    if ([[fileExtension lowercaseString] isEqualToString:@"sdf"])
    {
        if (![self readFromSDFData:fileData])
        {
            return nil;
        }
    }
    else if ([[fileExtension lowercaseString] isEqualToString:@"xyz"])
    {
        if (![self readFromXYZData:fileData])
        {
            return nil;
        }
    }
    else
    {
        if (![self readFromPDBData:fileData])
        {
            return nil;
        }
    }
	
	return self;
}

+ (BOOL)isFiletypeSupportedForFile:(NSString *)filePath;
{
	// TODO: Make the categories perform a selector to determine whether this file is supported
	if ([[[filePath pathExtension] lowercaseString] isEqualToString:@"pdb"]) // Uncompressed PDB file
	{
		return YES;
	}
    if ([[[filePath pathExtension] lowercaseString] isEqualToString:@"sdf"]) // Uncompressed SDF file
	{
		return YES;
	}
    if ([[[filePath pathExtension] lowercaseString] isEqualToString:@"xyz"]) // Uncompressed XYZ file
	{
		return YES;
	}
	else if ([[[filePath pathExtension] lowercaseString] isEqualToString:@"gz"]) // Gzipped PDB file
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

#pragma mark -
#pragma mark Molecule 3-D geometry generation
+ (void)setBondColor:(GLubyte *)bondColor forResidueType:(SLSResidueType)residueType;
{
	// Bonds are grey by default
	bondColor[0] = 150;
	bondColor[1] = 150;
	bondColor[2] = 150;
	bondColor[3] = 255;

	switch (residueType)
	{
		case ADENINE:
		case DEOXYADENINE:
		{
			bondColor[0] = 160;
			bondColor[1] = 160;
			bondColor[2] = 255;
		}; break;
		case CYTOSINE:
		case DEOXYCYTOSINE:
		{
			bondColor[0] = 255;
			bondColor[1] = 140;
			bondColor[2] = 75;
		}; break;
		case GUANINE:
		case DEOXYGUANINE:
		{
			bondColor[0] = 255;
			bondColor[1] = 112;
			bondColor[2] = 112;
		}; break;
		case URACIL:
		{
			bondColor[0] = 255;
			bondColor[1] = 128;
			bondColor[2] = 128;
		}; break;
		case DEOXYTHYMINE:
		{
			bondColor[0] = 160;
			bondColor[1] = 255;
			bondColor[2] = 160;
		}; break;
		case GLYCINE:
		{
			bondColor[0] = 235;
			bondColor[1] = 235;
			bondColor[2] = 235;
		}; break;
		case ALANINE:
		{
			bondColor[0] = 200;
			bondColor[1] = 200;
			bondColor[2] = 200;
		}; break;
		case VALINE:
		{
			bondColor[0] = 15;
			bondColor[1] = 130;
			bondColor[2] = 15;
		}; break;
		case LEUCINE:
		{
			bondColor[0] = 15;
			bondColor[1] = 130;
			bondColor[2] = 15;
		}; break;
		case ISOLEUCINE:
		{
			bondColor[0] = 15;
			bondColor[1] = 130;
			bondColor[2] = 15;
		}; break;
		case SERINE:
		{
			bondColor[0] = 250;
			bondColor[1] = 150;
			bondColor[2] = 0;
		}; break;
		case CYSTEINE:
		{
			bondColor[0] = 230;
			bondColor[1] = 230;
			bondColor[2] = 0;
		}; break;
		case THREONINE:
		{
			bondColor[0] = 250;
			bondColor[1] = 150;
			bondColor[2] = 0;
		}; break;
		case METHIONINE:
		{
			bondColor[0] = 230;
			bondColor[1] = 230;
			bondColor[2] = 0;
		}; break;
		case PROLINE:
		{
			bondColor[0] = 220;
			bondColor[1] = 150;
			bondColor[2] = 130;
		}; break;
		case PHENYLALANINE:
		{
			bondColor[0] = 50;
			bondColor[1] = 50;
			bondColor[2] = 170;
		}; break;
		case TYROSINE:
		{
			bondColor[0] = 50;
			bondColor[1] = 50;
			bondColor[2] = 170;
		}; break;
		case TRYPTOPHAN:
		{
			bondColor[0] = 180;
			bondColor[1] = 90;
			bondColor[2] = 180;
		}; break;
		case HISTIDINE:
		{
			bondColor[0] = 130;
			bondColor[1] = 130;
			bondColor[2] = 210;
		}; break;
		case LYSINE:
		{
			bondColor[0] = 20;
			bondColor[1] = 90;
			bondColor[2] = 255;
		}; break;
		case ARGININE:
		{
			bondColor[0] = 20;
			bondColor[1] = 90;
			bondColor[2] = 255;
		}; break;
		case ASPARTICACID:
		{
			bondColor[0] = 230;
			bondColor[1] = 10;
			bondColor[2] = 10;
		}; break;
		case GLUTAMICACID:
		{
			bondColor[0] = 230;
			bondColor[1] = 10;
			bondColor[2] = 10;
		}; break;
		case ASPARAGINE:
		{
			bondColor[0] = 0;
			bondColor[1] = 220;
			bondColor[2] = 220;
		}; break;
		case GLUTAMINE:
		{
			bondColor[0] = 0;
			bondColor[1] = 220;
			bondColor[2] = 220;
		}; break;
		case WATER:
		{
			bondColor[0] = 0;
			bondColor[1] = 0;
			bondColor[2] = 255;
		}; break;
		case UNKNOWNRESIDUE:
        default:
		{
			bondColor[0] = 255;
			bondColor[1] = 255;
			bondColor[2] = 255;
		}; break;
	}
}

#pragma mark -
#pragma mark Database methods

- (void)addMetadataToDatabase:(NSString *)metadata type:(SLSMetadataType)metadataType;
{
//    NSLog(@"Adding metadata: %@ of type: %d", metadata, metadataType);
}

- (NSInteger)addAtomToDatabase:(SLSAtomType)atomType atPoint:(SLS3DPoint)newPoint structureNumber:(NSInteger)structureNumber residueKey:(SLSResidueType)residueKey;
{
    _elementsPresentInMolecule[atomType] = YES;
    
    SLSAtomContainer atomContainer;
    atomContainer.atomType = atomType;
    atomContainer.center = newPoint;
    atomContainer.structureNumber = structureNumber;
    atomContainer.residueKey = residueKey;
    
    NSValue *atomValue = [NSValue valueWithBytes:&atomContainer objCType:@encode(SLSAtomContainer)];
    [atomArray addObject:atomValue];
    
	if (stillCountingAtomsInFirstStructure)
		numberOfAtoms++;

	return (numberOfAtoms - 1);
}

- (BOOL *)elementsPresentInMolecule;
{
    return _elementsPresentInMolecule;
}

// Evaluate using atom IDs here for greater rendering flexibility
- (void)addBondToDatabaseWithStartPoint:(NSValue *)startValue endPoint:(NSValue *)endValue bondType:(SLSBondType)bondType structureNumber:(NSInteger)structureNumber residueKey:(NSInteger)residueKey;
{
	SLS3DPoint startPoint, endPoint;
	if ( (startValue == nil) || (endValue == nil) )
		return;
	[startValue getValue:&startPoint];
	[endValue getValue:&endPoint];

	float bondLength = sqrt((startPoint.x - endPoint.x) * (startPoint.x - endPoint.x) + (startPoint.y - endPoint.y) * (startPoint.y - endPoint.y) + (startPoint.z - endPoint.z) * (startPoint.z - endPoint.z));
	if (bondLength > BOND_LENGTH_LIMIT)
	{
		// Don't allow weird, wrong bonds to be displayed
		return;
	}
    
    SLSBondContainer bondContainer;
    bondContainer.startPoint = startPoint;
    bondContainer.endPoint = endPoint;
    bondContainer.bondType = bondType;
    bondContainer.structureNumber = structureNumber;
    bondContainer.residueKey = residueKey;
	    
    NSValue *bondValue = [NSValue valueWithBytes:&bondContainer objCType:@encode(SLSBondContainer)];
    [bondArray addObject:bondValue];

	if (stillCountingAtomsInFirstStructure)
		numberOfBonds++;
}

#pragma mark -
#pragma mark Status notification methods

- (void)showStatusIndicator;
{
    [self.renderingDelegate renderingStarted];
}

- (void)updateStatusIndicator;
{
    [self.renderingDelegate renderingUpdated:(double)currentFeatureBeingRendered/(double)totalNumberOfFeaturesToRender];
}

- (void)hideStatusIndicator;
{
    [self.renderingDelegate renderingEnded];
}

#pragma mark -
#pragma mark Rendering

- (void)switchToDefaultVisualizationMode;
{
    if ((numberOfAtoms < 600) && (numberOfBonds > 0))
    {
//        self.currentVisualizationType = SPACEFILLING;
        self.currentVisualizationType = BALLANDSTICK;
    }
    else
    {
        self.currentVisualizationType = SPACEFILLING;
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:currentVisualizationType forKey:@"currentVisualizationMode"];
}

- (BOOL)renderMolecule:(SLSOpenGLRenderer *)openGLRenderer;
{
    currentRenderer = openGLRenderer;
	@autoreleasepool {
        
		isDoneRendering = NO;
		[self performSelectorOnMainThread:@selector(showStatusIndicator) withObject:nil waitUntilDone:NO];
        
        [openGLRenderer initiateMoleculeRendering];
        
        openGLRenderer.overallMoleculeScaleFactor = scaleAdjustmentForX;
        
		currentFeatureBeingRendered = 0;
        
		switch(currentVisualizationType)
		{
			case BALLANDSTICK:
			{
                [openGLRenderer configureBasedOnNumberOfAtoms:self.numberOfAtoms numberOfBonds:self.numberOfBonds];
				totalNumberOfFeaturesToRender = numberOfAtoms + numberOfBonds;
                
                openGLRenderer.bondRadiusScaleFactor = 0.15;
                openGLRenderer.atomRadiusScaleFactor = 0.35;
				
				[self readAndRenderAtoms:openGLRenderer];
				[self readAndRenderBonds:openGLRenderer];
                //            openGLESRenderer.atomRadiusScaleFactor = 0.27;
			}; break;
			case SPACEFILLING:
			{
                [openGLRenderer configureBasedOnNumberOfAtoms:self.numberOfAtoms numberOfBonds:0];
				totalNumberOfFeaturesToRender = numberOfAtoms;
                
                openGLRenderer.atomRadiusScaleFactor = 1.0;
                [self readAndRenderAtoms:openGLRenderer];
			}; break;
			case CYLINDRICAL:
			{
                [openGLRenderer configureBasedOnNumberOfAtoms:0 numberOfBonds:self.numberOfBonds];
                
				totalNumberOfFeaturesToRender = numberOfBonds;
                
                openGLRenderer.bondRadiusScaleFactor = 0.15;
				[self readAndRenderBonds:openGLRenderer];
			}; break;
		}
		
		if (!isRenderingCancelled)
		{
            [openGLRenderer bindVertexBuffersForMolecule:self];
            //        }
            //        else
            //        {
            //            [openGLESRenderer performSelectorOnMainThread:@selector(bindVertexBuffersForMolecule) withObject:nil waitUntilDone:YES];
            //        }
		}
		else
		{
            isBeingDisplayed = NO;
            isRenderingCancelled = NO;
            
            [openGLRenderer terminateMoleculeRendering];
		}
		
        
		isDoneRendering = YES;
		[self performSelectorOnMainThread:@selector(hideStatusIndicator) withObject:nil waitUntilDone:YES];
        
	}
    
    currentRenderer = nil;
	return YES;
}

- (void)readAndRenderAtoms:(SLSOpenGLRenderer *)openGLRenderer;
{	
	if (isRenderingCancelled)
    {
		return;
    }
    
	// Bind the query variables.
    	
    for (NSValue *atomValue in atomArray)
    {
//		if ( (currentFeatureBeingRendered % 100) == 0)
//        {
//			[self performSelectorOnMainThread:@selector(updateStatusIndicator) withObject:nil waitUntilDone:NO];
//        }
        
		currentFeatureBeingRendered++;
        
        SLSAtomContainer atomContainer;
        [atomValue getValue:&atomContainer];
        
        SLS3DPoint atomCoordinate = atomContainer.center;
		atomCoordinate.x -= centerOfMassInX;
		atomCoordinate.x *= scaleAdjustmentForX;
		atomCoordinate.y -= centerOfMassInY;
		atomCoordinate.y *= scaleAdjustmentForX;
		atomCoordinate.z -= centerOfMassInZ;
		atomCoordinate.z *= scaleAdjustmentForX;

        if (atomContainer.residueKey != WATER)
        {
			[openGLRenderer addAtomToVertexBuffers:atomContainer.atomType atPoint:atomCoordinate];
        }
    }
}

- (void)readAndRenderBonds:(SLSOpenGLRenderer *)openGLRenderer;
{
	if (isRenderingCancelled)
    {
		return;
    }
		
    for (NSValue *bondValue in bondArray)
    {
        //		// TODO: Determine if rendering a particular structure, if not don't render atom
        //		if ( (currentFeatureBeingRendered % 100) == 0)
        //			[self performSelectorOnMainThread:@selector(updateStatusIndicator) withObject:nil waitUntilDone:NO];
        
		currentFeatureBeingRendered++;
        
        SLSBondContainer bondContainer;
        [bondValue getValue:&bondContainer];
        
        SLS3DPoint startingCoordinate = bondContainer.startPoint;
		startingCoordinate.x -= centerOfMassInX;
		startingCoordinate.x *= scaleAdjustmentForX;
		startingCoordinate.y -= centerOfMassInY;
		startingCoordinate.y *= scaleAdjustmentForX;
		startingCoordinate.z -= centerOfMassInZ;
		startingCoordinate.z *= scaleAdjustmentForX;
        SLS3DPoint endingCoordinate = bondContainer.endPoint;
        endingCoordinate.x -= centerOfMassInX;
		endingCoordinate.x *= scaleAdjustmentForX;
		endingCoordinate.y -= centerOfMassInY;
		endingCoordinate.y *= scaleAdjustmentForX;
		endingCoordinate.z -= centerOfMassInZ;
		endingCoordinate.z *= scaleAdjustmentForX;

        GLubyte bondColor[4] = {200,200,200,255};  // Bonds are grey by default
        
		if (currentVisualizationType == CYLINDRICAL)
        {
			[SLSMolecule setBondColor:bondColor forResidueType:bondContainer.residueKey];
        }
        
		if (bondContainer.residueKey != WATER)
        {
			[openGLRenderer addBondToVertexBuffersWithStartPoint:startingCoordinate endPoint:endingCoordinate bondColor:bondColor bondType:bondContainer.bondType];
        }
    }

//
}


#pragma mark -
#pragma mark Accessors

@synthesize centerOfMassInX, centerOfMassInY, centerOfMassInZ;
@synthesize filename, filenameWithoutExtension, title, keywords, journalAuthor, journalTitle, journalReference, sequence, compound, source, author;
@synthesize isBeingDisplayed, isDoneRendering, isRenderingCancelled;
@synthesize numberOfAtoms, numberOfBonds, numberOfStructures;
@synthesize previousTerminalAtomValue;
@synthesize currentVisualizationType;
@synthesize numberOfStructureBeingDisplayed;


- (void)setIsBeingDisplayed:(BOOL)newValue;
{
	if (newValue == isBeingDisplayed)
    {
		return;
    }
    
	isBeingDisplayed = newValue;
	if (isBeingDisplayed)
	{
		isRenderingCancelled = NO;
	}
	else
	{
		if (!isDoneRendering)
		{
			self.isRenderingCancelled = YES;
            [currentRenderer cancelMoleculeRendering];
			[NSThread sleepForTimeInterval:1.0];
		}
	}
}

@end
