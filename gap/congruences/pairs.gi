############################################################################
##
#W  congruences/pairs.gi
#Y  Copyright (C) 2015                                   Michael C. Torpey
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##
## This file contains functions for any finite semigroup congruence with
## generating pairs, using a pair enumeration and union-find method.
##
#############################################################################
##
## A congruence here is defined by a semigroup and a list of generating pairs.
## Most of the work is done by SEMIGROUPS_Enumerate, a hidden function which
## begins to multiply known pairs in the congruence by the semigroup's
## generators, checking its results periodically against a supplied "lookfunc"
## which checks whether some condition has been fulfilled.
##
## Any function which requires information about a congruence may call
## SEMIGROUPS_Enumerate with a lookfunc to allow it to terminate as soon as the
## necessary information is found, without doing extra work.  Information found
## so far is then stored in a "congruence data" object, and work may be resumed
## in subsequent calls to SEMIGROUPS_Enumerate.
##
## If all the pairs of the congruence have been found, the congruence data
## object is discarded, and a lookup table is stored, giving complete
## information about the congruence classes.  If a lookup table is available,
## it is always used instead of SEMIGROUPS_Enumerate, which will always return
## fail from then on.
##
## Most methods in this file apply to (two-sided) congruences, as well as left
## congruences and right congruences.  The _InstallMethodsForCongruences
## function is called three times when Semigroups is loaded, installing slightly
## different methods for left, right, and two-sided congruences.  Of course a
## left congruence may turn out also to be a right congruence, and so on, but
## the properties HasGeneratingPairsOf(Left/Right)MagmaCongruence allow us to
## determine which type of relation we are treating it as.
##
## See J.M. Howie's "Fundamentals of Semigroup Theory" Section 1.5, and see
## Michael Torpey's MSc thesis "Computing with Semigroup Congruences" Chapter 2
## (www-circa.mcs.st-and.ac.uk/~mct25/files/mt5099-report.pdf) for more details.
##
#############################################################################

SEMIGROUPS.SetupCongData := function(cong)
  # This function creates the congruence data object for cong.  It should only
  # be called once.
  local S, elms, pairs, hashlen, ht, data, genpairs, right_compat, left_compat;

  S := Range(cong);
  elms := SEMIGROUP_ELEMENTS(GenericSemigroupData(S), infinity);

  # Is this a left, right, or 2-sided congruence?
  if HasGeneratingPairsOfMagmaCongruence(cong) then
    genpairs := GeneratingPairsOfSemigroupCongruence(cong);
  elif HasGeneratingPairsOfLeftMagmaCongruence(cong) then
    genpairs := GeneratingPairsOfLeftSemigroupCongruence(cong);
  elif HasGeneratingPairsOfRightMagmaCongruence(cong) then
    genpairs := GeneratingPairsOfRightSemigroupCongruence(cong);
  fi;

  pairs   := List(genpairs, x -> [Position(elms, x[1]), Position(elms, x[2])]);
  hashlen := SEMIGROUPS_OptionsRec(S).hashlen.L;

  ht := HTCreate([1, 1], rec(forflatplainlists := true,
                             treehashsize := hashlen));

  data := rec(cong         := cong,
              pairstoapply := pairs,
              pos          := 0,
              ht           := ht,
              elms         := elms,
              found        := false,
              ufdata       := UF_NEW(Size(S)));

  cong!.data := Objectify(NewType(FamilyObj(cong),
                                  SEMIGROUPS_IsSemigroupCongruenceData),
                          data);
end;

#

