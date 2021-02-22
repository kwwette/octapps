## Copyright (C) 2012 Rik Wehbring
## Copyright (C) 1995-2016 Kurt Hornik
##
## This program is free software: you can redistribute it and/or
## modify it under the terms of the GNU General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {} {} octforge_stdnormal_cdf (@var{x})
## For each element of @var{x}, compute the cumulative distribution function
## (CDF) at @var{x} of the standard normal distribution
## (mean = 0, standard deviation = 1).
## @end deftypefn

## Author: KH <Kurt.Hornik@wu-wien.ac.at>
## Description: CDF of the standard normal distribution

function cdf = octforge_stdnormal_cdf (x)

  if (nargin != 1)
    print_usage ();
  endif

  if (iscomplex (x))
    error ("stdnormal_cdf: X must not be complex");
  endif

  cdf = erfc (x / (-sqrt(2))) / 2;

endfunction


%!shared x,y
%! x = [-Inf 0 1 Inf];
%! y = [0, 0.5, 1/2*(1+erf(1/sqrt(2))), 1];
%!assert (octforge_stdnormal_cdf ([x, NaN]), [y, NaN])

## Test class of input preserved
%!assert (octforge_stdnormal_cdf (single ([x, NaN])), single ([y, NaN]), eps ("single"))

## Test input validation
%!error octforge_stdnormal_cdf ()
%!error octforge_stdnormal_cdf (1,2)
%!error octforge_stdnormal_cdf (i)
