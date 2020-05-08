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
## @deftypefn  {} {} octforge_normpdf (@var{x})
## @deftypefnx {} {} octforge_normpdf (@var{x}, @var{mu}, @var{sigma})
## For each element of @var{x}, compute the probability density function (PDF)
## at @var{x} of the normal distribution with mean @var{mu} and
## standard deviation @var{sigma}.
##
## Default values are @var{mu} = 0, @var{sigma} = 1.
## @end deftypefn

## Author: TT <Teresa.Twaroch@ci.tuwien.ac.at>
## Description: PDF of the normal distribution

function pdf = octforge_normpdf (x, mu = 0, sigma = 1)

  if (nargin != 1 && nargin != 3)
    print_usage ();
  endif

  if (! isscalar (mu) || ! isscalar (sigma))
    [retval, x, mu, sigma] = common_size (x, mu, sigma);
    if (retval > 0)
      error ("normpdf: X, MU, and SIGMA must be of common size or scalars");
    endif
  endif

  if (iscomplex (x) || iscomplex (mu) || iscomplex (sigma))
    error ("normpdf: X, MU, and SIGMA must not be complex");
  endif

  if (isa (x, "single") || isa (mu, "single") || isa (sigma, "single"))
    pdf = zeros (size (x), "single");
  else
    pdf = zeros (size (x));
  endif

  if (isscalar (mu) && isscalar (sigma))
    if (isfinite (mu) && (sigma > 0) && (sigma < Inf))
      pdf = octforge_stdnormal_pdf ((x - mu) / sigma) / sigma;
    else
      pdf = NaN (size (x), class (pdf));
    endif
  else
    k = isinf (mu) | !(sigma > 0) | !(sigma < Inf);
    pdf(k) = NaN;

    k = ! isinf (mu) & (sigma > 0) & (sigma < Inf);
    pdf(k) = octforge_stdnormal_pdf ((x(k) - mu(k)) ./ sigma(k)) ./ sigma(k);
  endif

endfunction


%!shared x,y
%! x = [-Inf 1 2 Inf];
%! y = 1/sqrt(2*pi)*exp (-(x-1).^2/2);
%!assert (octforge_normpdf (x, ones (1,4), ones (1,4)), y, eps)
%!assert (octforge_normpdf (x, 1, ones (1,4)), y, eps)
%!assert (octforge_normpdf (x, ones (1,4), 1), y, eps)
%!assert (octforge_normpdf (x, [0 -Inf NaN Inf], 1), [y(1) NaN NaN NaN], eps)
%!assert (octforge_normpdf (x, 1, [Inf NaN -1 0]), [NaN NaN NaN NaN], eps)
%!assert (octforge_normpdf ([x, NaN], 1, 1), [y, NaN], eps)

## Test class of input preserved
%!assert (octforge_normpdf (single ([x, NaN]), 1, 1), single ([y, NaN]), eps ("single"))
%!assert (octforge_normpdf ([x, NaN], single (1), 1), single ([y, NaN]), eps ("single"))
%!assert (octforge_normpdf ([x, NaN], 1, single (1)), single ([y, NaN]), eps ("single"))

## Test input validation
%!error octforge_normpdf ()
%!error octforge_normpdf (1,2)
%!error octforge_normpdf (1,2,3,4)
%!error octforge_normpdf (ones (3), ones (2), ones (2))
%!error octforge_normpdf (ones (2), ones (3), ones (2))
%!error octforge_normpdf (ones (2), ones (2), ones (3))
%!error octforge_normpdf (i, 2, 2)
%!error octforge_normpdf (2, i, 2)
%!error octforge_normpdf (2, 2, i)