InstallMethod(SEMIGROUPS_Enumerate,
"for semigroup congruence data and a function",
[SEMIGROUPS_IsSemigroupCongruenceData, IsFunction],
function(data, lookfunc)
  # Enumerates pairs in the congruence in batches until lookfunc is satisfied
  local cong, ufdata, pairstoapply, ht, S, left, right, genstoapply, i, nr, x,
        check_period, j, y, next, newtable, ii;

  # Restore our place from the congruence data record
  cong         := data!.cong;
  ufdata       := data!.ufdata;
  pairstoapply := data!.pairstoapply;
  ht           := data!.ht;
  S            := Range(cong);

  # Find the necessary Cayley graphs
  if HasGeneratingPairsOfLeftMagmaCongruence(cong) then
    left := LeftCayleyGraphSemigroup(S);
  elif HasGeneratingPairsOfRightMagmaCongruence(cong) then
    right := RightCayleyGraphSemigroup(S);
  elif HasGeneratingPairsOfMagmaCongruence(cong) then
    left := LeftCayleyGraphSemigroup(S);
    right := RightCayleyGraphSemigroup(S);
  fi;

  genstoapply := [1 .. Size(GeneratorsOfSemigroup(S))];
  i     := data!.pos;
  nr    := Size(pairstoapply);

  if i = 0 then
    # Add the generating pairs themselves
    for x in pairstoapply do
      if x[1] <> x[2] and HTValue(ht, x) = fail then
        HTAdd(ht, x, true);
        UF_UNION(ufdata, x);
      fi;
    od;
  fi;

  # Have we already found what we were looking for?
  if lookfunc(data) then
    data!.found := true;
    return data;
  fi;

  # Define how often we check the lookfunc
  check_period := 200;

  # Main loop: find new pairs and keep multiplying them
  # We may need left-multiples, right-multiples, or both
  if HasGeneratingPairsOfMagmaCongruence(cong) then
    while i < nr do
      i := i + 1;
      x := pairstoapply[i];
      # Add the pair's left-multiples
      for j in genstoapply do
        y := [left[x[1]][j], left[x[2]][j]];
        if y[1] <> y[2] and HTValue(ht, y) = fail then
          HTAdd(ht, y, true);
          nr := nr + 1;
          pairstoapply[nr] := y;
          UF_UNION(ufdata, y);
        fi;
      od;
      # Add the pair's right-multiples
      for j in genstoapply do
        y := [right[x[1]][j], right[x[2]][j]];
        if y[1] <> y[2] and HTValue(ht, y) = fail then
          HTAdd(ht, y, true);
          nr := nr + 1;
          pairstoapply[nr] := y;
          UF_UNION(ufdata, y);
        fi;
      od;
      # Check lookfunc periodically
      if i mod check_period = 0 and lookfunc(data) then
        # Save our place
        data!.pos := i;
        data!.found := true;
        return data;
      fi;
    od;
  elif HasGeneratingPairsOfLeftMagmaCongruence(cong) then
    # Main loop: find new pairs and keep multiplying them
    while i < nr do
      i := i + 1;
      x := pairstoapply[i];
      # Add the pair's left-multiples
      for j in genstoapply do
        y := [left[x[1]][j], left[x[2]][j]];
        if y[1] <> y[2] and HTValue(ht, y) = fail then
          HTAdd(ht, y, true);
          nr := nr + 1;
          pairstoapply[nr] := y;
          UF_UNION(ufdata, y);
        fi;
      od;
      # Check lookfunc periodically
      if i mod check_period = 0 and lookfunc(data) then
        # Save our place
        data!.pos := i;
        data!.found := true;
        return data;
      fi;
    od;
  elif HasGeneratingPairsOfRightMagmaCongruence(cong) then
    while i < nr do
      i := i + 1;
      x := pairstoapply[i];
      # Add the pair's right-multiples
      for j in genstoapply do
        y := [right[x[1]][j], right[x[2]][j]];
        if y[1] <> y[2] and HTValue(ht, y) = fail then
          HTAdd(ht, y, true);
          nr := nr + 1;
          pairstoapply[nr] := y;
          UF_UNION(ufdata, y);
        fi;
      od;
      # Check lookfunc periodically
      if i mod check_period = 0 and lookfunc(data) then
        # Save our place
        data!.pos := i;
        data!.found := true;
        return data;
      fi;
    od;
  fi;

  # All pairs have been found: save a lookup tabloe
  next := 1;
  newtable := [];
  for i in [1 .. UF_SIZE(ufdata)] do
    ii := UF_FIND(ufdata, i);
    if ii = i then
      newtable[i] := next;
      next := next + 1;
    else
      newtable[i] := newtable[ii];
    fi;
  od;
  SetAsLookupTable(cong, newtable);

  # No need for congruence data object any more
  Unbind(cong!.data);

  # Return the data object with important final data
  data!.found := lookfunc(data);
  data!.lookup := newtable;
  return data;
end);

#

InstallMethod(IsRightSemigroupCongruence,
"for a left semigroup congruence with known generating pairs",
[IsLeftSemigroupCongruence and HasGeneratingPairsOfLeftMagmaCongruence],
function(congl)
  local pairs, cong2;
  # Is this left congruence right-compatible?
  # First, create the 2-sided congruence generated by these pairs.
  pairs := GeneratingPairsOfLeftSemigroupCongruence(congl);
  cong2 := SemigroupCongruence(Range(congl), pairs);

  # congl is right-compatible iff these describe the same relation
  if congl = cong2 then
    SetGeneratingPairsOfMagmaCongruence(congl, pairs);
    SetIsSemigroupCongruence(congl, true);
    return true;
  else
    SetIsSemigroupCongruence(congl, false);
    return false;
  fi;
end);

#

