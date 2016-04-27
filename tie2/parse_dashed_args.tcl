##Library Header
#
# $Id: parse_dashed_args.tcl,v 1.42 2006/10/30 22:00:00 mkirkham Exp $
# Copyright (c) 2002 by Cisco Systems, Inc.
#
# Name:
#   parse_dashed_args
#
# Purpose:
#   This library provides the procedure "parse_dashed_args", which is used
#   to parse a list of dashed arguments into an array or variables within
#   the context of the calling routine or script.
#
# Author:
#   Michael Kirkham, Dave Cardosi and Wayne Marquette
#
# Usage:
#   package require parse_dashed_args
#
# Description:
#   The top level procedure for this library is parse_dashed_args. All other 
#   procedures in this library are internal in support of parse_dashed_args.
#
#   To see all the features of parse_dashed_args, refer to the
#   procedure description.
#
# Requirements:
#   None
#
# Support Alias:  
#   ats-support@cisco.com
#
# Keywords:
#   parsing parser parse dashed args arguments
#
# Category:
#   utilities,parsing utilities,development
#
# End of Header

# SCRIPT_CHECKER_EXCLUDE(S5.1): script_checker gives false errors about
# uplevel calls requiring levels because the level is specified but not
# constant.

namespace eval pda {
    variable _re            ;# Reg. Exps used for type-value validation
    variable pda_flag_arg   ;# pda args that are of type FLAG
    set pda_flag_arg(exact) {}
    set pda_flag_arg(closest) {}
    set pda_flag_arg(no_help) {}
    set pda_flag_arg(passthru) {}
    set pda_flag_arg(return_direct) {}

    namespace export parse_dashed_args
}

