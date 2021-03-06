dnl Process this file with autoconf to produce a configure script.


dnl Making releases:
dnl   MOBILECT_JOB_ORDERS_MICRO_VERSION += 1;
dnl   MOBILECT_JOB_ORDERS_INTERFACE_AGE += 1;
dnl   MOBILECT_JOB_ORDERS_BINARY_AGE += 1;
dnl if any functions have been added, set MOBILECT_JOB_ORDERS_INTERFACE_AGE to 0.
dnl if backwards compatibility has been broken,
dnl set MOBILECT_JOB_ORDERS_BINARY_AGE and MOBILECT_JOB_ORDERS_INTERFACE_AGE to 0.

m4_define([mobilect_job_orders_major_version], [0])
m4_define([mobilect_job_orders_minor_version], [9])
m4_define([mobilect_job_orders_micro_version], [0])
m4_define([mobilect_job_orders_interface_age], [0])
m4_define([mobilect_job_orders_binary_age],
          [m4_eval(100 * mobilect_job_orders_minor_version + mobilect_job_orders_micro_version)])
m4_define([mobilect_job_orders_version],
          [mobilect_job_orders_major_version.mobilect_job_orders_minor_version.mobilect_job_orders_micro_version])
dnl This is the X.Y used in -lmobilect-job-orders-FOO-X.Y
m4_define([mobilect_job_orders_api_version], [1.0])

dnl Define a string for the earliest version that this release has
dnl backwards binary compatibility with for all interfaces a module
dnl might. Unless we add module-only API with lower stability
dnl guarantees, this should be unchanged until we break binary compat
dnl for GPInstruct.
dnl
dnl MOBILECT_JOB_ORDERS_BINARY_VERSION=$MOBILECT_JOB_ORDERS_MAJOR_VERSION.$MOBILECT_JOB_ORDERS_MINOR_VERSION.$LT_CURRENT
m4_define([mobilect_job_orders_binary_version], [0.9.0])


AC_INIT([Mobilect Job Orders], [mobilect_job_orders_version],
        [info@mobilectpower.com],
        [mobilect-job-orders],
        [http://www.mobilectpower.com/])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_SRCDIR([ChangeLog])


MOBILECT_JOB_ORDERS_MAJOR_VERSION=mobilect_job_orders_major_version
MOBILECT_JOB_ORDERS_MINOR_VERSION=mobilect_job_orders_minor_version
MOBILECT_JOB_ORDERS_MICRO_VERSION=mobilect_job_orders_micro_version
MOBILECT_JOB_ORDERS_INTERFACE_AGE=mobilect_job_orders_interface_age
MOBILECT_JOB_ORDERS_BINARY_AGE=mobilect_job_orders_binary_age
MOBILECT_JOB_ORDERS_VERSION=mobilect_job_orders_version
MOBILECT_JOB_ORDERS_API_VERSION=mobilect_job_orders_api_version
MOBILECT_JOB_ORDERS_BINARY_VERSION=mobilect_job_orders_binary_version
AC_SUBST(MOBILECT_JOB_ORDERS_MAJOR_VERSION)
AC_SUBST(MOBILECT_JOB_ORDERS_MINOR_VERSION)
AC_SUBST(MOBILECT_JOB_ORDERS_MICRO_VERSION)
AC_SUBST(MOBILECT_JOB_ORDERS_INTERFACE_AGE)
AC_SUBST(MOBILECT_JOB_ORDERS_BINARY_AGE)
AC_SUBST(MOBILECT_JOB_ORDERS_API_VERSION)
AC_SUBST(MOBILECT_JOB_ORDERS_VERSION)
AC_SUBST(MOBILECT_JOB_ORDERS_BINARY_VERSION)

dnl libtool versioning
m4_define([lt_current], [m4_eval(100 * mobilect_job_orders_minor_version + mobilect_job_orders_micro_version - mobilect_job_orders_interface_age)])
m4_define([lt_revision], [mobilect_job_orders_interface_age])
m4_define([lt_age], [m4_eval(mobilect_job_orders_binary_age - mobilect_job_orders_interface_age)])
LT_VERSION_INFO="lt_current:lt_revision:lt_age"
LT_CURRENT_MINUS_AGE=m4_eval(lt_current - lt_age)
AC_SUBST(LT_VERSION_INFO)
AC_SUBST(LT_CURRENT_MINUS_AGE)


AM_INIT_AUTOMAKE([-Wall -Werror gnu no-dist-gzip dist-xz])

AM_SILENT_RULES([yes])


AC_PROG_CC
AM_PROG_VALAC([0.16.0])
AM_PROG_AR


LT_INIT([disable-static])
LT_OUTPUT


dnl ***************************************************************************
dnl Check for MS Windows
dnl ***************************************************************************

AC_CANONICAL_HOST

case $host_os in
  *mingw* | pw32* | cygwin*)
    platform_win32=yes
    ;;
  *)
    platform_win32=no
    ;;
esac
AM_CONDITIONAL(PLATFORM_WIN32, test x"$platform_win32" = "xyes")

case $host_os in
  *mingw*)
    native_win32=yes
    ;;
  *)
    native_win32=no
    ;;
esac
AM_CONDITIONAL(NATIVE_WIN32, test x"$native_win32" = "xyes")

if test "$native_win32" = "yes"; then
  AC_CHECK_TOOL(WINDRES, windres, no)
  if test "$WINDRES" = no; then
    AC_MSG_ERROR([*** Could not find an implementation of windres in your PATH.])
  fi
fi


dnl ***************************************************************************
dnl Internationalization
dnl ***************************************************************************

IT_PROG_INTLTOOL([0.40.1])

GETTEXT_PACKAGE="$PACKAGE-$MOBILECT_JOB_ORDERS_API_VERSION"
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE", [GETTEXT package name])


dnl ***************************************************************************
dnl Configure submodules
dnl ***************************************************************************

LIBGD_INIT([header-bar notification revealer stack static tagged-entry])


dnl ***************************************************************************
dnl Check packages
dnl ***************************************************************************

PKG_CHECK_MODULES([GTK], [gtk+-3.0 >= 3.10.0])
PKG_CHECK_MODULES([GDA], [libgda-5.0])
PKG_CHECK_MODULES([MOBILECT_WIDGETS], [mobilect-widgets-1.0])

MOBILECT_WIDGETS_VAPIDIR=`$PKG_CONFIG --variable vapidir mobilect-widgets-1.0`
AC_SUBST(MOBILECT_WIDGETS_VAPIDIR)


dnl ***************************************************************************
dnl Check tools
dnl ***************************************************************************

GLIB_COMPILE_RESOURCES=`$PKG_CONFIG --variable glib_compile_resources gio-2.0`
AC_SUBST(GLIB_COMPILE_RESOURCES)


AC_CONFIG_FILES([
Makefile
libgd/Makefile
vapi/Makefile
src/Makefile
po/Makefile.in
])

AC_OUTPUT
