/* This file is part of the Variable::Magic Perl module.
 * See http://search.cpan.org/dist/Variable-Magic/ */

#include <stdarg.h> /* <va_list>, va_{start,arg,end}, ... */

#include <stdio.h>  /* sprintf() */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define __PACKAGE__ "Variable::Magic"

#define R(S) fprintf(stderr, "R(" #S ") = %d\n", SvREFCNT(S))

#define PERL_VERSION_GE(R, V, S) (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#define PERL_VERSION_LE(R, V, S) (PERL_REVISION < (R) || (PERL_REVISION == (R) && (PERL_VERSION < (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION <= (S))))))

#define PERL_API_VERSION_GE(R, V, S) (PERL_API_REVISION > (R) || (PERL_API_REVISION == (R) && (PERL_API_VERSION > (V) || (PERL_API_VERSION == (V) && (PERL_API_SUBVERSION >= (S))))))

#define PERL_API_VERSION_LE(R, V, S) (PERL_API_REVISION < (R) || (PERL_API_REVISION == (R) && (PERL_API_VERSION < (V) || (PERL_API_VERSION == (V) && (PERL_API_SUBVERSION <= (S))))))

#ifndef VMG_PERL_PATCHLEVEL
# ifdef PERL_PATCHNUM
#  define VMG_PERL_PATCHLEVEL PERL_PATCHNUM
# else
#  define VMG_PERL_PATCHLEVEL 0
# endif
#endif

/* --- Compatibility ------------------------------------------------------- */

#ifndef Newx
# define Newx(v, n, c) New(0, v, n, c)
#endif

#ifndef SvMAGIC_set
# define SvMAGIC_set(sv, val) (SvMAGIC(sv) = (val))
#endif

#ifndef mPUSHi
# define mPUSHi(I) PUSHs(sv_2mortal(newSViv(I)))
#endif

#ifndef dMY_CXT
# define MY_CXT vmg_globaldata
# define dMY_CXT
# define START_MY_CXT STATIC my_cxt_t MY_CXT;
# define MY_CXT_INIT
#endif

#ifndef PERL_MAGIC_ext
# define PERL_MAGIC_ext '~'
#endif

#ifndef MGf_COPY
# define MGf_COPY 0
#endif

#ifndef MGf_DUP
# define MGf_DUP 0
#endif

#ifndef MGf_LOCAL
# define MGf_LOCAL 0
#endif

#if PERL_API_VERSION_GE(5, 10, 0)
# define VMG_UVAR 1
#else
# define VMG_UVAR 0
#endif

#if (VMG_PERL_PATCHLEVEL >= 25854) || (!VMG_PERL_PATCHLEVEL && PERL_VERSION_GE(5, 9, 3))
# define VMG_COMPAT_ARRAY_PUSH_NOLEN 1
#else
# define VMG_COMPAT_ARRAY_PUSH_NOLEN 0
#endif

/* since 5.9.5 - see #43357 */
#if (VMG_PERL_PATCHLEVEL >= 31473) || (!VMG_PERL_PATCHLEVEL && PERL_VERSION_GE(5, 9, 5))
# define VMG_COMPAT_ARRAY_UNDEF_CLEAR 1
#else
# define VMG_COMPAT_ARRAY_UNDEF_CLEAR 0
#endif

#if (VMG_PERL_PATCHLEVEL >= 32969) || (!VMG_PERL_PATCHLEVEL && PERL_VERSION_GE(5, 11, 0))
# define VMG_COMPAT_SCALAR_LENGTH_NOLEN 1
#else
# define VMG_COMPAT_SCALAR_LENGTH_NOLEN 0
#endif

#if VMG_UVAR

/* Bug-free mg_magical - see http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2008-01/msg00036.html - but specialized to our needs. */
STATIC void vmg_sv_magicuvar(pTHX_ SV *sv, const char *uf, I32 len) {
#define vmg_sv_magicuvar(S, U, L) vmg_sv_magicuvar(aTHX_ (S), (U), (L))
 const MAGIC* mg;
 sv_magic(sv, NULL, PERL_MAGIC_uvar, uf, len);
 /* uvar magic has set and get magic, hence this has set SVs_GMG and SVs_SMG. */
 PERL_UNUSED_CONTEXT;
 if ((mg = SvMAGIC(sv))) {
  SvRMAGICAL_off(sv);
  do {
   const MGVTBL* const vtbl = mg->mg_virtual;
   if (vtbl) {
    if (vtbl->svt_clear) {
     SvRMAGICAL_on(sv);
     break;
    }
   }
  } while ((mg = mg->mg_moremagic));
 }
}