##Procedure Header
#
# Name:
#   parse_dashed_args
#
# Purpose:
#   To parse a list of dashed arguments into an array or variables within
#   the context of the calling routine or script.
#
# Synopsis:
#   parse_dashed_args -args <parse_arglist> 
#                     [-mandatory_args <man_arglist>] 
#                     [-optional_args <opt_arglist>]
#                     [-return_direct | -return_array <array-name>]
#                     [-passthru]
#                     [-no_help]
#                     [-level <context-level>]
#
# Arguments:
#   -args <parse_arglist>
#       List of arguments to be parsed, where arguments must be in a
#       dashed format.  The format can be stand-alone (ex. -arg1) or in 
#       argument/value pairs (ex. -arg1 value1). Note the value may
#       also be a list (ex. -arg1 value1 value2 value3).
#       Each element in the parse list must appear in one of the
#       argument check lists (mandatory or optional).  If all check
#       lists are null, then any arguments in the parse list cause an
#       error to be thrown.
#
#   -mandatory_args <man_arglist>
#       List of mandatory arguments.
#       Every element in this list identifies a dashed argument name
#       required in the parse list.  
#       If a mandatory argument specified here is not found in the 
#       arguments being parsed, an error is thrown.
#       By default, a null list is assumed, meaning there are
#       no mandatory arguments.
#       The arguments are specified in a "line" format as follows:
#         -<argname>[:<altname>] <check_type> <check_fields>
#                                <check_type> <check_fields>
#                                ...
#         -<argname>[:<altname>] <check_type> <check_fields>
#                                <check_type> <check_fields>
#                                ...
#         Breakdown:
#           - The <argname> is the name of the dashed argument 
#             (with the dash).  It is required.
#           - The colon separated <altname> is optional.  If specified, it
#             will be used as an alternative variable name or array index
#             upleveled to the callers context, instead of the argname.
#             In most cases this should be avoided if possible.
#           - The <check_type> is a check type which may be followed by 
#             corresponding <check_fields> depending on the type as
#             follows (check_type is always specifed in all caps):
#               RANGE <low_value>-<high_value>
#                  A numeric range, between low_value and high_value.
#               CHOICES <choice1> <choice2> <choice3>... 
#                  A list of choice values logically or'ed together.
#               IP
#                  An IP address, either v4 (dotted decimal notation) or
#                  v6 (colon hexadecimal notation).
#               IPV4
#                  A v4 IP address (of the form #.#.#.#).
#               IPV6
#                  A v6 IP address (of the form #:#:#:#:#:#:#:#).
#               MASK
#                  An IP mask in either v4, v6, or CIDR (decimal) format.
#               MAC
#                  A MAC address, in standard or Cisco format.
#               KEYLIST 
#                  A TCL keyed list.  The KEYLIST type is exclusive, meaning
#                  it cannot be combined with other check types, and only
#                  a single keylist value is allowed.  No verification is
#                  done on the keylist value, it is assumed to be in
#                  TCL keylist format, so invalid keylist formats will
#                  have unforseen consequences.
#               REGEXP
#                  A TCL regular expression.
#               ALPHA
#                  An alphabetic only value.
#               NUMERIC
#                  A numeric only value.
#               ALPHANUM
#                  An alphanumeric value (letters, numbers, or underbars).
#               DECIMAL
#                  A decimal value (a number with a possible single
#                  decimal point).
#               HEX
#                  A hex value, which may optionally have a leading "0x".
#               FLAG
#                  A flag argument, meaning this argument either does not have
#                  any value and is a stand-alone argument or accepts a boolean
#                  value (0, 1, yes, no, true or false).  The behavior of
#                  FLAG switches depends on the presence or absense of a
#                  DEFAULT value.
#
#                  If a DEFAULT value is defined for the flag, then the
#                  return variable will always be set to 0 or 1 and the
#                  optional_args return variable will get both the switch
#                  name and the 0 or 1 value.
#
#                  If a DEFAULT value IS NOT defined for the flag, then the
#                  return variable is set to 1 only if the switch is provided
#                  and is not set otherwise.  Likewise, only the switch
#                  name will be included in the optional_args return variable
#                  and only if the switch is provided.
#
#                  The FLAG type is exclusive, meaning it cannot be combined
#                  with other check types.
#               SHIFT
#                  An unchecked value which is blindly "shifted" from the
#                  list of arguments.  This is generally used for string 
#                  values which could contain special characters, and would
#                  therefore confuse the parser if not ignored (such as a
#                  leading dash).
#                  This type is limited to a single value since only a
#                  single positional shift is performed, so anything that
#                  may contain spaces must be quoted into a single string.
#                  ** Note **
#                  This check type should be avoided unless absolutely
#                  required, and use caution in those cases as a blind
#                  shift can have unforseen consequences, such as taking the
#                  next dashed argument as the value if no value exists.
#               ANY
#                  Any value, meaning no check is performed on the value.
#                  This type is equivalent to not specifying a check type
#                  and therefore unnecessary, but is provided simply for 
#                  user convenience.
#               LIST_SIZE <value>
#                  The number of values allowed for this argument.  By
#                  default, any argument can be a list and therefore have
#                  multiple values.  Using this type allows you to specify
#                  the list size.  The minimum value is 1.  
#               DEFAULT <value> 
#                  A default value.  This applies only to optional
#                  arguments.  If the optional argument is not specified,
#                  it will be set to this value.
#                  It is good programming technique to always include
#                  a DEFAULT setting, which then allows the scripter to
#                  check the variable directly (since it will always be
#                  set to a value if it has a default), thereby avoiding
#                  the scripter having to use "info exists" calls.
#               REQUIRES <list> 
#                  This property specifies the names of other options
#                  that must also be specified along with the option that
#                  this property is assigned to.
#               EXCLUDES <list> 
#                  This property specifies the names of other options that
#                  must not be used when the option that this property is
#                  assigned to is used.
#               VCMD <proc>
#                  Specifies the name of an external procedure to be invoked
#                  in order to validate the value with the corresponding
#                  option.  The specified procedure is appended with one
#                  list element providing the value to be validated.  The
#                  procedure can return either a boolean value or a list
#                  consisting of a boolean value and a reason message,
#                  where any "true", "yes" or any non-zero value indicates
#                  that the value is valid, while "false", "no" or 0 indicates
#                  the value is invalid, and the reason message can be used
#                  to indicate what is wrong with the value.
#               FORMAT <value>
#                  Formats the value provided with an argument according
#                  to the defined format string.  The format string can
#                  take any of the forms accepted by Tcl's format command,
#                  with the following exception: you cannot have a format
#                  string that would require more than one argument to the
#                  format command.  That is, using the * or $ flags or
#                  having more than one % code in the string.  If you
#                  specify more than one FORMAT line, they will be attempted
#                  in order until one is successful.  Surrounding braces
#                  and quotes are removed.
#           - If the parsed value for an argument does not match the check
#             value, an error is thrown.  Note that if the parsed value is
#             a list, then the check is done for each element of the list.
#           - Only one dashed argument may appear on a line, however multiple
#             check types may be used for each argument.  Multiple checks
#             are logically or'ed together.
#
#   -optional_args <opt_arglist>
#       Space separated list of optional arguments, specified as:
#       <argname>[:<altname>][<<check_value>>]  
#       Every element in this list identifies a dashed argument
#       name which may optionally appear in the parse list.  
#       By default, a null list is assumed, meaning there are
#       no optional arguments.
#       Note: The same format breakdown applies here as for the
#       mandatory argument list.
#
#   -return_direct
#       Flag indicating all parsed arguments are to be returned directly
#       back as variables of the same name within the context of the 
#       calling procedure or script.  This is the default.
#
#   -return_array <array-name>
#       If specified, parsed arguments will be returned as indexes within
#       the specified array-name.  The array will be returned back as a
#       single variable within the context of the calling procedure or 
#       script.  This is mutually exclusive of the -return_direct option.
#
#   -passthru
#       Option to pass through or save all "extra" arguments in the
#       parsed list.  Normally, any extra parsed arguments not 
#       found in the mandatory or optional lists would 
#       cause an error to be thrown.  With the -passthru option,
#       these arguments are instead placed into a variable called
#       "passthru_args", which is upleveled back to the callers 
#       context, and no error is generated.  This option may
#       be useful in cases where argument lists are "passed down" between
#       procedures, so strict argument checking at the top level procedure
#       would cause problems, however care should be taken as this option
#       could mask problems by allowing invalid options to go unchecked.
#
#   -no_help
#       Option to turn off the automatic procedure usage help normally 
#       displayed for parse failures.
#
#   -level <context-level>
#       The context level where variables will be placed (via
#       uplevel).  By default, the level is 1 (meaning the 
#       level of the calling procedure or script).  This is
#       provided for internal use, so end users should have no
#       reason to ever change this.
#
#   -exact
#       Flag specifying the use of exact matching of arguments to
#       their corresponding specification, meaning the options must
#       be provided using their exact names.  This is the default
#       in Tcl's non-interactive mode.
#
#   -closest
#       Flag specifying the use of closest matching of arguments to
#       their corresponding specification, meaning the options may
#       be provided using any unique prefix for the actual option
#       name within the specification.  This is the default
#       in Tcl's interactive mode.
#
# Return Values:
#   For success:
#       Each dashed argument in the parse list is placed into the
#       context of the caller as a variable or array index of the same
#       name (without the dash), containing the value from the
#       parse list.  For stand-alone dashed arguments, they
#       are placed as variables with a value of 1.  Note that
#       if the <argname>:<altname> format was used, then the
#       variables or indexes are named accordingly.  
#       In addition, the variables or indexes "mandatory_args",
#       "optional_args", and "passthru_args" are passed back for each
#       of those options, containing a list of the respective arguments.
#   For failure:
#       Throws an error. Note that the caller can invoke parse_dashed_args 
#       using catch cmd to capture the error message and exit gracefully
#       without printing the full error stack trace.
#
# Description:
#   This procedure is intended to provide a single, centralized parsing
#   solution for scripters, thereby removing the repetitive and mundane
#   burden of having parsing code within every script or procedure.
#   It takes a list of dashed arguments, parses them, and returns them
#   as an array or variables within the context of the calling routine
#   or script.
#   The procedure is quite robust, with a slew of features, among them:
#
#   * Predefined type checking:
#        Complex types such as IP addresses or ranges of values can
#        be easily verified via built in type specifications.
#
#   * Custom type checking:
#        Supports "regexp" specification for custom built user check types.
#
#   * Multiple type checking:
#        Check types can be combined, allowing for combinations of values
#        and either/or style logic verification.
#
#   * Mandatory arguments:
#        Ability to require arguments as mandatory.
#
#   * Optional arguments:
#        Ability to specify arguments as optional.
#
#   * Passthrough arguments:
#        Ability to allow unspecified arguments to be "passed through".
#
#   * Default values:
#        Ability to assign a default value to any optional argument.
#
#   * Argument lists:
#        Ability for arguments to contain no value, a single value, or a
#        list of values, and the ability to control the list size.
#
#   * Argument aliasing:
#        Ability for arguments to have alternate names.
#
#   * Argument return type flexibility:
#        Allow for arguments to be returned as individual variables or
#        as an array.
#
# Examples:
#   Example 1:  Using check types
#
#     # Note: Normally the args come from the command line or
#     # the proc call, but they are set here for reference
#     set args "-port eth1/0/0 eth2/0/0 5\
#               -clock internal \
#               -debug \
#               -detail \
#               -framing sdh \
#               -ip 100.1.55.250 1a1b:2:3:4:aa:bb:9a:ffff \
#               -ip4 1.2.3.4 \
#               -ip6 1111:2222:aaaa:bbbb:0:0:1:9999 \
#               -mask 16 255.255.0.0 \
#               -mac 11.22.aa.aa.ff.1f 1234.aabb.1f1f \
#               -slot 1 4 8 \
#               -name dave \
#               -kl {{a 1} {b 2} {c 3}}\
#               -shift1 -foo \
#               -alp abc \
#               -num 100 \
#               -rtr sys_1 \
#               -dec 12.52 \
#               -hex 0xa5 1bf \
#               -type xyz 5 node_1 4.2 whatever
#               "
#     set man_list {-port
#                   -clock CHOICES internal line
#                  }
#     set opt_list {-debug    FLAG
#                   -detail   
#                   -framing  CHOICES sdh sonet atm
#                   -ip       IP
#                   -ip4      IPV4
#                   -ip6      IPV6
#                   -mask     MASK
#                   -mac      MAC
#                   -slot     RANGE 1-8
#                   -name     REGEXP  ^[a-z]+$
#                   -kl       KEYLIST
#                   -shift1   SHIFT
#                   -alp      ALPHA
#                   -num      NUMERIC
#                   -rtr      ALPHANUM
#                   -dec      DECIMAL
#                   -hex      HEX
#                   -type     ANY
#                   -un1      NUMERIC
#                   }
#     parse_dashed_args -args $args -mandatory_args $man_list\
#         -optional_args $opt_list 
#     # At this point, all args that were passed in are now present
#     # as variables of the same name.
#     # All args that were not passed in are not present as variables,
#     # which means they are undefined.  Use of the "info exists"
#     # call would be required for all optional arguments in order to
#     # determine their existance.
#     # If we print the the user args, they would look like this:
#     puts "$port"
#       # Would display "eth1/0/0 eth2/0/0 5"
#       # Notice that port is a list of values.  The parser allows any
#       # argument to be a list by default.
#     puts "$clock"
#       # Would display "internal"
#     puts "$debug"
#       # Would display "1".  Notice that this was defined as a FLAG, so
#       # the parser set the value to 1.
#     puts "$detail"
#       # Would display "1".  Notice that this was not defined as a FLAG,
#       # yet the parser determined this was a flag so set the value to 1.
#       # This is a rather unique property of flag type variables, the
#       # parser can dynamically determine them and set them to a 1 value.
#     puts "$framing"
#       # Would display "sdh"
#     puts "$ip"
#       # Would display "100.1.55.250 1a1b:2:3:4:aa:bb:9a:ffff".  Notice
#       # both ipv4 and ipv6 formats allowed for type IP.
#     puts "$ip4"
#       # Would display "1.2.3.4"
#     puts "$ip6"
#       # Would display "1111:2222:aaaa:bbbb:0:0:1:9999"
#     puts "$mask"
#       # Would display "16 255.255.0.0".  Notice the CIDR and IP masks
#       # both allowed for type MASK.
#     puts "$mac"
#       # Would display "11.22.aa.aa.ff.1f 1234.aabb.1f1f".  Notice both
#       # standard and Cisco formats allowed for type MAC.
#     puts "$slot"
#       # Would display "1 4 8"
#     puts "$name"
#       # Would display "dave"
#     puts "$kl"
#       # Would display "{a 1} {b 2} {c 3}"
#     puts "$shift1"
#       # Would display "-foo".  Notice this was check type SHIFT, so the
#       # leading dash was allowed as a value.  Please avoid the SHIFT
#       # type unless absolutely necessary due to the possible bad
#       # consequences of doing a hard shift.  The check type ANY should
#       # suffice for most strings.
#     puts "$alp"
#       # Would display "abc"
#     puts "$num"
#       # Would display "100"
#     puts "$rtr"
#       # Would display "sys_1"
#     puts "$dec"
#       # Would display "12.52"
#     puts "$hex"
#       # Would display "0xa5 1bf".  Notice values allowed with or without
#       # the leading "0x" for type HEX.
#     puts "$type"
#       # Would display "xyz 5 node_1 4.2 whatever".  
#     # Those are all the user variables, however the parser also returns
#     # the mandatory and optional arguments and values as variables.  They
#     # are always named "mandatory_args" and "optional_args", so be sure
#     # not to have variables of the same name within your script already
#     # or they will be overwritten.
#     puts "$mandatory_args"
#       # Would display "-clock internal"
#     puts "$optional_args"
#       # Would display "-debug -detail -framing sdh
#                        -ip {100.1.55.250 1a1b:2:3:4:aa:bb:9a:ffff}
#                        -ip4 1.2.3.4 -ip6 1111:2222:aaaa:bbbb:0:0:1:9999
#                        -mask {16 255.255.0.0}
#                        -mac {11.22.aa.aa.ff.1f 1234.aabb.1f1f}
#                        -slot {1 4 8} -name dave
#                        -kl {{a 1} {b 2} {c 3}}
#                        -shift1 -foo -alp abc -num 100 -rtr sys_1
#                        -dec 12.52 -hex {0xa5 1bf}
#                        -type {xyz 5 node_1 4.2 whatever}"
#       # Notice that only the variables and values specified by the user are 
#       # contained in the returned optional_args variable, other valid
#       # optional arguments that the user did not specify values for
#       # are not returned, so this is a list of optional arguments that
#       # were actually parsed.
#       # These variables are normally used for passing to subsequent
#       # procedure calls.
#
#
#   Example 2: Using multiple check types, lists, and defaults
#
#     set args {-port_type oc12 \
#               -keepalive off \
#               -hosts rtr1 rtr2 rtr3 \
#               -slot 2 \
#              }
#     set man_list {-port_type   CHOICES oc3 oc12 oc48
#                                CHOICES eth faste gige atm
#                                RANGE 1-5
#                                RANGE 10-20
#                                IP
#                  }
#     set opt_list {-keepalive   DEFAULT 5
#                                CHOICES on off 
#                                RANGE 0-10
#                   -count       CHOICES up down sideways 
#                                NUMERIC
#                                DEFAULT 8
#                   -hosts       ALPHANUM
#                                LIST_SIZE 3
#                   -slot        NUMERIC
#                                LIST_SIZE 1
#                  }
#     parse_dashed_args -args $args -optional_args $opt_list \
#                       -mandatory_args $man_list
#     puts "$port_type"
#       # Would display "oc12".  Notice that many check types were specified
#       # for this field, so the valid values allowed were not only the 
#       # various choices, but also a number from 1-5, a number from 10-20,
#       # or an ip address.  Any of these would have been accepted.  This
#       # shows the power of multiple check types.
#     puts "$keepalive"
#       # Would display "off".  Notice that since a value was specified
#       # in the parsed arguments, the default was not needed.
#     puts "$count"
#       # Would display "8".  Notice that there was no -count in the args 
#       # being parsed, and yet a value was assigned based on the DEFAULT
#       # specification.  A default can only be specified for optional
#       # arguments (since a user must give a value for mandatory args).
#     puts "$hosts"
#       # Would display "rtr1 rtr2 rtr3".  Notice the LIST_SIZE specification,
#       # which means the parser ensures that there are 3 elements for this
#       # option.
#     puts "$slot"
#       # Would display "2".  Notice the LIST_SIZE specification of 1,
#       # which means the parser ensures that this field only contains 1
#       # value (so it is not really a list).  This is the mechanism to
#       # use if you want to override the default parser functionality of
#       # always allowing lists for every option.
#
#
#   Example 3:  Passing back an array
#
#     set args {-port 5 \
#               -ip 1.1.1.1 \
#               -mode t1}
#     set man_list {-port RANGE 1-10}
#     set opt_list {-ip IP
#                   -mode CHOICES t1 e1}
#     parse_dashed_args -args $args -mandatory_args $man_list\
#         -optional_args $opt_list -return_array blob
#     puts "$blob(port)"
#       # Would display "5".  Notice that instead of a variable being
#       # returned, the array "blob" was now used.  The argument becomes
#       # the array index.
#     puts "$blob(ip)"
#       # Would display "1.1.1.1".
#     puts "$blob(mode)"
#       # Would display "t1".
#     puts "$blob(mandatory_args)"
#       # Would display "-port 5".
#     puts "$blob(optional_args)"
#       # Would display "-ip 1.1.1.1 -mode t1".
#
#
#   Example 4:  Dynamic choices
#
#     set args {-port 5 \
#               -mode t1}
#     set choice_list "t1 e1 atm fr qos"
#     set man_list {-port RANGE 1-10}
#     set opt_list "-ip IP
#                   -mode CHOICES $choice_list
#                         CHOICES eth gige
#                  "
#     # Notice the opt_list above was specified with double quotes, not braces.
#     # This allows TCL to expand any variables in the string, which in this
#     # example will expand the $choice_list to their values.
#     parse_dashed_args -args $args -mandatory_args $man_list\
#         -optional_args $opt_list
#     puts "$port"
#       # Would display "5".
#     puts "$ip"
#       # Would display "1.1.1.1".
#     puts "$mode"
#       # Would display "t1".  
#
#
#   Example 5:  Passing arguments through
#
#     # Be careful when using -passthru option as it could mask
#     # user input errors.
#     set args {-port 5 \
#               -framing sdh \
#               -ip 1.1.1.1 \
#               -mode t1}
#     set man_list {-port RANGE 1-10}
#     set opt_list {-ip IP}
#     parse_dashed_args -args $args -mandatory_args $man_list\
#         -optional_args $opt_list -passthru
#     puts "$port"
#       # Would display "5".
#     puts "$ip"
#       # Would display "1.1.1.1".
#     puts "$mandatory_args"
#       # Would display "-port 5".
#     puts "$optional_args"
#       # Would display "-ip 1.1.1.1"
#     puts "$passthru_args"
#       # Would display "-framing sdh -mode t1".  The passthru_args variable
#       # is only returned when the -passthru option is specified on the
#       # parser call.  A word of caution, by allowing arguments to be
#       # "passed through", the normal error checking for these unknown
#       # arguments is disabled, which means anything can slip through,
#       # including valid options that are mistyped.  The intention of
#       # passthru is that the passthru_args variable would be passed down
#       # to a subsequent procedure, which could then do another round of
#       # parsing.
#
#
#   Example 6:  Error conditions
#
#     set man_list {-port RANGE 1-10}
#     set opt_list {-ip IP}
#
#     parse_dashed_args -args {-ip 1.1.1.1} \
#         -mandatory_args $man_list -optional_args $opt_list
#       # Would generate error that mandatory -port argument is missing
#
#     parse_dashed_args -args {-slot 1 -port 5} \
#         -mandatory_args $man_list -optional_args $opt_list
#       # Would generate error that -slot argument is not allowed,
#       # since it is not in mandatory or optional list
#
#     parse_dashed_args -args {-port 25} \
#         -mandatory_args $man_list -optional_args $opt_list
#       # Would generate error that port value 25 is out of range
#
#     parse_dashed_args -args {-ip 1.2.3 -port 1} \
#         -mandatory_args $man_list -optional_args $opt_list
#       # Would generate error that ip value 1.2.3 is invalid
#
#     check_info -badarg 5
#     procDescr check_info {
#        Usage:
#           check_info -slot <number>      
#     }
#     proc check_info {args} {
#        set man_list {-slot NUMERIC}    
#        parse_dashed_args -args $args -mandatory_args $man_list
#         # This shows the parser being called from within a procedure.
#         # The arguments passed into the procedure call were in error,
#         # (-badarg was used instead of -slot), so the parser would
#         # generate the appropriate error.
#         # In addition, since this call is being made from within a proc,
#         # and the procedure has a procDescr with a Usage section defined,
#         # then a procedure usage message would also be generated.
#         # This is done dynamically via the "cisco_help" utility.
#     }
#
#   Example 7:  Exiting gracefully under error conditions
#
#     set man_list {-port RANGE 1-10}
#     set opt_list {-ip IP}
#
#     if  {[catch {parse_dashed_args -args {-ip 1.1.1.1} \
#                                    -mandatory_args $man_list \
#                                    -optional_args $opt_list} err_msg]} {
#         puts stderr $err_msg
#         exit 1
#     } ;# End of if stmt
#     # The catch cmd would return a non-zero status.
#     # Would generate error that mandatory -port argument is missing.
#     # This error message will be available in $err_msg variable.
#     # The $err_msg will be printed to stderr without the error stack.
#     # The exit cmd will gracefully terminate the script.
#
#   Example 8: Exact vs. closest argument matching
#
#     set man_list {-port RANGE 1-10}
#     set opt_list {-address1 IP -address2 IP -foo ANY -foo1 ANY}
#
#     parse_dashed_args -exact -args {-address1 1.2.3.4 -p 1} \
#         -mandatory_args $man_list -optional_args $opt_list
#       # Would generate error indicating that the -p argument is not found
#       # in the mandatory or optional argument list.
#
#     parse_dashed_args -closest -args {-address1 1.2.3.4 -p 1} \
#         -mandatory_args $man_list -optional_args $opt_list
#       # Would accept the -p argument as equivalent to -port.
#
#     parse_dashed_args -closest -args {-address 1.2.3.4 -p 1} \
#         -mandatory_args $man_list -optional_args $opt_list
#       # Would generate error indicating that -address is ambiguous.
#
#     parse_dashed_args -closest -args {-foo bar} \
#         -mandatory_args $man_list -optional_args $opt_list
#       # Would accept -foo as being an exact, unambiguous match
#
#   Example 9: Using VCMD to verify that a value is an integer
#
#       proc isInteger { value } {
#           if {[string is integer $value]} {
#               return 1
#           } else {
#               return [list 0 "specified value is not an integer"]
#           }
#       }
#       
#       parse_dashed_args -args [list -isinteger notAnInteger] \
#           -mandatory_args {
#              -isinteger VCMD isInteger
#           }
#
#   Example 10: Optional arguments requiring and excluding other optional args
#
#       parse_dashed_args -args $args \
#           -optional_args {
#               -option1    ANY
#                           REQUIRES -option2 -option3
#               -option2    ANY
#                           EXCLUDES -option4
#               -option3    ANY
#               -option3    ANY
#           }
#       # If -option1 is given, -option2 and -option3 must also be given.
#       # If -option2 is given, -option4 must not be given.
#
#   Example 11: Using FLAG type switches with and without values
#
#       set args {
#           -flag2
#           -flag3 0
#           -flag4 true
#           -flag5 false
#       }
#
#       parse_dashed_args -args $args \
#           -optional_args {
#               -flag0      FLAG
#               -flag1      FLAG
#                           DEFAULT 0
#               -flag2      FLAG
#               -flag3      FLAG
#               -flag4      FLAG
#               -flag5      FLAG
#                           DEFAULT 0
#           } -return_direct
#
#     puts "$flag0"
#       # Would generate an error, because without a DEFAULT value
#       # unspecified flags' associated variables are not set.
#     puts "$flag1"
#       # Would display "0" from the DEFAULT.
#     puts "$flag2"
#       # Would display "1".
#     puts "$flag3"
#       # Would generate an error, because without a DEFAULT value
#       # associated variables are not set for false values.
#     puts "$flag4"
#       # Would display "1" because boolean values are converted to 0/1.
#     puts "$flag5"
#       # Would display "0".
#     puts "$optional_args"
#       # Would display "-flag2 -flag4 -flag5 0" because only "true"
#       # flags and "false" flags with DEFAULT values are treated as
#       # having been specified, and only flags (true or false) with
#       # DEFAULT values are treated as having specified a value.
#
#   Example 12:  Formatting a floating point value with 2 levels of precision
#
#   parse_dashed_args -args {-float 1} \
#       -mandatory_args {
#           -float  FORMAT %0.2f
#                   DECIMAL
#       }
#
#   Example 13:  Formatting a string to be right-justified in 10 spaces
#
#   parse_dashed_args -args {-string foo} \
#       -mandatory_args {
#           -string ANY
#                   FORMAT %10s
#       }
#
#   Example 11:  The following FORMAT strings in this example are ILLEGAL
#
#   parse_dashed_args -args $args \
#       -mandatory_args {
#           -badformat1 ANY
#                       FORMAT %*s
#           -badformat2 ANY
#                       FORMAT %s%s
#           -badformat3 ANY
#                       FORMAT %2$d
#       }
#
# Notes:
#   Creation Date: October 19, 2001        
#   Author: Wayne Marquette/Dave Cardosi
# End of Header

