############################################################################
##
#W  congruences/univ.gd
#Y  Copyright (C) 2015                                   Michael C. Torpey
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##
## This file contains methods for the unique universal congruence on a
## semigroup, that is the relation SxS on a semigroup S.
##

# Universal Congruences
DeclareCategory("IsUniversalSemigroupCongruence",
                IsSemigroupCongruence and IsAttributeStoringRep and IsFinite);
DeclareCategory("IsUniversalSemigroupCongruenceClass",
                IsCongruenceClass and IsAttributeStoringRep and
                IsAssociativeElement);
DeclareOperation("UniversalSemigroupCongruence", [IsSemigroup]);