#endif /* VMG_UVAR */

/* --- Context-safe global data -------------------------------------------- */

#define MY_CXT_KEY __PACKAGE__ "::_guts" XS_VERSION

typedef struct {
 HV *wizz;
 U16 count;
} my_cxt_t;

START_MY_CXT

/* --- Signatures ---------------------------------------------------------- */

#define SIG_MIN ((U16) (1u << 8))
#define SIG_MAX ((U16) ((1u << 16) - 1))
#define SIG_NBR (SIG_MAX - SIG_MIN + 1)
#define SIG_WIZ ((U16) ((1u << 8) - 1))

/* ... Generate signatures ................................................. */

STATIC U16 vmg_gensig(pTHX) {
#define vmg_gensig() vmg_gensig(aTHX)
 U16 sig;
 char buf[8];
 dMY_CXT;

 do {
  sig = SIG_NBR * Drand01() + SIG_MIN;
 } while (hv_exists(MY_CXT.wizz, buf, sprintf(buf, "%u", sig)));

 return sig;
}

/* --- MGWIZ structure ----------------------------------------------------- */

typedef struct {
 MGVTBL *vtbl;
 U16 sig;
 U16 uvar;
 SV *cb_data;
 SV *cb_get, *cb_set, *cb_len, *cb_clear, *cb_free;
#if MGf_COPY
 SV *cb_copy;
#endif /* MGf_COPY */
#if MGf_DUP
 SV *cb_dup;
#endif /* MGf_DUP */
#if MGf_LOCAL
 SV *cb_local;
#endif /* MGf_LOCAL */
#if VMG_UVAR
 SV *cb_fetch, *cb_store, *cb_exists, *cb_delete;
#endif /* VMG_UVAR */
} MGWIZ;

#define MGWIZ2SV(W) (newSVuv(PTR2UV(W)))
#define SV2MGWIZ(S) (INT2PTR(MGWIZ*, SvUVX((SV *) (S))))

/* ... Construct private data .............................................. */

STATIC SV *vmg_data_new(pTHX_ SV *ctor, SV *sv, AV *args) {
#define vmg_data_new(C, S, A) vmg_data_new(aTHX_ (C), (S), (A))
 SV *nsv;

 dSP;
 int count;

 ENTER;
 SAVETMPS;

 PUSHMARK(SP);
 XPUSHs(sv_2mortal(newRV_inc(sv)));
 if (args != NULL) {
  I32 i, alen = av_len(args);
  for (i = 0; i < alen; ++i) { XPUSHs(*av_fetch(args, i, 0)); }
 }
 PUTBACK;

 count = call_sv(ctor, G_SCALAR);

 SPAGAIN;

 if (count != 1) { croak("Callback needs to return 1 scalar\n"); }
 nsv = POPs;
#if PERL_VERSION_LE(5, 8, 2)
 nsv = sv_newref(nsv); /* Workaround some bug in SvREFCNT_inc() */
#else
 SvREFCNT_inc(nsv);    /* Or it will be destroyed in FREETMPS */
#endif

 PUTBACK;

 FREETMPS;
 LEAVE;

 return nsv;
}

STATIC SV *vmg_data_get(SV *sv, U16 sig) {
 MAGIC *mg, *moremagic;

 if (SvTYPE(sv) >= SVt_PVMG) {
  for (mg = SvMAGIC(sv); mg; mg = moremagic) {
   moremagic = mg->mg_moremagic;
   if ((mg->mg_type == PERL_MAGIC_ext) && (mg->mg_private == sig)) { break; }
  }
  if (mg) { return mg->mg_obj; }
 }

 return NULL;
} 

/* ... Magic cast/dispell .................................................. */

#if VMG_UVAR
STATIC I32 vmg_svt_val(pTHX_ IV, SV *);

STATIC void vmg_uvar_del(SV *sv, MAGIC *prevmagic, MAGIC *mg, MAGIC *moremagic) {
 if (prevmagic) {
  prevmagic->mg_moremagic = moremagic;
 } else {
  SvMAGIC_set(sv, moremagic);
 }
 mg->mg_moremagic = NULL;
 Safefree(mg->mg_ptr);
 Safefree(mg);
}
#endif /* VMG_UVAR */