proc pda::parse_dashed_args {args} {
    variable _re
    variable pda_flag_arg

    set procName [namespace tail [lindex [info level 0] 0]]

    set num_args [llength $args]
    if {$num_args < 1} {
        return -code error "$procName: Called with no arguments."
    }

    # Track parse_dashed_args library usage via itramp
    #::pats::post_cmd_data {Parse_dashed_args Library} \
    #                      "version=[package provide parse_dashed_args]"

    # Initialize vars
    # -----------------------
    set mandatory_flag 0
    set optional_flag 0
    set proc_flag 0
    set mandatory_arg_count 0
    set optional_list ""
    set mandatory_list ""
    set mandatory_arg_count_actual 0
    set process_args ""
    set level 1
    set passthru 0
    set no_help 0
    set return_direct 1
    set use_closest_match $::tcl_interactive
    set switch_list [list]
    set switches_provided [list]
    set switch_pairings [list]
    set mandatory_provided [list]   ;# list of mandatory switches provided
    set optional_provided [list]    ;# list of optional switches provided
    set optional_args [list]        ;# list of optional args/values provided
    set mandatory_args [list]       ;# list of mandatory args/values provided
    set passthru_args [list]        ;# list of unknown args/values provided

    set stacklevel [info level] ;# gives the current level of stack
    if {$stacklevel > 1} {
        set calling_proc_name [lindex [info level -1 ] 0]
    } else {
        set calling_proc_name ""
    }

    for { set i 0 } { $i < $num_args } { incr i } {
        set arg [lindex $args $i]
        switch -- $arg {
            -args {
                incr i
                if {$i >= $num_args} {
                    return -code error \
                        "wrong # args: should be \"-args list\""
                }
                set process_args [lindex $args $i]
            }
            -exact {
                set use_closest_match 0
            }
            -closest {
                set use_closest_match 1
            }
            -mandatory_args {
                incr i
                if {$i >= $num_args} {
                    return -code error \
                        "wrong # args: should be \"-mandatory_args spec\""
                }
                set mandatory_list [lindex $args $i]
            }
            -optional_args {
                incr i
                if {$i >= $num_args} {
                    return -code error \
                        "wrong # args: should be \"-optional_args spec\""
                }
                set optional_list [lindex $args $i]
            }
            -proc_name {
                # legacy option
                incr i
                if {$i >= $num_args} {
                    return -code error \
                        "wrong # args: should be \"-proc_name name\""
                }
                set calling_proc_name [lindex $args $i]
            }
            -level {
                incr i
                if {$i >= $num_args} {
                    return -code error \
                        "wrong # args: should be \"-level num\""
                }
                set level [lindex $args $i]
            }
            -no_help {
                set calling_proc_name ""
            }
            -passthru {
                set passthru 1
            }
            -return_direct {
                set return_direct 1
            }
            -return_array {
                incr i
                if {$i >= $num_args} {
                    return -code error \
                        "wrong # args: should be \"-return_array arrayname\""
                }
                set arr_name [lindex $args $i]
                set return_direct 0
            }
            default {
                return -code error "$procName: Invalid arg \"$arg\""
            }
        }
    }

    # Adjust level so that it is absolute, if it wasn't already specified
    # to be such.  This way the right level should be used no matter where
    # in deeper stack levels for pda functions uplevels are called.

    if {[string is integer -strict $level]} {
        set level [format "#%i" [expr {[info level] - $level}]]
    }

    # Parse all mandatory args
    ::pda::_parse_check_args $procName mandatory $mandatory_list

    # Parse all optional args
    ::pda::_parse_check_args $procName optional $optional_list

    # Uplevel any default values

    foreach { varname def_value } [array get default_value] {
        # Change variable name in case of alternate name
        if {[info exists var_array($varname)]} {
            set varname $var_array($varname)
        }
        if {$return_direct} {
            uplevel $level [list set $varname $def_value]
        } else {
            uplevel $level [list array set $arr_name [list $varname $def_value]]
        }
    }

    set switch_list [array names check_array]

    # From this point on, we want any error message to look like it
    # came from the calling proc if the user supplied one.  We will
    # prepend the calling proc name and append the calling proc usage.

    # Parse arguments from procs or from command line 
    # and check for valid args
    # ------------------------------------------------
    set num_args [llength $process_args]
    # Loop through arguments for parsing
    for { set i 0 } { $i < $num_args } { incr i } {
        set keylist_flag 0

        # Grab next argument, which should be a switch

        set arg [::pda::_get_switch $calling_proc_name $process_args $i \
                    $switch_list $use_closest_match]

        if {![info exists check_array($arg)]} {
            set check_array($arg) ""
        }

        # Reset state information from previous argument

        unset -nocomplain value check_type check_val

        # Add this argument to the list of "have been provided" arguments
        # for later checking of required/excluded option pairs.

        lappend switches_provided $arg

        # Grab any value arguments associated with this dashed arg

        set value_count 0
        while {$i < [expr {$num_args - 1}]} {
            set next_arg [lindex $process_args [expr {$i + 1}]]
 
            # If the type is a shift, blindly grab the next argument since
            # a shift string can contain anything (including a leading dash)

            if {[::pda::_is_shift $check_array($arg)]} {
                set value $next_arg
                incr i
                # Unset string check type since so we don't go through the
                # check code, which would have problems with complex strings,
                # and there's nothing to check anyway, we already know it's
                # a string
                set check_array($arg) ""
                break
            }

            # Check if next argument is dashed.  If so, it can't be a value
            # for the current dashed argument, since it isn't a SHIFT type.

            if {[string index $next_arg 0] eq "-"} {
                # The next argument can be dashed if it is the first value
                # after a dashed argument, unless it is of type FLAG
                if {$value_count} {
                    break
                }
                # If the current argument is of type FLAG, the next
                # argument can be a dashed argument.
                if {[::pda::_is_flag $check_array($arg)]} {
                    break
                }
                # If the current argument is one of the pda arguments
                # which is of type FLAG, the next argument can be a
                # dashed argument
                if {[info exists pda_flag_arg($arg)]} {
                    break
                }
                # If the next dashed argument is in the $check_array()
                # we treat it as a valid pda argument and break here
                # Limitation of this assumption: users cannot pass a dashed 
                # argument as a value to an option, if it is also a valid option.
                # For ex:  -debug -loglevels "-debug -warn" is not valid 
                #               when -debug is also an accepted FLAG option
                if {[info exists check_array([string range $next_arg 1 end])]} {
                    break
                }
            }

	    # Next argument is a value for this argument.  For single
	    # value, just set it, but for multiple values (meaning a
	    # list) use lappend to keep it a list.  The "single value"
	    # can an itself be a list.

            switch -- $value_count {
                0 {
                    set value $next_arg
                }
                1 {
                    set value [list $value $next_arg]
                }
                default {
                    lappend value $next_arg
                }
            }

            incr value_count
            incr i
        } ;# end of value grabbing while loop

        # Change the value to use the varname instead of switch name for
        # alternate named arguments
        if {[info exists var_array($arg)]} {
            set var_switch $arg
            set var_name $var_array($arg)
        } else {
            set var_name $arg
        }
                
        # Check for valid value against any user specified check value
        if {$check_array($arg) ne ""} {
            # Make sure we have a value to check
            if {![info exists value]} {
                # There's no value, so unless it's a flag type, error out
                if {![::pda::_is_flag $check_array($arg)]} {
                    # Null value for non-flag type, throw error

                    set valid_string \
                        [::pda::_format_valid_string $calling_proc_name \
                            $level "" "" $arg $check_array($arg) 0]
                    return -code error [::pda::_build_parse_error \
                            $calling_proc_name \
                               "Invalid null value for \"-$arg\"\
                                argument.\nValid values are: $valid_string"]
                } else {
                    # Check if exclude or require is provide if so form a pair
                    foreach { check_flag check_flag_val } $check_array($arg) {
                      switch -- $check_flag {
                          "requires" -
                          "excludes" {
                              foreach check_flag_val $check_flag_val {
                                  lappend switch_pairings $arg \
                                      $check_flag $check_flag_val
                              }
                              set check_flag_val ""
                              continue
                          }
                      }
                    }
                    # Null value for flag type, we're done, set to not loop
                    set loop_value ""
                }
            } else {
                # Setup for checking values.  For lists, need to loop through
                # each value.  Also setup string for error message based on
                # value type (list or single value).
                # Note: The llength command can fail on complicated strings,
                # so first see if we can use llength to determine length.
                if {[catch { llength $value }]} {
                    # The llength operation has failed, which most
                    # likely means the value is a complicated string.
                    # For example, the string: "blah". blah blah 
                    # has something in quotes followed by a dot
                    # followed by other things, which llength would 
                    # blow up on as an invalid list (because
                    # llength sucks).  Anyways, since llength can't 
                    # handle it, that proves whatever it is is not
                    # a valid list, so treat it as a single value.

                    set loop_value [list $value]
                    set value_type "value"
                } elseif {[llength $value] >= 2} {
                    # Value is a list, so loop on value will cycle thru list
                    # and every list value will be checked.
                    set loop_value $value
                    set value_type "list element"
                } elseif {[llength [lindex $value 0]] >= 2} {
                    # Value is a list passed in as single element, so set
                    # to loop on "inside" list to check every list element.
                    # Note: This only works for single inside list, it is
                    # not recursive for multi-lists of lists.  Doubtful
                    # anyone would ever need that anyway (even this is 
                    # rare case).
                    set loop_value [lindex $value 0]
                    set value_type "list element"
                } else {
                    # Value is single value, so will just loop once
                    set loop_value $value
                    set value_type "value"
                }

                # Check for too many values if list size exists
                # Note: Only one LIST_SIZE is allowed, if more are specified
                # then only the first one will be used.
                foreach { check_type check_val } $check_array($arg) {
                    if {$check_type eq "LIST_SIZE"} {
                        if {[llength $value] != $check_val} {
                            return -code error [::pda::_build_parse_error \
                                $calling_proc_name \
                                "Incorrect number of values specified for\
                                \"-$arg\"\ argument.\nThe required list\
                                size is $check_val, yet [llength $value]\
                                values were given: \"$value\""]
                        }

                        break
                    }
                } ;# end of list size check
            } ;# end of value else

            # Loop through all the values and see if they match at least
            # one user specification for that field
            set check_errors  0
            foreach element $loop_value {
                foreach { check_type check_val } $check_array($arg) {
                    # Build out regular expression for known types
                    switch -- $check_type {
                        "IPV4" {
                            # V4 IP only
                            set check_val $_re(IPV4)
                        }
                        "IPV6" {
                            # V6 IP only
                            set check_val $_re(IPV6)
                        }
                        "IP" {
                            # Any IP (v4 or v6)
                            set check_val $_re(IP)
                        }
                        "MAC" {
                            set check_val $_re(MAC)
                        }
                        "RANGE" {
                            set low_val [lindex $check_val 0]
                            set high_val [lindex $check_val 1]
                            set check_type "RANGE"
                        }
                        "CHOICES" {
                            # Put in anchoring around choices
                            regsub -- {^} $check_val {^(} check_val
                            regsub -- {$} $check_val {)$} check_val
                        }
                        "KEYLIST" {
                            # We don't want to check anything for a keyed
                            # list so just null out the check and set flag
                            set check_val ""
                            set keylist_flag 1
                        }
                        "FLAG" {
                        }
                        "DECIMAL" {
                            # A decimal value
                            set check_val $_re(DECIMAL)
                        }
                        "HEX" {
                            # A hex value, with optional leading 0x
                            set check_val $_re(HEX)
                        }
                        "NUMERIC" {
                            # A numeric only value
                            set check_val $_re(NUMERIC)
                        }
                        "ALPHA" {
                            # An alphabetic only value
                            set check_val $_re(ALPHA)
                        }
                        "ALPHANUM" {
                            # An alphanumeric value
                            set check_val $_re(ALPHANUM)
                        }
                        "REGEXP" {
                        }
                        "LIST_SIZE" {
                            continue
                        }
                        "requires" -
                        "excludes" {
                            # These directives are ignored until later,
                            # after all arguments have been processed.
                            # But we'll set a flag indicating this
                            # processing needs to be done to avoid the
                            # overhead of re-processing this check info
                            # when these are not in use.

                            foreach check_val $check_val {
                                lappend switch_pairings $arg \
                                    $check_type $check_val
                            }
                            set check_val ""
                            continue
                        }
                        "FORMAT" {
                            # Collect format string for later processing
                            lappend arg_format $check_val
                            continue
                        }
                        "VCMD" {
                        }
                        default {
                            return -code error [::pda::_build_parse_error \
                                       $calling_proc_name \
                                       "Invalid check value\
                                        specification: Check type\
                                        \"$check_val\" is unknown."]
                        }
                    } ;# end of switch
                    
                    # Check if value matches user specified check criteria
                    # Check individual element
                    if {$check_type == "RANGE"} {
                        # Add decimal point to range values so large
                        # numbers can be handled.
                        # Without decimal, highest number handled is
                        # 2147483647 (just in case you wondered)
                        set low_val $low_val.0
                        set high_val $high_val.0
                        if {![regexp -- {\.} $element]} {
                            # Add decimal to user value
                            set temp_element $element.0
                        } else {
                            # User value already has decimal
                            set temp_element $element
                        }
                        if {($temp_element < $low_val) || \
                                ($temp_element > $high_val)} {
                            incr check_errors
                        } else {
                            set check_errors 0
                            break
                        }
                    } elseif {$check_type == "FLAG"} {
                        # A flag type should have either no value or
                        # any boolean value (e.g. 0, 1, true, false, yes, no)
                        # It does not allow more than one value to be
                        # provided.

                        if {[info exists value] && \
                                ![string is boolean $value]} {
                            incr check_errors
                        } else {
                            set check_errors 0
                            break
                        }
                    } elseif {$check_type == "VCMD"} {
                        # Use the defined command to validate the value.

                        if {[catch { set vcmd_out [uplevel $level \
                                [list $check_val $element]] } \
                                vcmd_msg]} {

                            return -code error [::pda::_build_parse_error \
                                $calling_proc_name $vcmd_msg]
                        }

                        # If the first element is false, then it is invalid.

                        if {![lindex $vcmd_out 0]} {
                            incr check_errors
                        } else {
                            set check_errors 0
                            break
                        }
                    } else {
                        if {![regexp -- "$check_val" $element]} {
                            incr check_errors
                        } else {
                            set check_errors 0
                            break
                        }
                    }
                } ;# end of check type loop

                # Return error if element failed all check type validations

                if {$check_errors} {
                    return -code error \
                        [::pda::_format_valid_string $calling_proc_name \
                            $level $value_type $element \
                            $arg $check_array($arg) 1]
                }
            } ;# end of element check loop
        } ;# end of check array if

        if {[info exists check_type] && ($check_type == "FLAG")} {
	    # When the FLAG has no associated DEFAULT value, we want to
	    # treat "false" values as having not been specified at all
	    # and "true" values as having been specified only with the
	    # switch (no value), for backwards-compatibility.
	    # [CSCeh94732]
            if {[info exists value] && \
                        ![string is boolean -strict $value]} {
                return -code error \
                    [::pda::_format_valid_string $calling_proc_name \
                      $level "value" $value $arg "FLAG {}" 1] 
            }
            if {![info exist default_value($arg)]} {
                if {!$value} {
                    continue
                }

                unset value
            } elseif {[info exists value]} {
                # Convert yes/no/true/false to 1/0, if specified
                set value [expr {1 && $value}]
            }
        }

        # Format the values according to FORMAT specifications, if any

        if {[info exist arg_format] && [info exist value]} {
            set value [::pda::_apply_format $value $value_type $arg_format]
            unset arg_format
        }

        # Check if arg is mandatory
        # --------------------- --------------------------------
        if {[info exists mandatory_array($arg)]} {
            # Check for duplicate mandatory args being passed
            if {[lsearch -exact $mandatory_provided $arg] >= 0} {
                return -code error "$procName:\
                Duplicate argument found.  The mandatory argument\
                \"$arg\" was specified twice."
            }

            # Keep track of mandatory arguments that have been provided

            incr mandatory_arg_count_actual
            lappend mandatory_provided $arg

            # Append mandatory args to variable for later upleveling

            if {[info exists value]} {
                lappend mandatory_args "-$arg" $value
            } else {
                lappend mandatory_args "-$arg"
            }
        } elseif {![info exists optional_array($arg)]} {
            # Not mandatory or optional, check for pass thru
            if {$passthru} {
                # Append pass through args to variable for later upleveling
                lappend passthru_args "-$arg"

                #Flags that are not provided any value by the user, will 
                #consider the next argument as the value and the value count 
                #will be greater than 1, in that case just append the to
                #passthru args instead of lappend(CSCtx01021)

                if {[info exists value]} {
		    if {[info exists value_count] && ($value_count > 1)} {
			append passthru_args " $value"
                    } else {
			lappend passthru_args $value
                    }
                }
                # Parse next arg
                continue
            } else {
                return -code error [::pda::_build_parse_error \
                      $calling_proc_name "Argument\
                      \"-$arg\" not found in mandatory or optional argument\
                       list."]
            }
        } else {
            # Check for duplicate optional args being passed
            if {[lsearch -exact $optional_provided $arg] >= 0} {
                return -code error "$procName:\
                Duplicate argument found.  The optional argument\
                \"$arg\" was specified twice."
            }

            # Keep track of optional arguments that have been provided

            lappend optional_provided $arg

            # Append optional args to variable for later upleveling

            if {[info exists value]} {
                lappend optional_args "-$arg" $value
            } else {
                lappend optional_args "-$arg"
            }
        }

        # Uplevel flag switches with value of 1
        if {![info exists value]} {
            set value 1
        }

        if {$return_direct} {
            uplevel $level [list set $var_name $value]
        } else {
            uplevel $level [list array set $arr_name [list $var_name $value]]
        }
    } ;# end of parse argument loop

    # Check mandatory arg count matches required count
    # -------------------------------------------------------------
    if {$mandatory_arg_count && \
       ($mandatory_arg_count_actual != $mandatory_arg_count)} {
        return -code error [::pda::_build_parse_error $calling_proc_name \
              "Missing mandatory arguments\n\
              Expected: $mandatory_string\nActual:\
              [join $mandatory_provided]"]
    }

    # Check for required/excluded argument pairings, if indicated in
    # the option specification.

    ::pda::_check_pairs $calling_proc_name $switches_provided \
        $switch_pairings $switch_list [array names mandatory_array]

    # Return the complete grouped sets of mandatory, optional and passthru
    # arguments to the calling scope.

    if {$return_direct} {
        # Return optional_args, mandatory and passthru_args as
        # individual variables in the calling scope.

        uplevel $level [list set optional_args $optional_args]
        uplevel $level [list set mandatory_args $mandatory_args]

        if {$passthru} {
            uplevel $level [list set passthru_args $passthru_args]
        }
    } else {
        # Return optional_args, mandatory and passthru_args as
        # return_array array elements in the calling scope.

        lappend array_data "optional_args"  $optional_args
        lappend array_data "mandatory_args" $mandatory_args

        if {$passthru} {
            lappend array_data "passthru_args" $passthru_args
        }

        uplevel $level [list array set $arr_name $array_data]
    }
}


