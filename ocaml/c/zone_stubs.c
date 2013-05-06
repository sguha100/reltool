/* This stuff is courtesy the UPPAAL DBM library. */
#include <dbm/constraints.h>
#include <dbm/dbm.h>
#include <dbm/fed.h>
#include <dbm/print.h>
#include <base/bitstring.h>

#include <stdio.h>

#ifdef __cplusplus
using namespace dbm;

typedef struct dbm_struct_t {
  cindex_t dim;
  raw_t *dbm;
} dbm_struct_t;

std::string getClockName(cindex_t index) 
{
  char str1[4];
  sprintf(str1, "x%d", index);
  return std::string(str1);
}

const char *dbm_toString(raw_t *dbm, cindex_t dim) 
{
  if (dbm_isEmpty(dbm, dim))
    {
      return "false";
    }

  uint32_t mingraph[bits2intsize(dim*dim)];
  size_t n = dbm_cleanBitMatrix(dbm, dim, mingraph,
                                dbm_analyzeForMinDBM(dbm, dim, mingraph));
  if (n == 0)
    {
      return "true";
    }

  char buffer[32];
  std::string str;
  bool firstConstraint = true;

  str += "(";
  for(cindex_t i = 0; i < dim; ++i)
    {
      for(cindex_t j = 0; j < dim; ++j)
        {
          if (base_readOneBit(mingraph, i*dim+j))
            {
              assert(i != j); // Not part of mingraph.

              // Conjunction of constraints.
              if (!firstConstraint)
                {
                  str += " && ";
                }
              firstConstraint = false;

              // Write constraints xi-xj <|<= DBM[i,j]
              if (i == 0)
                {
                  assert(j != 0); // 0,0 never part of mingraph
                  if (dbm_addFiniteRaw(dbm[j], dbm[j*dim]) == dbm_LE_ZERO)
                    {
                      assert(n);
                      n -= base_getOneBit(mingraph, j*dim);
                      base_resetOneBit(mingraph, j*dim);

                      // xj == b
                      snprintf(buffer, sizeof(buffer), "==%d",
                               -dbm_raw2bound(dbm[j]));
                      str += getClockName(j);
                      str += buffer;
                    }
                  else // b < xj, b <= xj
                    {
                      snprintf(buffer, sizeof(buffer), "%d%s",
                               -dbm_raw2bound(dbm[j]),
                               dbm_rawIsStrict(dbm[j]) ? "<" : "<=");
                      str += buffer;
                      str += getClockName(j);
                    }
                }
              else
                {
                  // xi-xj == b ?
                  if (dbm_addFiniteRaw(dbm[i*dim+j], dbm[j*dim+i]) == dbm_LE_ZERO)
                    {
                      assert(n);
                      n -= base_getOneBit(mingraph, j*dim+i);
                      base_resetOneBit(mingraph, j*dim+i);

                      // xi == xj
                      if (j > 0 && dbm[i*dim+j] == dbm_LE_ZERO)
                        {
                          str += getClockName(i);
                          str += "==";
                          str += getClockName(j);
                          goto consume_n;
                        }
                      // == b
                      snprintf(buffer, sizeof(buffer), "==%d",
                               dbm_raw2bound(dbm[i*dim+j]));
                    }
                  else
                    {
                      // xi < xj, xi <= xj
                      if (j > 0 && dbm_raw2bound(dbm[i*dim+j]) == 0)
                        {
                          str += getClockName(i);
                          str += dbm_rawIsStrict(dbm[i*dim+j]) ? "<" : "<=";
                          str += getClockName(j);
                          goto consume_n;
                        }
                      // < b, <= b
                      snprintf(buffer, sizeof(buffer), "%s%d",
                               dbm_rawIsStrict(dbm[i*dim+j]) ? "<" : "<=",
                               dbm_raw2bound(dbm[i*dim+j]));
                    }

                  if (j == 0) // xi < b, xi <= b
                    {
                      assert(i != 0); // 0,0 never part of mingraph
                      str += getClockName(i);
                      str += buffer;
                    }
                  else // xi-xj < b, xi-xj <= b
                    {
                      str += getClockName(i);
                      str += "-";
                      str += getClockName(j);
                      str += buffer;
                    }
                }
            consume_n:
              assert(n);
              --n; // Consumed one constraint.
              if (!n) goto stop_loops;
            }
        }
    }
 stop_loops:
  str += ")";

  return str.c_str();
}

