## Process this file with automake to produce Makefile.in

## Created by Anjuta

NULL =


AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	-I$(top_srcdir)/egg-list-box \
	-I$(top_srcdir)/libgd \
	$(GTK_CFLAGS) \
	$(GDA_CFLAGS) \
	$(MOBILECT_WIDGETS_CFLAGS) \
	$(NULL)

AM_CFLAGS = \
	-w \
	-g

bin_PROGRAMS = mobilect-job-orders

mobilect_job_orders_SOURCES = \
	main.vala \
	database.vala \
	application.vala \
	window.vala \
	job-order-list-view.vala \
	job-order-editor.vala \
	purchase-order-list-view.vala \
	purchase-order-editor.vala \
	invoice-list-view.vala \
	config.vapi \
	resources.c \
	$(NULL)

mobilect_job_orders_VALAFLAGS = \
	--vapidir=$(top_builddir)/vapi \
	--vapidir=$(top_builddir)/egg-list-box \
	--vapidir=$(top_builddir)/libgd \
	--vapidir=$(MOBILECT_WIDGETS_VAPIDIR) \
	--pkg=gtk+-3.0 \
	--pkg=libgda-5.0 \
	--pkg=egglistbox \
	--pkg=gd-1.0 \
	--pkg=mobilect-widgets-1.0 \
	--thread \
	--target-glib=2.32 \
	--debug \
	$(NULL)

mobilect_job_orders_LDFLAGS = \
	-no-undefined \
	-Wl,--export-dynamic \
	$(NULL)

mobilect_job_orders_LDADD = \
	$(GTK_LIBS) \
	$(GDA_LIBS) \
	$(MOBILECT_WIDGETS_LIBS) \
	$(top_builddir)/egg-list-box/libegglistbox.la \
	$(top_builddir)/libgd/libgd.la \
	$(NULL)


resources = \
	application.ui \
	job-order-list-view.ui \
	job-order-editor.ui \
	purchase-order-list-view.ui \
	purchase-order-editor.ui \
	invoice-list-view.ui \
	$(NULL)

resources.c: mobilect-job-orders.gresource.xml $(resources)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) \
		--sourcedir=$(srcdir) --target=$@ --generate $<


EXTRA_DIST = \
	mobilect-job-orders.gresource.xml \
	$(resources) \
	$(NULL)