InstallMethod(IsLeftSemigroupCongruence,
"for a right semigroup congruence with known generating pairs",
[IsRightSemigroupCongruence and HasGeneratingPairsOfRightMagmaCongruence],
function(congr)
  local pairs, cong2;
  # Is this right congruence left-compatible?
  # First, create the 2-sided congruence generated by these pairs.
  pairs := GeneratingPairsOfRightSemigroupCongruence(congr);
  cong2 := SemigroupCongruence(Range(congr), pairs);

  # congr is left-compatible iff these describe the same relation
  if congr = cong2 then
    SetGeneratingPairsOfMagmaCongruence(congr, pairs);
    SetIsSemigroupCongruence(congr, true);
    return true;
  else
    SetIsSemigroupCongruence(congr, false);
    return false;
  fi;
end);

#

InstallMethod(IsSemigroupCongruence,
"for a left semigroup congruence with known generating pairs",
[IsLeftSemigroupCongruence and HasGeneratingPairsOfLeftMagmaCongruence],
function(cong)
  return IsRightSemigroupCongruence(cong);
end);

#

InstallMethod(IsSemigroupCongruence,
"for a right semigroup congruence with known generating pairs",
[IsRightSemigroupCongruence and HasGeneratingPairsOfRightMagmaCongruence],
function(cong)
  return IsLeftSemigroupCongruence(cong);
end);

#

_GenericCongruenceEquality := function(c1, c2)
  # This function tests equality of left, right, or 2-sided congruences
  return Range(c1) = Range(c2) and AsLookupTable(c1) = AsLookupTable(c2);
end;

# _GenericCongruenceEquality tests equality for any combination of left, right
# and 2-sided congruences, so it is installed for the six combinations below.
# If the arguments are the same type of congruence, a different method is used

InstallMethod(\=,
Concatenation("for a left semigroup congruence with known generating pairs ",
              "and a right semigroup congruence with known generating pairs"),
[IsLeftSemigroupCongruence and HasGeneratingPairsOfLeftMagmaCongruence,
 IsRightSemigroupCongruence and HasGeneratingPairsOfRightMagmaCongruence],
_GenericCongruenceEquality);

InstallMethod(\=,
Concatenation("for a right semigroup congruence with known generating pairs ",
              "and a left semigroup congruence with known generating pairs"),
[IsRightSemigroupCongruence and HasGeneratingPairsOfRightMagmaCongruence,
 IsLeftSemigroupCongruence and HasGeneratingPairsOfLeftMagmaCongruence],
_GenericCongruenceEquality);

InstallMethod(\=,
Concatenation("for a left semigroup congruence with known generating pairs ",
              "and a semigroup congruence with known generating pairs"),
[IsLeftSemigroupCongruence and HasGeneratingPairsOfLeftMagmaCongruence,
 IsSemigroupCongruence and HasGeneratingPairsOfMagmaCongruence],
_GenericCongruenceEquality);

InstallMethod(\=,
Concatenation("for a right semigroup congruence with known generating pairs ",
              "and a semigroup congruence with known generating pairs"),
[IsRightSemigroupCongruence and HasGeneratingPairsOfRightMagmaCongruence,
 IsSemigroupCongruence and HasGeneratingPairsOfMagmaCongruence],
_GenericCongruenceEquality);

InstallMethod(\=,
Concatenation("for a semigroup congruence with known generating pairs ",
              "and a left semigroup congruence with known generating pairs"),
[IsSemigroupCongruence and HasGeneratingPairsOfMagmaCongruence,
 IsLeftSemigroupCongruence and HasGeneratingPairsOfLeftMagmaCongruence],
_GenericCongruenceEquality);

InstallMethod(\=,
Concatenation("for a semigroup congruence with known generating pairs ",
              "and a right semigroup congruence with known generating pairs"),
[IsSemigroupCongruence and HasGeneratingPairsOfMagmaCongruence,
 IsRightSemigroupCongruence and HasGeneratingPairsOfRightMagmaCongruence],
_GenericCongruenceEquality);

Unbind(_GenericCongruenceEquality);

#

################################################################################
# We now have some methods which apply to left congruences, right congruences
# and 2-sided congruences.  These functions behave only slightly differently for
# these three types of object, so they are installed by the function
# _InstallMethodsForCongruences, which takes a record describing the type of
# object the filters apply to (left, right, or 2-sided).
#
# See below for the loop where this function is invoked. It is required to do
# this in a function so that the values _record,
# _GeneratingPairsOfXSemigroupCongruence, etc are available (as local
# variables in the function) when the methods installed in this function are
# actually called. If we don't use a function here, the values in _record etc
# are unbound by the time the methods are called.
################################################################################

