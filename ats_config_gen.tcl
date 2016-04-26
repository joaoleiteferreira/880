#!/bin/sh
# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
set starter { ${1:+"$@"}
    shift
    shift
    export AUTOTEST
    AUTOTEST="${AUTOTEST-/autons/autotest}"
    exec $AUTOTEST/bin/expect -f $0 -- ${1:+"$@"}
}
# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


# Notes
# - Add firewall and switch addresses and consoles for completeness.
#
#

package require Tcl 8.0

#catch {namespace delete ::config}

package provide config 1.0

namespace eval ::config {
    lappend ::auto_path $env(AUTOTEST)/regression/tests/functionality/ipsec
    package require ipsec
    package require struct::record
    package require ipsec
    package require dataUtils
    package require control
    package require textutil


    # List of registered configuration templates
    variable template
    variable TFTPSERVERADDR 172.19.201.81
    variable TFTPSERVERNAME nandigam-u10
    variable TB_NAME 0
    variable TB_ENTRIES 1
    variable tb_short_list {}
    variable array set device_long_names
    variable LINE_PW lab
    variable ENABLE_PW lab
    variable TACACS_PW lab
    variable EXCEPTION_DUMP_ADDR $TFTPSERVERADDR
    variable MAX_LINE_LENGTH 76
    variable CFG_FLAG_STR {__CONFIG__FILE__VAR__}
    variable TESTBED_NAME {__TBN__}


    variable names {
        { a {p1 p2 p3 17a  3845b 28a 3845a 7301a 72a 871a}}
        { b {p1 p2 p3 17a  3845b 28a 3845a 7301a 72a 871a}}
        { c {p1 p2 p3 831a 3845b 28a 3845a 7301a 72a 871a}}
        { f {p1 p2 p3 17a  3845b 28a 3845a 7301a 72a 871a 3845c 3825a}}
        { g {p1 p2 p3 831a 3845b 28a 3845a 7301a 72a 871a}}
        { h {p1 p2 p3 831a 3845b 28a 3845a 7301a 72a 871a}}
        { i {p1 p2 p3 17a  3845b 28a 3845a 7301a 72a 871a}}
        { m {p1 p2 p3 17a  3845b 28a 3845a 7301a 72a 871a}}
        { n {p1 p2 p3 17a  3845b 28a 3845a 7301a 72a 871a 7606a}}
        { o {p1 p2 p3 17a  3845b 28a 3845a 7301a 72a 871a 7606a}}
        { p {p1 p2 p3 17a  3845b 28a 3845a 7301a 72a 871a 7606a}}
        { q {p1 p2 p3 17a  3845b 28a 3845a 7301a 72a 871a 7606a}}
        { r {p1 p2 p3 17a  3845b 28a 3845a 7301a 72a 871a}}
    }

    variable interfaces {
        { a {Fas0/0 Fas0/0 Fas0/0 Fas0/0 Gig0/0 Fas0/0 Gig0/0 Gig0/0 Eth1/0 Vlan1}}

        { b {Fas0/0 Fas0/0 Fas0/0 Fas0/0 Gig0/0 Fas0/0 Gig0/0 Gig0/0 Eth1/0 Vlan1}}

        { c {Fas0/0 Fas0/0 Fas0/0 Eth0 Gig0/0 Fas0/0 Gig0/0 Gig0/0 Eth1/0 Vlan1}}

        { f {Eth0/0 Eth0/0 Eth0/0 Fas0/0 Gig0/0 Fas0/0 Gig0/0 Gig0/0 Eth1/0 Vlan1\
                 Gig0/0 Gig0/0 }}

        { g {Eth0/0 Eth0/0 Eth0/0 Eth0 Gig0/0 Fas0/0 Gig0/0 Gig0/0 Eth1/0 Vlan1 }}

        { h {Eth0/0 Eth0/0 Eth0/0 Eth0 Gig0/0 Fas0/0 Gig0/0 Gig0/0 Eth1/0 Vlan1 }}

        { i {Eth0/0 Eth0/0 Eth0/0 Fas0/0 Gig0/0 Fas0/0 Gig0/0 Gig0/0 Eth1/0 Vlan1}}

        { m {Fas0/0 Fas0/0 Fas0/0 Fas0/0 Gig0/0 Fas0/0 Gig0/0 Gig0/0 Eth1/0 Vlan1}}

        { n {fa0/0 fa0/0 fa0/0 Fas0/0 Gig0/0 Fas0/0 Gig0/0 Gig0/0 Eth1/0 Vlan1 \
                 Gig1/1 }}

        { o {fa0/0 fa0/0 fa0/0 Fas0/0 Gig0/0 Fas0/0 Gig0/0 Gig0/0 Eth1/0 Vlan1 \
                 Fas1/1 }}

        { p {Fas0/0 Fas0/0 Fas0/0 Fas0/0 Gig0/0 Fas0/0 Gig0/0 Gig0/0 Eth1/0 Vlan1\
                 Fas2/1 }}

        { q {Fas0/0 Fas0/0 Fas0/0 Fas0/0 Gig0/0 Fas0/0 Gig0/0 Gig0/0 Eth1/0 Vlan1\
                 Fas2/1 }}

        { r {Fas0/0 Fas0/0 Fas0/0 Fas0/0 Gig0/0 Fas0/0 Gig0/0 Gig0/0 Eth1/0 Vlan1}}
    }

    variable address_list {
        { a { 10.2.14.1   255.255.255.224 }}
        { b { 10.2.14.33  255.255.255.224 }}
        { c { 10.2.14.65  255.255.255.224 }}

        { f { 10.1.38.1   255.255.255.0 }}
        { g { 10.1.39.1   255.255.255.0 }}
        { h { 10.1.40.1   255.255.255.0 }}
        { i { 10.1.41.1   255.255.255.0 }}

        { m { 10.1.52.1   255.255.255.0 }}
        { n { 10.1.53.1   255.255.255.0 }}
        { o { 10.1.54.1   255.255.255.0 }}
        { p { 10.1.22.1   255.255.255.0 }}
        { q { 10.2.10.1   255.255.255.0 }}
        { r { 10.2.14.129 255.255.255.224 }}
    }

