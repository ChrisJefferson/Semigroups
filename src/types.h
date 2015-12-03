/*
 * Semigroups GAP package
 *
 * This file contains types of semigroups for use in the Semigroups kernel
 * module.
 *
 */

#ifndef SEMIGROUPS_GAP_TYPES_H
#define SEMIGROUPS_GAP_TYPES_H 1

#include "src/compiled.h"          /* GAP headers                */

#include <assert.h>
#include <iostream>
#include <vector>

/*******************************************************************************
 * GAP TNUM for wrapping C++ semigroup
*******************************************************************************/

#ifndef T_SEMI
#define T_SEMI T_SPARE2 //TODO use Register_TNUM when it's available
#endif

enum SemigroupsBagType {
  UF_DATA    = 0,
  SEMIGROUP  = 1,
  CONVERTER  = 2,
  GAP_BIPART = 3
};

template <typename Class>
inline Obj NewSemigroupsBag (Class* cpp_class, SemigroupsBagType type, size_t size) {
  Obj o = NewBag(T_SEMI, size * sizeof(Obj));
  ADDR_OBJ(o)[0] = (Obj)type;
  ADDR_OBJ(o)[1] = reinterpret_cast<Obj>(cpp_class);
  for (size_t i = 2; i < size; i++) {
    ADDR_OBJ(o)[i] = NULL;
  }
  return o;
}

// get C++ Class from GAP object

template <typename Class>
inline Class* CLASS_OBJ(Obj o) {
    return reinterpret_cast<Class*>(ADDR_OBJ(o)[1]);
}

#define IS_T_SEMI(o)         (TNUM_OBJ(o) == T_SEMI)
#define IS_CONVERTER_BAG(o)  (IS_T_SEMI(o) && (Int)ADDR_OBJ(o)[0] == CONVERTER)
#define IS_SEMIGROUP_BAG(o)  (IS_T_SEMI(o) && (Int)ADDR_OBJ(o)[0] == SEMIGROUP)
#define IS_UF_DATA_BAG(o)    (IS_T_SEMI(o) && (Int)ADDR_OBJ(o)[0] == UF_DATA)
#define IS_GAP_BIPART_BAG(o) (IS_T_SEMI(o) && (Int)ADDR_OBJ(o)[0] == GAP_BIPART)

/*******************************************************************************
 * Macros for checking types of objects
*******************************************************************************/

//FIXME remove CALL_1ARGS here

#define IS_BOOL_MAT(x)           (CALL_1ARGS(IsBooleanMat, x) == True)
#define IS_BIPART(x)             (CALL_1ARGS(IsBipartition, x) == True)
#define IS_MAT_OVER_SEMI_RING(x) (CALL_1ARGS(IsMatrixOverSemiring, x) == True)
#define IS_MAX_PLUS_MAT(x)       (CALL_1ARGS(IsMaxPlusMatrix, x) == True)
#define IS_MIN_PLUS_MAT(x)       (CALL_1ARGS(IsMinPlusMatrix, x) == True)
#define IS_TROP_MAT(x)           (CALL_1ARGS(IsTropicalMatrix, x) == True)
#define IS_TROP_MAX_PLUS_MAT(x)  (CALL_1ARGS(IsTropicalMaxPlusMatrix, x) == True)
#define IS_TROP_MIN_PLUS_MAT(x)  (CALL_1ARGS(IsTropicalMinPlusMatrix, x) == True)
#define IS_PROJ_MAX_PLUS_MAT(x)  (CALL_1ARGS(IsProjectiveMaxPlusMatrix, x) == True)
#define IS_NTP_MAT(x)            (CALL_1ARGS(IsNTPMatrix, x) == True)
#define IS_INT_MAT(x)            (CALL_1ARGS(IsIntegerMatrix, x) == True)
#define IS_MAT_OVER_PF(x)        (CALL_1ARGS(IsMatrixOverPrimeField, x) == True)
#define IS_PBR(x)                (CALL_1ARGS(IsPBR, x) == True)

/*******************************************************************************
 * Imported types from the library
*******************************************************************************/