STATIC UV vmg_cast(pTHX_ SV *sv, SV *wiz, AV *args) {
#define vmg_cast(S, W, A) vmg_cast(aTHX_ (S), (W), (A))
 MAGIC *mg = NULL, *moremagic = NULL;
 MGWIZ *w;
 SV *data;

 w = SV2MGWIZ(wiz);

 if (SvTYPE(sv) >= SVt_PVMG) {
  for (mg = SvMAGIC(sv); mg; mg = moremagic) {
   moremagic = mg->mg_moremagic;
   if ((mg->mg_type == PERL_MAGIC_ext) && (mg->mg_private == w->sig)) { break; }
  }
  if (mg) { return 1; }
 }

 data = (w->cb_data) ? vmg_data_new(w->cb_data, sv, args) : NULL;
 mg = sv_magicext(sv, data, PERL_MAGIC_ext, w->vtbl, (const char *) wiz, HEf_SVKEY);
 mg->mg_private = w->sig;
 mg->mg_flags   = mg->mg_flags
#if MGf_COPY
                | MGf_COPY
#endif /* MGf_COPY */
#if MGf_DUP
                | MGf_DUP
#endif /* MGf_DUP */
#if MGf_LOCAL
                | MGf_LOCAL
#endif /* MGf_LOCAL */
                ;

#if VMG_UVAR
 if (w->uvar && SvTYPE(sv) >= SVt_PVHV) {
  MAGIC *prevmagic;
  int add_uvar = 1;
  struct ufuncs uf[2];

  uf[0].uf_val   = vmg_svt_val;
  uf[0].uf_set   = NULL;
  uf[0].uf_index = 0;
  uf[1].uf_val   = NULL;
  uf[1].uf_set   = NULL;
  uf[1].uf_index = 0;

  /* One uvar magic in the chain is enough. */
  for (prevmagic = NULL, mg = SvMAGIC(sv); mg; prevmagic = mg, mg = moremagic) {
   moremagic = mg->mg_moremagic;
   if (mg->mg_type == PERL_MAGIC_uvar) { break; }
  }

  if (mg) { /* Found another uvar magic. */
   struct ufuncs *olduf = (struct ufuncs *) mg->mg_ptr;
   if (olduf->uf_val == vmg_svt_val) {
    /* It's our uvar magic, nothing to do. */
    add_uvar = 0;
   } else {
    /* It's another uvar magic, backup it and replace it by ours. */
    uf[1] = *olduf;
    vmg_uvar_del(sv, prevmagic, mg, moremagic);
   }
  }

  if (add_uvar) {
   vmg_sv_magicuvar(sv, (const char *) &uf, sizeof(uf));
  }

 }
#endif /* VMG_UVAR */

 return 1;
}