    variable pagent_key_list {
        { a {"25.47.1.56 9.99.0.0"  "19.47.11.55 69.63.0.0"  \
                 "46.76.14.12 1.69.0.0"  }}

        { b {"80.98.18.50 84.96.0.0"  "10.7.66.77 69.89.0.0"  \
                 "5.44.46.68 94.38.0.0"}}

        { c {"75.50.74.27 37.57.0.0"  "41.63.65.38 24.16.0.0"  \
                 "88.48.25.19 83.95.0.0"  }}

        { f {"62.93.43.37 42.0.7.0"  "74.47.63.32 57.99.0.0"  \
                 "96.55.69.36 59.4.0.0"  }}

        { g {"30.90.57.18 83.56.0.0"  "39.33.54.4 71.85.0.0"  \
                 "97.34.24.46 38.75.0.0"  }}

        { h {"15.78.75.69 26.76.0.0"  "10.9.88.36 42.77.0.0"  \
                 "30.41.88.8 96.12.0.0"  }}

        { i {"31.73.94.78 34.13.0.0"  "46.18.3.83 42.91.0.0"  \
                 "28.20.40.20 82.44.0.0"  }}

        { m {"65.53.98.69 54.15.0.0"  "55.75.82.0 57.65.0.0"  \
                 "24.2.32.63 35.58.0.0"  }}

        { n {"7.23.83.19 12.51.0.0"  "55.62.30.69 36.24.0.0"  \
                 "55.95.00.52 25.75.0.0"  }}

        { o {"36.87.77.80 33.32.0.0"  "99.35.54.59 7.17.0.0"  \
                 "1.41.94.59 11.58.0.0"  }}

        { p {"17.27.5.38 59.50.0.0"  "62.79.99.30 27.13.0.0"  \
                 "59.27.30.85 42.69.0.0"  }}

        { q {"12.45.17.4 21.32.0.0"  "63.66.88.63 76.53.0.0"  \
                 "64.93.2.14 22.65.0.0"  }}

        { r {"37.63.65.93 28.70.0.0"  "92.38.44.37 6.18.0.0"  \
                 "87.82.76.4 68.99.0.0"  }}
    }

    variable type_list {
        { a {3745 3745 3745 1700 3845 2800 3845 7301 7200 871 }}

        { b {3745 3745 3745 1700 3845 2800 3845 7301 7200 871 }}

        { c {3745 3745 3745 831 3845 2800 3845 7301 7200 871 }}

        { f {3640 3640 3640 1700 3845 2800 3845 7301 7200 871 3845 3825 }}

        { g {3640 3640 3640 831 3845 2800 3845 7301 7200 871 }}

        { h {3640 3640 3640 831 3845 2800 3845 7301 7200 871 }}

        { i {3640 3640 3640 1700 3845 2800 3845 7301 7200 871 }}

        { m {3745 3745 3745 1700 3845 2800 3845 7301 7200 871 }}

        { n {3745 3745 3745 1700 3845 2800 3845 7301 7200 871 7606 }}

        { o {3745 3745 3745 1700 3845 2800 3845 7301 7200 871 7606 }}

        { p {3745 3745 3745 1700 3845 2800 3845 7300 7200 871 7606 }}

        { q {3745 3745 3745 1700 3845 2800 3845 7301 7200 871 7606 }}

        { r {3745 3745 3745 1700 3845 2800 3845 7301 7200 871 }}
    }

    variable access_type_list {
        { a {"ipseca-cs1 6004" "ipseca-cs1 6005" "ipseca-cs1 6006" "ipseca-cs1 6015"\
                 "ipseca-cs1 6009" "ipseca-cs1 6008" "ipseca-cs1 6007" \
                 "ipseca-cs1 6003" "ipseca-cs1 6002" "ipseca-cs1 6013" }}

        { b {"ipsecb-cs1 6006" "ipsecb-cs1 6007" "ipsecb-cs1 6008" "ipsecb-cs1 6003"\
                 "ipsecc-cs1 6012" "ipsecc-cs1 6011" "ipsecc-cs1 6009" \
                 "ipsecb-cs1 6005" "ipsecb-cs1 6004" "ipseca-cs1 6014" }}

        { c {"ipsecc-cs1 6004" "ipsecc-cs1 6005" "ipsecc-cs1 6006" "ipsecc-cs1 6015"\
                 "ipsecc-cs1 6014" "ipsecc-cs1 6013" "ipsecc-cs1 6003" \
                 "ipsecc-cs1 6002" "ipsecc-cs1 6016" "ipsecc-cs1 6008" }}

        { f {"ipsecf-cs1 6015" "ipsecf-cs1 6012" "ipsecf-cs1 6016" \
                 "ipsecf-cs1 6009" "ipsecf-cs1 6007" "ipsecf-cs1 6010" \
                 "ipsecf-cs1 6014" "ipsecf-cs1 6008" "ipsecf-cs1 6004" \
                 "ipsecf-cs1 6011" "ipsecf-cs1 6005" "ipsecf-cs1 6006" }}

        { g {"ipsecg-cs1 6077" "ipsecg-cs1 6080" "ipsecg-cs1 6079" "ipsecg-cs1 6066"\
                 "ipsecg-cs1 6067" "ipsecg-cs1 6065" "ipsecg-cs1 6069" \
                 "ipsecg-cs1 6070" "ipsecg-cs1 6071" "ipsecg-cs1 6068" }}

        { h {"ipsech-cs1 6041" "ipsech-cs1 6043" "ipsech-cs1 6047" "ipsech-cs1 6046"\
                 "ipsech-cs1 6033" "ipsech-cs1 6048" "ipsech-cs1 6038" \
                 "ipsech-cs1 6037" "ipsech-cs1 6035" "ipsech-cs1 6042" }}

        { i {"ipseci-cs1 6041" "ipseci-cs1 6047" "ipseci-cs1 6045" "ipseci-cs1 6044"\
                 "ipseci-cs1 6046" "ipseci-cs1 6048" "ipseci-cs1 6038"\
                 "ipseci-cs1 6040" "ipseci-cs1 6036" "ipseci-cs1 6042" }}

        { m {"ipsecm-cs1 6075" "ipsecm-cs1 6074" "ipsecm-cs1 6073" "ipsecm-cs1 6068"\
                 "ipsecm-cs1 6066" "ipsecm-cs1 6069" "ipsecm-cs1 6067" \
                 "ipsecm-cs1 6070" "ipsecm-cs1 6065" "ipsecm-cs1 6071" }}

        { n {"ipsecn-cs1 6075" "ipsecn-cs1 6074" "ipsecn-cs1 6073" "ipsecn-cs1 6069"\
                 "ipsecn-cs1 6066" "ipsecn-cs1 6070" "ipsecn-cs1 6067" \
                 "ipsecn-cs1 6071" "ipsecn-cs1 6065" "ipsecn-cs1 6072" \
                 "ipsecn-cs1 6068" }}

        { o {"ipseco-cs1 6075" "ipseco-cs1 6074" "ipseco-cs1 6073" "ipseco-cs1 6069"\
                 "ipseco-cs1 6066" "ipseco-cs1 6070" "ipseco-cs1 6067" \
                 "ipseco-cs1 6071" "ipseco-cs1 6065" "ipseco-cs1 6072" \
                 "ipseco-cs1 6068" }}

        { p {"ipsecp-cs1 6014" "ipsecp-cs1 6013" "ipsecp-cs1 6012" "ipsecp-cs1 6011"\
                 "ipsecp-cs1 6010" "ipsecp-cs1 6004" "ipsecp-cs1 6003" \
                 "ipsecp-cs1 6002" "ipsecp-cs1 6001" "ipsecp-cs1 6016" \
                 "ipsecq-cs1 6005" }}

        { q {"ipsecq-cs1 6016" "ipsecq-cs1 2002" "ipsecq-cs1 6003" "ipsecq-cs1 6007"\
                 "ipsecq-cs1 6008" "ipsecq-cs1 6009" "ipsecq-cs1 6004" \
                 "ipsecq-cs1 6012" "ipsecq-cs1 2014" "ipsecq-cs1 6006" \
                 "ipsecq-cs1 6011" }}

        { r {"ipsecr-cs1 6006" "ipsecr-cs1 6007" "ipsecr-cs1 6008" "ipsecr-cs1 6004"\
                 "ipsecr-cs1 6003" "ipsecr-cs1 6005" "ipsecr-cs1 6009" \
                 "ipsecr-cs1 6002" "ipsecr-cs1 6001" "ipsecr-cs1 6013" }}
    }

