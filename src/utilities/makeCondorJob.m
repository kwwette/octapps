## Copyright (C) 2011,2012 Karl Wette
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

## Set up a Condor job for running Octave scripts.
## Usage:
##   job_file = makeCondorJob("opt", val, ...)
## where
##   job_file = name of Condor job submit file
## Options:
##   "job_name":        name of Condor job, used to name submit file
##                      and input/output directories
##   "parent_dir":      where to write submit file and input/output
##                      directories (default: current directory)
##   "log_dir":         where to write Condor log files (default: $TMP")
##   "func_name":       name of Octave function to run
##   "arguments":       cell array of arguments to pass to function.
##                      use condorVar() to insert reference to a Condor variable.
##   "func_nargout":    how many outputs returned by the function to save
##   "exec_files":      cell array of executable files required by the function
##   "data_files":      cell array of data files required by the function;
##                      elements of cell array may be either:
##                      * "file_path", or
##                      * {"ENVPATH", "file_name_in_ENVPATH", ...}
##                      where ENVPATH is the name of an environment path
##   "extra_condor":    extra commands to write to Condor submit file, in form:
##                      {"command", "value", ...}
##   "output_format":   output format of file containg saved outputs from function:
##                      * "Oct(Text|Bin)(Z)": Octave (text|binary) (zipped) format
##                        - file extension will be .(txt|bin)(.gz)
##                      * "HDF5": Hierarchical Data Format version 5 format
##                        - file extension will be .hdf5
##                      * "Mat": Matlab (version 6) binary format
##                        - file extension will be .mat
##                      Default is "OctBinZ"

