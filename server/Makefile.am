# We want to build this directory first, before descending into tests subdir.
# The reason is that ideally the tests should link existing objects from this
# directory. That eliminates any discrepancies between tested code and
# production code. Sadly, we are not there yet.
SUBDIRS = . tests

BINDLIBDIR = @BINDDIR@/lib

AM_CPPFLAGS = -I.. -DLOCALSTATEDIR='"@localstatedir@"'

dist_sysconf_DATA = dhcpd.conf.example
sbin_PROGRAMS = dhcpd
dhcpd_SOURCES = dhcpd.c dhcp.c bootp.c confpars.c db.c class.c failover.c \
		omapi.c mdb.c stables.c salloc.c ddns.c dhcpleasequery.c \
		dhcpv6.c mdb6.c ldap.c ldap_casa.c leasechain.c ldap_krb_helper.c

dhcpd_CFLAGS = $(LDAP_CFLAGS)
dhcpd_LDADD = ../common/libdhcp.a ../omapip/libomapi.a \
	      ../dhcpctl/libdhcpctl.a $(BINDLIBDIR)/libirs.a \
	      $(BINDLIBDIR)/libdns.a $(BINDLIBDIR)/libisccfg.a \
	      $(BINDLIBDIR)/libisc.a $(LDAP_LIBS)

man_MANS = dhcpd.8 dhcpd.conf.5 dhcpd.leases.5
EXTRA_DIST = $(man_MANS)