    variable isdn_options {
        { a {50006 61345 172.19.216.102}}

        { b {50001 71019 172.19.216.102}}

        { c {50010 71018 172.19.216.102}}

        { f {50114 61994 172.19.216.102}}

        { g {50116 61995 172.19.216.102}}

        { h {50115 61996 172.19.216.102}}

        { i {50113 61997 172.19.216.102}}

        { m {51003 61005 172.19.216.102}}

        { n {51002 61004 172.19.216.102}}

        { o {51003 61005 172.19.216.102}}

        { p {50007 71012 172.19.192.102}}

        { q {50017 71030 172.19.192.102}}

        { r {50002 71020 172.19.216.102}}
    }


    variable tcl_file_header {# $Id: ats_config_gen.tcl,v 1.4 2006/09/21 18:51:19 tennis Exp $
        global env __CONFIG__FILE__VAR__

        #
        # The following statement is wrapped in an 'info exists env' if statement
        # because of earms.  The config is loaded into earms offline, so the
        # env isn't fully config'd with all env vars yet.  If we referenced
        # AUTOTEST directly, earms would complain.
        #
        if {[info exists env(AUTOTEST) ]} {
            # This loads the contents of ipsec.lib (*not* ipsec.exp) so ipsec::debug
            # will be supported.
            lappend ::auto_path $env(AUTOTEST)/regression/tests/functionality/ipsec
            package require ipsec
        } ; # end if

        #
        # The line below will contain this file's current cvs revision number. This
        # is set automatically by cvs and requires *no* editing. The rev # will also
        # be stuffed into "myversion" by CVS itself whenever this file is sourced.
        #
        if {![regexp {Revision: *([0-9.]+)} {$Revision: 1.4 $} => myversion]} {
            set myversion "unknown"
        }

        #
        # Return if this file has been sourced already _unless_ debug is turned on.
        # If debug is enabled, then we may need to source this file multiple times
        # for debugging purposes.
        #
        if { [ info exists __CONFIG__FILE__VAR__ ] } {
            return -1
        } else {
            set __CONFIG__FILE__VAR__ 1
        } ; # End if
    }

#     variable tcl_file_header \
#         {# $Id: ats_config_gen.tcl,v 1.4 2006/09/21 18:51:19 tennis Exp $}

    variable globals     "global \\\n\
        env                    \\\n\
        MAPDIR                 \\\n\
        tb_tftp_server_name    \\\n\
        tb_tftp_server_addr    \\\n\
        tb_device_configs      \\\n\
        tb_clean_cmd           \\\n\
        tb_devices             \\\n\
        _device                \\\n\
        _catdevice             \\\n\
        tb_passwd              \\\n\
        csccon_default         \\\n\
        testbeds               "

    variable footer "\n\
    \n\
    # [::textutil::strRepeat "-" $MAX_LINE_LENGTH]\n\
    #                            CVS MAINTENANCE LOGS\n\
    #                            ~~~~~~~~~~~~~~~~~~~~\n\
    # \$Log: ats_config_gen.tcl,v $
    # \Revision 1.4  2006/09/21 18:51:19  tennis
    # \
    # \Various updates to some minor support utilities.
    # \
    # \Revision 1.3  2006/06/24 17:55:53  tennis
    # \Added changes to allow for higher address ranges. Reduces
    # \changes of dup ip addrs.
    # \
    # \Revision 1.2  2006/05/24 13:04:29  tennis
    # \
    # \Updates to stop using mpexpr.
    # \\n\
    #\n\
    #\n\
    # [::textutil::strRepeat "-" $MAX_LINE_LENGTH]\n\
    # Local Variables:\n\
    # mode: tcl\n\
    # End:\n\
    "

    variable earms_hook "\n\
    #
    # The preferred path for iou configs is the individual\n\
    # user.  Default to the eArms version if necessary.\n\
    #\n\
    # This is mostly to fake out eArms. When eArms parses a CONFIG\n\
    # file, it does not know about the user environment. When the CONFIG\n\
    # is used however, it will have a user environment defined, so\n\
    # env(ATS_USER_PATH) will be valid.\n\
    #\n\
    if \{\[info exists env(ATS_USER_PATH)\]\} \{\n\
        set path \"\$env(ATS_USER_PATH)/etc/__TBN__\.config\"\n\
        set MAPDIR \$env(ATS_USER_PATH)/etc\n\
        source \$env(ATS_USER_PATH)/stg_reg/utils/custom_report\n\
    \} else \{\n\
        set MAPDIR /auto/stg-devtest/earms/etc\n\
        set path \"/auto/stg-devtest/earms/etc/__TBN__\.config\"\n\
        source /auto/stg-devtest/earms/stg_reg/utils/custom_report\n\
    \} ; # end if\n\n\
    if \{ !\[catch \"source \$MAPDIR/__TBN__\.MAP\" errmsg\] \} \{
    set coremap \$tb_map
    unset tb_map
    \}  else \{
    error \"Error in sourcing  __TBN__.MAP: \$errmsg\"
    \}\n\
    set CUSTOM_REPORT_FUNC custom_report_func\n\
    set UNIQUE_TID 1\n\n\
    set TIMS_ATTRIBUTE(dns_name) tims.cisco.com/Tnr203p\n\
    set TIMS_ATTRIBUTE(GROUP) IKE-IPSEC\n\
    "

