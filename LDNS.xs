#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#define NEED_newRV_noinc
#include "ppport.h"

#include <ldns/ldns.h>
typedef ldns_resolver *Net__LDNS;
typedef ldns_pkt *Net__LDNS__Packet;
typedef ldns_rr_list *Net__LDNS__RRList;
typedef ldns_rr *Net__LDNS__RR;
typedef ldns_rr *Net__LDNS__RR__NS;
typedef ldns_rr *Net__LDNS__RR__A;
typedef ldns_rr *Net__LDNS__RR__AAAA;
typedef ldns_rr *Net__LDNS__RR__SOA;
typedef ldns_rr *Net__LDNS__RR__MX;
typedef ldns_rr *Net__LDNS__RR__DS;
typedef ldns_rr *Net__LDNS__RR__DNSKEY;
typedef ldns_rr *Net__LDNS__RR__RRSIG;
typedef ldns_rr *Net__LDNS__RR__NSEC;
typedef ldns_rr *Net__LDNS__RR__NSEC3;
typedef ldns_rr *Net__LDNS__RR__NSEC3PARAM;
typedef ldns_rr *Net__LDNS__RR__PTR;
typedef ldns_rr *Net__LDNS__RR__CNAME;
typedef ldns_rr *Net__LDNS__RR__TXT;

#define D_STRING(what,where) ldns_rdf2str(ldns_rr_rdf(what,where))
#define D_U8(what,where) ldns_rdf2native_int8(ldns_rr_rdf(what,where))
#define D_U16(what,where) ldns_rdf2native_int16(ldns_rr_rdf(what,where))
#define D_U32(what,where) ldns_rdf2native_int32(ldns_rr_rdf(what,where))

MODULE = Net::LDNS        PACKAGE = Net::LDNS

PROTOTYPES: ENABLE

Net::LDNS
new(class, ...)
    char *class;
    CODE:
    {
        int i;

        if (items == 1 ) {
            ldns_resolver_new_frm_file(&RETVAL,NULL);
        }
        else {
            RETVAL = ldns_resolver_new();
            for (i=1;i<items;i++)
            {
                ldns_status s;
                ldns_rdf *addr;

                if ( !SvOK(ST(i)) || !SvPOK(ST(i)) ) {
                    continue;
                }

                addr = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_A, SvPV_nolen(ST(i)));
                if ( addr == NULL) {
                    addr = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_AAAA, SvPV_nolen(ST(i)));
                }
                if ( addr == NULL ) {
                    croak("Failed to parse IP address: %s", SvPV_nolen(ST(i)));
                }
                s = ldns_resolver_push_nameserver(RETVAL, addr);
                if(s != LDNS_STATUS_OK)
                {
                    croak("Adding nameserver failed: %s", ldns_get_errorstr_by_id(s));
                }
            }
        }
    }
    OUTPUT:
        RETVAL

Net::LDNS::Packet
query(obj, dname, rrtype="A", rrclass="IN")
    Net::LDNS obj;
    char *dname;
    char *rrtype;
    char *rrclass;
    CODE:
    {
        ldns_rdf *domain;
        ldns_rr_type t;
        ldns_rr_class c;
        ldns_status status;

        t = ldns_get_rr_type_by_name(rrtype);
        if(!t)
        {
            croak("Unknown RR type: %s", rrtype);
        }

        c = ldns_get_rr_class_by_name(rrclass);
        if(!c)
        {
            croak("Unknown RR class: %s", rrclass);
        }

        domain = ldns_dname_new_frm_str(dname);
        status = ldns_resolver_send(&RETVAL, obj, domain, t, c, LDNS_RD);
        if ( status != LDNS_STATUS_OK) {
            croak("%s", ldns_get_errorstr_by_id(status));
            RETVAL = NULL;
        }
    }
    OUTPUT:
        RETVAL