extern "C" {
#endif

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>

  /* Accessing the DBM_STRUCT_T part of a Caml custom block */
#define dbm_struct_t_val(v) (*((dbm_struct_t *) Data_custom_val(v)))

  /* Accessing the RAW_T * part of a Caml custom block */
#define raw_t_val(v) (*((raw_t **) Data_custom_val(v)))

  /* Accessing the CONSTRAINT_T * part of a Caml custom block */
#define constraint_t_val(v) (*((constraint_t **) Data_custom_val(v)))

  /* Freeing the RAW_T * part of the DBM_STRUCT_T part of a Caml custom block
      while garbage collecting. */
  void dbm_struct_t_finalize (value v) {
    free(dbm_struct_t_val(v).dbm);
  }

  long dbm_struct_t_hash(value v) {
    return ((long) dbm_hash(dbm_struct_t_val(v).dbm, dbm_struct_t_val(v).dim));
  }

  int dbm_struct_t_compare (value v1, value v2) {
    raw_t *dbm1 = dbm_struct_t_val(v1).dbm;
    cindex_t dim1 = dbm_struct_t_val(v1).dim;
    raw_t *dbm2 = dbm_struct_t_val(v2).dbm;
    cindex_t dim2 = dbm_struct_t_val(v2).dim;
    if (dim1 != dim2) {
      if (dim1 > dim2) {
        return 1;
      } else {
        return -1;
      }
    } else {
      if (dbm_hash(dbm1, dim1) == dbm_hash(dbm2, dim2)) {
        return 0;
      } else {
        if (dbm_hash(dbm1, dim1) > dbm_hash(dbm2, dim2)) {
          return 1;
        } else {
          return -1;
        }
      }
    }
  }

  /* Freeing the RAW_T * part of a Caml custom block while garbage collecting. */
  void raw_t_finalize (value v) {
    free(raw_t_val(v));
  }

  /* Freeing the CONSTRAINT_T * part of a Caml custom block while garbage collecting. */
  void constraint_t_finalize (value v) {
    free(constraint_t_val(v));
  }

  /* Encapsulation of opaque handles (of type DBM_STRUCT_T *)
     as Caml custom blocks. */
  static struct custom_operations udbm_dbm_struct_t_ops = {
    "fr.inria.caml.udbm_dbm_struct_t",
    dbm_struct_t_finalize,
    dbm_struct_t_compare,
    dbm_struct_t_hash,
    custom_serialize_default,
    custom_deserialize_default
  };

  /* Encapsulation of opaque handles (of type RAW_T *)
     as Caml custom blocks. */
  static struct custom_operations udbm_raw_t_ops = {
    "fr.inria.caml.udbm_raw_t",
    raw_t_finalize,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default
  };

  /* Encapsulation of opaque handles (of type CONSTRAINT_T *)
     as Caml custom blocks. */
  static struct custom_operations udbm_constraint_t_ops = {
    "fr.inria.caml.udbm_constraint_t",
    constraint_t_finalize,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default
  };

  /* Allocating a Caml custom block to hold the given DBM_STRUCT_T */
  static value alloc_dbm_struct_t(dbm_struct_t  w)
  {
    value v = alloc_custom(&udbm_dbm_struct_t_ops, sizeof(dbm_struct_t), 0, 1);
    dbm_struct_t_val(v) = w;
    return v;
  }

  /* Allocating a Caml custom block to hold the given RAW_T * */
  static value alloc_raw_t(raw_t * w)
  {
    value v = alloc_custom(&udbm_raw_t_ops, sizeof(raw_t *), 0, 1);
    raw_t_val(v) = w;
    return v;
  }

  /* Allocating a Caml custom block to hold the given CONSTRAINT_T * */
  static value alloc_constraint_t(constraint_t * w)
  {
    value v = alloc_custom(&udbm_constraint_t_ops, sizeof(constraint_t *), 0, 1);
    constraint_t_val(v) = w;
    return v;
  }

  CAMLprim value zone_dbm_init (value dim) {
    CAMLparam1(dim);
    dbm_struct_t s;
    s.dim = Int_val(dim);
    s.dbm = (raw_t *)malloc(Int_val(dim)*Int_val(dim)*sizeof(raw_t));
    dbm_init(s.dbm, s.dim);
    CAMLreturn (alloc_dbm_struct_t(s));
  }

  CAMLprim value zone_dbm_constrainC (value dbm, value c) {
    CAMLparam2(dbm, c);
    /*Ignoring the argument dim.*/
    dbm_struct_t s, s_dup;
    s = dbm_struct_t_val(dbm);
    s_dup.dim = s.dim;
    s_dup.dbm = (raw_t *) malloc(s_dup.dim*s_dup.dim*sizeof(raw_t));
    dbm_copy(s_dup.dbm, s.dbm, s_dup.dim);
    dbm_constrainC(s_dup.dbm, s_dup.dim, *(constraint_t_val(c)));
    CAMLreturn (alloc_dbm_struct_t(s_dup));
  }

  CAMLprim value zone_dbm_constraint2 (value i,
                                       value j,
                                       value bound,
                                       value isStrict) {
    CAMLparam4(i, j, bound, isStrict);
    constraint_t *constraint = (constraint_t *)malloc(sizeof(constraint_t *));
    *constraint = dbm_constraint2((cindex_t)Int_val(i),
                                  (cindex_t)Int_val(j),
                                  (int32_t)Int_val(bound),
                                  isStrict == Val_true ? TRUE : FALSE);
    CAMLreturn (alloc_constraint_t(constraint));
  }

  CAMLprim value zone_dbm_isEmpty (value dbm, value dim) {
    CAMLparam2(dbm, dim);
    dbm_struct_t s = dbm_struct_t_val(dbm);
    /*Ignoring the argument dim.*/
    if (dbm_isEmpty(s.dbm, s.dim) == TRUE) {
      CAMLreturn (Val_int(1)); //ocaml true
    } else {
      CAMLreturn (Val_int(0)); //ocaml false
    }
  }

  CAMLprim value zone_dbm_haveIntersection (value dst, value src, value dim) {
    CAMLparam3(dst, src, dim);
    dbm_struct_t dst_dup;
    dst_dup.dim = dbm_struct_t_val(dst).dim;
    dst_dup.dbm = (raw_t *) malloc(dst_dup.dim*dst_dup.dim*sizeof(raw_t));
    dbm_copy(dst_dup.dbm, dbm_struct_t_val(dst).dbm, dst_dup.dim);
    if (dbm_intersection(dst_dup.dbm, dbm_struct_t_val(src).dbm, dst_dup.dim) == TRUE) {
      free(dst_dup.dbm);
      CAMLreturn (Val_int(1)); //ocaml true
    } else {
      free(dst_dup.dbm);
      CAMLreturn (Val_int(0)); //ocaml false
    }
  }

  CAMLprim value zone_dbm_intersection (value dst, value src, value dim) {
    CAMLparam3(dst, src, dim);
    dbm_struct_t dst_dup;
    dst_dup.dim = dbm_struct_t_val(dst).dim;
    dst_dup.dbm = (raw_t *) malloc(dst_dup.dim*dst_dup.dim*sizeof(raw_t));
    dbm_copy(dst_dup.dbm, dbm_struct_t_val(dst).dbm, dst_dup.dim);
    dbm_intersection(dst_dup.dbm, dbm_struct_t_val(src).dbm, dst_dup.dim);
    CAMLreturn (alloc_dbm_struct_t(dst_dup));
  }

  CAMLprim value zone_dbm_freeClock (value dbm, value dim, value k) {
    CAMLparam3(dbm, dim, k);
    dbm_struct_t s_dup;
    s_dup.dim = dbm_struct_t_val(dbm).dim;
    s_dup.dbm = (raw_t *) malloc(s_dup.dim*s_dup.dim*sizeof(raw_t));
    dbm_copy(s_dup.dbm, dbm_struct_t_val(dbm).dbm, s_dup.dim);
    dbm_freeClock(s_dup.dbm, s_dup.dim, Int_val(k));
    CAMLreturn (alloc_dbm_struct_t(s_dup));
  }

  CAMLprim value zone_dbm_updateValue (value dbm, value dim, value k, value val) {
    CAMLparam4(dbm, dim, k, val);
    dbm_struct_t s_dup;
    s_dup.dim = dbm_struct_t_val(dbm).dim;
    s_dup.dbm = (raw_t *) malloc(s_dup.dim*s_dup.dim*sizeof(raw_t));
    dbm_copy(s_dup.dbm, dbm_struct_t_val(dbm).dbm, s_dup.dim);
    dbm_updateValue(s_dup.dbm, s_dup.dim, Int_val(k), Int_val(val));
    CAMLreturn (alloc_dbm_struct_t(s_dup));
  }

  CAMLprim value zone_dbm_up(value dbm, value dim) {
    CAMLparam2(dbm, dim);
    dbm_struct_t s_dup;
    s_dup.dim = dbm_struct_t_val(dbm).dim;
    s_dup.dbm = (raw_t *) malloc(s_dup.dim*s_dup.dim*sizeof(raw_t));
    dbm_copy(s_dup.dbm, dbm_struct_t_val(dbm).dbm, s_dup.dim);
    dbm_up(s_dup.dbm, s_dup.dim);
    CAMLreturn (alloc_dbm_struct_t(s_dup));
  }

  CAMLprim value zone_dbm_toString(value dbm, value dim) {
    CAMLparam2(dbm, dim);
    CAMLreturn (caml_copy_string(dbm_toString(dbm_struct_t_val(dbm).dbm, dbm_struct_t_val(dbm).dim)));
  }

  CAMLprim value zone_dbm_zero(value dbm, value dim) {
    CAMLparam2(dbm, dim);
    dbm_struct_t s_dup;
    s_dup.dim = dbm_struct_t_val(dbm).dim;
    s_dup.dbm = (raw_t *) malloc(s_dup.dim*s_dup.dim*sizeof(raw_t));
    dbm_copy(s_dup.dbm, dbm_struct_t_val(dbm).dbm, s_dup.dim);
    dbm_zero(s_dup.dbm, Int_val(dim));
    CAMLreturn (alloc_dbm_struct_t(s_dup));
  }

  CAMLprim value zone_dbm_areEqual(value dbm1, value dbm2, value dim) {
    CAMLparam3(dbm1, dbm2, dim);
    switch
      (dbm_areEqual
       (dbm_struct_t_val(dbm1).dbm, dbm_struct_t_val(dbm2).dbm, dbm_struct_t_val(dbm1).dim)
       ) {
    case TRUE:
      CAMLreturn(Val_int(1));
      break;
    case FALSE:
      CAMLreturn(Val_int(0));
      break;
    default:
      CAMLreturn(Val_int(0));
      break;
    }
  }

  CAMLprim value zone_dbm_isZeroIncluded(value dbm, value dim) {
    CAMLparam2(dbm, dim);
    int32_t *pt = (int32_t *)malloc(Int_val(dim)*sizeof(int32_t));
    int ii;
    for (ii = 0; ii++; ii < Int_val(dim)) {
      pt[ii] = 0;
    }
    BOOL temp1 = dbm_isPointIncluded(pt, dbm_struct_t_val(dbm).dbm, dbm_struct_t_val(dbm).dim);
    free(pt);
    switch (temp1) {
    case TRUE:
      CAMLreturn(Val_int(1));
      break;
    case FALSE:
      CAMLreturn(Val_int(0));
      break;
    default:
      CAMLreturn(Val_int(0));
      break;
    }
  }

  CAMLprim value zone_dbm_toConstraintList(value dbm_value, value dim_value) 
  {
    CAMLparam2(dbm_value, dim_value);
    raw_t *dbm = dbm_struct_t_val(dbm_value).dbm;
    cindex_t dim = dbm_struct_t_val(dbm_value).dim;
    assert (!dbm_isEmpty(dbm, dim));
      
    uint32_t mingraph[bits2intsize(dim*dim)];
    size_t n = dbm_cleanBitMatrix(dbm, dim, mingraph,
                                  dbm_analyzeForMinDBM(dbm, dim, mingraph));
    if (n == 0)
      {
        //This is the "true" constraint, so we just let it be an empty list.
        CAMLreturn(Val_int(0)); 
      }

    /* This allocates an empty OCAML list. */
    CAMLlocal1 (current);
    current = Val_int(0); 

    /* str += "("; */
    for(cindex_t i = 0; i < dim; ++i)
      {
        for(cindex_t j = 0; j < dim; ++j)
          {
            if (base_readOneBit(mingraph, i*dim+j))
              {
                CAMLlocal1(hd);
                hd = caml_alloc_tuple(4);
                Store_field(hd, 0, Val_int(i));
                Store_field(hd, 1, Val_int(j));
                switch (dbm_rawIsStrict(dbm[i*dim+j])) {
                case TRUE: Store_field(hd, 2, Val_int(1));break;
                case FALSE: Store_field(hd, 2, Val_int(0));break;
                default: break;
                }
                Store_field(hd, 3, Val_int(dbm_raw2bound(dbm[i*dim + j])));
                CAMLlocal1(temp);
                temp = caml_alloc(2, 0);
                Store_field(temp, 0, hd);
                Store_field(temp, 1, current);
                current = temp;
              }
          }
      }
  stop_loops:
    CAMLreturn(current);
  }

  CAMLprim value zone_dbm_toLargerConstraintList(value dbm_value, value dim_value) 
  {
    CAMLparam2(dbm_value, dim_value);
    raw_t *dbm = dbm_struct_t_val(dbm_value).dbm;
    cindex_t dim = dbm_struct_t_val(dbm_value).dim;
    assert (!dbm_isEmpty(dbm, dim));
      
    uint32_t mingraph[bits2intsize(dim*dim)];
    size_t n = dbm_cleanBitMatrix(dbm, dim, mingraph,
                                  dbm_analyzeForMinDBM(dbm, dim, mingraph));
    if (n == 0)
      {
        //This is the "true" constraint, so we just let it be an empty list.
        CAMLreturn(Val_int(0)); 
      }

    /* This allocates an empty OCAML list. */
    CAMLlocal1 (current);
    current = Val_int(0); 

    /* str += "("; */
    for(cindex_t i = 0; i < dim; ++i)
      {
        for(cindex_t j = 0; j < dim; ++j)
          {
            if (!(dbm[i*dim+j] == dbm_LS_INFINITY) && i != j)
              {
                CAMLlocal1(hd);
                hd = caml_alloc_tuple(4);
                Store_field(hd, 0, Val_int(i));
                Store_field(hd, 1, Val_int(j));
                switch (dbm_rawIsStrict(dbm[i*dim+j])) {
                case TRUE: Store_field(hd, 2, Val_int(1));break;
                case FALSE: Store_field(hd, 2, Val_int(0));break;
                default: break;
                }
                Store_field(hd, 3, Val_int(dbm_raw2bound(dbm[i*dim + j])));
                CAMLlocal1(temp);
                temp = caml_alloc(2, 0);
                Store_field(temp, 0, hd);
                Store_field(temp, 1, current);
                current = temp;
              }
          }
      }
  stop_loops:
    CAMLreturn(current);
  }

  /* This is intended to be experimental in nature. */
  CAMLprim value zone_int_toList (value n) {
    CAMLparam1(n);
    CAMLlocal1(current);
    current = Val_int(0);
    int i;
    for (i = 0; i < Int_val(n); i++) {
      CAMLlocal1(temp);
      temp = caml_alloc(2, 0);
      CAMLlocal1(hd);
      hd = caml_alloc_tuple(2);
      Store_field(hd, 0, Val_int(i));
      Store_field(hd, 1, Val_int(1));
      Store_field(temp, 0, hd);
      Store_field(temp, 1, current);
      current = temp;
    }
    CAMLreturn(current);
  }

#ifdef __cplusplus
}
#endif
