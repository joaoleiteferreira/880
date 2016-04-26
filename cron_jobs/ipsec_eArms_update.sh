##s
# $Id: ipsec_eArms_update.sh,v 1.8 2007/10/15 21:29:41 gicarval Exp $
# Copyright (c) 2006 Cisco Systems, Inc.
#
# Name:
# ~~~~~
#     scriptname
#
#
# Purpose:
# ~~~~~~~~
#   Keep the ats tree used by eArms updated
#
#
# Author:
# ~~~~~~~
#    Tennis Smith
#
#
# Description:
# ~~~~~~~~~~~~
#
#  This is a simple cron job that runs on a daily basis.  This will run a
#  "cvs update" on our common eArms tree and therefore get the latest changes.
#  NOTE: Any changes which have been made to the eArms tree, but are not in the
#  repository WILL BE DISCARDED and the repository version substituted.
#
#
# Known Bugs:
# ~~~~~~~~~~~
#  None
#
#
# Todo:
# ~~~~~
#  None
#
# End of Header
#
# ------------------------------------------
#
#  The cvs switches used are the following:
#
# -d
#     Pull down new directories.
#
# -A
#     Reset any sticky tags, dates, or keyword options and replace the
#     existing files in the sandbox with the revision at the head of the
#     trunk. CVS merges any changes you have made to the sandbox with the
#     revision it downloads. Use -C as well as -A if you want the changes
#     overwritten.
#
# -R
#     Perform a recursive operation on all subdirectories, as well as the
#     current directory.  (This is the default, but since it can be locally
#     overridden via the .cvsrc file, make certain this is set.)
#
# -C
#     Overwrite files in the sandbox with copies from the repository.
#
#

cd /auto/stg-devtest/eArms/stg_reg
cvs update -d -A -R -C

cd /auto/stg-devtest/eArms/lib
cvs update -d -R

cd /auto/stg-devtest/eArms/regression/tests/functionality/ipsec
cvs update -d -A -R -C

cd /auto/stg-devtest/eArms/lib/cisco-shared
cvs update -d -R

cd /auto/stg-devtest/eArms/regression/tests/functionality/hw_ipsec_7200
cvs update -d -A -R -C

cd /auto/stg-devtest/eArms/regression/tests/functionality/hw_ipv6_ipsec
cvs update -d -A -R -C

#
# -----------------------------------------------------------------------------
#                            CVS MAINTENANCE LOGS
#                            ~~~~~~~~~~~~~~~~~~~~
# $Log: ipsec_eArms_update.sh,v $
# Revision 1.8  2007/10/15 21:29:41  gicarval
#    Added hw_ipsec_7200 & hw_ipv6_ipsec to list of directories for daily updates
#
# Revision 1.7  2006/10/13 08:34:04  gicarval
#    Removed -A and -C switches from cvs update of /auto/stg-devtest/eArms/lib/cisco-shared so
# to allow the use of older library revisions incase the latest revision breaks
#
# Revision 1.6  2006/10/13 00:43:30  gicarval
#    Removed -A and -C switches from cvs update of /auto/stg-devtest/earms/lib so
# to allow the use of older library revisions incase the latest revision breaks
# something.
#
# Revision 1.5  2006/09/21 18:51:18  tennis
#
# Various updates to some minor support utilities.
#
# Revision 1.4  2006/05/03 22:50:32  tennis
#
# -----------------------------------------------------------------------------
# Local Variables:
# mode: shell-script
# End:
