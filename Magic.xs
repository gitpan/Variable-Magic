#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* --- Compatibility ------------------------------------------------------- */

#ifndef Newx
# define Newx(v, n, c) New(0, v, n, c)
#endif

#ifndef SvMAGIC_set
# define SvMAGIC_set(sv, val) (SvMAGIC(sv) = (val))
#endif

#define SIG_WIZ ((U16) (1u << 8 - 1))

#define R(S) fprintf(stderr, "R(" #S ") = %d\n", SvREFCNT(sv))

typedef struct {
 MGVTBL *vtbl;
 U16 sig;
 SV *cb_get, *cb_set, *cb_len, *cb_clear, *cb_free, *cb_data;
} MGWIZ;

#define MGWIZ2SV(W) (newSVuv(PTR2UV(W)))
#define SV2MGWIZ(S) (INT2PTR(MGWIZ*, SvUVX((SV *) (S))))

/* ... Construct private data .............................................. */

STATIC SV *vmg_data_new(pTHX_ SV *ctor, SV *sv) {
#define vmg_data_new(C, S) vmg_data_new(aTHX_ (C), (S))
 SV *nsv;

 dSP;
 int count;

 ENTER;
 SAVETMPS;

 PUSHMARK(SP);
 XPUSHs(sv);
 PUTBACK;

 count = call_sv(ctor, G_SCALAR);

 SPAGAIN;

 if (count != 1) { croak("Callback needs to return 1 scalar\n"); }
 nsv = POPs;
 SvREFCNT_inc(nsv); /* Or it will be destroyed in FREETMPS */

 PUTBACK;

 FREETMPS;
 LEAVE;

 return nsv;
}