STATIC UV vmg_dispell(pTHX_ SV *sv, U16 sig) {
#define vmg_dispell(S, Z) vmg_dispell(aTHX_ (S), (Z))
#if VMG_UVAR
 U32 uvars = 0;
#endif /* VMG_UVAR */
 MAGIC *mg, *prevmagic, *moremagic = NULL;

 if (SvTYPE(sv) < SVt_PVMG) { return 0; }

 for (prevmagic = NULL, mg = SvMAGIC(sv); mg; prevmagic = mg, mg = moremagic) {
  moremagic = mg->mg_moremagic;
  if (mg->mg_type == PERL_MAGIC_ext) {
   if (mg->mg_private == sig) {
#if VMG_UVAR
    /* If the current has no uvar, short-circuit uvar deletion. */
    uvars = (SV2MGWIZ(mg->mg_ptr)->uvar) ? (uvars + 1) : 0;
#endif /* VMG_UVAR */
    break;
#if VMG_UVAR
   } else if ((mg->mg_private >= SIG_MIN) &&
              (mg->mg_private <= SIG_MAX) &&
               SV2MGWIZ(mg->mg_ptr)->uvar) {
    ++uvars;
    /* We can't break here since we need to find the ext magic to delete. */
#endif /* VMG_UVAR */
   }
  }
 }
 if (!mg) { return 0; }

 if (prevmagic) {
  prevmagic->mg_moremagic = moremagic;
 } else {
  SvMAGIC_set(sv, moremagic);
 }
 mg->mg_moremagic = NULL;

 if (mg->mg_obj != sv) { SvREFCNT_dec(mg->mg_obj); } /* Destroy private data */
 SvREFCNT_dec((SV *) mg->mg_ptr); /* Unreference the wizard */
 Safefree(mg);

#if VMG_UVAR
 if (uvars == 1 && SvTYPE(sv) >= SVt_PVHV) {
  /* mg was the first ext magic in the chain that had uvar */

  for (mg = moremagic; mg; mg = mg->mg_moremagic) {
   if ((mg->mg_type == PERL_MAGIC_ext) &&
       (mg->mg_private >= SIG_MIN) &&
       (mg->mg_private <= SIG_MAX) &&
        SV2MGWIZ(mg->mg_ptr)->uvar) {
    ++uvars;
    break;
   }
  }

  if (uvars == 1) {
   struct ufuncs *uf;
   for (prevmagic = NULL, mg = SvMAGIC(sv); mg; prevmagic = mg, mg = moremagic){
    moremagic = mg->mg_moremagic;
    if (mg->mg_type == PERL_MAGIC_uvar) { break; }
   }
   /* assert(mg); */
   uf = (struct ufuncs *) mg->mg_ptr;
   /* assert(uf->uf_val == vmg_svt_val); */
   if (uf[1].uf_val || uf[1].uf_set) {
    /* Revert the original uvar magic. */
    uf[0] = uf[1];
    Renew(uf, 1, struct ufuncs);
    mg->mg_ptr = (char *) uf;
    mg->mg_len = sizeof(struct ufuncs);
   } else {
    /* Remove the uvar magic. */
    vmg_uvar_del(sv, prevmagic, mg, moremagic);
   }
  }
 }
#endif /* VMG_UVAR */

 return 1;
}

/* ... svt callbacks ....................................................... */

STATIC int vmg_cb_call(pTHX_ SV *cb, SV *sv, SV *data, unsigned int args, ...) {
 va_list ap;
 SV *svr;
 int ret;
 unsigned int i;

 dSP;
 int count;

 ENTER;
 SAVETMPS;

 PUSHMARK(SP);
 EXTEND(SP, args + 2);
 PUSHs(sv_2mortal(newRV_inc(sv)));
 PUSHs(data ? data : &PL_sv_undef);
 va_start(ap, args);
 for (i = 0; i < args; ++i) {
  SV *sva = va_arg(ap, SV *);
  PUSHs(sva ? sva : &PL_sv_undef);
 }
 va_end(ap);
 PUTBACK;

 count = call_sv(cb, G_SCALAR);

 SPAGAIN;

 if (count != 1) { croak("Callback needs to return 1 scalar\n"); }
 svr = POPs;
 ret = SvOK(svr) ? SvIV(svr) : 0;

 PUTBACK;

 FREETMPS;
 LEAVE;

 return ret;
}

#define vmg_cb_call1(I, S, D)         vmg_cb_call(aTHX_ (I), (S), (D), 0)
#define vmg_cb_call2(I, S, D, S2)     vmg_cb_call(aTHX_ (I), (S), (D), 1, (S2))
#define vmg_cb_call3(I, S, D, S2, S3) vmg_cb_call(aTHX_ (I), (S), (D), 2, (S2), (S3))

STATIC int vmg_svt_get(pTHX_ SV *sv, MAGIC *mg) {
 return vmg_cb_call1(SV2MGWIZ(mg->mg_ptr)->cb_get, sv, mg->mg_obj);
}

STATIC int vmg_svt_set(pTHX_ SV *sv, MAGIC *mg) {
 return vmg_cb_call1(SV2MGWIZ(mg->mg_ptr)->cb_set, sv, mg->mg_obj);
}

