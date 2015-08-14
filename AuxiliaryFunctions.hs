module AuxiliaryFunctions ( (.+)
                          , (.-)
                          , (.*)
                          , dotProd
                          , crossProd
                          , sqNorm
                          , norm
                          ) where

import GeometricTypes

(.+) :: Vector -> Vector -> Vector
(a,b,c) .+ (d,e,f) = (a+d,b+e,c+f)

(.-) :: Vector -> Vector -> Vector
(a,b,c) .- (d,e,f) = (a-d,b-e,c-f)

(.*) :: Double -> Vector -> Vector
n .* (a,b,c) = (n*a, n*b, n*c)

dotProd :: Vector -> Vector -> Double
dotProd (x,y,z) (x',y',z') = x*x' + y*y' + z*z'

crossProd :: Vector -> Vector -> Vector
crossProd (a,b,c) (d,e,f) = (x,y,z)
  where x = b*f - c*e
        y = c*d - a*f
        z = a*e - b*d

sqNorm :: Vector -> Double
sqNorm x = dotProd x x

norm :: Vector -> Double
norm = sqrt . sqNorm