proc pda::_apply_format { value_list value_type arg_format_list } {
    # Format all of the values provided.  Try each FORMAT
    # specification until one is successful.

    if {$value_type eq "list element"} {
        set new_value ""

        foreach value $value_list {
            foreach arg_format $arg_format_list {
                if {![catch { set value [format $arg_format $value] }]} {
                    break
                }
            }

            lappend new_value $value
        }

        set value $new_value
    } else {
        set value $value_list

        foreach arg_format $arg_format_list {
            if {![catch { set value [format $arg_format $value] }]} {
                break
            }
        }
    }

    return $value
}

##Internal Procedure Header
#
# Name:
#   _format_valid_string
#
# Synopsis:
#   _format_valid_string <procname> <level> <value_type> <element> \
#   <arg> <check_list> <for_error>
#
# Arguments:
#   <procname>      = Name of procedure for error messages
#   <level>         = Level in which parse_dashed_args was invoked
#   <value_type>    = The string "value" or "list element"
#   <element>       = A value which, if <for_error> is true, is invalid
#   <arg>           = The switch name
#   <check_list>    = The list of validation rules for the named switch
#   <for_error>     = Flag indicating whether the result should be
#                     formatted for return directly as an error.
#                     This basically tells it to use _build_parse_error
#                     and re-invoke VCMD procedures to further format
#                     the result for return directly as an error.
#
# Return Values:
#   Returns the formatted string for error messages
#
# Description:
#   This function formats a string that's either a complete error message
#   (if <for_error> is true) or just a string with a textual description
#   of allowed values, given details about the value being checked and
#   the validation rules for the switch.  The latter form is used in the
#   special case that no value was given but one was required.
#
#   If the validation rules include VCMDs, and <for_error> is true, then
#   it's a given that validation failed the VCMD check(s).  It will
#   re-invoke them in order to obtain the error message provided in their
#   results (if any) to include in the error message.
#
# End of Header

