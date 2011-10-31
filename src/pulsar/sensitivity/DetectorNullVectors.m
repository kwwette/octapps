## Copyright (C) 2011 Karl Wette
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

## Calculate the vectors along which an interferometric detector
## is insensitive to gravitational waves
## Syntax:
##   [a, b] = DetectorNullVectors(Phis, slambda, gamma)
## where:
##   a,b     = detector null vectors in equatorial coordinates
##   Phis    = local sidereal time at the detector
##   slambda = sine of the detector's latitude
##   gamma   = detector orientation in radians

function [a, b] = DetectorNullVectors(Phis, slambda, gamma)

  ## make inputs the same size
  [err, Phis, slambda, gamma] = common_size(Phis, slambda, gamma);
  if err > 0
    error("%s: Phis, slambda, and gamma are not of common size", funcName);
  endif

  ## make inputs row vectors
  Phis = Phis(:)';
  slambda = slambda(:)';
  gamma = gamma(:)';

  ## cosine and sine terms of detector vectors
  c1 = sin(gamma);              # cos(pi/2 - gamma)
  s1 = cos(gamma);              # sin(pi/2 - gamma)
  c2 = slambda;                 # cos(lambda - pi/2)
  s2 = -sqrt(1 - slambda.^2);   # sin(lambda - pi/2)
  c3 = -sin(Phis);              # cos(-Phis - pi/2)
  s3 = -cos(Phis);              # sin(-Phis - pi/2)

  ## detector vectors
  a = [ c1.*c3 - c2.*s1.*s3; -c1.*s3 - c2.*c3.*s1;  s1.*s2 ];
  b = [ c3.*s1 + c1.*c2.*s3; -s1.*s3 + c1.*c2.*c3; -c1.*s2 ];

endfunction