STATIC SV *vmg_data_get(SV *sv, U16 sig) {
 MAGIC *mg, *moremagic;
 MGWIZ *w;

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

STATIC UV vmg_cast(pTHX_ SV *sv, SV *wiz) {
#define vmg_cast(S, W) vmg_cast(aTHX_ (S), (W))
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

 data = (w->cb_data) ? vmg_data_new(w->cb_data, sv) : NULL;
 mg = sv_magicext(sv, data, PERL_MAGIC_ext, w->vtbl,
                            (const char *) wiz, HEf_SVKEY);
 mg->mg_private = w->sig;

 return 1;
}

STATIC UV vmg_dispell(pTHX_ SV *sv, U16 sig) {
#define vmg_dispell(S, Z) vmg_dispell(aTHX_ (S), (Z))
 MAGIC *mg, *prevmagic, *moremagic = NULL;
 MGWIZ *w;

 if (SvTYPE(sv) < SVt_PVMG) { return 0; }

 for (prevmagic = NULL, mg = SvMAGIC(sv); mg; prevmagic = mg, mg = moremagic) {
  moremagic = mg->mg_moremagic;
  if ((mg->mg_type == PERL_MAGIC_ext) && (mg->mg_private == sig)) { break; }
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

 return 1;
}

/* ... svt callbacks ....................................................... */

STATIC int vmg_cb_call(pTHX_ SV *cb, SV *sv, SV *data) {
#define vmg_cb_call(I, S, D) vmg_cb_call(aTHX_ (I), (S), (D))
 int ret;

 dSP;
 int count;

 ENTER;
 SAVETMPS;

 PUSHMARK(SP);
 switch (SvTYPE(sv)) {
  case SVt_PVAV:
  case SVt_PVHV: XPUSHs(sv_2mortal(newRV_inc(sv))); break;
  default:       XPUSHs(sv);
 }
 if (data) { XPUSHs(data); }
 PUTBACK;

 count = call_sv(cb, G_SCALAR);

 SPAGAIN;

 if (count != 1) { croak("Callback needs to return 1 scalar\n"); }
 ret = POPi;

 PUTBACK;

 FREETMPS;
 LEAVE;

 return ret;
}

STATIC int vmg_svt_get(pTHX_ SV *sv, MAGIC *mg) {
 return vmg_cb_call(SV2MGWIZ(mg->mg_ptr)->cb_get, sv, mg->mg_obj);
}

STATIC int vmg_svt_set(pTHX_ SV *sv, MAGIC *mg) {
 return vmg_cb_call(SV2MGWIZ(mg->mg_ptr)->cb_set, sv, mg->mg_obj);
}

STATIC U32 vmg_svt_len(pTHX_ SV *sv, MAGIC *mg) {
 U32 ret;

 dSP;
 int count;

 ENTER;
 SAVETMPS;

 PUSHMARK(SP);
 switch (SvTYPE(sv)) {
  case SVt_PVAV:
  case SVt_PVHV: XPUSHs(sv_2mortal(newRV_inc(sv))); break;
  default:       XPUSHs(sv);
 }
 XPUSHs((mg->mg_obj) ? (mg->mg_obj) : &PL_sv_undef);
 if (SvTYPE(sv) == SVt_PVAV) {
  XPUSHs(sv_2mortal(newSViv(av_len((AV *) sv) + 1)));
 }
 PUTBACK;

 count = call_sv(SV2MGWIZ(mg->mg_ptr)->cb_len, G_SCALAR);

 SPAGAIN;

 if (count != 1) { croak("Callback needs to return 1 scalar\n"); }
 ret = POPi;

 PUTBACK;

 FREETMPS;
 LEAVE;

 return ret - 1;
}

STATIC int vmg_svt_clear(pTHX_ SV *sv, MAGIC *mg) {
 return vmg_cb_call(SV2MGWIZ(mg->mg_ptr)->cb_clear, sv, mg->mg_obj);
}

STATIC int vmg_svt_free(pTHX_ SV *sv, MAGIC *mg) {
 /* So that it can survive tmp cleanup in vmg_cb_call */
 if (SvREFCNT(sv) <= 0) { SvREFCNT_inc(sv); }
 /* Perl_mg_free will get rid of the magic and decrement mg->mg_obj and
  * mg->mg_ptr reference count */
 return vmg_cb_call(SV2MGWIZ(mg->mg_ptr)->cb_free, sv, mg->mg_obj);
}

/* ... Wizard destructor ................................................... */

STATIC int vmg_wizard_free(pTHX_ SV *wiz, MAGIC *mg) {
 MGWIZ *w = SV2MGWIZ(wiz);

 if (w->cb_get   != NULL) { SvREFCNT_dec(SvRV(w->cb_get)); }
 if (w->cb_set   != NULL) { SvREFCNT_dec(SvRV(w->cb_set)); }
 if (w->cb_len   != NULL) { SvREFCNT_dec(SvRV(w->cb_len)); }
 if (w->cb_clear != NULL) { SvREFCNT_dec(SvRV(w->cb_clear)); }
 if (w->cb_free  != NULL) { SvREFCNT_dec(SvRV(w->cb_free)); }
 if (w->cb_data  != NULL) { SvREFCNT_dec(SvRV(w->cb_data)); }
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
#ifdef MGf_COPY
 NULL,            /* copy */
#endif /* MGf_COPY */
#ifdef MGf_DUP
 NULL,            /* dup */
#endif /* MGf_DUP */
};

STATIC const char vmg_invalid_wiz[] = "Invalid wizard object";
STATIC const char vmg_invalid_sv[]  = "Invalid variable";
STATIC const char vmg_invalid_sig[] = "Invalid numeric signature";

/* --- XS ------------------------------------------------------------------ */

MODULE = Variable::Magic            PACKAGE = Variable::Magic

PROTOTYPES: ENABLE

SV *_wizard(SV *sig, SV *cb_get, SV *cb_set, SV *cb_len, SV *cb_clear, SV *cb_free, SV *cb_data)
PROTOTYPE: $&&&&&
PREINIT:
 MGWIZ *w;
 MGVTBL *t;
 MAGIC *mg;
 SV *sv;
CODE:
 if (!SvIOK(sig)) { croak(vmg_invalid_sig); }
 
 Newx(t, 1, MGVTBL);
 t->svt_get   = (SvOK(cb_get))   ? vmg_svt_get   : NULL;
 t->svt_set   = (SvOK(cb_set))   ? vmg_svt_set   : NULL;
 t->svt_len   = (SvOK(cb_len))   ? vmg_svt_len   : NULL;
 t->svt_clear = (SvOK(cb_clear)) ? vmg_svt_clear : NULL;
 t->svt_free  = (SvOK(cb_free))  ? vmg_svt_free  : NULL;
#ifdef MGf_COPY
 t->svt_copy  = NULL;
#endif /* MGf_COPY */
#ifdef MGf_DUP
 t->svt_dup   = NULL;
#endif /* MGf_DUP */

 Newx(w, 1, MGWIZ);
 w->vtbl = t;
 w->sig  = SvUVX(sig);
 w->cb_get   = (SvROK(cb_get))   ? newRV_inc(SvRV(cb_get))   : NULL;
 w->cb_set   = (SvROK(cb_set))   ? newRV_inc(SvRV(cb_set))   : NULL;
 w->cb_len   = (SvROK(cb_len))   ? newRV_inc(SvRV(cb_len))   : NULL;
 w->cb_clear = (SvROK(cb_clear)) ? newRV_inc(SvRV(cb_clear)) : NULL;
 w->cb_free  = (SvROK(cb_free))  ? newRV_inc(SvRV(cb_free))  : NULL;
 w->cb_data  = (SvROK(cb_data))  ? newRV_inc(SvRV(cb_data))  : NULL;

 sv = MGWIZ2SV(w);
 mg = sv_magicext(sv, NULL, PERL_MAGIC_ext, &vmg_wizard_vtbl, NULL, -1);
 mg->mg_private = SIG_WIZ;

 RETVAL = newRV_noinc(sv);
OUTPUT:
 RETVAL

SV *getsig(SV *wiz)
PROTOTYPE: $
CODE:
 if (!SvROK(wiz)) { croak(vmg_invalid_wiz); }
 RETVAL = newSVuv(SV2MGWIZ(SvRV(wiz))->sig);
OUTPUT:
 RETVAL

SV *cast(SV *sv, SV *wiz)
PROTOTYPE: \[$@%&*]$
CODE:
 if (!SvROK(wiz)) { croak(vmg_invalid_wiz); }
 RETVAL = newSVuv(vmg_cast(SvRV(sv), SvRV(wiz)));
OUTPUT:
 RETVAL

SV *getdata(SV *sv, SV *wiz)
PROTOTYPE: \[$@%&*]$
PREINIT:
 SV *data;
CODE:
 if (!SvROK(wiz)) { croak(vmg_invalid_wiz); }
 data = vmg_data_get(SvRV(sv), SV2MGWIZ(SvRV(wiz))->sig);
 if (!data) { XSRETURN_UNDEF; }
 ST(0) = newSVsv(data);
 XSRETURN(1);

SV *dispell(SV *sv, SV *wiz)
PROTOTYPE: \[$@%&*]$
PREINIT:
 U16 sig;
CODE:
 if (SvROK(wiz)) {
  sig = SV2MGWIZ(SvRV(wiz))->sig;
 } else if (SvIOK(wiz)) {
  sig = SvUVX(wiz);
 } else {
  croak(vmg_invalid_wiz);
 }
 RETVAL = newSVuv(vmg_dispell(SvRV(sv), sig));
OUTPUT:
 RETVAL
