############################################################################
##
#W  setup.gd
#Y  Copyright (C) 2013-15                                James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

# This file contains declarations of everything required for a semigroup
# belonging to IsActingSemigroup...

DeclareCategory("IsActingSemigroup", IsSemigroup and IsFinite, 8);
# so that the rank of IsActingSemigroup is higher than that of
# IsSemigroup and IsFinite and HasGeneratorsOfSemigroup, and
# IsSemigroupIdeal and IsFinite and HasGeneratorsOfSemigroupIdeal

DeclareProperty("IsGeneratorsOfActingSemigroup",
                IsAssociativeElementCollection);
DeclareProperty("IsActingSemigroupWithFixedDegreeMultiplication",
                IsActingSemigroup);

DeclareCategory("IsActingSemigroupGreensClass", IsGreensClass);

DeclareAttribute("ActionDegree", IsAssociativeElement);
DeclareAttribute("ActionDegree", IsAssociativeElementCollection);
DeclareAttribute("ActionRank", IsSemigroup);
DeclareOperation("ActionRank", [IsAssociativeElement, IsInt]);
DeclareAttribute("MinActionRank", IsSemigroup);

DeclareAttribute("RhoAct", IsSemigroup);
DeclareAttribute("LambdaAct", IsSemigroup);

DeclareAttribute("LambdaOrbOpts", IsSemigroup);
DeclareAttribute("RhoOrbOpts", IsSemigroup);

DeclareAttribute("LambdaRank", IsSemigroup);
DeclareAttribute("RhoRank", IsSemigroup);

DeclareAttribute("LambdaFunc", IsSemigroup);
DeclareAttribute("RhoFunc", IsSemigroup);

DeclareAttribute("RhoInverse", IsSemigroup);
DeclareAttribute("LambdaInverse", IsSemigroup);
DeclareAttribute("LambdaPerm", IsSemigroup);
DeclareAttribute("LambdaConjugator", IsSemigroup);

DeclareAttribute("LambdaOrbSeed", IsSemigroup);
DeclareAttribute("RhoOrbSeed", IsSemigroup);

DeclareAttribute("IdempotentTester", IsSemigroup);
DeclareAttribute("IdempotentCreator", IsSemigroup);

DeclareAttribute("StabilizerAction", IsSemigroup);

DeclareOperation("FakeOne", [IsAssociativeElementCollection]);
