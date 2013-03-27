#import "SLSMolecule+PDB.h"
#import "NSData+Gzip.h"
#import "VCTitleCase.h"

static NSDictionary *pdbResidueLookupTable;

//const unsigned int PRECISION = 16; 
//inline GLfixed floatToFixed (GLfloat aValue)
//{ 
//	return (GLfixed) (aValue * 65536.0f); 
//}

//#define GL_UNSIGNED_INT                   0x1405

@implementation SLSMolecule (PDB)

#pragma mark -
#pragma mark Initialization and deallocation

- (void)createBondsForPDBResidue:(NSString *)residueType withAtomDictionary:(NSDictionary *)atomDictionary structureNumber:(NSInteger)structureNumber;
{
	if (pdbResidueLookupTable == nil)
	{
		// Set up the residue lookup table once for all molecules
		pdbResidueLookupTable = [[NSDictionary alloc] initWithObjectsAndKeys:
							  [NSNumber numberWithInteger:DEOXYADENINE], @"DA", 
							  [NSNumber numberWithInteger:DEOXYCYTOSINE], @"DC",
							  [NSNumber numberWithInteger:DEOXYGUANINE], @"DG",
							  [NSNumber numberWithInteger:DEOXYTHYMINE], @"DT",
							  [NSNumber numberWithInteger:ADENINE], @"A",
							  [NSNumber numberWithInteger:CYTOSINE], @"C",
							  [NSNumber numberWithInteger:GUANINE], @"G",
							  [NSNumber numberWithInteger:URACIL], @"U",
							  [NSNumber numberWithInteger:GLYCINE], @"GLY",
							  [NSNumber numberWithInteger:ALANINE], @"ALA",
							  [NSNumber numberWithInteger:VALINE], @"VAL",
							  [NSNumber numberWithInteger:LEUCINE], @"LEU",
							  [NSNumber numberWithInteger:ISOLEUCINE], @"ILE",
							  [NSNumber numberWithInteger:SERINE], @"SER",
							  [NSNumber numberWithInteger:CYSTEINE], @"CYS",
							  [NSNumber numberWithInteger:THREONINE], @"THR",
							  [NSNumber numberWithInteger:METHIONINE], @"MET",
							  [NSNumber numberWithInteger:PROLINE], @"PRO",
							  [NSNumber numberWithInteger:PHENYLALANINE], @"PHE",
							  [NSNumber numberWithInteger:TYROSINE], @"TYR",
							  [NSNumber numberWithInteger:TRYPTOPHAN], @"TRP",
							  [NSNumber numberWithInteger:HISTIDINE], @"HIS",
							  [NSNumber numberWithInteger:LYSINE], @"LYS",
							  [NSNumber numberWithInteger:ARGININE], @"ARG",
							  [NSNumber numberWithInteger:ASPARTICACID], @"ASP",
							  [NSNumber numberWithInteger:GLUTAMICACID], @"GLU",
							  [NSNumber numberWithInteger:ASPARAGINE], @"ASN",
							  [NSNumber numberWithInteger:GLUTAMINE], @"GLN",
							  nil];	
		
	}
	SLSResidueType residueIdentifier = [[pdbResidueLookupTable objectForKey:residueType] intValue];
	
	// Do the common atoms for classes of residues
	switch (residueIdentifier)
	{
		case ADENINE: // RNA nucleotides
		case CYTOSINE:
		case GUANINE:
		case URACIL:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C2'"] endPoint:[atomDictionary objectForKey:@"O2'"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		};
		case DEOXYADENINE: // DNA nucleotides
		case DEOXYCYTOSINE:
		case DEOXYGUANINE:
		case DEOXYTHYMINE:
		{
			// P -> O3' (Starts from 3' end, so no P in first nucleotide)
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"P"] endPoint:[atomDictionary objectForKey:@"OP1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"P"] endPoint:[atomDictionary objectForKey:@"OP2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"P"] endPoint:[atomDictionary objectForKey:@"O5'"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"O5'"] endPoint:[atomDictionary objectForKey:@"C5'"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C5'"] endPoint:[atomDictionary objectForKey:@"C4'"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C4'"] endPoint:[atomDictionary objectForKey:@"O4'"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C4'"] endPoint:[atomDictionary objectForKey:@"C3'"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C3'"] endPoint:[atomDictionary objectForKey:@"O3'"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"O4'"] endPoint:[atomDictionary objectForKey:@"C1'"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C3'"] endPoint:[atomDictionary objectForKey:@"C2'"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C2'"] endPoint:[atomDictionary objectForKey:@"C1'"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			
			// Link the nucleotides together
			if (self.previousTerminalAtomValue != nil)
				[self addBondToDatabaseWithStartPoint:self.previousTerminalAtomValue endPoint:[atomDictionary objectForKey:@"P"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			self.previousTerminalAtomValue = [atomDictionary objectForKey:@"O3'"];
		}; break;
		case GLYCINE: // Amino acids
		case ALANINE:
		case VALINE:
		case LEUCINE:
		case ISOLEUCINE:
		case SERINE:
		case CYSTEINE:
		case THREONINE:
		case METHIONINE:
		case PROLINE:
		case PHENYLALANINE:
		case TYROSINE:
		case TRYPTOPHAN:
		case HISTIDINE:
		case LYSINE:
		case ARGININE:
		case ASPARTICACID:
		case GLUTAMICACID:
		case ASPARAGINE:
		case GLUTAMINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"N"] endPoint:[atomDictionary objectForKey:@"CA"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"C"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C"] endPoint:[atomDictionary objectForKey:@"O"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];

			// Peptide bond
			if (self.previousTerminalAtomValue != nil)
			{
				[self addBondToDatabaseWithStartPoint:self.previousTerminalAtomValue endPoint:[atomDictionary objectForKey:@"N"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			}
			self.previousTerminalAtomValue = [atomDictionary objectForKey:@"C"];
			
		}; break;
		case WATER:
		case UNKNOWNRESIDUE:
        default:
		{
			
		}; break;
	}

	// Now do the residue-specific atoms
	switch (residueIdentifier)
	{
		case ADENINE:
		case DEOXYADENINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C1'"] endPoint:[atomDictionary objectForKey:@"N9"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"N9"] endPoint:[atomDictionary objectForKey:@"C4"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C4"] endPoint:[atomDictionary objectForKey:@"N3"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"N3"] endPoint:[atomDictionary objectForKey:@"C2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C2"] endPoint:[atomDictionary objectForKey:@"N1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"N1"] endPoint:[atomDictionary objectForKey:@"C6"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C6"] endPoint:[atomDictionary objectForKey:@"N6"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C6"] endPoint:[atomDictionary objectForKey:@"C5"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C5"] endPoint:[atomDictionary objectForKey:@"C4"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C5"] endPoint:[atomDictionary objectForKey:@"N7"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"N7"] endPoint:[atomDictionary objectForKey:@"C8"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C8"] endPoint:[atomDictionary objectForKey:@"N9"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case CYTOSINE:
		case DEOXYCYTOSINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C1'"] endPoint:[atomDictionary objectForKey:@"N1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"N1"] endPoint:[atomDictionary objectForKey:@"C2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C2"] endPoint:[atomDictionary objectForKey:@"O2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C2"] endPoint:[atomDictionary objectForKey:@"N3"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"N3"] endPoint:[atomDictionary objectForKey:@"C4"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C4"] endPoint:[atomDictionary objectForKey:@"N4"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C4"] endPoint:[atomDictionary objectForKey:@"C5"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C5"] endPoint:[atomDictionary objectForKey:@"C6"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C6"] endPoint:[atomDictionary objectForKey:@"N1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case GUANINE:
		case DEOXYGUANINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C1'"] endPoint:[atomDictionary objectForKey:@"N9"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"N9"] endPoint:[atomDictionary objectForKey:@"C4"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C4"] endPoint:[atomDictionary objectForKey:@"N3"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"N3"] endPoint:[atomDictionary objectForKey:@"C2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C2"] endPoint:[atomDictionary objectForKey:@"N2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C2"] endPoint:[atomDictionary objectForKey:@"N1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"N1"] endPoint:[atomDictionary objectForKey:@"C6"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C6"] endPoint:[atomDictionary objectForKey:@"O6"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C6"] endPoint:[atomDictionary objectForKey:@"C5"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C5"] endPoint:[atomDictionary objectForKey:@"C4"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C5"] endPoint:[atomDictionary objectForKey:@"N7"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"N7"] endPoint:[atomDictionary objectForKey:@"C8"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C8"] endPoint:[atomDictionary objectForKey:@"N9"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case DEOXYTHYMINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C5"] endPoint:[atomDictionary objectForKey:@"C7"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		};
		case URACIL:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C1'"] endPoint:[atomDictionary objectForKey:@"N1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"N1"] endPoint:[atomDictionary objectForKey:@"C2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C2"] endPoint:[atomDictionary objectForKey:@"O2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C2"] endPoint:[atomDictionary objectForKey:@"N3"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"N3"] endPoint:[atomDictionary objectForKey:@"C4"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C4"] endPoint:[atomDictionary objectForKey:@"O4"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C4"] endPoint:[atomDictionary objectForKey:@"C5"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C5"] endPoint:[atomDictionary objectForKey:@"C6"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"C6"] endPoint:[atomDictionary objectForKey:@"N1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case ALANINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case VALINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case LEUCINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case ISOLEUCINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG1"] endPoint:[atomDictionary objectForKey:@"CD1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case SERINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"OB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case CYSTEINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"SG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case THREONINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"OG1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case METHIONINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"SD"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"SD"] endPoint:[atomDictionary objectForKey:@"CE"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case PROLINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD"] endPoint:[atomDictionary objectForKey:@"N"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case PHENYLALANINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD1"] endPoint:[atomDictionary objectForKey:@"CE1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD2"] endPoint:[atomDictionary objectForKey:@"CE2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CE1"] endPoint:[atomDictionary objectForKey:@"CZ"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CE2"] endPoint:[atomDictionary objectForKey:@"CZ"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case TYROSINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD1"] endPoint:[atomDictionary objectForKey:@"CE1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD2"] endPoint:[atomDictionary objectForKey:@"CE2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CE1"] endPoint:[atomDictionary objectForKey:@"CZ"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CE2"] endPoint:[atomDictionary objectForKey:@"CZ"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CZ"] endPoint:[atomDictionary objectForKey:@"OH"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case TRYPTOPHAN:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD1"] endPoint:[atomDictionary objectForKey:@"NE1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD2"] endPoint:[atomDictionary objectForKey:@"CE2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"NE1"] endPoint:[atomDictionary objectForKey:@"CE2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CE2"] endPoint:[atomDictionary objectForKey:@"CZ2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CZ2"] endPoint:[atomDictionary objectForKey:@"CH2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CH2"] endPoint:[atomDictionary objectForKey:@"CZ3"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CZ3"] endPoint:[atomDictionary objectForKey:@"CE3"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CE3"] endPoint:[atomDictionary objectForKey:@"CD2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case HISTIDINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"ND1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"ND1"] endPoint:[atomDictionary objectForKey:@"CE1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD2"] endPoint:[atomDictionary objectForKey:@"NE2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CE1"] endPoint:[atomDictionary objectForKey:@"NE2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case LYSINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD"] endPoint:[atomDictionary objectForKey:@"CE"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CE"] endPoint:[atomDictionary objectForKey:@"NZ"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case ARGININE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD"] endPoint:[atomDictionary objectForKey:@"NE"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"NE"] endPoint:[atomDictionary objectForKey:@"CZ"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CZ"] endPoint:[atomDictionary objectForKey:@"NH1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CZ"] endPoint:[atomDictionary objectForKey:@"NH2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case ASPARTICACID:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"OD1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"OD2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case GLUTAMICACID:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD"] endPoint:[atomDictionary objectForKey:@"OE1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD"] endPoint:[atomDictionary objectForKey:@"OE2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case ASPARAGINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"OD1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"ND2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case GLUTAMINE:
		{
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CA"] endPoint:[atomDictionary objectForKey:@"CB"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CB"] endPoint:[atomDictionary objectForKey:@"CG"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CG"] endPoint:[atomDictionary objectForKey:@"CD"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD"] endPoint:[atomDictionary objectForKey:@"OE1"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
			[self addBondToDatabaseWithStartPoint:[atomDictionary objectForKey:@"CD"] endPoint:[atomDictionary objectForKey:@"NE2"] bondType:SINGLEBOND structureNumber:structureNumber residueKey:residueIdentifier];
		}; break;
		case GLYCINE:
		{
			
		}; break;
		case WATER:
		{
			
		}; break;
		case UNKNOWNRESIDUE:
        default:
		{
			
		}; break;			
	}
}

- (BOOL)readFromPDBData:(NSData *)fileData;
{
	// TODO: Add structure number
	unsigned int currentStructureNumber = 1;
	
	NSMutableDictionary *atomCoordinates = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *residueAtoms = nil;
	NSString *currentResidueType = nil;
	int currentResidueNumber = -1;
		
	stillCountingAtomsInFirstStructure = YES;
	numberOfAtoms = 0;
	float tallyForCenterOfMassInX = 0.0f, tallyForCenterOfMassInY = 0.0f, tallyForCenterOfMassInZ = 0.0f;
	minimumXPosition = 1000.0f;
	maximumXPosition = 0.0f;
	minimumYPosition = 1000.0f;
	maximumYPosition = 0.0f;
	minimumZPosition = 1000.0f;
	maximumZPosition = 0.0f;

	// Deal with compressed files
	NSString *pdbFileContents = [[NSString alloc] initWithData:fileData encoding:NSASCIIStringEncoding];
	NSUInteger length = [pdbFileContents length];
	NSUInteger lineStart = 0, lineEnd = 0, contentsEnd = 0;
	NSRange currentRange;
	
	while (lineEnd < length) 
	{
		@autoreleasepool {
			[pdbFileContents getParagraphStart:&lineStart end:&lineEnd contentsEnd:&contentsEnd forRange:NSMakeRange(lineEnd, 0)];
			currentRange = NSMakeRange(lineStart, contentsEnd - lineStart);
			NSString *currentLine = [pdbFileContents substringWithRange:currentRange];
			
			if ([currentLine length] >= 6) // Make sure that we at least have a line identifier present, move on the the next line otherwise
			{
				NSString *lineIdentifier = [[currentLine substringWithRange:NSMakeRange(0, 6)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				if (([lineIdentifier isEqualToString:@"ATOM"]) || ([lineIdentifier isEqualToString:@"HETATM"]))
				{
					// Process the bonds in the previous residue if starting a new residue
					if (![lineIdentifier isEqualToString:@"HETATM"])
					{
						int residueNumber = [[currentLine substringWithRange:NSMakeRange(22, 5)] intValue];
						if (residueNumber != currentResidueNumber)
						{
							if (residueAtoms != nil)
							{
								[self createBondsForPDBResidue:currentResidueType withAtomDictionary:residueAtoms structureNumber:currentStructureNumber];
								residueAtoms = nil;
								currentResidueType = nil;
							}
							residueAtoms = [[NSMutableDictionary alloc] init];
							currentResidueNumber = residueNumber;
							currentResidueType = [[currentLine substringWithRange:NSMakeRange(17, 3)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
						}
					}
					else // Bond (-0.231000,89.028999,38.627998)
					{
						if (residueAtoms != nil)
						{
							[self createBondsForPDBResidue:currentResidueType withAtomDictionary:residueAtoms structureNumber:currentStructureNumber];
							residueAtoms = nil;
							currentResidueType = nil;
						}
						
						self.previousTerminalAtomValue = nil;
					}			
					
					SLS3DPoint atomCoordinate;
					
					atomCoordinate.x = [[currentLine substringWithRange:NSMakeRange(30, 8)] floatValue];
					atomCoordinate.y = [[currentLine substringWithRange:NSMakeRange(38, 8)] floatValue];
					atomCoordinate.z = [[currentLine substringWithRange:NSMakeRange(46, 8)] floatValue];
					if (stillCountingAtomsInFirstStructure)
					{
						tallyForCenterOfMassInX += atomCoordinate.x;
						if (minimumXPosition > atomCoordinate.x)
						{
							minimumXPosition = atomCoordinate.x;
						}
						if (maximumXPosition < atomCoordinate.x)
						{
							maximumXPosition = atomCoordinate.x;
						}
						
						tallyForCenterOfMassInY += atomCoordinate.y;
						if (minimumYPosition > atomCoordinate.y)
						{
							minimumYPosition = atomCoordinate.y;
						}
						if (maximumYPosition < atomCoordinate.y)
						{
							maximumYPosition = atomCoordinate.y;
						}
						
						tallyForCenterOfMassInZ += atomCoordinate.z;
						if (minimumZPosition > atomCoordinate.z)
						{
							minimumZPosition = atomCoordinate.z;
						}
						if (maximumZPosition < atomCoordinate.z)
						{
							maximumZPosition = atomCoordinate.z;
						}
					}
					
					unsigned int atomSerialNumber = [[currentLine substringWithRange:NSMakeRange(6, 5)] intValue];
					[atomCoordinates setObject:[NSValue valueWithBytes:&atomCoordinate objCType:@encode(SLS3DPoint)] forKey:[NSNumber numberWithInt:atomSerialNumber]];
					if (![lineIdentifier isEqualToString:@"HETATM"])
					{
						NSString *atomResidueIdentifier = [[currentLine substringWithRange:NSMakeRange(12, 4)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
						[residueAtoms setObject:[NSValue valueWithBytes:&atomCoordinate objCType:@encode(SLS3DPoint)] forKey:atomResidueIdentifier];
					}
					
					NSString *atomElement;
					if ([currentLine length] < 78)
					{
						atomElement = [currentLine substringWithRange:NSMakeRange(12, 2)];
					}
					else
					{
						atomElement = [currentLine substringWithRange:NSMakeRange(76, 2)];
					}
                                
					SLSAtomType processedAtomType;
					if ([atomElement isEqualToString:@" C"])
					{
						processedAtomType = CARBON;
					}
					else if ([atomElement isEqualToString:@" H"])
					{
						processedAtomType = HYDROGEN;
					}
					else if ([atomElement isEqualToString:@" O"])
					{
						processedAtomType = OXYGEN;
					}
					else if ([atomElement isEqualToString:@" N"])
					{
						processedAtomType = NITROGEN;
					}
					else if ([atomElement isEqualToString:@" S"])
					{
						processedAtomType = SULFUR;
					}
					else if ([atomElement isEqualToString:@" P"])
					{
						processedAtomType = PHOSPHOROUS;
					}
					else if ([atomElement isEqualToString:@"FE"])
					{
						processedAtomType = IRON;
					}
					else if ([atomElement isEqualToString:@"SI"])
					{
						processedAtomType = SILICON;
					}
					else if ([atomElement isEqualToString:@" F"])
					{
						processedAtomType = FLUORINE;
					}
					else if ([atomElement isEqualToString:@"CL"])
					{
						processedAtomType = CHLORINE;
					}
					else if ([atomElement isEqualToString:@"BR"])
					{
						processedAtomType = BROMINE;
					}
					else if ([atomElement isEqualToString:@" I"])
					{
						processedAtomType = IODINE;
					}
					else if ([atomElement isEqualToString:@"CA"])
					{
						processedAtomType = CALCIUM;
					}
					else if ([atomElement isEqualToString:@"ZN"])
					{
						processedAtomType = ZINC;
					}
					else if ([atomElement isEqualToString:@"CD"])
					{
						processedAtomType = CADMIUM;
					}
					else if ([atomElement isEqualToString:@"NA"])
					{
						processedAtomType = SODIUM;
					}
					else if ([atomElement isEqualToString:@"MG"])
					{
						processedAtomType = MAGNESIUM;
					}
					else 
					{                
						processedAtomType = UNKNOWN;
					}				
                

					if ([lineIdentifier isEqualToString:@"HETATM"])
					{
						NSString *atomResidueIdentifier = [[currentLine substringWithRange:NSMakeRange(16, 4)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
						if ([atomResidueIdentifier isEqualToString:@"HOH"])
						{
							[self addAtomToDatabase:processedAtomType atPoint:atomCoordinate structureNumber:currentStructureNumber residueKey:WATER];
						}
						else
						{
							[self addAtomToDatabase:processedAtomType atPoint:atomCoordinate structureNumber:currentStructureNumber residueKey:UNKNOWNRESIDUE];
						}
					}
					else
					{
						[self addAtomToDatabase:processedAtomType atPoint:atomCoordinate structureNumber:currentStructureNumber residueKey:SERINE];
					}
				}
				else if ([lineIdentifier isEqualToString:@"TER"])
				{
					// Catch the last residue of the chain
					if (residueAtoms != nil)
					{
						[self createBondsForPDBResidue:currentResidueType withAtomDictionary:residueAtoms structureNumber:currentStructureNumber];
						residueAtoms = nil;
						currentResidueType = nil;
					}
					
					self.previousTerminalAtomValue = nil;
				}
				else if ([lineIdentifier isEqualToString:@"CONECT"])
				{
					NSValue *startValue = nil;
					int indexForFirstAtom = [[currentLine substringWithRange:NSMakeRange(6, 5)] intValue];
					if ( (indexForFirstAtom <= [atomCoordinates count]) && (indexForFirstAtom > 0) )
					{
						startValue = [atomCoordinates objectForKey:[NSNumber numberWithInt:indexForFirstAtom]];
					}
					if (indexForFirstAtom > 0)
					{
						int indexForNextAtom;
						if ([currentLine length] > 15)
						{
							indexForNextAtom = [[currentLine substringWithRange:NSMakeRange(11, 5)] intValue];
							if ( (indexForNextAtom > 0) && (indexForNextAtom <= [atomCoordinates count]) )
							{
								[self addBondToDatabaseWithStartPoint:startValue endPoint:[atomCoordinates objectForKey:[NSNumber numberWithInt:indexForNextAtom]] bondType:SINGLEBOND structureNumber:currentStructureNumber residueKey:UNKNOWNRESIDUE];
							}
						}
						
						if ([currentLine length] > 20)
						{
							indexForNextAtom = [[currentLine substringWithRange:NSMakeRange(16, 5)] intValue];
							if ( (indexForNextAtom > 0) && (indexForNextAtom <= [atomCoordinates count]) )
							{
								[self addBondToDatabaseWithStartPoint:startValue endPoint:[atomCoordinates objectForKey:[NSNumber numberWithInt:indexForNextAtom]] bondType:SINGLEBOND structureNumber:currentStructureNumber residueKey:UNKNOWNRESIDUE];
							}
						}
						
						if ([currentLine length] > 25)
						{
							indexForNextAtom = [[currentLine substringWithRange:NSMakeRange(21, 5)] intValue];
							if ( (indexForNextAtom > 0) && (indexForNextAtom <= [atomCoordinates count]) )
							{
								[self addBondToDatabaseWithStartPoint:startValue endPoint:[atomCoordinates objectForKey:[NSNumber numberWithInt:indexForNextAtom]] bondType:SINGLEBOND structureNumber:currentStructureNumber residueKey:UNKNOWNRESIDUE];
							}
						}

						if ([currentLine length] > 30)
						{
							indexForNextAtom = [[currentLine substringWithRange:NSMakeRange(26, 5)] intValue];
							if ( (indexForNextAtom > 0) && (indexForNextAtom <= [atomCoordinates count]) )
							{
								[self addBondToDatabaseWithStartPoint:startValue endPoint:[atomCoordinates objectForKey:[NSNumber numberWithInt:indexForNextAtom]] bondType:SINGLEBOND structureNumber:currentStructureNumber residueKey:UNKNOWNRESIDUE];
							}
						}
					}
				}
				else if ([lineIdentifier isEqualToString:@"MODEL"])
				{
					currentStructureNumber = [[currentLine substringWithRange:NSMakeRange(12, 4)] intValue];
					if (currentStructureNumber > numberOfStructures)
					{
						numberOfStructures = currentStructureNumber;
					}
				}
				else if ([lineIdentifier isEqualToString:@"ENDMDL"])
				{
					stillCountingAtomsInFirstStructure = NO;
				}
				else if ([lineIdentifier isEqualToString:@"TITLE"])
				{
					if (title == nil)
					{
						title = [[currentLine substringFromIndex:10] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					}
					else
					{
						title = [title stringByAppendingFormat:@" %@", [[currentLine substringFromIndex:10] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
					}
				}
				else if ([lineIdentifier isEqualToString:@"COMPND"])
				{
					if ([currentLine length] > 20)
					{
						NSString *compoundIdentifier = [[currentLine substringWithRange:NSMakeRange(10, 10)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
						if ([compoundIdentifier isEqualToString:@"MOLECULE:"])
						{
							if (compound == nil)
							{
								compound = [[currentLine substringFromIndex:20] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
							}
						}
					}				
				}
				else if ([lineIdentifier isEqualToString:@"SOURCE"])
				{
					if (source == nil)
					{
						source = [[currentLine substringFromIndex:10] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					}
					else
					{
						source = [source stringByAppendingFormat:@" %@", [[currentLine substringFromIndex:10] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
					}
				}
				else if ([lineIdentifier isEqualToString:@"AUTHOR"])
				{
					if (author == nil)
					{
						author = [[currentLine substringFromIndex:10] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					}
					else
					{
						author = [author stringByAppendingFormat:@" %@", [[currentLine substringFromIndex:10] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
					}
				}
				else if ([lineIdentifier isEqualToString:@"JRNL"])
				{
					NSString *journalIdentifier = [[currentLine substringWithRange:NSMakeRange(12, 4)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					if ([journalIdentifier isEqualToString:@"AUTH"])
					{
						if (journalAuthor == nil)
						{
							journalAuthor = [[currentLine substringFromIndex:18] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
						}
						else
						{
							journalAuthor = [journalAuthor stringByAppendingFormat:@" %@", [[currentLine substringFromIndex:18] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
						}
					}
					else if ([journalIdentifier isEqualToString:@"TITL"])
					{
						if (journalTitle == nil)
						{
							journalTitle = [[currentLine substringFromIndex:18] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
						}
						else
						{
							journalTitle = [journalTitle stringByAppendingFormat:@" %@", [[currentLine substringFromIndex:18] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
						}
					}
					else if ( ([journalIdentifier isEqualToString:@"REF"]) || ([journalIdentifier isEqualToString:@"REFN"]) )
					{
						if (journalReference == nil)
						{
							journalReference = [[currentLine substringFromIndex:18] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
						}
						else
						{
							journalReference = [journalReference stringByAppendingFormat:@" %@", [[currentLine substringFromIndex:18] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
						}
					}
				}		
				else if ([lineIdentifier isEqualToString:@"SEQRES"])
				{
					if (sequence == nil)
					{
						sequence = [[currentLine substringFromIndex:14] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					}
					else
					{
						sequence = [sequence stringByAppendingFormat:@"\n%@", [[currentLine substringFromIndex:14] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
					}
				}
				
				// 	NSString *pdbCode, *title, *keywords, *journalReference, *sequence, *compound;			
			}
		
		}
	}
	
	// Create bonds for the very last residue in the list
	if (residueAtoms != nil)
	{
		[self createBondsForPDBResidue:currentResidueType withAtomDictionary:residueAtoms structureNumber:currentStructureNumber];
	}
	
	residueAtoms = nil;
	currentResidueType = nil;
	
	if (numberOfAtoms > 0)
	{		
		centerOfMassInX = tallyForCenterOfMassInX / (float)numberOfAtoms;
		centerOfMassInY = tallyForCenterOfMassInY / (float)numberOfAtoms;
		centerOfMassInZ = tallyForCenterOfMassInZ / (float)numberOfAtoms;
		scaleAdjustmentForX = 1.5 / (maximumXPosition - minimumXPosition);
		scaleAdjustmentForY = 1.5 / (maximumYPosition - minimumYPosition);
		scaleAdjustmentForZ = (1.5 * 1.25) / (maximumZPosition - minimumZPosition);
		if (scaleAdjustmentForY < scaleAdjustmentForX)
		{
			scaleAdjustmentForX = scaleAdjustmentForY;
		}
		if (scaleAdjustmentForZ < scaleAdjustmentForX)
		{
			scaleAdjustmentForX = scaleAdjustmentForZ;
		}
	}
	
	// Convert the strings to title case and strip off the ;s at the end of lines
	NSCharacterSet *semicolonSet = [NSCharacterSet characterSetWithCharactersInString:@";"];

	if (title != nil)
	{
		title = [title lowercaseString];
		title = [title titlecaseString];
		title = [title stringByTrimmingCharactersInSet:semicolonSet];
	}
	else
	{
		title = [filename copy];
	}

	if (compound != nil)
	{
		compound = [compound lowercaseString];
		compound = [compound titlecaseString];
		compound = [compound stringByTrimmingCharactersInSet:semicolonSet];
	}
	else
	{
        NSRange rangeUntilFirstPeriod = [filename rangeOfString:@"."];
        if (rangeUntilFirstPeriod.location == NSNotFound)
        {
            compound = [filename copy];
        }
        else
        {
            compound = [[filename substringToIndex:rangeUntilFirstPeriod.location] titlecaseString];	
        }
	}

	if (source != nil)
	{
		source = [source lowercaseString];
		source = [source titlecaseString];
		source = [source stringByTrimmingCharactersInSet:semicolonSet];
		[self addMetadataToDatabase:source type:MOLECULESOURCE];
	}

	if (author != nil)
	{
		author = [author capitalizedString];
		author = [author stringByTrimmingCharactersInSet:semicolonSet];
		[self addMetadataToDatabase:author type:MOLECULEAUTHOR];
	}

 	if (journalAuthor != nil)
	{
		journalAuthor = [journalAuthor capitalizedString];
		journalAuthor = [journalAuthor stringByTrimmingCharactersInSet:semicolonSet];
		[self addMetadataToDatabase:journalAuthor type:JOURNALAUTHOR];
	}
	
	if (journalTitle != nil)
	{
		journalTitle = [journalTitle lowercaseString];
		journalTitle = [journalTitle titlecaseString];
		journalTitle = [journalTitle stringByTrimmingCharactersInSet:semicolonSet];
		[self addMetadataToDatabase:journalTitle type:JOURNALTITLE];
	}

	if (journalReference != nil)
	{
		journalReference = [journalReference capitalizedString];
		journalReference = [journalReference stringByTrimmingCharactersInSet:semicolonSet];
		[self addMetadataToDatabase:journalReference type:JOURNALREFERENCE];
	}

	if (sequence != nil)
	{
		[self addMetadataToDatabase:sequence type:MOLECULESEQUENCE];
	}

	return YES;
}

@end