STATIC U32 vmg_svt_len(pTHX_ SV *sv, MAGIC *mg) {
 SV *svr;
 I32 len;
 U32 ret;

 dSP;
 int count;

 ENTER;
 SAVETMPS;

 PUSHMARK(SP);
 EXTEND(SP, 3);
 PUSHs(sv_2mortal(newRV_inc(sv)));
 PUSHs(mg->mg_obj ? mg->mg_obj : &PL_sv_undef);
 if (SvTYPE(sv) == SVt_PVAV) {
  len = av_len((AV *) sv) + 1;
  mPUSHi(len);
 } else {
  len = 1;
  PUSHs(&PL_sv_undef);
 }
 PUTBACK;

 count = call_sv(SV2MGWIZ(mg->mg_ptr)->cb_len, G_SCALAR);

 SPAGAIN;

 if (count != 1) { croak("Callback needs to return 1 scalar\n"); }
 svr = POPs;
 ret = SvOK(svr) ? SvUV(svr) : len;

 PUTBACK;

 FREETMPS;
 LEAVE;

 return ret - 1;
}

STATIC int vmg_svt_clear(pTHX_ SV *sv, MAGIC *mg) {
 return vmg_cb_call1(SV2MGWIZ(mg->mg_ptr)->cb_clear, sv, mg->mg_obj);
}

STATIC int vmg_svt_free(pTHX_ SV *sv, MAGIC *mg) {
 /* So that it can survive tmp cleanup in vmg_cb_call */
 SvREFCNT_inc(sv);
 /* Perl_mg_free will get rid of the magic and decrement mg->mg_obj and
  * mg->mg_ptr reference count */
 return vmg_cb_call1(SV2MGWIZ(mg->mg_ptr)->cb_free, sv, mg->mg_obj);
}

#if MGf_COPY
STATIC int vmg_svt_copy(pTHX_ SV *sv, MAGIC *mg, SV *nsv, const char *key,
# if (VMG_PERL_PATCHLEVEL >= 33256) || (!VMG_PERL_PATCHLEVEL && PERL_API_VERSION_GE(5, 11, 0))
  I32 keylen
# else
  int keylen
# endif
 ) {
 SV *keysv;
 int ret;

 if (keylen == HEf_SVKEY) {
  keysv = (SV *) key;
 } else {
  keysv = newSVpvn(key, keylen);
 }

 ret = vmg_cb_call3(SV2MGWIZ(mg->mg_ptr)->cb_copy, sv, mg->mg_obj, keysv, nsv);

 if (keylen != HEf_SVKEY) {
  SvREFCNT_dec(keysv);
 }

 return ret;
}
#endif /* MGf_COPY */

#if 0 /*  MGf_DUP */
STATIC int vmg_svt_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
 return 0;
}
#endif /* MGf_DUP */

#if MGf_LOCAL
STATIC int vmg_svt_local(pTHX_ SV *nsv, MAGIC *mg) {
 return vmg_cb_call1(SV2MGWIZ(mg->mg_ptr)->cb_local, nsv, mg->mg_obj);
}
#endif /* MGf_LOCAL */

#if VMG_UVAR
STATIC I32 vmg_svt_val(pTHX_ IV action, SV *sv) {
 struct ufuncs *uf;
 MAGIC *mg;
 SV *key = NULL;

 mg  = mg_find(sv, PERL_MAGIC_uvar);
 /* mg can't be NULL or we wouldn't be there. */
 key = mg->mg_obj;
 uf  = (struct ufuncs *) mg->mg_ptr;

 if (uf[1].uf_val != NULL) { uf[1].uf_val(aTHX_ action, sv); }
 if (uf[1].uf_set != NULL) { uf[1].uf_set(aTHX_ action, sv); }

 action &= HV_FETCH_ISSTORE | HV_FETCH_ISEXISTS | HV_FETCH_LVALUE | HV_DELETE;
 for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
  MGWIZ *w;
  if ((mg->mg_type != PERL_MAGIC_ext)
   || (mg->mg_private < SIG_MIN)
   || (mg->mg_private > SIG_MAX)) { continue; }
  w = SV2MGWIZ(mg->mg_ptr);
  if (!w->uvar) { continue; }
  switch (action) {
   case 0:
    if (w->cb_fetch)  { vmg_cb_call2(w->cb_fetch,  sv, mg->mg_obj, key); }
    break;
   case HV_FETCH_ISSTORE:
   case HV_FETCH_LVALUE:
   case (HV_FETCH_ISSTORE|HV_FETCH_LVALUE):
    if (w->cb_store)  { vmg_cb_call2(w->cb_store,  sv, mg->mg_obj, key); }
    break;
   case HV_FETCH_ISEXISTS:
    if (w->cb_exists) { vmg_cb_call2(w->cb_exists, sv, mg->mg_obj, key); }
    break;
   case HV_DELETE:
    if (w->cb_delete) { vmg_cb_call2(w->cb_delete, sv, mg->mg_obj, key); }
    break;
  }
 }

 return 0;
}
#endif /* VMG_UVAR */

