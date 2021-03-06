{-# OPTIONS_GHC -Wall #-}
module HW04 where

import Data.List

newtype Poly a = P [a]

-- Exercise 1 -----------------------------------------

x :: Num a => Poly a
x = P [0,1]

-- Exercise 2 ----------------------------------------

instance (Num a, Eq a) => Eq (Poly a) where
    (==) (P f1) (P f2) = (dropWhileEnd (==0) f1) == (dropWhileEnd (==0) f2)

-- Exercise 3 -----------------------------------------

instance (Num a, Eq a, Show a) => Show (Poly a) where
    show (P f) = concat . intersperse " + " . reverse $ toTerms f

toTerms :: (Num a, Eq a, Show a) => [a]-> [String]
toTerms a = filter (\t -> t /= "0" && (not . null $ t)) . map toTerm $ zipWithIndex a

zipWithIndex :: [a] -> [(Int, a)]
zipWithIndex = zip [0,1..]

toTerm :: (Num a, Eq a, Show a) => (Int, a) -> String
toTerm (0, c)  = show c
toTerm (_, 0)  = ""
toTerm (1, 1)  = "x"
toTerm (1, -1) = "-x"
toTerm (1, c)  = show c ++ "x"
toTerm (d, 1)  = "x"    ++ "^" ++ show d
toTerm (d, -1) = "-x"   ++ "^" ++ show d
toTerm (d, c)  = show c ++ "x" ++ "^" ++ show d

-- Exercise 4 -----------------------------------------

plus :: Num a => Poly a -> Poly a -> Poly a
plus (P a) (P b) = P (rewrite a b)

rewrite ::Num a => [a] -> [a] -> [a]
rewrite ys zs
    | length ys == length zs = zipWith (+) ys zs
    | length ys > length zs = rewrite ys (zs ++ [0])
    | otherwise = rewrite (ys ++ [0]) zs

-- Exercise 5 -----------------------------------------

times :: Num a => Poly a -> Poly a -> Poly a
times (P y) (P z) = foldr (+) (P [0]) $ termTimes y z

termTimes :: Num a => [a] -> [a] -> [Poly a]
termTimes (y:ys) zs = P (map (*y) zs) : termTimes ys (0:zs)
termTimes [] _ = []

-- Exercise 6 -----------------------------------------

instance Num a => Num (Poly a) where
    (+) = plus
    (*) = times
    negate (P zs)     = P (map negate zs)
    fromInteger i = P [(fromInteger i)]
    -- No meaningful definitions exist
    abs    = undefined
    signum = undefined

-- Exercise 7 -----------------------------------------

applyP :: Num a => Poly a -> a -> a
applyP (P (z:zs)) v = v^(length zs) * z + applyP (P zs) v
applyP (P []) _ = 0


-- Exercise 8 -----------------------------------------

-- Differentiation is the action of computing a derivative
-- Deriative means "Đạo Hàm" - Tốc độ biến thiên của f(x) theo x
class Num a => Differentiable a where
    deriv  :: a -> a
    nderiv :: Int -> a -> a
    nderiv n 
        | n > 0 = nderiv (n-1) . deriv
        | otherwise = id

-- Exercise 9 -----------------------------------------

instance Num a => Differentiable (Poly a) where
    deriv (P z) = P . termDeriv . reverse $ tail z

termDeriv :: (Num a) => [a] -> [a]
termDeriv [] = []
termDeriv (z:zs) = termDeriv zs ++ z * fromIntegral (length $ z:zs):[]

--thanks to https://github.com/amar47shah/cis-194/tree/master/2015-noamz