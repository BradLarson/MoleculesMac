//
//  SLSMolecule.h
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/26/2008.
//
//  This is the model class for the molecule object.  It parses a PDB file, generates a vertex buffer object, and renders that object to the screen

#import "SLSMolecule.h"

@interface SLSMolecule (PDB)

- (void)createBondsForPDBResidue:(NSString *)residueType withAtomDictionary:(NSDictionary *)atomDictionary structureNumber:(NSInteger)structureNumber;
- (BOOL)readFromPDBData:(NSData *)fileData;


@end