proc pda::_format_valid_string { procName level value_type element arg \
    check_list for_error } {

    set valid_list  ""  ;# List of textual descriptions of rules
    set vcmds       ""  ;# List of VCMD procedures to be invoked

    # Cycle through each of the validation rules to build a list of
    # textual descriptions for all of the rules that apply.

    foreach { check_type check_data } $check_list {
        switch -- $check_type {
            IP {
                lappend valid_list "An IP address (v4 or v6)"
            }
            IPV4 {
                lappend valid_list "A v4 format IP address (of form #.#.#.#)"
            }
            IPV6 {
                lappend valid_list \
                    "A v6 format IP address (of form #:#:#:#:#:#:#:#)"
            }
            MAC {
                lappend valid_list "MAC address"
            }
            ALPHANUM {
                lappend valid_list \
                    "An alphanumeric value (letters, numbers, or underbars)"
            }
            ALPHA {
                lappend valid_list \
                    "An alphabetic only value"
            }
            FLAG {
                lappend valid_list "0|1|true|false|yes|no"
            }
            NUMERIC {
                lappend valid_list "A numeric only value"
            }
            DECIMAL {
                lappend valid_list \
                    "A decimal value (a number which may contain\
                     a decimal point)"
            }
            HEX {
                lappend valid_list \
                    "A hexadecimal value (with optional leading \"0x\")"
            }
            KEYLIST {
                lappend valid_list "Keyed list"
            }
            CHOICES {
                lappend valid_list $check_data
            }
            REGEXP {
                lappend valid_list \
                    "A value conforming to the regular expression: $check_data"
            }
            RANGE {
                set min [lindex $check_data 0]
                set max [lindex $check_data 1]
                lappend valid_list "Number between $min and $max"
            }
            LIST_SIZE {
                lappend valid_list "List size must be $check_data"
            }
            VCMD {
                # Since VCMDs can return any message, they won't necessarily
                # be worded to say what is required, but rather may say
                # why a given value is not valid.  So they will only be
                # re-invoked to get the message if formatting the result
                # for returning an error indicating a value is invalid.

                lappend vcmds $check_data
            }
        }
    }

    # Do further formatting of the message if it is to be returned as an
    # error indicating a provided value was invalid for all rules.

    if {$for_error} {
        set temp ""

        # Format each rule's textual description with additional verbiage.
        # Note: printing the "Invalid ... Valid values are:" bit for every
        # one is redundant, but the behavior has been preserved from
        # earlier revisions to minimize differences in error messages
        # from prior to this function's implementation.

        foreach err $valid_list {
            lappend temp [::pda::_build_parse_error $procName \
                "Invalid $value_type \"$element\" for \"-$arg\"\
                argument.\nValid values are: \"$err\""]
        }

        # Call the validation commands to include error messages
        # if any are provided.

        foreach vcmd $vcmds {
            set vcmd_out ""
            catch { set vcmd_out [uplevel $level [list $vcmd $element]] }

            # Include message if either there is none already or it
            # the command provided details for the message.  There's
            # no point in repeating the string multiple times in the
            # message when there's no further detail for each, or it's
            # already there for each of the valid_list-based messages.

            if {([llength $vcmd_out] > 1) || ![llength $temp]} {
                set message [::pda::_build_parse_error $procName \
                    "Invalid $value_type \"$element\" for \"-$arg\" argument"]

                # Add the details provided by the command, if any

                if {[llength $vcmd_out] > 1} {
                    append message ": [lindex $vcmd_out end]"
                }
            }

            lappend temp $message
        }

        set valid_list $temp
    }

    # Safeguard against being called with an empty check_list.  This
    # should never happen, but might due to rules being added elsewhere
    # but not here.

    if {![llength $valid_list]} {
        return -code error [::pda::_build_parse_error $procName \
            "internal error: no validation rules to format"]
    }

    return [join $valid_list "\n"]
}

##i
# Utility function returns 1 if the arg specification indicates
# the argument is a SHIFT type, 0 otherwise.

proc pda::_is_shift { check_list } {
    foreach { check_type check_val } $check_list {
        if {$check_type eq "SHIFT"} {
            return 1
        }
    }

    return 0
}

##i
# Utility function returns 1 if the arg specification indicates
# the argument is a FLAG type, 0 otherwise.

proc pda::_is_flag { check_list } {
    foreach { check_type check_val } $check_list {
        if {$check_type eq "FLAG"} {
            return 1
        }
    }

    return 0
}

##Internal Procedure Header
#
# Name:
#   _parse_check_args
#
# Purpose:
#
# Synopsis:
#   _parse_check_args <procname> <argtype> <arglist>
#
# Arguments:
#   <procname>  = name of procedure for error messages
#   <argtype>   = optional|mandatory
#   <arglist>   = list of argument specifications
#
# Return Values:
#   The following variables are set in the caller:
#
#     <argtype>_arg_count   = Number of <argtype> switch arguments found
#     <argtype>_string      = A space-delimited string of switch names
#     default_value         = Array of default values keyed by switch
#     check_array           = Array of validation rules keyed by switch.
#                             each rule consists of a keyword (such as
#                             REGEXP) followed by details for that rule
#                             (such as the regular expression).
#     <argtype>_array       = An array whose keys are switch and variable
#                             names.  All entries have the value 1.
#     var_array             = Array of switch-to-variable name mappings
#
# Description:
#   Internal procedure to parse the mandatory or optional argument
#   specifications.  Specification is either in "line" or "block"
#   format.  Line format should always be used, however legacy code
#   still uses the older block format, therefore we must support it.
#   Documentation on block format has been removed from the main
#   procedure usage so users are no longer aware of it.  For posterity,
#   it has been placed here for reference. 
#
#   Legacy Block Format Documentation:
#     Block format is as follows:
#       <argname>[:<varname>][<<check_value>>]
#       Breakdown:
#         - The <argname> is the name of the dashed argument 
#           (with or without the dash).  It is required.
#         - The colon separated <varname> is optional.  If specified,
#           then it will be used as the variable name upleveled to the
#           callers context, instead of the argname.  In most cases
#           this should be avoided if possible.
#         - The <<check_value>> is an optional regular expression 
#           used to check against the parsed value.  If specified, it
#           must be enclosed in angle brackets <>.  If the parsed 
#           value for an argument does not match the check value 
#           regular expression, an error is thrown.  Note that
#           if the parsed value is a list, then the check is done
#           for each element of the list.
#           In addition to a regular expression check, a set of
#           customized check values are available, which are essentially
#           shorthand types for complicated regular expressions.
#           These are specified by a leading dash "-" on the check_value,
#           and are as follows:
#             -IP
#                An IP address, either v4 (dotted decimal notation) or
#                v6 (colon hexadecimal notation).
#             -MAC
#                A MAC address, in standard or Cisco format.
#             -RANGE:<low_value>-<high_value>
#                A numeric range, between low_value and high_value.
#             -CHOICES:<choice1>|<choice2>|<choice3>... 
#                A list of choice values logically or'ed together.
#             -KEYLIST 
#                A TCL keyed list.
#             -STRING
#                An alphanumeric string.
#             -NUMERIC
#                A numeric only value.
#             -FLAG
#                A flag argument, meaning this argument does not have
#                any value and is a stand-alone argument.
# End of Header

proc pda::_parse_check_args { procName argtype arglist} {
    variable _re

    # Hardcode proc name to match parser
    set arg_count 0
    set defaults {}
    set check_list {}
    set argtype_list {}
    set switch_map {}

    # Strip away any leading or trailing whitespace in arglist

    set arglist [string trim $arglist]

    # Do nothing if there is no argument specification to parse

    if {$arglist == ""} {
        return
    }

    # Replace any tabs with spaces, as tabs would be interpreted as arguments
    regsub -all -- "\t" $arglist " " arglist

    # Determine if line (new) or block (old) format.
    # If newline present then must be new format, however also
    # need to cover case for single line new format so do that by 
    # looking for all caps type after argument
    if {[regexp -- {\n} $arglist] || [regexp -- {^-[^ ]+ +[A-Z]} $arglist]} {
        set arg_specs [::pda::_parse_line_format $arglist]
    } else {
        set arg_specs [::pda::_parse_block_format $arglist]
    }

    foreach { var_switch spec } $arg_specs {
        regsub -- {^-} $var_switch {} var_switch
        # Found a switch, increment switch count
        incr arg_count

        set var_name $var_switch
        # Check for alternate name
        if {[regexp -- {:} $var_switch]} {
            # Set switch and variable name different
            set split_var [split $var_switch {:}]
            set var_switch [lindex $split_var 0]
            set var_name [lindex $split_var 1]
        }
        lappend switch_list $var_switch

        set check_value ""  ;# Validation rules that may be affected by ANY
        set check_other ""  ;# Validation rules not affected by ANY
        set any_type    0   ;# ANY type was specified for this switch
            
        foreach { type line } $spec {
            if {$type eq ""} {
                set type "ANY"
            }

            switch -- $type {
                DEFAULT {
                    # Strip off any surrounding quotes or braces
                    if {[regexp -- {^(".*")$|^(\{.*\})$} $line]} {
                        set line [string range $line 1 end-1]
                    }
                    lappend defaults $var_switch $line
                }
                ANY -
                SHIFT -
                IP -
                IPV4 -
                IPV6 -
                MASK -
                MAC -
                ALPHANUM -
                ALPHA -
                NUMERIC -
                DECIMAL -
                HEX -
                KEYLIST -
                FLAG {
                    # These types take no arguments, make sure nothing
                    # extra on line
                    if {$line ne ""} {
                        return -code error "$procName: Invalid check\
                          value specification: The check type \"$type\"\
                          allows no further arguments, yet \"$line\"\
                          was found following the type."
                    }
                    if {$type == "MASK"} {
                        # This is a combination of IP and NUMERIC, so
                        # just convert to those
                        lappend check_value "IP" {} "NUMERIC" {}
                    } elseif {$type == "ANY"} {
                        # Set flag indicating ANY type was present, to
                        # override later when all validation rules are parsed.
                        set any_type 1
                    } else {
                        lappend check_value $type {}
                    }
                }
                CHOICES {
                    # TODO: should check for empty line
                    lappend check_value $type [join $line "|"]
                }
                REGEXP {
                    # TODO: should check for empty line
                    lappend check_value $type $line
                }
                RANGE {
                    # Extract min/max values from line
                    # TODO: should require min < max or swap?

                    if {![regexp -- {^([0-9]+)((\s*-\s*)|\s+)([0-9]+)$} \
                              $line -> min -> -> max]} {
                        return -code error \
                            [::pda::_build_parse_error \
                                   $procName \
                                   "Invalid check value\
                                   specification: -RANGE:$line\nValid\
                                   RANGE format is: \"RANGE #-#\""]
                    }

                    lappend check_value $type [list $min $max]
                }
                LIST_SIZE {
                    # Require a single positive integer to be given

                    if {![string is integer -strict $line]} {
                        return -code error \
                            [::pda::_build_parse_error \
                                   $procName \
                                   "Invalid check value specification:\
                                   -LIST_SIZE:$line\nValid LIST_SIZE\
                                   format is: \"LIST_SIZE #\""]
                    }
                    if {$line == 0} {
                        return -code error \
                            [::pda::_build_parse_error \
                                   $procName \
                                   "Invalid check value specification:\
                                    -LIST_SIZE:$line\n\The\
                                    -LIST_SIZE cannot be 0.\
                                    Use the -FLAG specification\
                                    for arguments without values."]
                    }

                    lappend check_value $type $line
                }
                REQUIRES -
                EXCLUDES {
                    # TODO: should check for empty line
                    # These types take a list of other switch names.

                    set pair_args [list]

                    # Build list of paired switch names without hyphens

                    foreach pair_arg $line {
                        if {[string index $pair_arg 0] == "-"} {
                            set pair_arg [string range $pair_arg 1 end]
                        }
                        lappend pair_args $pair_arg
                    }

                    # Add extracted switch pairings with different
                    # delimiter.

                    lappend check_other [string tolower $type] $pair_args
                }
                FORMAT {
                    # Strip off any surrounding quotes or braces
                    if {[regexp -- {^(".*")$|^(\{.*\})$} $line]} {
                        set line [string range $line 1 end-1]
                    }

                    # Scan the entire format string for obviously
                    # bad formatting codes.

                    set format_count 0
                    set arg_format $line
                    while {[string length $line]} {
                        set c [string index $line 0]

                        # Skip everything up to the next %

                        if {$c != "%"} {
                            set line [string range $line 1 end]
                            continue
                        }

                        set c [string index $line 1]

                        # Skip %%, which just turns into a %

                        if {$c == "%"} {
                            set line [string range $line 2 end]
                            continue
                        }

                        # Error if either this is the second format
                        # code found, or it either doesn't look
                        # like a valid format or uses something
                        # that's valid to the format command but
                        # not for this use case (e.g. the * and $
                        # flags that would indicate more arguments
                        # than will be present in the format call.)

                        if {$format_count} {
                            return -code error \
                                [::pda::_build_parse_error $procName \
                                    "invalid format \"$arg_format\":\
                                    only one format code is allowed"]
                        }

                        if {![regexp -- $_re(FORMAT) $line]} {
                            return -code error \
                                [::pda::_build_parse_error $procName \
                                    "invalid format \"$arg_format\":\
                                    format code not recognized or not allowed"]
                        }

                        # Found something that looks like a format.
                        # Trim off at least enough to continue
                        # scanning for another.

                        set line [string range $line 2 end]
                        incr format_count
                    }

                    # Check if format string is constant, which is most
                    # probably not intended.

                    if {!$format_count} {
                        return -code error \
                            [::pda::_build_parse_error $procName \
                                "invalid format \"$arg_format\":\
                                 constant result"]
                    }

                    lappend check_other $type $arg_format
                }
                VCMD {
                    # TODO: should check for empty line
                    lappend check_value $type $line
                }
                default {
                    return -code error "$procName: Invalid check value\
                          specification: Check type \"$type\"\
                          is unknown."
                }
            }
        }

        # Delete superfluous validation rules if ANY type was specified

        if {$any_type} {
            set check_value ""
        }

        # Add in rules that are not to be affected by the ANY type and
        # that should not be skipped by passing a validation rule,
        # such as REQUIRES, EXCLUDES, and (soon) FORMAT.
        # TODO: should LIST_SIZE also be preserved?

        set check_value [concat $check_other $check_value]

        # Set return keys
        lappend check_list $var_switch $check_value $var_name $check_value
        lappend argtype_list $var_switch 1 $var_name 1
        lappend switch_map $var_switch $var_name
    }

    # Check for duplicate switches

    set seen {}
    foreach var_switch $switch_list {
        if {[lsearch -exact $seen $var_switch] != -1} {
            return -code error "$procName: Duplicate $argtype\
                argument found: \"$var_switch\""
        }
        lappend seen $var_switch
    }

    # Return parsed specification fields to parse_dashed_args

    uplevel 1 [list set ${argtype}_arg_count $arg_count]
    uplevel 1 [list set ${argtype}_string [join $switch_list " "]]
    uplevel 1 [list array set default_value $defaults]
    uplevel 1 [list array set check_array $check_list]
    uplevel 1 [list array set ${argtype}_array $argtype_list]
    uplevel 1 [list array set var_array $switch_map]
}