/* ... Wizard destructor ................................................... */

STATIC int vmg_wizard_free(pTHX_ SV *wiz, MAGIC *mg) {
 char buf[8];
 MGWIZ *w;
 dMY_CXT;

 w = SV2MGWIZ(wiz);

 SvREFCNT_inc(wiz); /* Fake survival - it's gonna be deleted anyway */
#if PERL_API_VERSION_GE(5, 9, 5)
 SvREFCNT_inc(wiz); /* One more push */
#endif
 if (hv_delete(MY_CXT.wizz, buf, sprintf(buf, "%u", w->sig), 0)) {
  --MY_CXT.count;
 }

 if (w->cb_data  != NULL) { SvREFCNT_dec(SvRV(w->cb_data)); }
 if (w->cb_get   != NULL) { SvREFCNT_dec(SvRV(w->cb_get)); }
 if (w->cb_set   != NULL) { SvREFCNT_dec(SvRV(w->cb_set)); }
 if (w->cb_len   != NULL) { SvREFCNT_dec(SvRV(w->cb_len)); }
 if (w->cb_clear != NULL) { SvREFCNT_dec(SvRV(w->cb_clear)); }
 if (w->cb_free  != NULL) { SvREFCNT_dec(SvRV(w->cb_free)); }
#if MGf_COPY
 if (w->cb_copy  != NULL) { SvREFCNT_dec(SvRV(w->cb_copy)); }
#endif /* MGf_COPY */
#if MGf_DUP
 if (w->cb_dup   != NULL) { SvREFCNT_dec(SvRV(w->cb_dup)); }
#endif /* MGf_DUP */
#if MGf_LOCAL
 if (w->cb_local != NULL) { SvREFCNT_dec(SvRV(w->cb_local)); }
#endif /* MGf_LOCAL */
#if VMG_UVAR
 if (w->cb_fetch  != NULL) { SvREFCNT_dec(SvRV(w->cb_fetch)); }
 if (w->cb_store  != NULL) { SvREFCNT_dec(SvRV(w->cb_store)); }
 if (w->cb_exists != NULL) { SvREFCNT_dec(SvRV(w->cb_exists)); }
 if (w->cb_delete != NULL) { SvREFCNT_dec(SvRV(w->cb_delete)); }
#endif /* VMG_UVAR */
 Safefree(w->vtbl);
 Safefree(w);

 return 0;
}

STATIC MGVTBL vmg_wizard_vtbl = {
 NULL,            /* get */
 NULL,            /* set */
 NULL,            /* len */
 NULL,            /* clear */
 vmg_wizard_free, /* free */
#if MGf_COPY
 NULL,            /* copy */
#endif /* MGf_COPY */
#if MGf_DUP
 NULL,            /* dup */
#endif /* MGf_DUP */
#if MGf_LOCAL
 NULL,            /* local */
#endif /* MGf_LOCAL */
};

STATIC const char vmg_invalid_wiz[]    = "Invalid wizard object";
STATIC const char vmg_invalid_sv[]     = "Invalid variable";
STATIC const char vmg_invalid_sig[]    = "Invalid numeric signature";
STATIC const char vmg_wrongargnum[]    = "Wrong number of arguments";
STATIC const char vmg_toomanysigs[]    = "Too many magic signatures used";
STATIC const char vmg_argstorefailed[] = "Error while storing arguments";

STATIC U16 vmg_sv2sig(pTHX_ SV *sv) {
#define vmg_sv2sig(S) vmg_sv2sig(aTHX_ (S))
 U16 sig;

 if (SvIOK(sv)) {
  sig = SvUVX(sv);
 } else if (SvNOK(sv)) {
  sig = SvNVX(sv);
 } else if ((SvPOK(sv) && grok_number(SvPVX(sv), SvCUR(sv), NULL))) {
  sig = SvUV(sv);
 } else {
  croak(vmg_invalid_sig);
 }
 if (sig < SIG_MIN) { sig += SIG_MIN; }
 if (sig > SIG_MAX) { sig %= SIG_MAX + 1; }

 return sig;
}

