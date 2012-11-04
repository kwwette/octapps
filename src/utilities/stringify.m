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
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{s} =} stringify(@var{x})
##
## Convert an Octave value @var{x} into a string expression, which can be re-used
## as input, i.e. @code{eval(stringify(@var{x}))} should re-create @var{x}.
## @end deftypefn

function s = stringify(x)

  ## switch on the class of x
  switch class(x)

    case "char"
      ## strings: if begins with \0, return literal x, otherwise quoted x
      if x(1) == "\0"
        s = x(2:end);
      else
        s = strcat("\"", x, "\"");
      endif

    case "cell"
      ## cells: create {} expression,
      ## calling stringify() for each element
      s = "{";
      if length(x) > 0
        s = strcat(s, stringify(x{1}));
        for i = 2:length(x)
          s = strcat(s, ",", stringify(x{i}));
        endfor
      endif
      s = strcat(s, "}");

    case "struct"
      ## structs: create struct() expression,
      ## calling stringify() for each field value
      n = fieldnames(x);
      s = "struct(";
      if length(n) > 0
        s = strcat(s, sprintf("\"%s\",%s", n{1}, stringify({x.(n{1})})));
        for i = 2:length(n)
          s = strcat(s, sprintf(",\"%s\",%s", n{i}, stringify({x.(n{i})})));
        endfor
      endif
      s = strcat(s, ")");

    case "function_handle"
      ## functions
      s = func2str(x);

    otherwise
      ## otherwise, try mat2str() for numbers, logical, matrices, etc.
      try
        s = mat2str(x, 17, "class");
      catch
        ## if mat2str() fails, class is not supported
        error("cannot stringify objects of class '%s'", class(x));
      end_try_catch

  endswitch

endfunction

## Test suite:

%!test
%! x = [1 2 3.4; 5.67 8.9 0];
%! assert(isequal(x, eval(stringify(x))));

%!test
%! x = int32([1 2 3 7]);
%! assert(isequal(x, eval(stringify(x))));

%!test
%! x = [true; false];
%! assert(isequal(x, eval(stringify(x))));

%!test
%! x = "A string";
%! assert(isequal(x, eval(stringify(x))));

%!test
%! x = @(y) y*2;
%! assert(x(7) == eval(stringify(x))(7));

%!test
%! x = {1, 2, "three", {4, 5, {6}, true}, 7, false, int16(9)};
%! assert(isequal(x, eval(stringify(x))));

%!test
%! x = struct("Hi","there","where", 2,"cell",{1,2,3,{4*5,6,{7,true}}});
%! assert(isequal(x, eval(stringify(x))));