##i
# Utility procedure to verify that a keyword is or is not paired
# with some additional information (e.g. REGEXP + the regular expression)
# in an argument specification.

proc pda::_check_type_data { procName type line data_required } {
    if {$data_required} {
        # This type requires arguments, make sure more data on the line
        if {$line eq ""} {
            return -code error "$procName: Invalid check\
                value specification: The check type \"$type\"\
                requires further arguments, yet none\
                were found following the type."
        }
    } else {
        # This type takes no arguments, make sure nothing extra on the line
        if {$line ne ""} {
            return -code error "$procName: Invalid check\
                value specification: The check type \"$type\"\
                allows no further arguments, yet \"$line\"\
                was found following the type."
        }
    }
}

##Internal Procedure Header
#
# Name:
#   _parse_line_format
#
# Synopsis:
#   _parse_line_format <argstring>
#
# Arguments:
#   <argstring> Error message
#
# Return Values:
#   A list of arg-name/arg-spec pairs, with arg-spec being a list of
#   check type/check data pairs.
#
# Description:
#   This procedure pre-processes argument specifications in line format
#   to determine which lines belong to which arguments, and prepare them
#   for further processing of individual keywords.
#
#   Line format has each arg on a separate line as:
#
#       -switch_name:alt_name data_type data_fields
#                             data_type data_fields
#                             ...
#
#   Where:
#       -switchname  = dashed switch argument  (ex. -slot)
#       alt_name     = alternative variable name and switch name
#       data_type    = all caps data type (ex. NUMERIC, RANGE, etc.)
#       data_fields  = fields required by data_type, different for each
#
#   This function splits its input into a list of lines, and groups
#   the lines into a list so that each list element contains all the
#   lines for one dashed argument.
#
# End of Header

proc pda::_parse_line_format { argstring } {
    set procName    "parse_dashed_args"
    set lines       [split $argstring \n]

    set result      ""
    set arg_spec    ""
    set arg_count   0

    # Look through lines for those starting with hyphens to group
    # together lines that belong to each dashed arg specification.

    foreach line $lines {
        set line [string trim $line]

        # Ignore blank lines in the argument specification

        if {[string length $line]} {
            # If the first character of the trimmed line starts with
            # a dash, then it is the start of a new arg specification.

            if {[string index $line 0] eq "-"} {
                incr arg_count

                # Store away the current arg spec, assuming one has been
                # parsed (i.e., this is not the first line starting with
                # a dash).
                
                if {[llength $arg_spec]} {
                    lappend result $arg_name $arg_spec
                    set arg_spec ""
                }

                # Extract the dashed arg name(s) from any check info

                regexp -- {^(\S+)\s*(.*)$} $line -> arg_name line
            }

            # Verify that the first non-empty line started with a dash

            if {$arg_count < 1} {
                return -code error "$procName: Type '$line' found with\
                    no corresponding dashed switch argument"
            }

            # Extract the check type keyword from data that goes along with
            # (e.g. "CHOICES" keyword and the choices themselves)

            set data ""
            set type ""
            regexp -- {^(\S+)\s*(.*)$} $line -> type data

            # Stash keyword and data away as an allowed form for the arg

            lappend arg_spec $type $data
        }
    }

    # Make sure the last switch specification is included in the result

    if {[llength $arg_spec]} {
        lappend result $arg_name $arg_spec
    }

    return $result
}

##Internal Procedure Header
#
# Name:
#   _parse_block_format
#
# Synopsis:
#   _parse_block_format <arglist>
#
# Arguments:
#   <arglist>   A list of argument specifications in the "old" format
#
# Return Values:
#   A list of arg-name/arg-spec pairs, with arg-spec being a list of
#   check type/check data pairs.
#
# Description:
#   This procedure parses the "old" block format for dashed argument
#   specifications, which put validation information in <>'s such
#   as "-foo<-IP>".  In converts this format into an intermediate
#   mostly-parsed format that is the same as the intermediate format
#   produced by _parse_line_format, allowing further parsing of the
#   argument specifications by both formats to use the same code.
#
# End of Header

proc pda::_parse_block_format { arglist } {
    set procName "parse_dashed_args"

    set result      ""

    # Block format (args in a single space separated block)
    foreach arg $arglist {
        # Check for invalid argument (to catch extra space between argument
        # and check-value notation)

        if {[regexp -- {^<} $arg]} {
            # Argument begins with check symbol, probably extra space typo
            return -code error "$procName: Invalid argument \"$arg\".\
               This is probably a check-value notation with an extra \
               space in front of it.\
               Please remove any spaces between the argument and the\
               check-value notation."
        }

        # Save any specified value check (between <> symbols)

        if {[regexp -- {^(.+)<(.+)>$} $arg -> arg_name check_values]} {
            # Split on comma and loop through all details

            set check_values    [split $check_values ","]
            set arg_spec        ""
            set arg_name        [string trim $arg_name]

            foreach check_value $check_values {
                set check_value [string trim $check_value]

                # Extract check type keyword from its data

                if {[regexp -- {^-([^:]+):(.+)$} $check_value -> type data]} {
                    # CHOICES alternates are delimeted by a bar in this
                    # format and whitespace in the line/intermediate format.

                    if {$type eq "CHOICES"} {
                        set data [string map {"|" " "} $data]
                    }
                } elseif {[string index $check_value 0] eq "-"} {
                    # No colon in the check type, but it does start with
                    # a dash, so it's a keyword without any additional
                    # details (like "-IP").

                    set type [string range $check_value 1 end]
                    set data ""
                } else {
                    # No dash at the start is a regular expression

                    set type "REGEXP"
                    set data $check_value
                }

                # Check for disallowed and remapped check type keywords

                switch -- $type {
                    "STRING" {
                        # STRING type was replaced by SHIFT in line format
                        set type "SHIFT"
                    }

                    "ANY" {
                        # Block format does not support ANY
                        return -code error "$procName: Invalid check value\
                              specification: Check type \"-$type\"\
                              is unknown."
                    }

                    "FORMAT" -
                    "REQUIRES" -
                    "EXCLUDES" -
                    "VCMD" -
                    "HEX" -
                    "DECIMAL" {
                        # These new types and only allowed in the new format
                        # Note: probably no technical reason not to allow
                        # at least HEX/DECIMAL.
                        return -code error "$procName: Invalid check value\
                            specification: Check type \"-$type\"\
                            is not allowed with legacy format.  Please\
                            use correct format for this check type."
                    }
                }

                # Stash keyword and data away as an allowed form for the arg

                lappend arg_spec $type $data
            }

            lappend result $arg_name $arg_spec
        } else {
            lappend result $arg ""
        }
    }

    return $result
}

##Internal Procedure Header
#
# Name:
#   _build_parse_error
#
# Synopsis:
#   _build_parse_error <proc-name> <msg>
#
# Arguments:
#   <proc-name>
#         The calling proc name (can be null if not supplied)
#   <msg>
#         Error message
#
# Return Values:
#   Error string.
#
# Description:
#         Internal procedure for building a parser error string with the
#         appropriate calling proc name and usage, allowing the error to look
#         like it came from the calling proc instead of the parser.
#     Author: Dave Cardosi
#     Date: May 2, 2003
#
# Examples:
#   return -code error [::pda::_build_parse_error $calling_proc_name \
#          "Missing mandatory arguments"]
#
# End of Header

proc pda::_build_parse_error {calling_proc_name msg} {

    # If calling proc name is available, and cisco_help proc is defined,
    # then build the appropriate return message with usage info, otherwise
    # just return parser name without usage.
    if {($calling_proc_name == "") || (![llength [info proc ::cisco_help]])} {
        # Hard code parser procname without usage for direct parser call
        set error_string "parse_dashed_args: $msg"
    } else {
        # Build string with calling proc name and usage
        # Add leading :: due to bug CSCdx82291
        set calling_proc_usage [::cisco_help +verbose \
                                    proc "\^(::)*$calling_proc_name$"]
        if {![regexp -- {^no help for} $calling_proc_usage]} {
            # Strip off everything from help except usage statement
            if {[regexp -nocase -- {Usage} $calling_proc_usage]} {
                regsub -nocase -- {^.*Usage} $calling_proc_usage {Usage} \
                    calling_proc_usage
                regsub -- "\[\n\r\] *\[\n\r\].*" $calling_proc_usage "\n" \
                    calling_proc_usage
            }
            set error_string "$calling_proc_name: $msg\n$calling_proc_usage"
        } else {
            set error_string "$calling_proc_name: $msg"
        }
    }
    return $error_string
}

##Internal Procedure Header
#
# Name:
#   _check_pairs
#
# Synopsis:
#   _check_pairs <calling_proc_name> <switches_provided> <switch_pairings> \
#                <switch_list> <mandatory_list>
#
# Arguments:
#   <calling_proc_name>
#       The name of the procedure calling parse_dashed_args
#   <switches_provided>
#       The list of all switches that were extracted from the provided args.
#   <switch_pairings>
#       The list of rules defining which switches require or exclude others
#   <switch_list>
#       The set of defined mandatory an optional switch names, used for
#       closest matching.
#   <mandatory_list>
#       The list of switch names that are mandatory.
#
# Return Values:
#   N/A
#
# Description:
#   Internal procedure to perform final checking after all arguments have
#   been processed to determine if REQUIRES/EXCLUDES conditions are met.
#
# End of Header

proc pda::_check_pairs { calling_proc_name switches_provided \
        switch_pairings switch_list mandatory_list } {

    foreach { arg1 mode arg2 } $switch_pairings {

        # Check to see if the required/excluded argument was
        # even defined within the option specification.

        if {[lsearch -exact $switch_list $arg2] == -1} {
            return -code error [::pda::_build_parse_error \
                $calling_proc_name \
                "option \"-$arg1\" $mode option \"-$arg2\",\
                    which is not defined in the option spec."]
        }

        # Check to see if the pairing rules were met

        switch -- $mode {
            "requires" {
                if {[lsearch -exact $switches_provided $arg2] == -1} {
                    return -code error [::pda::_build_parse_error \
                        $calling_proc_name \
                        "option \"-$arg1\" requires option\
                            \"-$arg2\", which was not provided."]
                }
            }
            "excludes" {
                # Check for options excluding themselves, which would
                # be an impossible requirement to meet.

                if {$arg1 == $arg2} {
                    return -code error [::pda::_build_parse_error \
                        $calling_proc_name \
                        "option \"-$arg1\" cannot exclude its self."]
                }
                    
                # Check for mandatory options excluding other mandatory
                # options, which would be a conflict.

                if {[lsearch -exact $mandatory_list $arg2] != -1} {
                    return -code error [::pda::_build_parse_error \
                        $calling_proc_name \
                        "option \"-$arg1\" cannot exclude mandatory option\
                            \"-$arg2\"."]
                }
                    
                if {[lsearch -exact $switches_provided $arg2] != -1} {
                    return -code error [::pda::_build_parse_error \
                        $calling_proc_name \
                        "option \"-$arg2\" cannot be used with option\
                            \"-$arg1\"."]
                }
            }
            default {
            }
        }
    }
}