_InstallMethodsForCongruences := function(_record)
  local _GeneratingPairsOfXSemigroupCongruence,
        _HasGeneratingPairsOfXSemigroupCongruence,
        _IsXSemigroupCongruence;

  _GeneratingPairsOfXSemigroupCongruence :=
    EvalString(Concatenation("GeneratingPairsOf",
                             _record.type_string,
                             "MagmaCongruence"));
  _HasGeneratingPairsOfXSemigroupCongruence :=
    EvalString(Concatenation("HasGeneratingPairsOf",
                             _record.type_string,
                             "MagmaCongruence"));
  _IsXSemigroupCongruence :=
    EvalString(Concatenation("Is",
                             _record.type_string,
                             "SemigroupCongruence"));

  #

  InstallImmediateMethod(IsFinite,
    Concatenation("for a ", _record.info_string, " with known range"),
    _IsXSemigroupCongruence and HasRange,
    0,
    function(cong)
      if HasIsFinite(Range(cong)) and IsFinite(Range(cong)) then
        return true;
      fi;
      TryNextMethod();
  end);

  #

  InstallMethod(\in,
  Concatenation("for dense list and ", _record.info_string,
                " with known generating pairs"),
  [IsDenseList, _IsXSemigroupCongruence and
   _HasGeneratingPairsOfXSemigroupCongruence],
  function(pair, cong)
    local S, elms, p1, p2, table, lookfunc;

    # Input checks
    if Size(pair) <> 2 then
      ErrorMayQuit("Semigroups: \\in (for a congruence): usage,\n",
                   "the first arg <pair> must be a list of length 2,");
    fi;
    S := Range(cong);
    if not (pair[1] in S and pair[2] in S) then
      ErrorMayQuit("Semigroups: \\in (for a congruence): usage,\n",
                   "elements of the first arg <pair> must be\n",
                   "in the range of the second arg <cong>,");
    fi;
    if not (HasIsFinite(S) and IsFinite(S)) then
      ErrorMayQuit("Semigroups: \\in (for a congruence): usage,\n",
                   "this function currently only works if <cong> is a ",
                   "congruence of a semigroup\nwhich is known to be finite,");
    fi;

    elms := SEMIGROUP_ELEMENTS(GenericSemigroupData(S), infinity);
    p1 := Position(elms, pair[1]);
    p2 := Position(elms, pair[2]);

    # Use lookup table if available
    if HasAsLookupTable(cong) then
      table := AsLookupTable(cong);
      return table[p1] = table[p2];
    else
      # Otherwise, begin calculating the lookup table and look for this pair
      lookfunc := function(data)
        return UF_FIND(data!.ufdata, p1)
               = UF_FIND(data!.ufdata, p2);
      end;
      return SEMIGROUPS_Enumerate(cong, lookfunc)!.found;
    fi;
  end);

  #

  InstallMethod(AsLookupTable,
  Concatenation("for a ", _record.info_string, "with known generating pairs"),
  [_IsXSemigroupCongruence and _HasGeneratingPairsOfXSemigroupCongruence],
  function(cong)
    local data;
    if not (HasIsFinite(Range(cong)) and IsFinite(Range(cong))) then
      ErrorMayQuit("Semigroups: AsLookupTable: usage,\n",
                   "<cong> must be a congruence of a finite semigroup,");
    fi;
    # Enumerate the congruence until all pairs are found
    data := SEMIGROUPS_Enumerate(cong, ReturnFalse);
    # Return the resultant lookup table
    return data!.lookup;
  end);

  #

  InstallMethod(SEMIGROUPS_Enumerate,
  Concatenation("for a ", _record.info_string,
                " with known generating pairs and a function"),
  [_IsXSemigroupCongruence and _HasGeneratingPairsOfXSemigroupCongruence,
   IsFunction],
  function(cong, lookfunc)
    # If we have a lookup table, then we have complete information
    # and there is nothing left to enumerate
    if HasAsLookupTable(cong) then
      return fail;
    fi;
    # If the congruence data does not exist, then we need to set it up
    if not IsBound(cong!.data) then
      SEMIGROUPS.SetupCongData(cong);
    fi;
    return SEMIGROUPS_Enumerate(cong!.data, lookfunc);
  end);

  #

  InstallMethod(EquivalenceClasses,
  Concatenation("for a ", _record.info_string, " with known generating pairs"),
  [_IsXSemigroupCongruence and _HasGeneratingPairsOfXSemigroupCongruence],
  function(cong)
    local classes, next, tab, elms, i;

    if not (HasIsFinite(Range(cong)) and IsFinite(Range(cong))) then
      ErrorMayQuit("Semigroups: EquivalenceClasses: usage,\n",
                   "this function currently only works if <cong> is a ",
                   "congruence of a semigroup\nwhich is known to be finite,");
    fi;
    classes := [];
    next := 1;
    tab := AsLookupTable(cong);
    elms := SEMIGROUP_ELEMENTS(GenericSemigroupData(Range(cong)), infinity);
    for i in [1 .. Size(tab)] do
      if tab[i] = next then
        classes[next] := EquivalenceClassOfElementNC(cong, elms[i]);
        next := next + 1;
      fi;
    od;
    return classes;
  end);

  #

  InstallMethod(NonTrivialEquivalenceClasses,
  Concatenation("for a ", _record.info_string, "with known generating pairs"),
  [_IsXSemigroupCongruence and _HasGeneratingPairsOfXSemigroupCongruence],
  function(cong)
    local classes;

    if not (HasIsFinite(Range(cong)) and IsFinite(Range(cong))) then
      ErrorMayQuit("Semigroups: NonTrivialEquivalenceClasses: usage,\n",
                   "this function currently only works if <cong> is a ",
                   "congruence of a semigroup\nwhich is known to be finite,");
    fi;
    classes := EquivalenceClasses(cong);
    return Filtered(classes, c -> Size(c) > 1);
  end);

  InstallMethod(\=,
  Concatenation("for finite ", _record.info_string,
                "s with known generating pairs"),
  [_IsXSemigroupCongruence and _HasGeneratingPairsOfXSemigroupCongruence and IsFinite,
   _IsXSemigroupCongruence and _HasGeneratingPairsOfXSemigroupCongruence and IsFinite],
  function(cong1, cong2)
    return Range(cong1) = Range(cong2)
           and ForAll(_GeneratingPairsOfXSemigroupCongruence(cong1), pair -> pair in cong2)
           and ForAll(_GeneratingPairsOfXSemigroupCongruence(cong2), pair -> pair in cong1);
  end);


  #

  InstallMethod(ImagesElm,
  Concatenation("for a ", _record.info_string, " with known generating pairs ",
                "and an associative element"),
  [_IsXSemigroupCongruence and _HasGeneratingPairsOfXSemigroupCongruence, IsAssociativeElement],
  function(cong, elm)
    local elms, lookup, classNo;
    elms := SEMIGROUP_ELEMENTS(GenericSemigroupData(Range(cong)), infinity);
    lookup := AsLookupTable(cong);
    classNo := lookup[Position(elms, elm)];
    return elms{Positions(lookup, classNo)};
  end);


  #

  InstallMethod(NrCongruenceClasses,
  Concatenation("for a ", _record.info_string, " with generating pairs"),
  [_IsXSemigroupCongruence and _HasGeneratingPairsOfXSemigroupCongruence],
  function(cong)
    local S;
    S := Range(cong);
    if not (HasIsFinite(S) and IsFinite(S)) then
      ErrorMayQuit("Semigroups: NrCongruenceClasses: usage,\n",
                   "this function currently only works if <cong> is a ",
                   "congruence of a semigroup\nwhich is known to be finite,");
    fi;
    return Maximum(AsLookupTable(cong));
  end);


  #

  InstallMethod(ViewObj,
  Concatenation("for a ", _record.info_string, " with generating pairs"),
  [_IsXSemigroupCongruence and _HasGeneratingPairsOfXSemigroupCongruence],
  function(cong)
    Print("<", _record.info_string, " over ");
    ViewObj(Range(cong));
    Print(" with ", Size(_GeneratingPairsOfXSemigroupCongruence(cong)),
          " generating pairs>");
  end);

  #

  InstallMethod(IsSubrelation,
  Concatenation("for two ", _record.info_string, "s with generating pairs"),
  [_IsXSemigroupCongruence and _HasGeneratingPairsOfXSemigroupCongruence,
   _IsXSemigroupCongruence and _HasGeneratingPairsOfXSemigroupCongruence],
  function(cong1, cong2)
    # Tests whether cong1 contains all the pairs in cong2
    if Range(cong1) <> Range(cong2) then
      ErrorMayQuit("Semigroups: IsSubrelation: usage,\n",
                   "congruences must be defined over the same semigroup,");
    fi;
    return ForAll(_GeneratingPairsOfXSemigroupCongruence(cong2),
                  pair -> pair in cong1);
  end);
