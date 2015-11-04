############################################################################
##
#W  semiringmat.gi
#Y  Copyright (C) 2015                                   James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

# This file contains methods for semigroups of matrices over semirings.

InstallMethod(SemigroupViewStringSuffix,
"for a matrix over semiring semigroup with generators",
[IsMatrixOverSemiringSemigroup],
function(S)
  local n;
  n := ViewString(DimensionOfMatrixOverSemiring(Representative(S)));
  # gaplint: ignore 3
  return Concatenation("\>\>", n, "x", n, "\< \>",
    SEMIGROUPS_TypeViewStringOfMatrixOverSemiring(Representative(S)),
                       "\< matrices\< ");
end);