##Internal Procedure Header
#
# Name:
#   _get_switch
#
# Synopsis:
#   _get_switch <calling_proc_name> <process_args> <index> <switch_list> \
#               <use_closest_match>
#
# Arguments:
#   <calling_proc_name>
#       The name of the procedure calling parse_dashed_args
#   <process_args>
#       The list of arguments supplied with -args that are to be parsed.
#   <index>
#       An index into process_args identifying the argument to be
#       extracted.
#   <switch_list>
#       The set of defined mandatory an optional switch names, used for
#       closest matching.
#   <use_closest_match>
#       A flag indicating that, if true, closest matching should be used.
#
# Return Values:
#   The name of the switch to be processed, with leading - stripped off.
#
# Description:
#   Internal procedure to obtain the next switch from the argument list
#   that is to be processed by parse_dashed_args.  In exact matching mode,
#   this is the actual argument.  In closest matching mode, this is the
#   closest unambiguous glob-style match to one of the defined switches.
#
# End of Header

proc pda::_get_switch { calling_proc_name process_args index \
        switch_list use_closest_match } {

    # Extract the next argument, switch or not

    set arg [lindex $process_args $index]

    # Make sure that this next argument is a switch (dashed argument)

    if {[string index $arg 0] ne "-"} {
        return -code error [::pda::_build_parse_error $calling_proc_name \
                "Illegal non-dashed argument \"$arg\" found in parsed\
                argument list."]
    }

    # Remove the dash from the switch, as most of the other code expects
    # it to not have the leading dash.

    set arg [string range $arg 1 end]

    # Use glob-style pattern matching to match the provided switch up to
    # a defined/expected switch, if requested or in interactive mode.

    if {$use_closest_match} {
        set opts_matched [lsearch -all -inline -glob $switch_list "$arg*"]

        # If there were multiple possible matches, see if any of them is an
        # exact match.  If not, the argument is ambiguous.

        if {[llength $opts_matched] > 1} {
            set actual_arg [lsearch -inline -exact $opts_matched $arg]

            # actual_arg will be an empty string if no exact match
            # was found.

            if {[string length $actual_arg] == 0} {
                # Format the ambiguous error message

                set switch_list [lsort -dictionary $switch_list]

                set message "ambiguous option \"-$arg\": must be "
                append message "-[lindex $switch_list 0]"

                set switch_list [lrange $switch_list 1 end]

                while {[llength $switch_list] > 1} {
                    append message ", -[lindex $switch_list 0]"
                    set switch_list [lrange $switch_list 1 end]
                }

                append message " or "
                append message "-[lindex $switch_list 0]"

                return -code error [::pda::_build_parse_error \
                    $calling_proc_name $message]
            }
        } elseif {[llength $opts_matched]} {
            set arg [lindex $opts_matched 0]
        }
    }

    return $arg
}

##Internal Procedure Header
#
# Name:
#   pda::_initialize
#
# Synopsis:
#   init_regexps
#
# Arguments:
#   None
#
# Return Values:
#   N/A
#
# Description:
#   Internal procedure for building the set of regular expressions
#   used to validate provided values versus type keywords such as
#   IP, DECIMAL, etc.  Called once at package initialization, allowing
#   Tcl to cache the compiled regular expression for improved performance.
#
# End of Header