end;
# End of _InstallMethodsForCongruences function

for _record in [rec(type_string := "",
                    info_string := "semigroup congruence"),
                rec(type_string   := "Left",
                    info_string := "left semigroup congruence"),
                rec(type_string   := "Right",
                    info_string := "right semigroup congruence")] do
  _InstallMethodsForCongruences(_record);
od;

Unbind(_record);
Unbind(_InstallMethodsForCongruences);

###########################################################################
# Some individual methods for congruences
###########################################################################

InstallMethod(PrintObj,
"for a left semigroup congruence with known generating pairs",
[IsLeftSemigroupCongruence and HasGeneratingPairsOfLeftMagmaCongruence],
function(cong)
  Print("LeftSemigroupCongruence( ");
  PrintObj(Range(cong));
  Print(", ");
  Print(GeneratingPairsOfLeftSemigroupCongruence(cong));
  Print(" )");
end);

InstallMethod(PrintObj,
"for a right semigroup congruence with known generating pairs",
[IsRightSemigroupCongruence and HasGeneratingPairsOfRightMagmaCongruence],
function(cong)
  Print("RightSemigroupCongruence( ");
  PrintObj(Range(cong));
  Print(", ");
  Print(GeneratingPairsOfRightSemigroupCongruence(cong));
  Print(" )");
end);

