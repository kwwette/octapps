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
## @deftypefn {} {} octforge_stdnormal_pdf (@var{x})
## For each element of @var{x}, compute the probability density function (PDF)
## at @var{x} of the standard normal distribution
## (mean = 0, standard deviation = 1).
## @end deftypefn

## Author: TT <Teresa.Twaroch@ci.tuwien.ac.at>
## Description: PDF of the standard normal distribution

function pdf = octforge_stdnormal_pdf (x)

  if (nargin != 1)
    print_usage ();
  endif

  if (iscomplex (x))
    error ("stdnormal_pdf: X must not be complex");
  endif

  pdf = (2 * pi)^(- 1/2) * exp (- x .^ 2 / 2);

endfunction


%!shared x,y
%! x = [-Inf 0 1 Inf];
%! y = 1/sqrt(2*pi)*exp (-x.^2/2);
%!assert (octforge_stdnormal_pdf ([x, NaN]), [y, NaN], eps)

## Test class of input preserved
%!assert (octforge_stdnormal_pdf (single ([x, NaN])), single ([y, NaN]), eps ("single"))

## Test input validation
%!error octforge_stdnormal_pdf ()
%!error octforge_stdnormal_pdf (1,2)
%!error octforge_stdnormal_pdf (i)