#define VMG_SET_CB(S, N)              \
 cb = (S);                            \
 w->cb_ ## N = (SvOK(cb) && SvROK(cb)) ? newRV_inc(SvRV(cb)) : NULL;

#define VMG_SET_SVT_CB(S, N)          \
 cb = (S);                            \
 if (SvOK(cb) && SvROK(cb)) {         \
  t->svt_ ## N = vmg_svt_ ## N;       \
  w->cb_  ## N = newRV_inc(SvRV(cb)); \
 } else {                             \
  t->svt_ ## N = NULL;                \
  w->cb_  ## N = NULL;                \
 }


/* --- XS ------------------------------------------------------------------ */

MODULE = Variable::Magic            PACKAGE = Variable::Magic

PROTOTYPES: ENABLE

BOOT:
{
 HV *stash;
 MY_CXT_INIT;
 MY_CXT.wizz = newHV();
 MY_CXT.count = 0;
 stash = gv_stashpv(__PACKAGE__, 1);
 newCONSTSUB(stash, "SIG_MIN",   newSVuv(SIG_MIN));
 newCONSTSUB(stash, "SIG_MAX",   newSVuv(SIG_MAX));
 newCONSTSUB(stash, "SIG_NBR",   newSVuv(SIG_NBR));
 newCONSTSUB(stash, "MGf_COPY",  newSVuv(MGf_COPY));
 newCONSTSUB(stash, "MGf_DUP",   newSVuv(MGf_DUP));
 newCONSTSUB(stash, "MGf_LOCAL", newSVuv(MGf_LOCAL));
 newCONSTSUB(stash, "VMG_UVAR",  newSVuv(VMG_UVAR));
 newCONSTSUB(stash, "VMG_COMPAT_ARRAY_PUSH_NOLEN",
                    newSVuv(VMG_COMPAT_ARRAY_PUSH_NOLEN));
 newCONSTSUB(stash, "VMG_COMPAT_ARRAY_UNDEF_CLEAR",
                    newSVuv(VMG_COMPAT_ARRAY_UNDEF_CLEAR));
 newCONSTSUB(stash, "VMG_COMPAT_SCALAR_LENGTH_NOLEN",
                    newSVuv(VMG_COMPAT_SCALAR_LENGTH_NOLEN));
}

SV *_wizard(...)
PROTOTYPE: DISABLE
PREINIT:
 I32 i = 0;
 U16 sig;
 char buf[8];
 MGWIZ *w;
 MGVTBL *t;
 MAGIC *mg;
 SV *sv;
 SV *svsig;
 SV *cb;
CODE:
 dMY_CXT;

 if (items != 7
#if MGf_COPY
              + 1
#endif /* MGf_COPY */
#if MGf_DUP
              + 1
#endif /* MGf_DUP */
#if MGf_LOCAL
              + 1
#endif /* MGf_LOCAL */
#if VMG_UVAR
              + 4
#endif /* VMG_UVAR */
              ) { croak(vmg_wrongargnum); }

 svsig = ST(i++);
 if (SvOK(svsig)) {
  SV **old;
  sig = vmg_sv2sig(svsig);
  if ((old = hv_fetch(MY_CXT.wizz, buf, sprintf(buf, "%u", sig), 0))) {
   ST(0) = sv_2mortal(newRV_inc(*old));
   XSRETURN(1);
  }
 } else {
  if (MY_CXT.count >= SIG_NBR) { croak(vmg_toomanysigs); }
  sig = vmg_gensig();
 }
 
 Newx(t, 1, MGVTBL);
 Newx(w, 1, MGWIZ);

 VMG_SET_CB(ST(i++), data);
 VMG_SET_SVT_CB(ST(i++), get);
 VMG_SET_SVT_CB(ST(i++), set);
 VMG_SET_SVT_CB(ST(i++), len);
 VMG_SET_SVT_CB(ST(i++), clear);
 VMG_SET_SVT_CB(ST(i++), free);
#if MGf_COPY
 VMG_SET_SVT_CB(ST(i++), copy);
#endif /* MGf_COPY */
#if MGf_DUP
 /* VMG_SET_SVT_CB(ST(i++), dup); */
 i++;
 t->svt_dup = NULL;
 w->cb_dup  = NULL;
#endif /* MGf_DUP */
#if MGf_LOCAL
 VMG_SET_SVT_CB(ST(i++), local);