InstallMethod(PrintObj,
"for a semigroup congruence with known generating pairs",
[IsSemigroupCongruence and HasGeneratingPairsOfMagmaCongruence],
function(cong)
  Print("SemigroupCongruence( ");
  PrintObj(Range(cong));
  Print(", ");
  Print(GeneratingPairsOfSemigroupCongruence(cong));
  Print(" )");
end);

###########################################################################
# methods for congruence classes
###########################################################################

InstallMethod(Enumerator, "for a congruence class",
[IsCongruenceClass],
function(class)
  local cong, S, enum;

  cong := EquivalenceClassRelation(class);
  S := Range(cong);

  if not (HasIsFinite(S) and IsFinite(S)) then
    TryNextMethod();
  fi;

  # cong has been enumerated: return a list
  if HasAsLookupTable(cong) then
    return Enumerator(AsList(class));
  fi;

  # cong has not yet been enumerated: make functions
  enum := rec();

  enum.ElementNumber := function(enum, pos)
    local lookfunc, result, table, classno, i;
    if pos <= enum!.len then
      return enum!.elms[enum!.list[pos]];
    fi;
    lookfunc := function(data)
      local classno, i;
      classno := UF_FIND(data!.ufdata, enum!.rep);
      for i in [1 .. UF_SIZE(data!.ufdata)] do
        if (not enum!.found[i]) and UF_FIND(data!.ufdata, i) = classno then
          enum!.found[i] := true;
          enum!.len := enum!.len + 1;
          enum!.list[enum!.len] := i;
        fi;
      od;
      return enum!.len >= pos;
    end;
    result := SEMIGROUPS_Enumerate(enum!.cong, lookfunc);
    if result = fail then
      # cong has AsLookupTable
      table := AsLookupTable(enum!.cong);
      classno := table[enum!.rep];
      for i in [1 .. Size(Range(enum!.cong))] do
        if table[i] = classno and not enum!.found[i] then
          enum!.found[i] := true;
          enum!.len := enum!.len + 1;
          enum!.list[enum!.len] := i;
        fi;
      od;
      SetSize(class, enum!.len);
      SetAsList(class, enum!.list);
    fi;
    if pos <= enum!.len then
      return enum!.elms[enum!.list[pos]];
    else
      return fail;
    fi;
  end;

  enum.NumberElement := function(enum, elm)
    local x, lookfunc, result, table, classno, i;
    x := Position(enum!.elms, elm);
    lookfunc := function(data)
      return UF_FIND(data!.ufdata, x)
             = UF_FIND(data!.ufdata, enum!.rep);
    end;
    result := SEMIGROUPS_Enumerate(enum!.cong, lookfunc);
    if result = fail then
      # cong has AsLookupTable
      table := AsLookupTable(enum!.cong);
      classno := table[enum!.rep];
      for i in [1 .. Size(Range(enum!.cong))] do
        if table[i] = classno and not enum!.found[i] then
          enum!.found[i] := true;
          enum!.len := enum!.len + 1;
          enum!.list[enum!.len] := i;
          if i = x then
            result := enum!.len;
          fi;
        fi;
      od;
      SetSize(class, enum!.len);
      SetAsList(class, enum!.list);
      return result;
    elif result!.found then
      # elm is in the class
      if enum!.found[x] then
        # elm already has a position
        return Position(enum!.list, x);
      else
        # put elm in the next available position
        enum!.found[x] := true;
        enum!.len := enum!.len + 1;
        enum!.list[enum!.len] := x;
        return enum!.len;
      fi;
    else
      # elm is not in the class
      return fail;
    fi;
  end;

  enum := EnumeratorByFunctions(class, enum);
  enum!.cong := EquivalenceClassRelation(UnderlyingCollection(enum));
  enum!.elms := SEMIGROUP_ELEMENTS(GenericSemigroupData(Range(enum!.cong)),
                                   infinity);
  enum!.rep := Position(enum!.elms,
                        Representative(UnderlyingCollection(enum)));
  enum!.list := [enum!.rep];
  enum!.found := BlistList([1 .. Size(enum!.elms)], [enum!.rep]);
  enum!.len := 1;

  return enum;
end);