function job_file = makeCondorJob(varargin)

  ## parse options
  parseOptions(varargin,
               {"job_name", "char"},
               {"parent_dir", "char", "."},
               {"log_dir", "char", getenv("TMP")},
               {"func_name", "char"},
               {"arguments", "cell,vector", {}},
               {"func_nargout", "integer,positive,scalar"},
               {"exec_files", "cell", {}},
               {"data_files", "cell", {}},
               {"extra_condor", "cell", {}},
               {"output_format", "char", "OctBinZ"},
               []);

  ## check input
  if !isempty(strchr(job_name, "."))
    error("%s: job name '%s' should not contain an extension", funcName, job_name);
  endif
  try
    str2func(func_name);
  catch
    error("%s: '%s' is not a recognised function", funcName, func_name);
  end_try_catch
  for i = 1:length(data_files)
    if iscell(data_files{i}) && length(data_files{i}) < 2
      error("%s: element %i of 'data_files' must be a cell array of at least 2 elements", funcName, i);
    endif
  endfor

  ## check output format
  switch output_format
    case "OctText";  save_args = {"-text"};           save_ext = "txt";
    case "OctTextZ"; save_args = {"-text", "-zip"};   save_ext = "txt.gz";
    case "OctBin";   save_args = {"-binary"};         save_ext = "bin";
    case "OctBinZ";  save_args = {"-binary", "-zip"}; save_ext = "bin.gz";
    case "HDF5";     save_args = {"-hdf5"};           save_ext = "hdf5";
    case "Mat";      save_args = {"-mat-binary"};     save_ext = "mat";
    otherwise
      error("%s: unknown output format '%s'", funcName, output_format);
  endswitch

  ## check that parent and log directories exist
  if exist(parent_dir, "dir")
    parent_dir = canonicalize_file_name(parent_dir);
  else
    error("%s: parent directory '%s' does not exist", funcName, parent_dir);
  endif
  if exist(log_dir, "dir")
    log_dir = canonicalize_file_name(log_dir);
  else
    error("%s: log directory '%s' does not exist", funcName, log_dir);
  endif

  ## check that job submit file, bootstrap script, and input/output directories do not exist
  job_file = fullfile(parent_dir, strcat(job_name, ".job"));
  if exist(job_file, "file")
    error("%s: job submit file '%s' already exists", funcName, job_file);
  endif
  job_boot_file = fullfile(parent_dir, strcat(job_name, ".sh"));
  if exist(job_boot_file, "file")
    error("%s: job bootstrap script '%s' already exists", funcName, job_boot_file);
  endif
  job_indir = fullfile(parent_dir, strcat(job_name, ".in"));
  if exist(job_indir, "dir")
    error("%s: job input directory '%s' already exists", funcName, job_indir);
  endif
  job_outdir = fullfile(parent_dir, strcat(job_name, ".out"));
  if exist(job_outdir, "dir")
    error("%s: job output directory '%s' already exists", funcName, job_outdir);
  endif

  ## remove job log file, if it exists
  job_log_file = fullfile(log_dir, strcat(job_name, ".log"));
  if exist(job_log_file, "file")
    if unlink(job_log_file) != 0
      error("%s: could not delete file '%s'", funcName, job_log_file);
    endif
  endif

  ## add Octave executable to list of executable files
  exec_files{end+1} = fullfile(octave_config_info("bindir"), "octave");

  ## resolve locations of executable files
  unmanglePATH;
  path_value = getenv("PATH");
  for i = 1:length(exec_files)
    resolved_file = file_in_path(path_value, exec_files{i});
    if isempty(resolved_file)
      error("%s: could not find required file '%s'", funcName, exec_files{i});
    endif
    exec_files{i} = resolved_file;
  endfor

  ## resolve locations of data files
  resolved_files = {};
  for i = 1:length(data_files)
    switch class(data_files{i})
      case "char"
        resolved_file = fullfile(parent_dir, data_files{i});
        if !exist(data_files{i}, "file")
          error("%s: could not find required file '%s'", funcName, data_files{i});
        endif
        resolved_files{end+1} = data_files{i};
      case "cell"
        envpath_name = data_files{i}{1};
        envpath_value = getenv(envpath_name);
        if length(envpath_value) == 0
          error("%s: environment path '%s' is not set", funcName, envpath_name);
        endif
        for j = 2:length(data_files{i})
          resolved_file = file_in_path(envpath_value, data_files{i}{j});
          if isempty(resolved_file)
            error("%s: could not find required file '%s'", funcName, data_files{i}{j});
          endif
          resolved_files{end+1} = resolved_file;
        endfor
    endswitch
  endfor
  data_files = resolved_files;

  ## prefixes of local Octave functions and shared libraries,
  ## which do not need to be distributed
  octprefixes = cellfun("octave_config_info", {"fcnfiledir", "octfiledir"}, "UniformOutput", false);
  libprefixes = {"/lib", "/usr/lib"};

  ## get dependencies of job function
  func_files = struct2cell(depends(octprefixes, func_name));

  ## find if any job function dependencies are .oct modules
  ## if so, load them, then add all loaded .octs as dependencies
  for i = 1:length(func_files)
    [func_file_path, func_file_name, func_file_ext] = fileparts(func_files{i});
    if strcmp(func_file_ext, ".oct")
      try
        eval(strcat(func_file_name, ";"));
      catch
        error("%s: could not load required module '%s'", funcName, func_file_name);
      end_try_catch
    endif
  endfor
  loaded_oct_files = unique({autoload.file});
  oct_files = {};
  for i = 1:length(loaded_oct_files)
    if any(cellfun(@(x) strncmp(loaded_oct_files{i}, x, length(x)), octprefixes))
      continue;
    endif
    oct_files = {oct_files{:}, loaded_oct_files{i}};
  endfor
  oct_files = unique(oct_files);
  func_files = setdiff(func_files, oct_files);

  ## get dependencies of executables and .oct modules
  if length(exec_files) > 0 || length(oct_files) > 0
    shlib_files = sharedlibdeps(libprefixes, exec_files{:}, oct_files{:});
    shlib_files = setdiff(shlib_files, {exec_files{:}, oct_files{:}});
  endif

  ## find any dependencies that are in class directories;
  ## need to copy the entire class directory in this case
  class_dirs = {};
  for i = 1:length(func_files)
    [class_dir, class_name] = fileparts(func_files{i});
    [_, class_dir_name] = fileparts(class_dir);
    if strcmp(strcat("@", class_name), class_dir_name)
      class_dirs{end+1} = class_dir;
    endif
  endfor
  for i = 1:length(class_dirs)
    class_dir = strcat(class_dirs{i}, filesep);
    func_files(strncmp(func_files, class_dir, length(class_dir))) = [];
  endfor

  ## directories where dependent executables/shared libraries and function/.oct files are copied
  execdir = ".exec";
  funcdir = ".func";

  ## build structure containing environment variables to be set in bootstrap script
  env_vars = struct;
  env_vars.LD_PRELOAD = "";
  for i = 1:length(shlib_files)
    [shlib_file_path, shlib_file_name, shlib_file_ext] = fileparts(shlib_files{i});
    env_vars.LD_PRELOAD = strcat(env_vars.LD_PRELOAD, sprintf(" ${PWD}/%s/%s%s", execdir, shlib_file_name, shlib_file_ext));
  endfor
  env_vars.PATH = sprintf("${PWD}/%s:${PATH}", execdir);
  env_vars.OCTAVE_PATH = sprintf("${PWD}/%s", funcdir);
  for i = 1:length(class_dirs)
    [_, class_dir_name] = fileparts(class_dirs{i});
    env_vars.OCTAVE_PATH = strcat(env_vars.OCTAVE_PATH, sprintf(":${PWD}/%s/%s", funcdir, class_dir_name));
  endfor
  env_vars.OCTAVE_PATH = strcat(env_vars.OCTAVE_PATH, ":${OCTAVE_PATH}");
  env_vars.OCTAVE_HISTFILE = "/dev/null";
  env_vars.LAL_DEBUG_LEVEL = "1";

  ## build bootstrap script, which sets up environment then executes Octave script, which calls function and saves output
  bootstr = "";
  env_var_names = fieldnames(env_vars);
  for i = 1:length(env_var_names)
    envvarname = env_var_names{i};
    envvar = env_vars.(envvarname);
    bootstr = strcat(bootstr, sprintf("%s=\"%s\"\nexport %s\n", envvarname, envvar, envvarname));
  endfor
  bootstr = strcat(bootstr, "MAKE_CONDOR_JOB_ID=$1\nMAKE_CONDOR_JOB_NODE=`hostname`\n");
  bootstr = strcat(bootstr, "cat <<EOF\n");
  bootstr = strcat(bootstr, "# Condor ID: ${MAKE_CONDOR_JOB_ID}\n");
  bootstr = strcat(bootstr, "# Condor Node: ${MAKE_CONDOR_JOB_NODE}\n");
  bootstr = strcat(bootstr, sprintf("# Octave Command: %s($2{:})\n", func_name));
  bootstr = strcat(bootstr, "EOF\n");
  bootstr = strcat(bootstr, "cat <<EOF | exec octave --silent --norc --no-history --no-window-system\n");
  bootstr = strcat(bootstr, "arguments=$2;\nwall_time=tic();\ncpu_time=cputime();\n");
  if length(arguments) > 0
    callfuncstr = sprintf("%s(arguments{:})", func_name);
  else
    callfuncstr = sprintf("%s", func_name);
  endif
  if func_nargout > 0
    bootstr = strcat(bootstr, sprintf("[results{1:%i}]=%s;\n", func_nargout, callfuncstr));
  else
    bootstr = strcat(bootstr, sprintf("results={};\n%s;\n", callfuncstr));
  endif
  bootstr = strcat(bootstr, "wall_time=(double(tic())-double(wall_time))*1e-6;\ncpu_time=cputime()-cpu_time;\n");
  bootstr = strcat(bootstr, "condor_ID=${MAKE_CONDOR_JOB_ID};\ncondor_node=\"${MAKE_CONDOR_JOB_NODE}\";\n");
  bootstr = strcat(bootstr, sprintf("save(\"%s\",\"stdres.%s\",\"%s\");\n", ...
                                    strjoin(save_args, "\",\""), save_ext, ...
                                    strjoin({"arguments", "results", ...
                                             "wall_time", "cpu_time", ...
                                             "condor_ID", "condor_node"}, "\",\"")));
  bootstr = strcat(bootstr, "EOF\n");

  ## build Condor arguments string containing Octave function arguments
  argstr = stringify(arguments);
  argstr = strrep(argstr, "'", "''");
  argstr = strrep(argstr, "\"", "\"\"");

  ## build Condor job submit file spec
  job_spec = struct;
  job_spec.universe = "vanilla";
  job_spec.executable = job_boot_file;
  job_spec.arguments = sprintf("\"'$(Cluster)' '%s'\"", argstr);
  job_spec.initialdir = "";
  job_spec.output = "stdout";
  job_spec.error = "stderr";
  job_spec.log = job_log_file;
  job_spec.getenv = "false";
  job_spec.should_transfer_files = "yes";
  job_spec.transfer_input_files = strcat(job_indir, filesep);
  job_spec.when_to_transfer_output = "on_exit";
  job_spec.notification = "never";
  extra_condor = struct(extra_condor{:});
  extra_condor_names = fieldnames(extra_condor);
  for i = 1:length(extra_condor_names)
    extra_condor_name =  extra_condor_names{i};
    if isfield(job_spec, extra_condor_name)
      error("%s: cannot override value of Condor command '%s'", funcName, extra_condor_name);
    endif
    extra_condor_val = extra_condor.(extra_condor_name);
    if !ischar(extra_condor_val)
      error("%s: value of Condor command '%s' must be a string", funcName, extra_condor_name);
    endif
    job_spec.(extra_condor_name) = extra_condor_val;
  endfor

  ## create input directories
  if !mkdir(job_indir)
    error("%s: failed to make directory '%s'", funcName, job_indir);
  endif
  job_inexecdir = fullfile(job_indir, execdir);
  if !mkdir(job_inexecdir)
    error("%s: failed to make directory '%s'", funcName, job_inexecdir);
  endif
  job_infuncdir = fullfile(job_indir, funcdir);
  if !mkdir(job_infuncdir)
    error("%s: failed to make directory '%s'", funcName, job_infuncdir);
  endif

  ## check existence of input files, then copy them to input directories
  copy_files = { ...
                { data_files, job_indir }, ...
                { exec_files, job_inexecdir }, ...
                { shlib_files, job_inexecdir }, ...
                { func_files, job_infuncdir }, ...
                { oct_files, job_infuncdir }, ...
                { class_dirs, job_infuncdir }
                };
  for i = 1:length(copy_files)
    copy_files_i = copy_files{i}{1};
    copy_dir_i = copy_files{i}{2};
    for j = 1:length(copy_files_i)
      copy_files_ij = copy_files_i{j};
      if (exist(copy_files_ij, "file") == 2) || (exist(copy_files_ij, "dir") == 7)
        status = system(sprintf("cp -rH '%s' '%s'", copy_files_ij, copy_dir_i));
        if status != 0
          error("%s: could not copy file/directory '%s' to '%s'", funcName, copy_files_ij, copy_dir_i);
        endif
      else
        error("%s: '%s' is neither a file or a directory", funcName, copy_files_ij);
      endif
    endfor
  endfor

  ## overwrite octapps_gitID.m with static copy of current repository's git ID
  octapps_gitID_file = fullfile(job_infuncdir, "octapps_gitID.m");
  if exist(octapps_gitID_file, "file")
    gitID = octapps_gitID();
    fid = fopen(octapps_gitID_file, "w");
    if fid < 0
      error("%s: could not open file '%s' for writing", funcName, octapps_gitID_file);
    endif
    fprintf(fid, "## generated by %s\n", funcName);
    fprintf(fid, "function ID = octapps_gitID()\n");
    fprintf(fid, "  ID = %s;\n", stringify(gitID));
    fprintf(fid, "endfunction\n");
    fclose(fid);
  endif

  ## write Condor job submit file
  fid = fopen(job_file, "w");
  if fid < 0
    error("%s: could not open file '%s' for writing", funcName, job_file);
  endif
  job_spec_names = sort(fieldnames(job_spec));
  for i = 1:length(job_spec_names)
    fprintf(fid, "%s = %s\n", job_spec_names{i}, job_spec.(job_spec_names{i}));
  endfor
  fprintf(fid, "queue 1\n");
  fclose(fid);

  ## write Condor job bootstrap script, and make it executable
  fid = fopen(job_boot_file, "w");
  if fid < 0
    error("%s: could not open file '%s' for writing", funcName, job_boot_file);
  endif
  fprintf(fid, "#!/bin/sh\n%s", bootstr);
  fclose(fid);
  status = system(sprintf("chmod a+x '%s'", job_boot_file));
  if status != 0
    error("%s: could not make file '%s' executable", job_boot_file);
  endif

endfunction
