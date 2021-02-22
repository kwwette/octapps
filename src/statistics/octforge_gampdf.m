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
## @deftypefn {} {} octforge_gampdf (@var{x}, @var{a}, @var{b})
## For each element of @var{x}, return the probability density function
## (PDF) at @var{x} of the Gamma distribution with shape parameter @var{a} and
## scale @var{b}.
## @end deftypefn

## Author: TT <Teresa.Twaroch@ci.tuwien.ac.at>
## Description: PDF of the Gamma distribution

function pdf = octforge_gampdf (x, a, b)

  if (nargin != 3)
    print_usage ();
  endif

  if (! isscalar (a) || ! isscalar (b))
    [retval, x, a, b] = common_size (x, a, b);
    if (retval > 0)
      error ("gampdf: X, A, and B must be of common size or scalars");
    endif
  endif

  if (iscomplex (x) || iscomplex (a) || iscomplex (b))
    error ("gampdf: X, A, and B must not be complex");
  endif

  if (isa (x, "single") || isa (a, "single") || isa (b, "single"))
    pdf = zeros (size (x), "single");
  else
    pdf = zeros (size (x));
  endif

  k = !(a > 0) | !(b > 0) | isnan (x);
  pdf(k) = NaN;

  k = (x >= 0) & (a > 0) & (a <= 1) & (b > 0);
  if (isscalar (a) && isscalar (b))
    pdf(k) = (x(k) .^ (a - 1)) ...
              .* exp (- x(k) / b) / gamma (a) / (b ^ a);
  else
    pdf(k) = (x(k) .^ (a(k) - 1)) ...
              .* exp (- x(k) ./ b(k)) ./ gamma (a(k)) ./ (b(k) .^ a(k));
  endif

  k = (x >= 0) & (a > 1) & (b > 0);
  if (isscalar (a) && isscalar (b))
    pdf(k) = exp (- a * log (b) + (a-1) * log (x(k))
                  - x(k) / b - gammaln (a));
  else
    pdf(k) = exp (- a(k) .* log (b(k)) + (a(k)-1) .* log (x(k))
                  - x(k) ./ b(k) - gammaln (a(k)));
  endif

endfunction


%!shared x,y
%! x = [-1 0 0.5 1 Inf];
%! y = [0 exp(-x(2:end))];
%!assert (octforge_gampdf (x, ones (1,5), ones (1,5)), y)
%!assert (octforge_gampdf (x, 1, ones (1,5)), y)
%!assert (octforge_gampdf (x, ones (1,5), 1), y)
%!assert (octforge_gampdf (x, [0 -Inf NaN Inf 1], 1), [NaN NaN NaN NaN y(5)])
%!assert (octforge_gampdf (x, 1, [0 -Inf NaN Inf 1]), [NaN NaN NaN 0 y(5)])
%!assert (octforge_gampdf ([x, NaN], 1, 1), [y, NaN])

## Test class of input preserved
%!assert (octforge_gampdf (single ([x, NaN]), 1, 1), single ([y, NaN]))
%!assert (octforge_gampdf ([x, NaN], single (1), 1), single ([y, NaN]))
%!assert (octforge_gampdf ([x, NaN], 1, single (1)), single ([y, NaN]))

## Test input validation
%!error octforge_gampdf ()
%!error octforge_gampdf (1)
%!error octforge_gampdf (1,2)
%!error octforge_gampdf (1,2,3,4)
%!error octforge_gampdf (ones (3), ones (2), ones (2))
%!error octforge_gampdf (ones (2), ones (3), ones (2))
%!error octforge_gampdf (ones (2), ones (2), ones (3))
%!error octforge_gampdf (i, 2, 2)
%!error octforge_gampdf (2, i, 2)
%!error octforge_gampdf (2, 2, i)
