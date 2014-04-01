############################################################################# 
## 
#W  ideals-attributes.gd
#Y  Copyright (C) 2013-14                                 James D. Mitchell
## 
##  Licensing information can be found in the README file of this package. 
## 
############################################################################# 
##

DeclareOperation("SmallIdealGeneratingSet",
[IsActingSemigroup and IsSemigroupIdeal]);
DeclareAttribute("IsomorphismTransformationSemigroup", IsSemigroupIdeal);
DeclareAttribute("IsomorphismPartialPermSemigroup", IsSemigroupIdeal);
DeclareAttribute("IsomorphismBipartitionSemigroup", IsSemigroupIdeal);
DeclareAttribute("IsomorphismBlockBijectionSemigroup", IsSemigroupIdeal);