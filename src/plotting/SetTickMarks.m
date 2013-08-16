## Copyright (C) 2013 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## Try to generate a given number of ticks on a given axis.
## Usage:
##   SetTickMarks(dim, nticks)
## where
##   dim    = "x"|"y"|"z"
##   nticks = number of ticks to try to generate

function SetTickMarks(dim, nticks)

  ## check input
  assert(length(dim) == 1 && any(dim == "xyz"));
  assert(nticks >= 2);

  ## magic jiggery-pokery to try to find sensible limits and ticks
  lim = r = get(gca, strcat(dim, "lim"));
  d = range(r) / (nticks - 1);
  de = 10^floor(log10(d));
  d = round(d / de) * de;
  r = round(r / d) * d;
  ticks = min(r):d:max(r);
  lim = [min([lim, ticks]), max([lim, ticks])];

  ## set axis limits and ticks
  set(gca, strcat(dim, "lim"), lim, strcat(dim, "tick"), ticks);

endfunction
