## Copyright (C) 2012 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## Run script from command line. This function is used by ./octapps_run
## to parse the command line and call the script. Command-line options
## are given as either
##   --name <value>   or   --name=<value>
## and are designed to be parsed further by parseOptions().

function octapps_run(octapps_run_script, function_name)

  ## check that function_name exists in Octave path
  try
    function_handle = str2func(function_name);
  catch
    error("%s: no function '%s'", octapps_run_script, function_name);
  end_try_catch

  ## get command line arguments passed to script, which start
  ## after the command-line argument '/dev/null'
  args = argv();
  args = args((strmatch("/dev/null", args)(1)+1):end);

  ## stupid Octave; if no command-line arguments are given to script, argv()
  ## will contain the entire Octave command-line, instead of simply the
  ## arguments after the script name! so we have to check for this
  if length(args) > 0 && strcmp(args{end}, program_invocation_name)
    args = {};
  endif

  ## print caller's usage if --help is given
  if length(strmatch("--help", args)) > 0
    feval("help", function_name);
    exit(1);
  endif

  ## parse command-line arguments
  opts = {};
  n = 1;
  while n <= length(args)
    arg = args{n++};
    argvalstr = [];

    ## if argument is '--', just parse it along, since
    ## it might be being used as an option separator
    if strcmp(arg, "--")
      opts{end+1} = arg;
      continue
    endif
    
    ## check that argument begins with '--'
    if strncmp(arg, "--", 2)
      
      ## if argument contains an '=', split into name=value,
      i = min(strfind(arg, "="));
      if !isempty(i)
        argcmdname = arg(3:i-1);
        argvalstr = arg(i+1:end);
      else
        ## otherwise just store the name
        argcmdname = arg(3:end);
      endif
      
    else
      error("%s: Could not parse argument '%s'", funcName, arg);
    endif
    
    ## replace '-' with '_' to make a valid Octave variable name
    argname = strrep(argcmdname, "-", "_");
    
    ## if no argument value string has been found yet, check next argument
    if isempty(argvalstr) && n <= length(args)
      nextarg = args{n++};
      ## if next argument isn't itself an argument, use as a value string
      if !strncmp(nextarg, "--", 2)
        argvalstr = nextarg;
      endif
    endif
    if isempty(argvalstr)
      error("%s: Could to determine the value of argument '%s'", funcName, argcmdname);
    endif

    ## add argument and value to options
    opts = {opts{:}, argname, argvalstr};

  endwhile

  ## run script
  feval(function_handle, opts{:});

endfunction