#

InstallMethod(\in,
"for an associative element and a finite congruence class",
[IsAssociativeElement, IsCongruenceClass and IsFinite],
function(elm, class)
  return [elm, Representative(class)] in EquivalenceClassRelation(class);
end);

#

InstallMethod(Size,
"for a finite congruence class",
[IsCongruenceClass and IsFinite],
function(class)
  local elms, p, tab;
  elms := SEMIGROUP_ELEMENTS(GenericSemigroupData(Parent(class)), infinity);
  p := Position(elms, Representative(class));
  tab := AsLookupTable(EquivalenceClassRelation(class));
  return Number(tab, n -> n = tab[p]);
end);

#

InstallMethod(\=,
"for two congruence classes",
[IsCongruenceClass, IsCongruenceClass],
function(class1, class2)
  return EquivalenceClassRelation(class1) = EquivalenceClassRelation(class2)
    and [Representative(class1), Representative(class2)]
        in EquivalenceClassRelation(class1);
end);


#

InstallMethod(\*,
"for two congruence classes",
[IsCongruenceClass, IsCongruenceClass],
function(class1, class2)
  if EquivalenceClassRelation(class1) <> EquivalenceClassRelation(class2) then
    ErrorMayQuit("Semigroups: \*: usage,\n",
                 "the args must be classes of the same congruence,");
  fi;
  return CongruenceClassOfElement(EquivalenceClassRelation(class1),
                                  Representative(class1) *
                                  Representative(class2));
end);

#

InstallMethod(AsList,
"for a congruence class",
[IsCongruenceClass],
function(class)
  return ImagesElm(EquivalenceClassRelation(class), Representative(class));
end);

#

# TODO shouldn't there be methods for left and right congruences too?

InstallMethod(JoinSemigroupCongruences,
"for two semigroup congruences",
[IsSemigroupCongruence and HasGeneratingPairsOfMagmaCongruence,
 IsSemigroupCongruence and HasGeneratingPairsOfMagmaCongruence],
function(c1, c2)
  local pairs;
  # TODO: combine lookup tables
  if Range(c1) <> Range(c2) then
    ErrorMayQuit("Semigroups: JoinSemigroupCongruences: usage,\n",
                 "congruences must be defined over the same semigroup,");
  fi;
  pairs := Concatenation(ShallowCopy(GeneratingPairsOfSemigroupCongruence(c1)),
                         ShallowCopy(GeneratingPairsOfSemigroupCongruence(c2)));
  return SemigroupCongruence(Range(c1), pairs);
end);

# TODO shouldn't there be a method for MeetSemigroupCongruences too?