extern Obj infinity;
extern Obj Ninfinity;
extern Obj IsBipartition;
extern Obj BipartitionType;
extern Obj BipartitionByIntRepNC; //FIXME remove this
extern Obj IsBooleanMat;
extern Obj BooleanMatType;
extern Obj IsMatrixOverSemiring;
extern Obj IsMaxPlusMatrix;
extern Obj MaxPlusMatrixType;
extern Obj IsMinPlusMatrix;
extern Obj MinPlusMatrixType;
extern Obj IsTropicalMatrix;
extern Obj IsTropicalMinPlusMatrix;
extern Obj TropicalMinPlusMatrixType;
extern Obj IsTropicalMaxPlusMatrix;
extern Obj TropicalMaxPlusMatrixType;
extern Obj IsProjectiveMaxPlusMatrix;
extern Obj ProjectiveMaxPlusMatrixType;
extern Obj IsNTPMatrix;
extern Obj NTPMatrixType;
extern Obj IsIntegerMatrix;
extern Obj IntegerMatrixType;
extern Obj IsMatrixOverPrimeField;
extern Obj MatrixOverPrimeFieldType;
extern Obj IsPBR;
extern Obj PBRType;

/*******************************************************************************
 * Union-find data structure
*******************************************************************************/

//FIXME move this to its own file

typedef std::vector<size_t>   table_t;
typedef std::vector<table_t*> blocks_t;

class UFData {
public:
  // Copy constructor
  UFData (const UFData& copy) : _size(copy._size),
                                _table(new table_t(*copy._table)),
                                _blocks(nullptr),
                                _haschanged(copy._haschanged) {
    if (copy._blocks != nullptr) {
      // Copy the blocks as well
      _blocks = new blocks_t();
      _blocks->reserve(copy._blocks->size());
      for (auto block: *copy._blocks) {
        if (block == nullptr) {
          _blocks->push_back(nullptr);
        } else {
          _blocks->push_back(new table_t(*block));
        }
      }
    }
  }
  UFData& operator= (UFData const& copy) = delete;

  // Constructor by size
  UFData (size_t size) : _size(size),
                         _table(new table_t()),
                         _blocks(nullptr),
                         _haschanged(false) {
    _table->reserve(size);
    for (size_t i=0; i<size; i++) {
      _table->push_back(i);
    }
  }

  // Destructor
  ~UFData () {
    delete _table;
    if (_blocks != nullptr) {
      for (size_t i=0; i<_blocks->size(); i++) {
        delete _blocks->at(i);
      }
      delete _blocks;
    }
  }

  // Getters
  size_t   get_size () { return _size; }
  table_t  *get_table () { return _table; }

  // get_blocks
  blocks_t *get_blocks () {
    table_t *block;
    // Is _blocks "bound" yet?
    if (_blocks == nullptr) {
      _blocks = new blocks_t();
      _blocks->reserve(_size);
      for (size_t i=0; i<_size; i++) {
        block = new table_t(1, i);
        _blocks->push_back(block);
      }
    }
    // Do we need to update the blocks?
    if (_haschanged) {
      size_t ii;
      for (size_t i=0; i<_size; i++) {
        if (_blocks->at(i) != nullptr) {
          ii = find(i);
          if (ii != i) {
            // Combine the two blocks
            _blocks->at(ii)->reserve(_blocks->at(ii)->size()
                                     + _blocks->at(i)->size());
            _blocks->at(ii)->insert(_blocks->at(ii)->end(),
                                    _blocks->at(i)->begin(),
                                    _blocks->at(i)->end());
            delete _blocks->at(i);
            _blocks->at(i) = nullptr;
          }
        }
      }
      _haschanged = false;
    }
    return _blocks;
  }

  // find
  size_t find (size_t i) {
    size_t ii;
    do {
      ii = i;
      i = _table->at(ii);
    } while (ii != i);
    return i;
  }

  // union
  void unite (size_t i, size_t j) {
    size_t ii, jj;
    ii = find(i);
    jj = find(j);
    if (ii < jj) {
      _table->at(jj) = ii;
    } else {
      _table->at(ii) = jj;
    }
    _haschanged = true;
  }

  // flatten
  void flatten() {
    for (size_t i=0; i<_size; i++) {
      _table->at(i) = find(i);
    }
  }
private:
  size_t    _size;
  table_t*  _table;
  blocks_t* _blocks;
  bool      _haschanged;
};

#endif