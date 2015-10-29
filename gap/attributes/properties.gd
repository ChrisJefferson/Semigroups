#############################################################################
##
#W  properties.gd
#Y  Copyright (C) 2013-15                                James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

# This file contains methods for determining properties of arbitrary
# semigroups. There are not very many specialised methods for acting semigroups
# and so we only have a single file.

#DeclareProperty("IsAbundantSemigroup", IsSemigroup);
#DeclareProperty("IsAdequateSemigroup", IsSemigroup);
DeclareProperty("IsBlockGroup", IsSemigroup);
DeclareProperty("IsRTrivial", IsSemigroup);
DeclareProperty("IsRTrivial", IsGreensDClass);
DeclareProperty("IsLTrivial", IsSemigroup);
DeclareProperty("IsLTrivial", IsGreensDClass);
DeclareProperty("IsHTrivial", IsSemigroup);
DeclareProperty("IsHTrivial", IsGreensDClass);

DeclareSynonymAttr("IsDTrivial", IsRTrivial and IsLTrivial);
DeclareSynonymAttr("IsAperiodicSemigroup", IsHTrivial);
DeclareSynonymAttr("IsCombinatorialSemigroup", IsHTrivial);
DeclareProperty("IsFactorisableInverseMonoid", IsSemigroup);
DeclareProperty("IsLeftSimple", IsSemigroup);
DeclareProperty("IsMonogenicInverseSemigroup", IsSemigroup);
DeclareOperation("IsRegularSemigroupElementNC",
                 [IsSemigroup, IsMultiplicativeElement and
                               IsAssociativeElement]);
DeclareProperty("IsRightSimple", IsSemigroup);
DeclareSynonymAttr("IsSemigroupWithCommutingIdempotents", IsBlockGroup);
DeclareProperty("IsUnitRegularMonoid", IsSemigroup);
DeclareProperty("IsZeroRectangularBand", IsSemigroup);
DeclareProperty("IsCongruenceFreeSemigroup", IsSemigroup);
DeclareProperty("IsEUnitaryInverseSemigroup", IsInverseSemigroup);

InstallTrueMethod(IsSemigroupWithInverseOp, IsInverseSemigroup and
                                            IsRegularStarSemigroup);
InstallTrueMethod(IsSemigroupWithInverseOp, IsInverseSemigroup and
                                            IsPartialPermSemigroup);
InstallTrueMethod(IsSemigroupWithInverseOp, IsInverseSemigroup and
                                            IsBlockBijectionSemigroup);
InstallTrueMethod(IsSemigroupWithInverseOp, IsInverseSemigroup and
                                            IsPartialPermBipartitionSemigroup);

#InstallTrueMethod(IsAbundantSemigroup, IsRegularSemigroup);
#InstallTrueMethod(IsAdequateSemigroup, IsAbundantSemigroup and IsBlockGroup);
InstallTrueMethod(IsBlockGroup, IsInverseSemigroup);
InstallTrueMethod(IsBlockGroup, IsPartialPermSemigroup);
InstallTrueMethod(IsDTrivial, IsSemilattice);
InstallTrueMethod(IsHTrivial, IsLTrivial);
InstallTrueMethod(IsHTrivial, IsRTrivial);
InstallTrueMethod(IsInverseMonoid, IsInverseSemigroup and IsMonoid);
InstallTrueMethod(IsLeftSimple, IsInverseSemigroup and IsGroupAsSemigroup);
InstallTrueMethod(IsLeftZeroSemigroup, IsSemigroup and IsTrivial);
InstallTrueMethod(IsRightZeroSemigroup, IsSemigroup and IsTrivial);
InstallTrueMethod(IsZeroSemigroup, IsSemigroup and IsTrivial);
InstallTrueMethod(IsNilpotentSemigroup, IsZeroSemigroup);
InstallTrueMethod(IsNilpotentSemigroup, IsSemigroup and IsTrivial);
InstallTrueMethod(IsLTrivial, IsInverseSemigroup and IsRTrivial);
InstallTrueMethod(IsLTrivial, IsDTrivial);
InstallTrueMethod(IsRectangularBand,
                  IsHTrivial and IsCompletelySimpleSemigroup);
InstallTrueMethod(IsRegularSemigroup, IsBand);
InstallTrueMethod(IsRightSimple, IsInverseSemigroup and IsGroupAsSemigroup);
InstallTrueMethod(IsRTrivial, IsInverseSemigroup and IsLTrivial);
InstallTrueMethod(IsRTrivial, IsDTrivial);
InstallTrueMethod(IsSemilattice, IsDTrivial and IsInverseSemigroup);
InstallTrueMethod(IsMonogenicInverseSemigroup,
                  IsInverseSemigroup and IsMonogenicSemigroup);
InstallTrueMethod(IsZeroRectangularBand, IsZeroGroup);
InstallTrueMethod(IsZeroGroup, IsZeroRectangularBand and IsInverseSemigroup);
InstallTrueMethod(IsRegularSemigroup, IsRegularStarSemigroup);
InstallTrueMethod(IsInverseSemigroup, IsGroup);
InstallTrueMethod(IsInverseSemigroup, IsBlockGroup and IsRegularSemigroup);
InstallTrueMethod(IsCommutativeSemigroup, IsZeroSemigroup);
InstallTrueMethod(IsTrivial,
                  IsLeftZeroSemigroup and IsRightZeroSemigroup);
InstallTrueMethod(IsBand, IsRectangularBand);
InstallTrueMethod(IsCompletelySimpleSemigroup, IsSimpleSemigroup and IsFinite);
