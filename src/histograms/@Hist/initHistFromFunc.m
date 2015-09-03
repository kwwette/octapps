## Copyright (C) 2015 Karl Wette
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Initialise a histogram directly from a given function.
## Usage:
##   hgrm = initHistFromFunc(hgrm, F, [xl_1, xh_1], ..., [xl_dim, xh_dim])
## where:
##   hgrm         = histogram class
##   F            = function used to initialise histogram
##   [xl_k, xh_k] = range in dimension 'k' to evaluate 'F' over

function hgrm = initHistFromFunc(hgrm, F, varargin)

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.bins);
  assert(is_function_handle(F));
  assert(length(varargin) == dim, "Number of domain ranges must match histogram dimension");

  ## enlarge histogram to given domain
  hgrm = addDataToHist(hgrm, [cellfun(@min, varargin); cellfun(@max, varargin)]);

  ## restrict histogram to given domain
  hgrm = restrictHist(hgrm, varargin{:});

  ## get histogram bin centre grids
  for k = 1:dim
    xc{k} = histBinGrids(hgrm, k, "centre");
  endfor

  ## set histogram counts to function evaluated at histogram bin centres
  hgrm.counts = feval(F, xc{:});

endfunction


%!test
%!  hgrm = Hist(1, {"lin", "dbin", 0.1});
%!  hgrm = initHistFromFunc(hgrm, @(x) normpdf(x, 1.3, 2.7), [-20, 20]);
%!  assert(abs(meanOfHist(hgrm) - 1.3) < 1e-3);
%!  assert(abs(stdvOfHist(hgrm) - 2.7) < 1e-3);

%!test
%!  hgrm = Hist(2, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1});
%!  hgrm = initHistFromFunc(hgrm, @(x, y) normpdf(x, y, 1.0), [-20, 20], [0, 10]);
%!  assert(abs(meanOfHist(hgrm, 1) - linspace(0.05, 9.95, 100)) < 1e-4);