#endif /* MGf_LOCAL */
#if VMG_UVAR
 VMG_SET_CB(ST(i++), fetch);
 VMG_SET_CB(ST(i++), store);
 VMG_SET_CB(ST(i++), exists);
 VMG_SET_CB(ST(i++), delete);
#endif /* VMG_UVAR */

 w->vtbl = t;
 w->sig  = sig;
#if VMG_UVAR
 w->uvar = (w->cb_fetch || w->cb_store || w->cb_exists || w->cb_delete);
#endif /* VMG_UVAR */

 sv = MGWIZ2SV(w);
 mg = sv_magicext(sv, NULL, PERL_MAGIC_ext, &vmg_wizard_vtbl, NULL, -1);
 mg->mg_private = SIG_WIZ;

 hv_store(MY_CXT.wizz, buf, sprintf(buf, "%u", sig), sv, 0);
 ++MY_CXT.count;
 
 RETVAL = newRV_noinc(sv);
OUTPUT:
 RETVAL

SV *gensig()
PROTOTYPE:
CODE:
 dMY_CXT;
 if (MY_CXT.count >= SIG_NBR) { croak(vmg_toomanysigs); }
 RETVAL = newSVuv(vmg_gensig());
OUTPUT:
 RETVAL

SV *getsig(SV *wiz)
PROTOTYPE: $
CODE:
 if (!SvROK(wiz)) { croak(vmg_invalid_wiz); }
 RETVAL = newSVuv(SV2MGWIZ(SvRV(wiz))->sig);
OUTPUT:
 RETVAL

SV *cast(SV *sv, SV *wiz, ...)
PROTOTYPE: \[$@%&*]$@
PREINIT:
 AV *args = NULL;
 SV *ret;
CODE:
 dMY_CXT;
 if (SvROK(wiz)) {
  wiz = SvRV(wiz);
 } else if (SvOK(wiz)) {
  char buf[8];
  SV **old;
  U16 sig = vmg_sv2sig(wiz);
  if ((old = hv_fetch(MY_CXT.wizz, buf, sprintf(buf, "%u", sig), 0))) {
   wiz = *old;
  } else {
   XSRETURN_UNDEF;
  }
 } else {
  croak(vmg_invalid_sig);
 }
 if (items > 2) {
  I32 i;
  args = newAV();
  av_fill(args, items - 2);
  for (i = 2; i < items; ++i) {
   SV *arg = ST(i);
   SvREFCNT_inc(arg);
   if (av_store(args, i - 2, arg) == NULL) { croak(vmg_argstorefailed); }
  }
 }
 ret = newSVuv(vmg_cast(SvRV(sv), wiz, args));
 SvREFCNT_dec(args);
 RETVAL = ret;
OUTPUT:
 RETVAL

SV *getdata(SV *sv, SV *wiz)
PROTOTYPE: \[$@%&*]$
PREINIT:
 SV *data;
 U16 sig;
CODE:
 dMY_CXT;
 if (SvROK(wiz)) {
  sig = SV2MGWIZ(SvRV(wiz))->sig;
 } else if (SvOK(wiz)) {
  char buf[8];
  sig = vmg_sv2sig(wiz);
  if (!hv_fetch(MY_CXT.wizz, buf, sprintf(buf, "%u", sig), 0)) {
   XSRETURN_UNDEF;
  }
 } else {
  croak(vmg_invalid_wiz);
 }
 data = vmg_data_get(SvRV(sv), sig);
 if (!data) { XSRETURN_UNDEF; }
 ST(0) = data;
 XSRETURN(1);

SV *dispell(SV *sv, SV *wiz)
PROTOTYPE: \[$@%&*]$
PREINIT:
 U16 sig;
CODE:
 dMY_CXT;
 if (SvROK(wiz)) {
  sig = SV2MGWIZ(SvRV(wiz))->sig;
 } else if (SvOK(wiz)) {
  char buf[8];
  sig = vmg_sv2sig(wiz);
  if (!hv_fetch(MY_CXT.wizz, buf, sprintf(buf, "%u", sig), 0)) {
   XSRETURN_UNDEF;
  }
 } else {
  croak(vmg_invalid_wiz);
 }
 RETVAL = newSVuv(vmg_dispell(SvRV(sv), sig));
OUTPUT:
 RETVAL
