############################################################################
##
#W  semiboolmat.gd
#Y  Copyright (C) 2015                                   James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

# This file contains methods for semigroups of boolean matrices.

DeclareSynonym("IsBooleanMatSemigroup",
               IsSemigroup and IsBooleanMatCollection);

DeclareSynonym("IsBooleanMatMonoid",
               IsMonoid and IsBooleanMatCollection);

InstallTrueMethod(IsFinite, IsBooleanMatSemigroup);

DeclareAttribute("AsBooleanMatSemigroup", IsSemigroup);
DeclareAttribute("IsomorphismBooleanMatSemigroup", IsSemigroup);

DeclareOperation("RegularBooleanMatMonoid", [IsPosInt]);
DeclareOperation("GossipMonoid", [IsPosInt]);
DeclareOperation("UnitriangularBooleanMatrixMonoid", [IsPosInt]);
DeclareOperation("TriangularBooleanMatrixMonoid", [IsPosInt]);

DeclareOperation("ReflexiveBooleanMatMonoid", [IsPosInt]);
DeclareOperation("HallMonoid", [IsPosInt]);
DeclareOperation("FullBooleanMatMonoid", [IsPosInt]);
