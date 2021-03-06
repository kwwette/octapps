## Copyright (C) 2017 Karl Wette
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

## Helper script so that makeCondorJob() can run executables directly.

function condorRunExec(executable, varargin)

  ## convert all arguments into strings
  for i = 1:length(varargin)
    if !ischar(varargin{i})
      if isscalar(varargin{i}) && isreal(varargin{i})
        varargin{i} = sprintf("%.16g", varargin{i});
      elseif islogical(varargin{i})
        varargin{i} = sprintf("%d", varargin{i});
      else
        error("%s: could not convert argument #%i into a string", i);
      endif
    endif
  endfor

  ## terminate Octave and run executable
  exec(executable, varargin);

endfunction
