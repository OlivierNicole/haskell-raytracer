module Render ( render
              ) where

import Scene
import Sphere
import Image
import Color
import qualified Data.Matrix as M
import GeometricTypes
import AuxiliaryFunctions
import Renderable
import Data.List (maximumBy,minimumBy)
import Data.Function (on)
import LightSource
import Data.Maybe (isNothing, fromJust, isJust)
import Debug.Trace

minExposure = 0.1
maxReflection = 5
maxRefraction = 5

-- camera is fixed at (0, 0, d) and the screen is orthogonal to the camera and
-- is a rectange centered in origin of size (a, b).
render :: ImageDefinition -> (Double, Double) -> Double -> Scene -> Image
render (w, h) (a, b) d scene = Image $ M.fromList h w $
   map (pointColor scene d 0 0)
      [Ray {origin = cameraPos,
            dir    = (x, y, 0) .- cameraPos,
            refr   = 1} | y <- ordinates, x <- abscissas]
   where
   cameraPos = (0, 0, d)
   abscissas =
     [a * (-0.5 + x / fromIntegral w) | x <- map fromIntegral [0..(w - 1)]]
   ordinates =
     [b * (-0.5 + y / fromIntegral h) | y <- map fromIntegral [(h - 1), (h - 2)..0]]

-- Only the closest intersection to the screen is considered.
pointColor :: Scene -> Double -> Int -> Int -> Ray -> Color
pointColor scene d acc acc' r | acc >= maxReflection || acc' >= maxRefraction || isNothing hit = black
                              | otherwise   =
   darken (op * (1-reflFactor) * max minExposure realExposure) (colorAt p obj) .+
   darken reflFactor reflColor .+
   refrResult
   where
   hit = closestHit (objs scene) r
   (obj, p) = fromJust hit
   n = normalise $ normal obj p
   lightDir = normalise $ direction (source scene)
   cameraPos = (0, 0, d)
   lightRay = Ray {origin = p, dir = lightDir, refr = 1}
   shadow = isJust $ closestHit (objs scene) lightRay
   realExposure =
     if shadow
     then 0
     else max 0 (lightDir `dotProd` n)
   curRefr = refr r
   reflFactor = reflectAt p obj
   reflRay = Ray {origin = p, dir = neg (dir r `sym` n), refr = curRefr}
   reflColor = pointColor scene d (acc + 1) acc' reflRay
   op = opacityAt p obj
   objRefr = refractAt p obj
   iSin = norm (n `crossProd` (dir r)) / ((norm (dir r)) * (norm n))
   refrRatio = curRefr / objRefr
   totRefl = refrRatio * iSin > 1
   rSin = refrRatio * iSin
   refrDir = refrRatio.*(dir r) .+
             ((refrRatio*(sqrt (1 - iSin^2)) - (sqrt (1-rSin^2))).* n)
   refrRay = Ray {origin = p, dir = refrDir, refr = refractAt p obj}
   refrColor = pointColor scene d acc (acc' + 1) refrRay
   refrResult =
     if totRefl
     then black
     else darken ((1 - op) * (1 - reflFactor)) refrColor

closestHit :: [SceneObject] -> Ray -> Maybe (SceneObject, Point)
closestHit objs r
   | null inters = Nothing
   | otherwise   = Just $ minimumBy (compare `on` (distance o . snd)) inters
   where inters = rmNothing $ map (\o -> (o, firstIntersection r o)) objs
         o = origin r

rmNothing :: [(a, Maybe b)] -> [(a, b)]
rmNothing [] = []
rmNothing ((_, Nothing) : xs) = rmNothing xs
rmNothing ((y, Just x) : xs) = (y,x) : rmNothing xs