InstallMethod(LatticeOfCongruences,
"for a semigroup",
[IsSemigroup],
function(S)
  local elms, pairs, congs1, nrcongs, children, parents, pair, badcong,
        newchildren, newparents, newcong, i, c, p, congs, length, found, start,
        j, k;
  elms := SEMIGROUP_ELEMENTS(GenericSemigroupData(S), infinity);

  # Get all non-reflexive pairs in SxS
  pairs := Combinations(elms, 2);

  # Get all the unique 1-generated congruences
  Info(InfoSemigroups, 1, "Getting all 1-generated congruences...");
  congs1 := [];     # List of all congruences found so far
  nrcongs := 0;     # Number of congruences found so far
  children := [];   # List of lists of children
  parents := [];    # List of lists of parents
  for pair in pairs do
    badcong := false;
    newchildren := []; # Children of newcong
    newparents := [];  # Parents of newcong
    newcong := SemigroupCongruence(S, pair);
    for i in [1 .. Length(congs1)] do
      if IsSubrelation(congs1[i], newcong) then
        if IsSubrelation(newcong, congs1[i]) then
          # This is not a new congruence - drop it!
          badcong := true;
          break;
        else
          Add(newparents, i);
        fi;
      elif IsSubrelation(newcong, congs1[i]) then
        Add(newchildren, i);
      fi;
    od;
    if not badcong then
      nrcongs := nrcongs + 1;
      congs1[nrcongs] := newcong;
      children[nrcongs] := newchildren;
      parents[nrcongs] := newparents;
      for c in newchildren do
        Add(parents[c], nrcongs);
      od;
      for p in newparents do
        Add(children[p], nrcongs);
      od;
    fi;
  od;
  congs := ShallowCopy(congs1);

  # Take all their joins
  Info(InfoSemigroups, 1, "Taking joins...");
  length := 0;
  found := true;
  while found do
    # There are new congruences to try joining
    start := length + 1;     # New congruences start here
    found := false;          # Have we found any more congruences on this sweep?
    length := Length(congs); # Remember starting position for next sweep
    for i in [start .. Length(congs)] do # for each new congruence
      for j in [1 .. Length(congs1)] do  # for each 1-generated congruence
        newcong := JoinSemigroupCongruences(congs[i], congs1[j]);
        badcong := false;  # Is newcong the same as another congruence?
        newchildren := []; # Children of newcong
        newparents := [];  # Parents of newcong
        for k in [1 .. Length(congs)] do
          if IsSubrelation(congs[k], newcong) then
            if IsSubrelation(newcong, congs[k]) then
              # This is the same as an old congruence - discard it!
              badcong := true;
              break;
            else
              Add(newparents, k);
            fi;
          elif IsSubrelation(newcong, congs[k]) then
            Add(newchildren, k);
          fi;
        od;
        if not badcong then
          nrcongs := nrcongs + 1;
          congs[nrcongs] := newcong;
          children[nrcongs] := newchildren;
          parents[nrcongs] := newparents;
          for c in newchildren do
            Add(parents[c], nrcongs);
          od;
          for p in newparents do
            Add(children[p], nrcongs);
          od;
          found := true;
        fi;
      od;
    od;
  od;

  # Add the trivial congruence at the start
  children := Concatenation([[]], children + 1);
  for i in [2 .. nrcongs + 1] do
    Add(children[i], 1, 1);
  od;
  Add(congs, SemigroupCongruence(S, []), 1);

  SetCongruencesOfSemigroup(S, congs);
  return children;
end);

InstallGlobalFunction(DotCongruences,
function(arg)
  local S, opts, lat, congs, symbols, i, nr, rel, str, j, k;
  # Check input
  if not Length(arg) in [1, 2] then
    ErrorMayQuit("Semigroups: DotCongruences: usage,\n",
                 "this function requires 1 or 2 arguments,");
  fi;
  S := arg[1];
  if not IsSemigroup(S) then
    ErrorMayQuit("Semigroups: DotCongruences: usage,\n",
                 "<S> must be a semigroup,");
  fi;
  if Length(arg) = 2 then
    opts := arg[2];
  else
    opts := rec();
  fi;
  if not IsRecord(opts) then
    ErrorMayQuit("Semigroups: DotCongruences: usage,\n",
                 "<opts> must be a record,");
  fi;

  lat := LatticeOfCongruences(S);
  congs := CongruencesOfSemigroup(S);
  symbols := EmptyPlist(Length(lat));

  # If the user wants info, then change the node labels
  if IsBound(opts.info) and opts.info = true then
    for i in [1..Length(lat)] do
      nr := NrCongruenceClasses(congs[i]);
      if nr = 1 then
        symbols[i] := "U";
      elif nr = Size(S) then
        symbols[i] := "T";
      elif IsReesCongruence(congs[i]) then
        symbols[i] := Concatenation("R", String(i));
      else
        symbols[i] := String(i);
      fi;
    od;
  else
    symbols := List([1 .. Length(lat)], String);
  fi;

  rel := List([1 .. Length(lat)], x -> Filtered(lat[x], y -> x <> y));
  str := "";

  if Length(rel) < 40 then
    Append(str, "//dot\ngraph graphname {\n     node [shape=circle]\n");
  else
    Append(str, "//dot\ngraph graphname {\n     node [shape=point]\n");
  fi;

  for i in [1..Length(rel)] do
    j := Difference(rel[i], Union(rel{rel[i]}));
    i := symbols[i];
    for k in j do
      k := symbols[k];
      Append(str, Concatenation(i, " -- ", k, "\n"));
    od;
  od;

  Append(str, " }");

  return str;
end);

#FIXME: you should avoid methods of this type, i.e. the method for
#CongruencesOfSemigroup calls itself (ok, it works, but this is bad). The
# actual method should either go in here or it should be in separate function
# that is called by both CongruencesOfSemigroup and LatticeOfCongruences, which
# returns both of these values and then the values of CongruencesOfSemigroup
# and LatticeOfCongruences are set in the respective methods for
# CongruencesOfSemigroup and LatticeOfCongruences

InstallMethod(CongruencesOfSemigroup,
"for a semigroup",
[IsSemigroup],
function(S)
  LatticeOfCongruences(S);
  return CongruencesOfSemigroup(S);
end);