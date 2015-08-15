module Render ( render
              ) where

import Scene
import Sphere
import Image
import Pixel
import qualified Data.Matrix as M
import GeometricTypes
import AuxiliaryFunctions
import Renderable
import Data.List (maximumBy)
import Data.Function (on)
import LightSource

minimalExposure = 0.05

-- camera is fixed at (0, 0, d) and the screen is orthogonal to the camera and
-- is a rectange centered in origin of size (a, b).
render :: ImageDefinition -> (Double, Double) -> Double -> Scene -> Image
render (w, h) (a, b) d scene = Image $ M.fromList w h $
   map (pointColor scene d)
      [Ray {origin = cameraPos,
            dir    = (x, y, 0) .- cameraPos} | y <- ordinates, x <- abscissas]
   where
   cameraPos = (0, 0, d)
   abscissas = [a * (-0.5 + x / fromIntegral w) | x <- map fromIntegral [0..(w - 1)]]
   ordinates = [b * (-0.5 + y / fromIntegral h) | y <- map fromIntegral [(h - 1), (h - 2)..0]]

-- Only the closest intersection to the screen is considered.
pointColor :: Scene -> Double -> Ray -> Pixel
pointColor scene d r | null inters = black
                     | otherwise   = lighten (max minimalExposure (lightDir `dotProd` n)) white
   where inters = concatMap (\o -> map ((,) o) (intersections r o)) (objs scene)
         (closestObj, closestPt) = maximumBy
            (compare `on` (distance cameraPos . snd)) inters
         n = normalise $ dir $ normal closestObj closestPt
         lightDir = normalise $ direction (source scene)
         cameraPos = (0, 0, d)

