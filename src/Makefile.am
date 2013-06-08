## Process this file with automake to produce Makefile.in

## Created by Anjuta

NULL =


AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	$(GTK_CFLAGS) \
	$(NULL)

AM_CFLAGS = \
	-w \
	-g

bin_PROGRAMS = mobilect-job-orders

mobilect_job_orders_SOURCES = \
	main.vala \
	$(NULL)

mobilect_job_orders_VALAFLAGS = \
	--pkg=gtk+-3.0 \
	--debug \
	$(NULL)

mobilect_job_orders_LDFLAGS = \
	-no-undefined \
	-Wl,--export-dynamic \
	$(NULL)

mobilect_job_orders_LDADD = \
	$(GTK_LIBS) \
	$(NULL)