proc pda::_initialize {} {
    variable _re

    # IPv4 is 4 dot separated decimal bytes,
    # of the form #.#.#.#
    # Setup v4 byte regexp as:
    # 0-9 or 00-99 or 000-199 or 200-249 or
    # 250-255

    set ipv4byte {([0-9]|[0-9][0-9]}

    append ipv4byte {|[0-1][0-9][0-9]}
    append ipv4byte {|2[0-4][0-9]}
    append ipv4byte {|25[0-5])}

    set _re(IPV4) "$ipv4byte\\\.$ipv4byte\\\.$ipv4byte\\\.$ipv4byte"

    # IPv6 is 8 colon separated hex bytes (words),
    # of the form #:#:#:#:#:#:#:#
    # Setup v6 byte regexp as 1-4 hex chars

    set ipv6byte {[0-9a-fA-F]{1,4}}

    # Now setup regexp for v6 address.  V6 allows
    # shorthand notation of double colon :: 
    # to represent multiple groups of 0

    set _re(IPV6) "("

    # Normal 8 byte address
    append _re(IPV6) "|((($ipv6byte:){7}$ipv6byte)"

    # 0 bytes followed by :: followed by 0-7 bytes
    append _re(IPV6) "|(::($ipv6byte:){0,6}"
    append _re(IPV6) "($ipv6byte)?)"

    # 1 byte followed by :: followed by 0-6 bytes
    append _re(IPV6) "|($ipv6byte\::($ipv6byte:){0,5}"
    append _re(IPV6) "($ipv6byte)?)"

    # 2 bytes followed by :: followed by 0-5 bytes
    append _re(IPV6) "|($ipv6byte:$ipv6byte\::"
    append _re(IPV6) "($ipv6byte:){0,4}($ipv6byte)?)"

    # 3 bytes followed by :: followed by 0-4 bytes
    append _re(IPV6) "|($ipv6byte:$ipv6byte:$ipv6byte"
    append _re(IPV6) "\::($ipv6byte:){0,3}($ipv6byte)?)"

    # 4 bytes followed by :: followed by 0-3 bytes
    append _re(IPV6) "|($ipv6byte:$ipv6byte:$ipv6byte:"
    append _re(IPV6) "$ipv6byte\::($ipv6byte:){0,2}"
    append _re(IPV6) "($ipv6byte)?)"

    # 5 bytes followed by :: followed by 0-2 bytes
    append _re(IPV6) "|($ipv6byte:$ipv6byte:$ipv6byte:"
    append _re(IPV6) "$ipv6byte:$ipv6byte\::($ipv6byte:){0,1}"
    append _re(IPV6) "($ipv6byte)?)"

    # 6 bytes followed by :: followed by 0-1 bytes
    append _re(IPV6) "|($ipv6byte:$ipv6byte:$ipv6byte:"
    append _re(IPV6) "$ipv6byte:$ipv6byte:$ipv6byte\::"
    append _re(IPV6) "($ipv6byte)?)"

    # 7 bytes followed by :: 
    append _re(IPV6) "|(($ipv6byte:){7}\:))"
        
    # 6 bytes followed by IPv4 address
    append _re(IPV6) "|((($ipv6byte:){6}"
    append _re(IPV6) "$ipv4byte\\\.$ipv4byte\\\.$ipv4byte\\\.$ipv4byte)"

    # 0 bytes followed by :: followed by (0,5) IPv6 bytes
    # followed by IPv4 address
    append _re(IPV6) "|(::($ipv6byte:){0,5}"
    append _re(IPV6) "$ipv4byte\\\.$ipv4byte\\\.$ipv4byte\\\.$ipv4byte)"

    # 1 byte followed by :: followed by 0-4 IPv6 bytes
    # followed by IPv4 address
    append _re(IPV6) "|($ipv6byte\::($ipv6byte:){0,4}"
    append _re(IPV6) "$ipv4byte\\\.$ipv4byte\\\.$ipv4byte\\\.$ipv4byte)"

    # 2 bytes followed by :: followed by 0-3 bytes
    # followed by IPv4 address
    append _re(IPV6) "|(($ipv6byte:){2}:($ipv6byte:){0,3}"
    append _re(IPV6) "$ipv4byte\\\.$ipv4byte\\\.$ipv4byte\\\.$ipv4byte)"

    # 3 bytes followed by :: followed by 0-2 byte
    # followed by IPv4 address
    append _re(IPV6) "|(($ipv6byte:){3}:($ipv6byte:){0,2}"
    append _re(IPV6) "$ipv4byte\\\.$ipv4byte\\\.$ipv4byte\\\.$ipv4byte)"

    # 4 bytes followed by :: followed by 0-1 byte
    # followed by IPv4 address
    append _re(IPV6) "|(($ipv6byte:){4}:($ipv6byte:)?"
    append _re(IPV6) "$ipv4byte\\\.$ipv4byte\\\.$ipv4byte\\\.$ipv4byte)"  

    # 5 bytes followed by :: followed by IPv4 address
    append _re(IPV6) "|(($ipv6byte:){5}:"
    append _re(IPV6) "$ipv4byte\\\.$ipv4byte\\\.$ipv4byte\\\.$ipv4byte))"

    append _re(IPV6) ")"

    # IP - can match IPV4 or IPV6

    set _re(IP) "^($_re(IPV4)|$_re(IPV6))$"

    # Done building IP regexp, so it's now safe to anchor the IPv4
    # and IPv6 regexps to line start/end.

    set _re(IPV4) "^$_re(IPV4)$"
    set _re(IPV6) "^$_re(IPV6)$"

    # MAC address is of the form xx.xx.xx.xx.xx.xx
    # (standard 6 byte format) or xxxx.xxxx.xxxx
    # (3 byte Cisco format)
    # Note: In the future we could add MAC3 or MAC6
    # if we need to allow only one type.

    set cscfmt {[0-9a-f][0-9a-f][0-9a-f][0-9a-f]}
    append cscfmt {\.[0-9a-f][0-9a-f][0-9a-f]}
    append cscfmt {[0-9a-f]}
    append cscfmt {\.[0-9a-f][0-9a-f][0-9a-f]}
    append cscfmt {[0-9a-f]}
    set stdfmt {[0-9a-f][0-9a-f]\.}
    append stdfmt {[0-9a-f][0-9a-f]\.}
    append stdfmt {[0-9a-f][0-9a-f]\.}
    append stdfmt {[0-9a-f][0-9a-f]\.}
    append stdfmt {[0-9a-f][0-9a-f]\.}
    append stdfmt {[0-9a-f][0-9a-f]}

    set _re(MAC) "(?i)^($stdfmt|$cscfmt)$"

    # DECIMAL - A decimal value (i.e., an integer or float, with
    # or without a leading digit).

    set cval1 {[0-9]+\.*[0-9]*}
    set cval2 {[0-9]*\.*[0-9]+}

    set _re(DECIMAL) "^($cval1|$cval2)$"

    # HEX - A hex value, with optional leading 0x

    set _re(HEX) {^(0x)?[0-9a-fA-F]+$}

    # NUMERIC - An integer only value

    set _re(NUMERIC) {^[0-9]+$}

    # ALPHA - An alphabetic only value

    set _re(ALPHA) {^[a-zA-Z]+$}

    # ALPHANUM - An alphanumeric value

    set _re(ALPHANUM) {^[a-zA-Z0-9_]+$}

    # FORMAT - Regular expression for validating formatting codes

    set _re(FORMAT) {^%[0# +-]*[0-9]*(\.[0-9]*)?[duioxXcsfeEgG]}

    # Alias parse_dashed_args for compatibility with earlier versions that
    # were not defined in a namespace.

    interp alias {} ::parse_dashed_args {} ::pda::parse_dashed_args
}

# Initialize regular expressions and provide global alias to parse_dashed_args
# for compatibility with code from prior to the move to the namespace.

::pda::_initialize

# $Log: parse_dashed_args.tcl,v $
# Revision 1.42  2006/10/30 22:00:00  mkirkham
# DDTS Number: CSCsg52134
# Reviewed By: hlavana
# Change Description:
# Changed parse_dashed_args to convert the -level option to an absolute
# offset from the current level if it's given as a simple integer, and
# removed the incr level from _format_valid_string.  If the level were
# given as absolute already (starting with a "#"), an error would occur
# because it wouldn't be a valid integer needed by incr.  This is safer,
# because now uplevels could be refactored to other procedures without
# needing to adjust the level.
#
# Revision 1.41  2006/09/21 08:51:23  mkirkham
# DDTS Number: CSCsd08934
# Reviewed By: vjeyem
# Change Description:
# Added a check to each of parse_dashed_args' switches that require a value
# (such as  -return_array) to make sure the value is present, and return an
# error if not.
#
# Revision 1.40  2006/06/07 04:06:52  mkirkham
# DDTS Number: CSCeh07670
# Reviewed By: hlavana
# Change Description:
# Added FORMAT keyword for argument specifications to allow input values
# to automatically be formatted via Tcl's format command.  For any given
# list value, each FORMAT attempted in turn (in the order they are
# defined) until one is successful.  So, for example, if you have an arg
# that accepts any type of data, one can arrange to format integers as
# floats with fixed precision yet pad other strings to a certain width
# with spaces.
#
# Revision 1.38  2006/06/02 22:03:54  mkirkham
# DDTS Number: CSCse40237
# Reviewed By: hlavana
# Change Description:
# Converted the check_array variable from -<keyword>:<detail> format to a
# pure list of <keyword> <detail> pairs that don't require reparsing.
#
# Moved validation of rule details down to _parse_check_args so that errors
# in arg specs are caught before attempting to validate args versus those
# rules.
#
# Moved all of the "invalid value" error message/valid_string generation stuff
# that used to be done through check_error_list to a separate procedure,
# _format_valid_string.  It now maintains a simple error counter to determine
# if a value failed all checks.
#
# The "REGEXP" type will no longer wipe out anything that came before it.
#
# Revision 1.37  2006/05/26 22:09:52  mkirkham
# DDTS Number: CSCse28920
# Reviewed By: hlavana
# Change Description:
# Refactored and partially rewrote _parse_check_args to format-specific
# parts for parsing the "old/block" format and "new/line" format for dashed
# arg specs into separate procs, _parse_block_format and _parse_line_format,
# to eliminate duplicate code and make it easier to modify the
# _parse_check_args return formats later.
#
# Revision 1.36  2006/05/26 22:03:02  mkirkham
# DDTS Number: CSCse28523
# Reviewed By: hlavana
# Change Description:
# Consolidated uplevels for returning mandatory/optional/passthru_args
# to pda callers so only one properly-listified uplevel is needed for arrays
# and info exists checks aren't needed.  Changed all of the uplevel calls
# to be properly-listified and eliminated the brace-checking hacks.  This
# reduces both code complexity and shimmering.
#
# Changed various string operations that build error messages with lists of
# arguments or allowed values to list operations, joined only when necessary,
# with adjustments to line continuations to avoid string concatenation overhead
# when not needed and makes the whitespace formatting of error messages
# consistent.
#
# Revision 1.35  2006/05/02 21:33:07  mkirkham
# DDTS Number: CSCse08644
# Reviewed By: hlavana
# Change Description:
# Factored out the regular expressions for validating argument values
# from parse_dashed_args into an initialization procedure invoked only
# once at startup, to improve readability and performance.
#
# Revision 1.34  2006/05/01 22:08:08  mkirkham
# DDTS Number: CSCse09012
# Reviewed By: hlavana
# Change Description:
# Factored INCLUDES/EXCLUDES pair checking of supplied arguments into a separate
# procedure (_check_pairs) to further reduce complexity of parse_dashed_args
# itself.
#
# Revision 1.33  2006/05/01 22:03:01  mkirkham
# DDTS Number: CSCse10208
# Reviewed By: hlavana
# Change Description:
# Factored out dashed argument acquisition and glob-style (closest) matching
# code into a separate procedure, _get_switch for readability/maintainability.
#
# Revision 1.32  2006/04/29 03:28:34  mkirkham
# DDTS Number: CSCsd96675
# Reviewed By: mkirkham
# Change Description:
# info proc cisco_help always returns an empty list after moving pda to its own
# namespace and needed to be qualified as ::cisco_help, otherwise it's never called.
# Was supposed to be part of the CSCsd96675 patch but got dropped in re-doing it.
#
# Revision 1.31  2006/04/17 17:03:03  mkirkham
# DDTS Number: CSCsd96675
# Reviewed By: hlavana
# Change Description:
# A flag given a value followed by another flag without a value would
# result in an error due to check_type still being set to FLAG but the value
# variable not being set.
#
# Revision 1.30  2006/04/07 05:06:51  mkirkham
# DDTS Number: CSCsd83843
# Reviewed By: hlavana
# Change Description:
# Removed dependency on Tclx keylists.  These were mainly used to collect
# data parsed from the argument specifications by _parse_check_args to be
# returned up to parse_dashed_args and disassembled, never to be used
# again.  Instead, the appropriate variables are set directly via
# uplevels in _parse_check_args.
#
# Some related refactoring was also done, moving common code to
# _parse_check_args, and duplicate argument checking code (which was
# itself duplicated) to the end of _parse_check_args.
#
# Revision 1.29  2006/04/07 02:35:13  mkirkham
# DDTS Number: CSCsd89526
# Reviewed By: hlavana
# Change Description:
# Renamed parse_dashed_args package to pda and moved to pda namespace, with
# alias (package and command) for backwards compatibility.  Fixed static
# analysis issues.  Added tcltests for duplicate switch names in
# mandatory/optional args.
#
# Revision 1.28  2006/01/19 14:07:18  mkirkham
# DDTS Number: CSCei58142
# Reviewed By: hlavana
# Change Description:
# Added case-insensitive flag (?i) to start of the regular expression for
# MAC address matching.  Added tcltest cases for MAC addresses (some
# adapted from the cisco-shared version's test_parse.exp script plus a
# bunch more).
#
# Revision 1.27  2005/10/24 19:36:06  mkirkham
# DDTS Number: CSCsc27093
# Reviewed By: hlavana
# Change Description: Using LIST_SIZE with other types suppressed checks
# of those other types, rather than requiring the specified number of items
# of one of those types.
#
# Revision 1.26  2005/10/20 20:44:21  mkirkham
# DDTS Number: CSCej31515
# Reviewed By: hlavana
# Change Description:
# Corrected a regression introduced by CSCeh94732 that caused because the FLAG
# type to be exclusive of all other types.
#
# Revision 1.25  2005/08/31 19:24:12  mkirkham
# DDTS Number: CSCej02630
# Reviewed By: hlavana
# Change Description: Corrected a regression issue whereby the ANY type
# (or unspecified type) arguments would generate an error if given a
# string that could not be converted to a list.  Tests were added for ANY
# type, including for this DDTS.  The other existing tests were changed
# to the style of more recent tests added for other.  packages (wrapping
# in a namespace, requiring tcltest 2.2)
#
# Revision 1.24.2.1  2005/08/31 19:18:42  mkirkham
# DDTS Number: CSCej02630
# Reviewed By: hlavana
# Change Description: Corrected a regression issue whereby the ANY type
# (or unspecified type) arguments would generate an error if given a
# string that could not be converted to a list.  Tests were added for ANY
# type, including for this DDTS.  The other existing tests were changed
# to the style of more recent tests added for other.  packages (wrapping
# in a namespace, requiring tcltest 2.2)
#
# Revision 1.24  2005/06/28 21:42:32  hlavana
# DDTS Number: CSCei32063
# Change Description:
# Itramp should track real usage via API invocation rather than [package require].
#
# Revision 1.23  2005/05/31 21:33:43  mkirkham
# DDTS Number: CSCeh94732
# Change Description: Enhanced the handling of FLAG type arguments, which
# previously accepted no value, to optionally accept any boolean value
# (0, 1, true, false, yes or no).  To remain compatible, "false" values are
# only returned and the optional_args value populated if such switches have
# a DEFAULT value, and values are returned as either 0 or 1.
#
# Revision 1.22  2005/05/13 17:24:10  mkirkham
# DDTS Number: CSCeh07511
# Reviewed by: hlavana
# Change Description: Two new keywords, REQUIRES and EXCLUDES, were added to
# parse_dashed_args to support specifications where some options must or must
# not be used with other options.  Each instance of either keyword can take
# one or more arguments to require or exclude.
#
# Revision 1.21  2005/05/13 16:42:41  mkirkham
# DDTS Number: CSCeh07740
# Reviewed by: hlavana
# Change Description: A new keyword was added, VCMD, which can be used to
# specify a procedure to be invoked from the parse_dashed_args caller's
# scope to validate an argument value externally.  The procedure takes one
# argument (the value) and can return either any boolean or a boolean and
# a failure message as a list.
#
# Revision 1.20  2005/05/11 22:48:54  mkirkham
# DDTS Number: CSCeh07751
#
# Reviewed by: hlavana
#
# Change Description: Options were added to parse_dashed_args was to support
# two different modes of matching switches provided with the -args option to the
# -mandatory_args and -optional_args specifications: -exact and -closest.
# In -exact mode, the argument must match exactly.  In -closest mode, the
# closest unambiguous match will be allowed (as in "-p" provided for "-port").
# The default is -closest when Tcl is running in interactive mode
# ($::tcl_interactive == 1) and -exact otherwise.
#
# Revision 1.19  2005/02/16 22:07:45  vjeyem
# DDTS Number:CSCeh08427
# Change Description:
# Added the fixed for the bug where parse will fail if the mandatory
# or optional arguments are on the same line as the leading brace.
#
# Revision 1.18  2005/02/07 19:38:36  hlavana
# DDTS Number: CSCeh06893
# Change Description:
# Replaced "error <string>" with "return -code error <string>"
#
# Revision 1.17  2005/01/20 21:55:51  dcardosi
# Change Description: Added new HEX check type.  Fixed problem so multiple
# RANGE types now allowed.  Fixed problem so alternate name properly set
# with default value.  Add code so cisco_help call is now conditional, which
# allows future removal of Cisco package dependency. Converted all
# documentation to new Autocat compatible format, and updated and added 
# examples.
# Reviewed by: wmarquet
#
# Revision 1.16  2004/11/05 16:07:28  dcardosi
# Change Description: Fixed issue where backslash was getting lost
# for the REGEXP specification.
# Reviewed by: wmarquet
#
# Revision 1.15  2004/08/25 22:36:28  dcardosi
# Reviewed by: jgeorgs
#
# Change Description: Added DECIMAL and ANY check types. Removed STRING type
# and replaced with SHIFT type to reflect it's true nature and to avoid users
# choosing STRING arbitrarily.
# Note: This is not backward compatible, we fully expect some current uses
# of STRING type to be rejected.  We believe the scope is very limited and
# therefore want to force these changes now before they become widespread.
#
# Revision 1.14  2004/08/19 18:44:59  dcardosi
# Reviewed by: wmarquet
#
# Change Description: Updated to ignore tabs in check specifications.
#
# Revision 1.13  2004/08/11 22:04:51  dcardosi
# Reviewed by: wmarquet
#
# Change Description: Changed returned passthru_args, mandatory_args, and
# optional_args to use straight append instead of lappend to solve issues
# with extra braces being upleveled.
#
# Revision 1.12  2004/07/30 19:43:36  dcardosi
# Reviewed by: wmarquet
#
# Change Description: Fixed to allow RANGE type to handle large values.
#
# Revision 1.11  2004/07/19 15:12:38  dcardosi
# Reviewed by: wmarquet
#
# Change Description: Added new ALPHA and ALPHANUM check types, and changed
# LIST_LIMIT to LIST_SIZE for more accurate functionality.
#
# Revision 1.10  2004/06/08 15:11:32  dcardosi
# Reviewed by: wmarquet
# Change Description: Fixed the IP check type to correctly verify V4 and
# V6 formatted IP addresses via the use of an amazing single regexp that
# goes beyond anything ever thought possible within tcl.
# Added new IPV4 and IPV6 check types.
# Fixed the documentation for REGEXP, updated examples, and added dummy
# procDescr for internal procs so autocat does not diplay them.
#
# Revision 1.9  2004/05/21 14:29:56  dcardosi
# Reviewed by: wmarquet
# Change Description: Documentation change only.  Updated usage to
# remove "block" format (moved to internal proc) since we want to
# use "line" format only going forward.
#
# Revision 1.8  2004/04/27 13:23:12  dcardosi
# Change Description: Updated to strip off any surrounding quotes or braces
#  on any default values (not just null or space).
# Reviewed by: wmarquet
#
# Revision 1.7  2004/04/21 21:19:27  dcardosi
# Reviewed by: wmarquet
# Change Description: Fixes to skip over null or blank arg lists, and
# to properly set null or blank default values.
#
# Revision 1.6  2004/04/21 15:24:41  dcardosi
# Reviewed by: wmarquette
#
# Change Description: Added trim of whitespace for older format arguments
#
# Revision 1.5  2004/04/21 14:03:49  dcardosi
# Reviewed by: Wayne Marquette
# Change Description:
# Many new features added:
#  -A new, easy to read single line format (no more cryptic check syntax)
#  -Multiple check types now allowed (ex. a range 1-7 or a value "off")
#  -Default values can now be set for optional args (no need to set each
#   variable beforehand)
#  -List limit feature (can specify maximum list lengths or single value only)
#  -New MASK check type added
#  -Values can be returned as an array (instead of current variable only method)
#
#
# Revision 1.4  2004/04/03 00:07:23  nkapur
# Change Description:
# Corrected name of library that was inadvertently changed during testing 
# of autocat
#
# Revision 1.3  2004/04/01 03:57:21  cms
# Commiting Files
#
# Revision 1.2  2004/02/09 16:49:06  dcardosi
# Reviewed by: Jurgen
# Change Description:
# Changed variable "level" to "stacklevel" for proc level checking.
#
# Revision 1.1  2004/02/05 21:24:01  cms
# Commiting Files
#
#
# ;;; Local Variables: ***
# ;;; mode: tcl ***
# ;;; indent-tabs-mode:nil
# ;;; End: ***