bool
recursive(obj,...)
    Net::LDNS obj;
    CODE:
        if(items>1) {
            ldns_resolver_set_recursive(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_recursive(obj);
    OUTPUT:
        RETVAL

bool
debug(obj,...)
    Net::LDNS obj;
    CODE:
        if ( items > 1 ) {
            ldns_resolver_set_debug(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_debug(obj);
    OUTPUT:
        RETVAL

bool
dnssec(obj,...)
    Net::LDNS obj;
    CODE:
        if ( items > 1 ) {
            ldns_resolver_set_dnssec(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_dnssec(obj);
    OUTPUT:
        RETVAL

bool
usevc(obj,...)
    Net::LDNS obj;
    CODE:
        if ( items > 1 ) {
            ldns_resolver_set_usevc(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_usevc(obj);
    OUTPUT:
        RETVAL

bool
igntc(obj,...)
    Net::LDNS obj;
    CODE:
        if ( items > 1 ) {
            ldns_resolver_set_igntc(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_igntc(obj);
    OUTPUT:
        RETVAL

U8
retry(obj,...)
    Net::LDNS obj;
    CODE:
        if ( items > 1 ) {
            ldns_resolver_set_retry(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_retry(obj);
    OUTPUT:
        RETVAL

U8
retrans(obj,...)
    Net::LDNS obj;
    CODE:
        if ( items > 1 ) {
            ldns_resolver_set_retrans(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_retrans(obj);
    OUTPUT:
        RETVAL

void
DESTROY(obj)
        Net::LDNS obj;
        CODE:
            ldns_resolver_deep_free(obj);

MODULE = Net::LDNS        PACKAGE = Net::LDNS::Packet           PREFIX=packet_

char *
packet_rcode(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_rcode2str(ldns_pkt_get_rcode(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);

char *
packet_opcode(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_opcode2str(ldns_pkt_get_opcode(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);

U16
packet_id(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_id(obj);
    OUTPUT:
        RETVAL

bool
packet_qr(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_qr(obj);
    OUTPUT:
        RETVAL

bool
packet_aa(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_aa(obj);
    OUTPUT:
        RETVAL

bool
packet_tc(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_tc(obj);
    OUTPUT:
        RETVAL

bool
packet_rd(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_rd(obj);
    OUTPUT:
        RETVAL

bool
packet_cd(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_cd(obj);
    OUTPUT:
        RETVAL

bool
packet_ra(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_ra(obj);
    OUTPUT:
        RETVAL

bool
packet_ad(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_ad(obj);
    OUTPUT:
        RETVAL

bool
packet_do(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_edns_do(obj);
    OUTPUT:
        RETVAL

size_t
packet_size(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_size(obj);
    OUTPUT:
        RETVAL

U32
packet_querytime(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_querytime(obj);
    OUTPUT:
        RETVAL

char *
packet_answerfrom(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_rdf2str(ldns_pkt_answerfrom(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);

double
packet_timestamp(obj)
    Net::LDNS::Packet obj;
    CODE:
        struct timeval t = ldns_pkt_timestamp(obj);
        RETVAL = (double)t.tv_sec;
        RETVAL += ((double)t.tv_usec)/1000000;
    OUTPUT:
        RETVAL

SV *
packet_answer(obj)
    Net::LDNS::Packet obj;
    PPCODE:
    {
        size_t i,n;
        ldns_rr_list *rrs;

        rrs = ldns_pkt_answer(obj);
        n = ldns_rr_list_rr_count(rrs);

        EXTEND(sp,n);
        for(i = 0; i < n; ++i)
        {
            char rrclass[30];
            char *type;

            ldns_rr *rr = ldns_rr_clone(ldns_rr_list_rr(rrs,i));

            type = ldns_rr_type2str(ldns_rr_get_type(rr));
            snprintf(rrclass, 30, "Net::LDNS::RR::%s", type);

            SV* rr_sv = sv_newmortal();
            sv_setref_pv(rr_sv, rrclass, rr);
            PUSHs(rr_sv);
            Safefree(type);
        }
    }

SV *
packet_authority(obj)
    Net::LDNS::Packet obj;
    PPCODE:
    {
        size_t i,n;
        ldns_rr_list *rrs;

        rrs = ldns_pkt_authority(obj);
        n = ldns_rr_list_rr_count(rrs);

        EXTEND(sp,n);
        for(i = 0; i < n; ++i)
        {
            char rrclass[30];
            char *type;

            ldns_rr *rr = ldns_rr_clone(ldns_rr_list_rr(rrs,i));

            type = ldns_rr_type2str(ldns_rr_get_type(rr));
            snprintf(rrclass, 30, "Net::LDNS::RR::%s", type);

            SV* rr_sv = sv_newmortal();
            sv_setref_pv(rr_sv, rrclass, rr);
            PUSHs(rr_sv);
            Safefree(type);
        }
    }

SV *
packet_additional(obj)
    Net::LDNS::Packet obj;
    PPCODE:
    {
        size_t i,n;
        ldns_rr_list *rrs;

        rrs = ldns_pkt_additional(obj);
        n = ldns_rr_list_rr_count(rrs);

        EXTEND(sp,n);
        for(i = 0; i < n; ++i)
        {
            char rrclass[30];
            char *type;

            ldns_rr *rr = ldns_rr_clone(ldns_rr_list_rr(rrs,i));

            type = ldns_rr_type2str(ldns_rr_get_type(rr));
            snprintf(rrclass, 30, "Net::LDNS::RR::%s", type);

            SV* rr_sv = sv_newmortal();
            sv_setref_pv(rr_sv, rrclass, rr);
            PUSHs(rr_sv);
            Safefree(type);
        }
    }

SV *
packet_question(obj)
    Net::LDNS::Packet obj;
    PPCODE:
    {
        size_t i,n;
        ldns_rr_list *rrs;

        rrs = ldns_pkt_question(obj);
        n = ldns_rr_list_rr_count(rrs);

        EXTEND(sp,n);
        for(i = 0; i < n; ++i)
        {
            char rrclass[40];
            char *type;

            ldns_rr *rr = ldns_rr_clone(ldns_rr_list_rr(rrs,i));

            type = ldns_rr_type2str(ldns_rr_get_type(rr));
            snprintf(rrclass, 39, "Net::LDNS::RR::%s", type);

            SV* rr_sv = sv_newmortal();
            sv_setref_pv(rr_sv, rrclass, rr);
            PUSHs(rr_sv);
            Safefree(type);
        }
    }

Net::LDNS::RRList
packet_all(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_all_noquestion(obj);
    OUTPUT:
        RETVAL

char *
packet_string(obj)
    Net::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt2str(obj);
        RETVAL[strlen(RETVAL)-1] = '\0';
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);

SV *
packet_wireformat(obj)
    Net::LDNS::Packet obj;
    CODE:
    {
        size_t sz;
        uint8_t *buf;
        ldns_status status;

        status = ldns_pkt2wire(&buf, obj, &sz);
        if(status != LDNS_STATUS_OK)
        {
            croak("Failed to produce wire format: %s",  ldns_get_errorstr_by_id(status));
        }
        else
        {
            RETVAL = newSVpvn((const char *)buf,sz);
            Safefree(buf);
        }
    }
    OUTPUT:
        RETVAL

Net::LDNS::Packet
packet_new_from_wireformat(class,buf)
    char *class;
    SV *buf;
    CODE:
    {
        Net__LDNS__Packet pkt;
        ldns_status status;

        status = ldns_wire2pkt(&pkt, (const uint8_t *)SvPV_nolen(buf), SvCUR(buf));
        if(status != LDNS_STATUS_OK)
        {
            croak("Failed to parse wire format: %s",  ldns_get_errorstr_by_id(status));
        }
        else
        {
            RETVAL = pkt;
        }
    }
    OUTPUT:
        RETVAL

void
packet_DESTROY(obj)
    Net::LDNS::Packet obj;
    CODE:
        ldns_pkt_free(obj);

MODULE = Net::LDNS        PACKAGE = Net::LDNS::RRList           PREFIX=rrlist_

void
rrlist_DESTROY(obj)
    Net::LDNS::RRList obj;
    CODE:
        ldns_rr_list_deep_free(obj);

MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR           PREFIX=rr_

SV *
rr_new_from_string(class,str)
    char *class;
    char *str;
    PPCODE:
        ldns_status s;
        ldns_rr *rr;
        char rrclass[40];
        char *rrtype;
        SV* rr_sv;

        s = ldns_rr_new_frm_str(&rr, str, 0, NULL, NULL);
        if(s != LDNS_STATUS_OK)
        {
            croak("Failed to build RR: %s", ldns_get_errorstr_by_id(s));
        }
        rrtype = ldns_rr_type2str(ldns_rr_get_type(rr));
        snprintf(rrclass, 39, "Net::LDNS::RR::%s", rrtype);
        Safefree(rrtype);
        rr_sv = sv_newmortal();
        sv_setref_pv(rr_sv, rrclass, rr);
        PUSHs(rr_sv);

SV *
rr_owner(obj)
    Net::LDNS::RR obj;
    CODE:
        char *str = ldns_rdf2str(ldns_rr_owner(obj));
        RETVAL = newSV(0);
        sv_usepvn(RETVAL, str, strlen(str));
    OUTPUT:
        RETVAL

U32
rr_ttl(obj)
    Net::LDNS::RR obj;
    CODE:
        RETVAL = ldns_rr_ttl(obj);
    OUTPUT:
        RETVAL

char *
rr_type(obj)
    Net::LDNS::RR obj;
    CODE:
        RETVAL = ldns_rr_type2str(ldns_rr_get_type(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);

char *
rr_class(obj)
    Net::LDNS::RR obj;
    CODE:
        RETVAL = ldns_rr_class2str(ldns_rr_get_class(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);

char *
rr_string(obj)
    Net::LDNS::RR obj;
    CODE:
        RETVAL = ldns_rr2str(obj);
        RETVAL[strlen(RETVAL)-1] = '\0';
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);

I32
rr_compare(obj1,obj2)
    Net::LDNS::RR obj1;
    Net::LDNS::RR obj2;
    CODE:
        RETVAL = ldns_rr_compare(obj1,obj2);
    OUTPUT:
        RETVAL

size_t
rr_rd_count(obj)
    Net::LDNS::RR obj;
    CODE:
        RETVAL = ldns_rr_rd_count(obj);
    OUTPUT:
        RETVAL

void
rr_DESTROY(obj)
    Net::LDNS::RR obj;
    CODE:
        ldns_rr_free(obj);



MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::NS           PREFIX=rr_ns_

char *
rr_ns_nsdname(obj)
    Net::LDNS::RR::NS obj;
    CODE:
        RETVAL = ldns_rdf2str(ldns_rr_rdf(obj, 0));
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);


MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::MX           PREFIX=rr_mx_

U16
rr_mx_preference(obj)
    Net::LDNS::RR::MX obj;
    CODE:
        RETVAL = D_U16(obj, 0);
    OUTPUT:
        RETVAL

char *
rr_mx_exchange(obj)
    Net::LDNS::RR::MX obj;
    CODE:
        RETVAL = D_STRING(obj, 1);
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);


MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::A                PREFIX=rr_a_

char *
rr_a_address(obj)
    Net::LDNS::RR::A obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);


MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::AAAA             PREFIX=rr_aaaa_

char *
rr_aaaa_address(obj)
    Net::LDNS::RR::AAAA obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);


MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::SOA              PREFIX=rr_soa_

char *
rr_soa_mname(obj)
    Net::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);

char *
rr_soa_rname(obj)
    Net::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_STRING(obj,1);
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);

U32
rr_soa_serial(obj)
    Net::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_U32(obj,2);
    OUTPUT:
        RETVAL

U32
rr_soa_refresh(obj)
    Net::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_U32(obj,3);
    OUTPUT:
        RETVAL

U32
rr_soa_retry(obj)
    Net::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_U32(obj,4);
    OUTPUT:
        RETVAL

U32
rr_soa_expire(obj)
    Net::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_U32(obj,5);
    OUTPUT:
        RETVAL

U32
rr_soa_minimum(obj)
    Net::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_U32(obj,6);
    OUTPUT:
        RETVAL


MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::DS               PREFIX=rr_ds_

U16
rr_ds_keytag(obj)
    Net::LDNS::RR::DS obj;
    CODE:
        RETVAL = D_U16(obj,0);
    OUTPUT:
        RETVAL

U8
rr_ds_algorithm(obj)
    Net::LDNS::RR::DS obj;
    CODE:
        RETVAL = D_U8(obj,1);
    OUTPUT:
        RETVAL

U8
rr_ds_digtype(obj)
    Net::LDNS::RR::DS obj;
    CODE:
        RETVAL = D_U8(obj,2);
    OUTPUT:
        RETVAL

SV *
rr_ds_digest(obj)
    Net::LDNS::RR::DS obj;
    CODE:
    {
        ldns_rdf *rdf = ldns_rr_rdf(obj,3);
        RETVAL = newSVpvn((char*)ldns_rdf_data(rdf), ldns_rdf_size(rdf));
    }
    OUTPUT:
        RETVAL

char *
rr_ds_hexdigest(obj)
    Net::LDNS::RR::DS obj;
    CODE:
        RETVAL = D_STRING(obj,3);
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);


MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::DNSKEY           PREFIX=rr_dnskey_

U16
rr_dnskey_flags(obj)
    Net::LDNS::RR::DNSKEY obj;
    CODE:
        RETVAL = D_U16(obj,0);
    OUTPUT:
        RETVAL

U8
rr_dnskey_protocol(obj)
    Net::LDNS::RR::DNSKEY obj;
    CODE:
        RETVAL = D_U8(obj,1);
    OUTPUT:
        RETVAL

U8
rr_dnskey_algorithm(obj)
    Net::LDNS::RR::DNSKEY obj;
    CODE:
        RETVAL = D_U8(obj,2);
    OUTPUT:
        RETVAL

SV *
rr_dnskey_keydata(obj)
    Net::LDNS::RR::DNSKEY obj;
    CODE:
    {
        ldns_rdf *rdf = ldns_rr_rdf(obj,3);
        RETVAL = newSVpvn((char*)ldns_rdf_data(rdf), ldns_rdf_size(rdf));
    }
    OUTPUT:
        RETVAL


MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::RRSIG            PREFIX=rr_rrsig_

char *
rr_rrsig_typecovered(obj)
    Net::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);

U8
rr_rrsig_algorithm(obj)
    Net::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_U8(obj,1);
    OUTPUT:
        RETVAL

U8
rr_rrsig_labels(obj)
    Net::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_U8(obj,2);
    OUTPUT:
        RETVAL

U32
rr_rrsig_origttl(obj)
    Net::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_U32(obj,3);
    OUTPUT:
        RETVAL

U32
rr_rrsig_expiration(obj)
    Net::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_U32(obj,4);
    OUTPUT:
        RETVAL

U32
rr_rrsig_inception(obj)
    Net::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_U32(obj,5);
    OUTPUT:
        RETVAL

U16
rr_rrsig_keytag(obj)
    Net::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_U16(obj,6);
    OUTPUT:
        RETVAL

char *
rr_rrsig_signer(obj)
    Net::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_STRING(obj,7);
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);

SV *
rr_rrsig_signature(obj)
    Net::LDNS::RR::RRSIG obj;
    CODE:
    {
        ldns_rdf *rdf = ldns_rr_rdf(obj,8);
        RETVAL = newSVpvn((char*)ldns_rdf_data(rdf), ldns_rdf_size(rdf));
    }
    OUTPUT:
        RETVAL


MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::NSEC             PREFIX=rr_nsec_

char *
rr_nsec_next(obj)
    Net::LDNS::RR::NSEC obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL

char *
rr_nsec_typelist(obj)
    Net::LDNS::RR::NSEC obj;
    CODE:
        RETVAL = D_STRING(obj,1);
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);

SV *
rr_nsec_typehref(obj)
    Net::LDNS::RR::NSEC obj;
    CODE:
    {
        char *typestring = D_STRING(obj,1);
        size_t pos;
        HV *res = newHV();

        pos = 0;
        while(typestring[pos] != '\0')
        {
            pos++;
            if(typestring[pos] == ' ')
            {
                typestring[pos] = '\0';
                if(hv_store(res,typestring,pos,newSViv(1),0)==NULL)
                {
                    croak("Failed to store to hash");
                }
                typestring += pos+1;
                pos = 0;
            }
        }
        RETVAL = newRV_noinc((SV *)res);
    }
    OUTPUT:
        RETVAL


MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::NSEC3            PREFIX=rr_nsec3_

U8
rr_nsec3_algorithm(obj)
    Net::LDNS::RR::NSEC3 obj;
    CODE:
        RETVAL = ldns_nsec3_algorithm(obj);
    OUTPUT:
        RETVAL

U8
rr_nsec3_flags(obj)
    Net::LDNS::RR::NSEC3 obj;
    CODE:
        RETVAL = ldns_nsec3_flags(obj);
    OUTPUT:
        RETVAL

bool
rr_nsec3_optout(obj)
    Net::LDNS::RR::NSEC3 obj;
    CODE:
        RETVAL = ldns_nsec3_optout(obj);
    OUTPUT:
        RETVAL

U16
rr_nsec3_iterations(obj)
    Net::LDNS::RR::NSEC3 obj;
    CODE:
        RETVAL = ldns_nsec3_iterations(obj);
    OUTPUT:
        RETVAL

SV *
rr_nsec3_salt(obj)
    Net::LDNS::RR::NSEC3 obj;
    PPCODE:
        if(ldns_nsec3_salt_length(obj) > 0)
        {
            ldns_rdf *buf = ldns_nsec3_salt(obj);
            fprintf(stderr, "Salt length: %d\n", ldns_nsec3_salt_length(obj));
            ST(0) = sv_2mortal(newSVpvn((char *)ldns_rdf_data(buf), ldns_rdf_size(buf)));
            ldns_rdf_free(buf);
        }

SV *
rr_nsec3_next_owner(obj)
    Net::LDNS::RR::NSEC3 obj;
    CODE:
        ldns_rdf *buf = ldns_nsec3_next_owner(obj);
        RETVAL = newSVpvn((char *)ldns_rdf_data(buf), ldns_rdf_size(buf));
    OUTPUT:
        RETVAL

char *
rr_nsec3_typelist(obj)
    Net::LDNS::RR::NSEC3 obj;
    CODE:
        RETVAL = ldns_rdf2str(ldns_nsec3_bitmap(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);

SV *
rr_nsec3_typehref(obj)
    Net::LDNS::RR::NSEC3 obj;
    CODE:
    {
        char *typestring = ldns_rdf2str(ldns_nsec3_bitmap(obj));
        size_t pos;
        HV *res = newHV();

        pos = 0;
        while(typestring[pos] != '\0')
        {
            pos++;
            if(typestring[pos] == ' ')
            {
                typestring[pos] = '\0';
                if(hv_store(res,typestring,pos,newSViv(1),0)==NULL)
                {
                    croak("Failed to store to hash");
                }
                typestring += pos+1;
                pos = 0;
            }
        }
        RETVAL = newRV_noinc((SV *)res);
    }
    OUTPUT:
        RETVAL

MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::NSEC3PARAM       PREFIX=rr_nsec3param_

U8
rr_nsec3param_algorithm(obj)
    Net::LDNS::RR::NSEC3PARAM obj;
    CODE:
        RETVAL = D_U8(obj,0);
    OUTPUT:
        RETVAL

U8
rr_nsec3param_flags(obj)
    Net::LDNS::RR::NSEC3PARAM obj;
    CODE:
        RETVAL = D_U8(obj,1);
    OUTPUT:
        RETVAL


U16
rr_nsec3param_iterations(obj)
    Net::LDNS::RR::NSEC3PARAM obj;
    CODE:
        RETVAL = D_U16(obj,2);
    OUTPUT:
        RETVAL

SV *
rr_nsec3param_salt(obj)
    Net::LDNS::RR::NSEC3PARAM obj;
    PPCODE:
        ldns_rdf *rdf = ldns_rr_rdf(obj,3);
        if(ldns_rdf_size(rdf) > 0)
        {
            mPUSHs(newSVpvn((char *)ldns_rdf_data(rdf), ldns_rdf_size(rdf)));
        }

MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::PTR              PREFIX=rr_ptr_

char *
rr_ptr_ptrdname(obj)
    Net::LDNS::RR::PTR obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);


MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::CNAME            PREFIX=rr_cname_

char *
rr_cname_cname(obj)
    Net::LDNS::RR::CNAME obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);


MODULE = Net::LDNS        PACKAGE = Net::LDNS::RR::TXT              PREFIX=rr_txt_

char *
rr_txt_txtdata(obj)
    Net::LDNS::RR::TXT obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        Safefree(RETVAL);