    variable earms_clean "
        # EARMS support
        set i 1
        if \{ \[ info exists env(EARMS_ROUTERS_USED) \] \} \{
            set clean_helper \[ split \$env(EARMS_ROUTERS_USED) \",\" \]
            set clean_section \{\}
            set CLEAN(\$this_testbed) \{\}
            foreach rtr \$clean_helper \{
                regsub -all -- \{-|:|\\.\} \$rtr \{_\} tmp_rtr
                if \{ \[ info exists env(EARMS_IMAGES_\$tmp_rtr) \] \} \{
                    lappend clean_section \"\$i stg_clean_router \$rtr\"
                \}
                incr i 1
            \}
            lappend CLEAN(\$this_testbed) \$clean_section
        \} else \{
            set CLEAN(\$this_testbed) \{
                \{"

    variable versions {
        set IMAGE_TYPE(1600)    {1600 Software \(C1600}
        set IMAGE_TYPE(2500)    {2500 Software \(C2500}
        set IMAGE_TYPE(2600)    {2600 Software \(C2600}
        set IMAGE_TYPE(2800)    {2800 Software \(C2800}
        set IMAGE_TYPE(3640)    {3600 Software \(C3640}
        set IMAGE_TYPE(3845)    {3800 Software \(C3845}
        set IMAGE_TYPE(4000)    {4000 Software}
        set IMAGE_TYPE(xx)      {4000 Software|4500 Software}
        set IMAGE_TYPE(4500)    {4500 Software \(C4500|4500 Software \(4500}
        set IMAGE_TYPE(7k)      {GS Software \(GS7|7000 Software}
        set IMAGE_TYPE(7200)    {7200 Software \(C7200}
        set IMAGE_TYPE(7606)    {7606 Software \(C7606}
        set IMAGE_TYPE(C5RSM)   {C5RSP Software \(C5RSP}
        set IMAGE_TYPE(vip)     {VIP Software \(RVIP}
        set IMAGE_TYPE(805)     {805}
        set IMAGE_TYPE(800)     {800}
        set IMAGE_TYPE(871)     {871}
    }

    variable tftp_def "\n\
    # [::textutil::strRepeat "-" $MAX_LINE_LENGTH]\n\
    # Testbed TFTP server name and address.\n\
    # [::textutil::strRepeat "-" $MAX_LINE_LENGTH]\n\
    set TFTPSERVERNAME  $TFTPSERVERNAME\n\
    set TFTPSERVERADDR  $TFTPSERVERADDR\n\
    set tb_tftp_server_name(__TBN__) $TFTPSERVERNAME\n\
    set tb_tftp_server_addr(__TBN__) $TFTPSERVERADDR\n\
    set TFTPDIR {/auto/tftp-stg-ios}\n\
    set BOOTDIR {}\n\
    set EARMS_AUTOTEST_CONCURRENCY 0\n\n
    if {\[catch \\
             {source /auto/stg-devtest/tennis/stg_reg/testbeds/config.lib} \\
             errmsg\]} {\n\
        error \"Error in sourcing config.lib : \$errmsg\"\n\
    }\n\
    "

    variable tb_def "
    # -------------------------------------------------------------------------
    # Set testbed name
    # -------------------------------------------------------------------------
    set this_testbed __TBN__

    if \[info exists env(USE_EARMS)\] {
        set testbeds \$this_testbed
    }
    "

    variable device_list_vars "\n
    set VERSIONS(\$this_testbed) any\n
    set tb_devices(\$this_testbed) \$device_list
    set ROUTERS_NO_EARMS_PROBE(\$this_testbed) \$device_list
    set tb_devices_no_earms_probe(\$this_testbed) \$device_list
    set ROUTERS(\$this_testbed) \$device_list
    set tb_clean_sequence(\$this_testbed) \$device_list"

    variable passwords "\n\
    # [::textutil::strRepeat "-" $MAX_LINE_LENGTH]\n\
    # Passwords configured on the testbed devices. The tb_passwd array is 2\n\
    # dimensional, where the first index is the testbed name and the second\n\
    # the second index is the type of the password.  For IOS routers, the\n\
    # password type can be \"enable\", \"line\", or \"tacacs\". You must\n\
    # have the same passwords on all routers in the testbed.\n\
    # [::textutil::strRepeat "-" $MAX_LINE_LENGTH]\n\
    set ENABLEPW(\$this_testbed) lab\n\
    set TACACSPW(\$this_testbed) lab\n\
    set LINEPW(\$this_testbed) lab\n\
    set tb_passwd(\$this_testbed,enable)   \"lab\"
    set tb_passwd(\$this_testbed,tacacs)   \"\"
    set tb_passwd(\$this_testbed,line)     \"\"
"

    variable footer "\n\
    \n\
    # [::textutil::strRepeat "-" $MAX_LINE_LENGTH]\n\
    #                            CVS MAINTENANCE LOGS\n\
    #                            ~~~~~~~~~~~~~~~~~~~~\n\
    # \$Log: ats_config_gen.tcl,v $
    # \Revision 1.4  2006/09/21 18:51:19  tennis
    # \
    # \Various updates to some minor support utilities.
    # \
    # \Revision 1.3  2006/06/24 17:55:53  tennis
    # \Added changes to allow for higher address ranges. Reduces
    # \changes of dup ip addrs.
    # \
    # \Revision 1.2  2006/05/24 13:04:29  tennis
    # \
    # \Updates to stop using mpexpr.
    # \
    # \Revision 1.1  2006/05/14 18:59:21  tennis
    # \*** empty log message ***
    # \
    # \Revision 1.2  2006/05/03 22:47:26  tennis
    # \
    # \Add mapdirs
    # \
    #\n\
    # [::textutil::strRepeat "-" $MAX_LINE_LENGTH]\n\
    # Local Variables:\n\
    # mode: tcl\n\
    # End:\n\
"
}

proc ::config::long2short { args } {

    set man_args {
        -testbed_name ANY
    }

    parse_dashed_args      \
        -args $args        \
        -mandatory_args $man_args

    set tbn ""

    if { [ expr {[clength $testbed_name] > 1} ] } {

        ipsec::debug "testbed name $testbed_name"

        set tbn [regsub -all -- {ipsec} $testbed_name {}]

    } else {

        ipsec::debug "TB name already in shortened form."

        set tbn $testbed_name
    }

    ipsec::debug "Returning $tbn"

    return $tbn
}

proc ::config::short2long { args } {
    set man_args {
        -testbed_name ALPHA
    }

    parse_dashed_args      \
        -args $args        \
        -mandatory_args $man_args

    ipsec::debug "tbd name length [clength $testbed_name]"

    if { [ expr {[clength $testbed_name] > 1} ] } {

        ipsec::debug "TB name already in elongated form"

        set tbn $testbed_name

    } else {

        set tbn [cconcat "ipsec" $testbed_name]

        ipsec::debug "elongating tb name to $tbn"
    }

    ipsec::debug "testbed_name is now $tbn, was $testbed_name"

    return $tbn
}

proc ::config::index2device_name { args } {
    variable names
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -testbed_index NUMERIC
        -device_index  NUMERIC
    }

    parse_dashed_args -args $args \
        -mandatory_args $man_args

    set device [lindex \
                    [lindex \
                         [lindex $names $testbed_index] \
                         $TB_ENTRIES] \
                    $device_index]

    ipsec::debug "device = $device"

    return $device
}

proc ::config::index2device_interface { args } {
    variable interfaces
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -testbed_index NUMERIC
        -device_index  NUMERIC
    }

    parse_dashed_args -args $args \
        -mandatory_args $man_args

    set intf [lindex \
                  [lindex \
                       [lindex $interfaces $testbed_index] \
                       $TB_ENTRIES] \
                  $device_index]

    ipsec::debug "intf = $intf"

    return $intf
}

proc ::config::index2device_ip { args } {
    variable address_list
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -testbed_index NUMERIC
        -device_index  NUMERIC
    }

    set opt_args {
        -gateway FLAG
        DEFAULT 0
        -mask FLAG
        DEFAULT 0
        -offset DECIMAL
        DEFAULT 0
    }

    parse_dashed_args -args $args \
        -mandatory_args $man_args \
        -optional_args $opt_args

    set addr_info  [lindex \
                        [lindex $address_list $testbed_index] \
                        $TB_ENTRIES]

    ipsec::debug "\naddr_info = $addr_info"

    foreach { ip_gateway ip_mask } $addr_info break

    ipsec::debug "\ngateway = $ip_gateway\nmask = $ip_mask"

    if {$gateway} {
        set ret_val $ip_gateway
    } elseif {$mask} {
        set ret_val $ip_mask
    } else {
        # indices count from zero, so we need to add 1 to avoid
        # using the gateway address on an interface.
        set ip_incr [ expr { $device_index + $offset + 1 } ]

        ipsec::debug "\nip_incr = $ip_incr"

        set ip_addr [dataUtils::next_host $ip_gateway \
                         -offset $ip_incr -mask $ip_mask]

        ipsec::debug "ip_addr = $ip_addr"

        set ret_val $ip_addr

    } ; # end if

    ipsec::debug "returning $ret_val"

    return $ret_val
}

proc ::config::index2device_pagent_key { args } {
    variable pagent_key_list
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -testbed_index NUMERIC
        -device_index  NUMERIC
    }

    parse_dashed_args -args $args \
        -mandatory_args $man_args

    set key_info  [lindex \
                       [lindex $pagent_key_list $testbed_index] \
                       $TB_ENTRIES]

    ipsec::debug "\nkey_info = $key_info"

    #
    # Subtract 1 from the index since we start from 0 and the llength cmd
    # returns a whole number
    #
    if {$device_index > [expr { [llength $key_info] - 1}]} {
        ipsec::debug "No key found"
        set key ""
    } else {

        ipsec::debug "Key present"
        set key [lindex $key_info $device_index]

    } ; # end if

    ipsec::debug "Returning key:$key"

    return $key
}

proc ::config::index2device_type { args } {
    variable type_list
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -testbed_index NUMERIC
        -device_index  NUMERIC
    }

    parse_dashed_args -args $args \
        -mandatory_args $man_args

    set type [lindex \
                  [lindex \
                       [lindex $type_list $testbed_index] \
                       $TB_ENTRIES] \
                  $device_index]

    ipsec::debug "device type = $type"

    return $type
}

proc ::config::index2testbed_name { args } {
    variable names
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -testbed_index NUMERIC
    }

    set opt_args {
        -long FLAG
        DEFAULT 0
    }

    parse_dashed_args -args $args \
        -mandatory_args $man_args \
        -optional_args $opt_args

    set name [lindex \
                  [lindex $names $testbed_index] \
                  $TB_NAME]

    ipsec::debug "testbed name = $name"

    #
    # do we want a fully-qualified name, or a
    # short one?
    #
    if {$long} {
        set name [cconcat "ipsec" $name]
        ipsec::debug "name is now $name"
    } else {
        ipsec::debug "returning single letter name"
    } ; # end if

    return $name
}

proc ::config::index2testbed_types { args } {
    variable type_list
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -testbed_index NUMERIC
    }

    parse_dashed_args -args $args \
        -mandatory_args $man_args

    set types [lindex \
                   [lindex $type_list $testbed_index] \
                   $TB_ENTRIES]

    # Get the device-by-device list of
    # types and simply remove all the dups.
    # That yields the testbed type list.
    set types [lrmdups $types]

    ipsec::debug "testbed types = $types"

    return $types
}

proc ::config::index2testbed_isdn_options { args } {
    variable isdn_options
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -testbed_index NUMERIC
    }

    parse_dashed_args -args $args \
        -mandatory_args $man_args

    set options [lindex \
                     [lindex $isdn_options $testbed_index] \
                     $TB_ENTRIES]

    ipsec::debug "testbed options = $options"

    return $options
}

proc ::config::index2device_access { args } {
    variable access_type_list
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -testbed_index NUMERIC
        -device_index  NUMERIC
    }

    parse_dashed_args -args $args \
        -mandatory_args $man_args

    set access [lindex \
                    [lindex \
                         [lindex $access_type_list $testbed_index] \
                         $TB_ENTRIES] \
                    $device_index]

    ipsec::debug "device access = $access"

    return $access
}

proc ::config::testbed_count { } {
    variable names

    return [llength $names]
}

proc ::config::testbed_device_count { args } {
    variable names
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -testbed_name ALPHA
    }

    parse_dashed_args      \
        -args $args        \
        -mandatory_args $man_args

    set tbndx [::config::testbed_name2index -testbed_name $testbed_name]

    set tb_count [lindex \
                      [lindex $names $tbndx] \
                      $TB_ENTRIES]
    ipsec::debug "tbcount is $tb_count"

    return $tb_count
}

proc ::config::testbeds { args } {
    variable names
    variable TB_NAME
    variable TB_ENTRIES
    variable tb_short_list

    set opt_args {
        -long_names FLAG
        DEFAULT 0
    }

    parse_dashed_args      \
        -args $args        \
        -optional_args $opt_args

    #
    # don't bother to recalculate this if its already done
    #
    if { [lempty $tb_short_list] } {

        ipsec::debug "Recalculating list"

        set tb_list ""

        set ndx 0

        ::control::do {

            ::config::index2testbed_name -testbed_index $ndx

            ipsec::debug "ndx is $ndx"

            set tb_short [::config::index2testbed_name -testbed_index $ndx]

            ipsec::debug "tb_short is $tb_short"

            #
            # walk thru the tb's and then enlongate the name
            # if needed.
            #
            if {$long_names} {
                set tb [::config::short2long -testbed_name $tb_short]
                ipsec::debug "short name $tb_short reset to long name: $tb"
            } else {
                ipsec::debug "Defaulting to short name $tb_short"
                set tb $tb_short
            } ; # end if

            lappend tb_list $tb

            incr ndx
        } while { [expr { $ndx < [::config::testbed_count] }] }

        set tb_short_list $tb_list

    } else {
        set tb_list $tb_short_list
    } ; # end if

    ipsec::debug "tb_list:\n$tb_list"

    return $tb_list
}


proc ::config::testbed_name2index { args } {
    variable names
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -testbed_name ALPHA
    }

    parse_dashed_args      \
        -args $args        \
        -mandatory_args $man_args

    #
    # Shorten the name if needed.
    #
    if { [ expr {[clength $testbed_name] > 1} ] } {
        set short_name [::config::long2short -testbed_name $testbed_name]
    } else {
        set short_name $testbed_name
    } ; # end if

    set tb_list [::config::testbeds]

    set ndx [lsearch -exact $tb_list $short_name]

    ipsec::debug "index found is $ndx"

    return $ndx
}

proc ::config::testbed_device_types { args } {
    variable names
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -testbed_name ALPHA
    }

    parse_dashed_args      \
        -args $args        \
        -mandatory_args $man_args

    #
    # Shorten the name if needed.
    #
    if { [ expr {[clength $testbed_name] > 1} ] } {
        ipsec::debug "Shortening testbed_name"
        set short_name [::config::long2short -testbed_name $testbed_name]
    } else {
        ipsec::debug "testbed_name already short"
        set short_name $testbed_name
    } ; # end if

    set tb_list [::config::testbeds]

    set ndx [lsearch -exact $tb_list $short_name]

    ipsec::debug "The index for $short_name is $ndx"

    set tb_types [::config::index2testbed_types -testbed_index $ndx]

    ipsec::debug "tb types for $short_name is:\n$tb_types"

    return $tb_types
}


proc ::config::devices { args } {
    variable names
    variable device_long_names
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -testbed_name ANY
    }

    set opt_args {
        -long_names FLAG
        DEFAULT 0
    }

    parse_dashed_args             \
        -args $args               \
        -mandatory_args $man_args \
        -optional_args $opt_args

    set tb_short [::config::long2short -testbed_name $testbed_name]

    #
    # After the first time we build this, just keep it handy.
    #
    if {[info exists device_long_names($tb_short)]} {
        set ret_val $device_long_names($tb_short)
    } else {
        set ndx [::config::testbed_name2index -testbed_name $tb_short]

        set devices [lindex [lindex $names $ndx] $TB_ENTRIES]

        ipsec::debug "devices are:\n$devices"

        if {$long_names} {
            set devices [regsub -all -- {([^ ]+)} $devices \
                             [cconcat "ipsec" $tb_short "-" \\1]]
        } else {
            ipsec::debug "Devices not changed to long names"
        } ; # end if

        ipsec::debug "devices $devices"

        set ret_val $devices

        set device_long_names($tb_short) $devices
    } ; # end if

    return $ret_val
}

proc ::config::device2testbed_name { args } {

    set man_args {
        -device ANY
    }

    parse_dashed_args              \
        -args $args                \
        -mandatory_args $man_args

    #
    # pull the tb name out, and squawk if not found.
    #
    if {[regexp -- {ipsec([a-z]).*} $device - tb]} {
        ipsec::debug "Got tb name:$tb"
    } else {
        puts "ERROR: could not get testbed name!"
        set tb ""
    } ; # end if

    return $tb
}

proc ::config::device2device_index { args } {
    variable names
    variable TB_NAME
    variable TB_ENTRIES

    set man_args {
        -device ANY
    }

    parse_dashed_args      \
        -args $args        \
        -mandatory_args $man_args

    set tb [::config::device2testbed_name -device $device]

    ipsec::debug "tb = $tb"

    set tbd [::config::devices -testbed_name $tb -long_names]

    ipsec::debug "tb_devices $tbd"

    set ndx [lsearch -exact $tbd $device]

    ipsec::debug "device index is: $ndx"

    return $ndx
}

proc ::config::device2testbed_index { args } {

    set man_args {
        -device ANY
    }

    parse_dashed_args      \
        -args $args        \
        -mandatory_args $man_args


    set tb [::config::device2testbed_name -device $device]

    ipsec::debug "tb = $tb"

    set tb_ndx [::config::testbed_name2index -testbed_name $tb]

    ipsec::debug "tb_ndx = $tb_ndx"

    return $tb_ndx

}

proc ::config::type { args } {

    set man_args {
        -device ANY
    }

    parse_dashed_args             \
        -args $args               \
        -mandatory_args $man_args

    set tb_ndx [::config::device2testbed_index -device $device]

    ipsec::debug "tb_ndx = $tb_ndx"

    set dev_ndx [::config::device2device_index -device $device]

    ipsec::debug "dev_ndx = $dev_ndx"

    set type [::config::index2device_type \
                  -testbed_index $tb_ndx \
                  -device_index $dev_ndx]

    ipsec::debug "type is $type"

    return $type

} ; # end type

proc ::config::interface { args } {

    set man_args {
        -device ANY
    }

    parse_dashed_args             \
        -args $args               \
        -mandatory_args $man_args

    set tb_ndx [::config::device2testbed_index -device $device]

    ipsec::debug "tb_ndx = $tb_ndx"

    set dev_ndx [::config::device2device_index -device $device]

    ipsec::debug "dev_ndx = $dev_ndx"

    set intf [::config::index2device_interface \
                  -testbed_index $tb_ndx \
                  -device_index $dev_ndx]

    ipsec::debug "intf is $intf"

    return $intf

} ; # end type

proc ::config::ip { args } {

    set man_args {
        -device ANY
    }

    set opt_args {
        -offset DECIMAL
        DEFAULT 0
    }

    parse_dashed_args             \
        -args $args               \
        -optional_args $opt_args  \
        -mandatory_args $man_args

    set tb_ndx [::config::device2testbed_index -device $device]

    ipsec::debug "tb_ndx = $tb_ndx"

    set dev_ndx [::config::device2device_index -device $device]

    ipsec::debug "dev_ndx = $dev_ndx"

    set addr [::config::index2device_ip  \
                  -offset $offset        \
                  -testbed_index $tb_ndx \
                  -device_index $dev_ndx]

    ipsec::debug "addr is $addr"

    return $addr

} ; # end type


proc ::config::mask { args } {

    set man_args {
        -device ANY
    }

    parse_dashed_args             \
        -args $args               \
        -mandatory_args $man_args

    set tb_ndx [::config::device2testbed_index -device $device]

    ipsec::debug "tb_ndx = $tb_ndx"

    set dev_ndx [::config::device2device_index -device $device]

    ipsec::debug "dev_ndx = $dev_ndx"

    set mask [::config::index2device_ip \
                  -mask \
                  -testbed_index $tb_ndx \
                  -device_index $dev_ndx]

    ipsec::debug "addr is $mask"

    return $mask

} ; # end type


proc ::config::gateway { args } {

    set man_args {
        -device ANY
    }

    parse_dashed_args             \
        -args $args               \
        -mandatory_args $man_args

    set tb_ndx [::config::device2testbed_index -device $device]

    ipsec::debug "tb_ndx = $tb_ndx"

    set dev_ndx [::config::device2device_index -device $device]

    ipsec::debug "dev_ndx = $dev_ndx"

    set mask [::config::index2device_ip \
                  -gateway \
                  -testbed_index $tb_ndx \
                  -device_index $dev_ndx]

    ipsec::debug "addr is $mask"

    return $mask

} ; # end type

proc ::config::pagent_key { args } {

    set man_args {
        -device ANY
    }

    parse_dashed_args             \
        -args $args               \
        -mandatory_args $man_args

    set tb_ndx [::config::device2testbed_index -device $device]

    ipsec::debug "tb_ndx = $tb_ndx"

    set dev_ndx [::config::device2device_index -device $device]

    ipsec::debug "dev_ndx = $dev_ndx"

    set key [::config::index2device_pagent_key \
                 -testbed_index $tb_ndx \
                 -device_index $dev_ndx]

    ipsec::debug "key is $key"

    return $key

} ; # end type

proc ::config::access { args } {

    set man_args {
        -device ANY
    }

    parse_dashed_args             \
        -args $args               \
        -mandatory_args $man_args

    set tb_ndx [::config::device2testbed_index -device $device]

    ipsec::debug "tb_ndx = $tb_ndx"

    set dev_ndx [::config::device2device_index -device $device]

    ipsec::debug "dev_ndx = $dev_ndx"

    set tn [::config::index2device_access \
                -testbed_index $tb_ndx \
                -device_index $dev_ndx]

    ipsec::debug "key is $tn"

    return $tn
} ; # end type


proc ::config::cfg_file_templates_get { args } {
    variable address_list
    variable footer
    variable passwords
    variable tb_def
    variable tftp_def
    variable versions
    variable earms_hook
    variable globals
    variable tcl_file_header
    variable LINE_PW lab
    variable ENABLE_PW lab
    variable TACACS_PW lab
    variable EXCEPTION_DUMP_ADDR
    variable TFTPSERVERADDR
    variable MAX_LINE_LENGTH 76
    variable earms_clean
    variable device_list_vars
    # Get rid of the formatting whitespace caused by
    # indentation.
    variable REMOVE_LEADING_WHITESPACE {^ +([^ ]+.*)}
    variable CFG_FLAG_STR {__CONFIG__FILE__VAR__}
    variable TESTBED_NAME {__TBN__}

    set opt_args {
        -testbed_name ALPHA
        DEFAULT {UNKNOWN}
        -image_versions FLAG
        DEFAULT 0
        -testbed_passwords FLAG
        DEFAULT 0
        -file_footer FLAG
        DEFAULT 0
        -tftp FLAG
        DEFAULT 0
        -cfg_earms_hook FLAG
        DEFAULT 0
        -file_header FLAG
        DEFAULT 0
        -global_defs FLAG
        DEFAULT 0
        -testbed_switch FLAG
        DEFAULT 0
        -device_list FLAG
        DEFAULT 0
        -device_types FLAG
        DEFAULT 0
        -per_device_types FLAG
        DEFAULT 0
        -telnet_addresses FLAG
        DEFAULT 0
        -isdn_options FLAG
        DEFAULT 0
        -post_configs FLAG
        DEFAULT 0
        -easy_defs FLAG
        DEFAULT 0
        -earms_support FLAG
        DEFAULT 0
    }

    parse_dashed_args \
        -args $args \
        -optional_args $opt_args

    set testbed_name [::config::short2long -testbed_name $testbed_name]

    #
    #
    #
    if {$image_versions} {

        set ver $versions

        ipsec::debug "versions:\n$ver"

        return $ver

    } elseif {$isdn_options} {

        set tbndx [::config::testbed_name2index -testbed_name $testbed_name]

        set opt [::config::index2testbed_isdn_options -testbed_index $tbndx]

        return "set OPTIONS(\$this_testbed) \{$opt\}"

    } elseif {$testbed_passwords} {

        set pwds $passwords

        ipsec::debug "pwds:\n$pwds"

        return $pwds

    } elseif {$tftp} {
        #
        # Set the testbed number inside our path settings which
        # make E-ARMS *think* we're an e-Arms testbed only.
        #
        regsub -line -all -- \
            $TESTBED_NAME $tftp_def \
            $testbed_name formatted_tftp_def

        ipsec::debug "tftp_def is now $formatted_tftp_def"

        return $formatted_tftp_def

    } elseif {$file_footer} {

        return $footer

    } elseif {$cfg_earms_hook} {

        #
        # Set the testbed number inside our path settings which
        # make E-ARMS *think* we're an e-Arms testbed only.
        #
        regsub -line -all -- \
            $TESTBED_NAME $earms_hook \
            $testbed_name formatted_earms_hook

        return $formatted_earms_hook

    } elseif {$global_defs} {

        return $::config::globals

    } elseif {$file_header} {

        set cfg_file_var [cconcat $testbed_name "_config_file_already_sourced"]

        #
        # Insert our particular config file name into the standard
        # config file header.
        #
        regsub -line -all -- $CFG_FLAG_STR $tcl_file_header \
            $cfg_file_var formatted_tcl_cfg_file_header

        return $formatted_tcl_cfg_file_header

    } elseif {$testbed_switch} {
        set formatted_tb_switch ""

        regsub -line -all -- \
            $TESTBED_NAME $tb_def \
            $testbed_name formatted_tb_switch

        return $formatted_tb_switch

    } elseif {$device_list} {

        set device_output ""

        set tb_dev [::config::devices \
                        -testbed_name $testbed_name -long_names]
        #
        # Make the device list formatting to fit inside 80 cols
        #
        set device_output [cconcat $device_output "set device_list \{ \\\n"]

        # Pull off 3 device names at a time.
        foreach {d1 d2 d3} $tb_dev {
            set device_output [cconcat $device_output "$d1 $d2 $d3" " \\\n"]
        }

        set device_output [cconcat $device_output "\}\n"]

        set device_output [cconcat $device_output $device_list_vars]

        return $device_output

    } elseif {$device_types} {

        set device_types [::config::testbed_device_types \
                              -testbed_name $testbed_name]

        return "set TYPE(\$this_testbed) \{$device_types\}\n"

    } elseif {$telnet_addresses} {

        set ta_tb_dev [::config::devices \
                        -testbed_name $testbed_name -long_names]

        set ta ""
        #
        # put in the telnet addresses.
        #
        foreach dev $ta_tb_dev {
            set ta [cconcat $ta  \
                        "set _device($dev) \
                   \"telnet [::config::access -device $dev]\"\n"]
        } ; # end foreach

        set ta [cconcat $ta "\n"]

        return $ta

    } elseif {$per_device_types} {

        set per_device_types ""

        set tb_dev [::config::devices \
                        -testbed_name $testbed_name -long_names]

        set autotest_q [::struct::queue]

        foreach rtr $tb_dev  {
            set type [::config::type -device $rtr]
            $autotest_q put "set TYPE($rtr) $type\n"
        } ; # end foreach

        ::control::do {
            set per_device_types [cconcat  $per_device_types [$autotest_q get]]
        } while { [$autotest_q size] > 0}

        set per_device_types [cconcat $per_device_types "\n"]

        ipsec::debug "per_device_types:\n$per_device_types"

        $autotest_q destroy

        return $per_device_types

    } elseif {$earms_support} {

        set e_arms $earms_clean

        set i 1
        foreach dev [::config::devices \
                         -testbed_name $testbed_name -long_names] {
            set e_arms [cconcat $e_arms "\n\{ $i stg_clean_router $dev \}"]
            incr i
        }

        set e_arms [cconcat $e_arms "\n\}\n\}\n\}\n\n"]

        ipsec::debug "earms support returning:\n$e_arms"

        return $e_arms

    } elseif {$easy_defs} {

        set defs "\
        # Use already-defined values for the easy defs \n\
        # where possible.\n\
        foreach dev \$ROUTERS(\$this_testbed) \{\n\
            set tb_type(\$dev) \$TYPE(\$dev)\n
            # For now, use the default configs as post configs\n\
            # for everything too.\n\
            set postconfig(\$dev)  \$defaultconfig(\$dev)\n\
            set tb_device_configs(preclean,\$dev,ios-classic) \\\n\
             \$defaultconfig(\$dev)\n\
            set tb_device_configs(postclean,\$dev,ios-classic) \\\n\
             \$defaultconfig(\$dev)\n\
            set tb_clean_cmd(\$dev) stg_autoeasy_clean_router\n\
        \} ; # end foreach\n\
        "
    } else {
        puts "ERROR! Unknown parm!"
    }; # end if
}

proc ::config::register {name body} {
    variable template

    # Verify that the template name is not already in use
    if {[info exists ::config::template($name)]} {
        error "Template '$name' already registered"
    }

    # Store the template
    set ::config::template($name) $body
    return $body
}

proc ::config::generate {name index args} {
    variable template

    # Verify that the named template has been registered
    if {![info exists ::config::template($name)]} {
        error "Template '$name' not registered"
    }

    set result $::config::template($name)
    set globalName $name

    # Replace the formatting strings in the template
    foreach {parm value} $args {
        set parm [join [list "@" [string range $parm 1 end] "@"] ""]
        ipsec::debug "Parm is $parm and value is $value"

        #
        #
        #
        if {[cequal $parm @pgenSec@] && [lempty $value]} {
            regsub -all $parm $result $value result
            regsub -all "ip host PAGENT-SECURITY-V3" $result "!" result
        } else {
            regsub -all $parm $result $value result
        } ; # end if
    }

    # Insure that all formatting strings have been replaced
    if {[regexp {@[^\s@]+@} $result]} {
        error "Variable elements not replaced in:\n$result"
    }

    # Store the global configuration
    regexp {\.([^\.]+$)} $globalName - globalName
    set "::${globalName}(${index})" $result

    return $result
}

###
### Sample usage
###

package require config

::config::register ipsec.defaultconfig {
    set defaultconfig(@host@) {
    hostname @host@
    ip host PAGENT-SECURITY-V3 @pgenSec@
    enable password lab
    no ip domain-lookup
    no ip routing
    ! Turning this off will provide better memory
    ! audit trails of memory allocations and who
    ! is doing them.
    no mem lite
    ip default-gateway @ipGw@
    service timestamps debug datetime msec localtime
    ! Make sure we capture any problems for our log
    logging buffered 500000 debugging
    no service config
    clock timezone PST -8
    clock summer-time PDT recurring
    interface @srcInt@
    ip address @ipAddr@ @ipMask@
    !
    speed 100
    duplex full
    !
    no shutdown
    !
    ! Ip routing is needed to make sure we can route to enable
    ! netboot after an un-config.  This won't work on a bootflash
    ! image, but it will not cause any problems either.
    ip routing
    !
    ip route 0.0.0.0 0.0.0.0 @ipGw@
    !
    no parser cache
    no boot network
    ip tftp source-interface @srcInt@
    exception core-file /auto/tftp-stg-ios/core-@host@
    exception dump 172.19.201.81
    exception memory minimum 500000
    exception crashinfo buffersize 100
    }
}

package require struct::queue

#
# Use this to avoid conflicting with existing
# addresses from previous config file versions.
#
set HIGHER_ADDRESS_RANGE 10

catch {::struct::record::record delete record router}

::struct::record::record define router {
    testbed
    name
    type
    intf
    intf_ip_addr
    intf_ip_mask
    ip_gw
    {pagent_key !}
    telnet
}

# Walk thru the testbeds, and instantiate all the routers.
foreach tb [::config::testbeds] {

    puts "AGC-00-001I ipsec$tb: Parsing testbed definitions"

    foreach rtr [::config::devices -testbed_name $tb -long_names] {

        router $rtr                                                        \
            -testbed $tb                                                   \
            -name $rtr                                                     \
            -type [::config::type -device $rtr]                            \
            -intf [::config::interface -device $rtr]                       \
            -intf_ip_addr [::config::ip \
                               -device $rtr -offset $HIGHER_ADDRESS_RANGE] \
            -intf_ip_mask [::config::mask -device $rtr]                    \
            -ip_gw [::config::gateway -device $rtr]                        \
            -pagent_key [::config::pagent_key -device $rtr]                \
            -telnet [::config::access -device $rtr]
    }
} ; # end foreach

puts "ACG-00-003I Completed parsing. Creating files next."

#
# Now that we have all the testbed input read, and router info sorted
# out, we can then built the testbed config files.
#
foreach tbn [::config::testbeds -long_names] {

    puts "ACG-00-001I ipsec$tbn - Generating config file..."

    set device_output {}

    set cfg_filename "/tmp/CONFIG.[::config::short2long -testbed_name $tbn]"

    catch { file delete -force $cfg_filename }

    set cfh [open $cfg_filename w]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -file_header]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -global_defs]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -testbed_switch]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -tftp]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -testbed_passwords]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -isdn_options]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -device_list]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -earms_support]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -image_versions]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -device_types]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -per_device_types]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -cfg_earms_hook]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -telnet_addresses]

    set devices [::config::devices -testbed_name $tbn -long_names]

    #
    # Generate all the configs for each router.
    #
    foreach rtr  $devices {
        puts $cfh [::config::generate ipsec.defaultconfig $rtr      \
                       -host $rtr                                   \
                       -pgenSec [::config::pagent_key -device $rtr] \
                       -ipAddr [::config::ip -device $rtr]          \
                       -ipMask [::config::mask -device $rtr]        \
                       -srcInt [::config::interface -device $rtr]   \
                       -ipGw [::config::gateway -device $rtr]]
    } ; # end foreach

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -easy_defs]

    puts $cfh [::config::cfg_file_templates_get \
                   -testbed_name $tbn -file_footer]
    flush $cfh
    close $cfh

    #
    # Now, make the file contents indented correctly.
    #
    catch {exec /usr/local/bin/emacs21                               \
               -batch                                                \
               $cfg_filename                                         \
               --no-init-file                                        \
               --no-site-file                                        \
               --eval "(setq indent-tabs-mode nil)"                  \
               --eval "(setq tab-width 4)"                           \
               --eval "(auto-fill-mode 1)"                           \
               --eval "(indent-region (point-min) (point-max) nil)"  \
               -f save-buffer}
}

puts "AGC-00-004I Config file generation complete!"