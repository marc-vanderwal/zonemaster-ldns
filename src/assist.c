#include <LDNS.h>

#define RR_CLASSNAME_MAX_LEN 34

char *
randomize_capitalization(char *in)
{
#ifdef RANDOMIZE
#warning "Case randomization is deprecated and will be removed in v2025.1."
    char *str;
    str = in;
    while(*str) {
        if(Drand01() < 0.5)
        {
            *str = tolower(*str);
        }
        else
        {
            *str = toupper(*str);
        }
        str++;
    }
#endif
    return in;
}

SV *
rr2sv(ldns_rr *rr)
{
    char rrclass[RR_CLASSNAME_MAX_LEN];
    char *type;

    type = ldns_rr_type2str(ldns_rr_get_type(rr));
    snprintf(rrclass, RR_CLASSNAME_MAX_LEN, "Zonemaster::LDNS::RR::%s", type);

    SV* rr_sv = newSV(0);
    if (strncmp(type, "TYPE", 4)==0)
    {
        sv_setref_pv(rr_sv, "Zonemaster::LDNS::RR", rr);
    }
    else
    {
        sv_setref_pv(rr_sv, rrclass, rr);
    }

    free(type);

    return rr_sv;
}

void
strip_newline(char* in)
{
    size_t length;

    if (in == NULL || in[0] == '\0')
    {
        return;
    }

    length = strlen(in);
    if (in[length - 1] == '\n')
    {
        in[length - 1] = '\0';
    }
}
