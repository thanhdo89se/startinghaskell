{-# LANGUAGE OverloadedStrings #-}

module CrossWar where

import Authenticator    
import Injector
import PacketGenerator
import Parser hiding (encode, decode)
import Serializer (hexDeserialize)
import qualified Data.ByteString.Char8 as C
import Data.ByteString (ByteString)
import Data.ByteString.Base16
import Network.Socket hiding (send, recv)
import Network.Socket.ByteString (recv, sendAll)
import Control.Monad
import Control.Concurrent

main :: IO ()
main = do match <- getMatch "1"
          winBet match
          loseBet match

---------------------------------------------------------
-- the last 1000 xu should bet 10 times 100xu
bet :: Integer -> Integer -> Socket -> ByteString -> IO ()
bet 0 lim c idx = bet lim lim c idx
bet 1 lim c idx = sendNTimes 10 c (bet100 idx)
bet n lim c idx
    | n > lim = bet lim lim c idx
    | otherwise = do sendNTimes (n - 1) c (bet1000 idx)
                     bet 1 lim c idx

-- buff players will lose money                 
loseBet :: Match -> IO ()
loseBet m = do pls <- buffPls
               forM_ pls $ \u -> forkIO $ do
                   conn <- joinWorld u
                   msg <- recv conn 80
                   bet (amount u) (div (coinInfo msg) 1000) conn (C.pack $ lose m)

-- players will win money
winBet :: Match -> IO ()
winBet m = do pls <- players
              forM_ pls $ \u -> forkIO $ do
                  conn <- joinWorld u
                  msg <- recv conn 80
                  bet (amount u) (div (coinInfo msg) 1000) conn (C.pack $ win m)


---------------------------------------------------------
flower :: String -> IO ()
flower idx = do
    pls <- buffPls
    forM_ pls $ \p -> do
        conn <- joinWorld p
        threadDelay 480000
        msg <- recv conn 2048
        sendAll conn $ cwarflower (C.pack idx) (C.pack $ show $ flowerInfo msg)

---------------------------------------------------------
-- looking coin info, get 80 bytes from socket after join and return number of coin
coinInfo :: ByteString -> Integer
coinInfo msg = hexDeserialize . C.drop 152 $ encode msg

-- looking flower info, 6405 is item code
flowerInfo :: ByteString -> Integer
flowerInfo msg = hexDeserialize . C.drop 24 . C.take 28 . snd . C.breakSubstring "6405" $ encode msg

info :: IO ()
info = do
    pls <- buffPls
    forM_ pls $ \p -> forkIO $ do
        uServer <- getServerInfo (defaultsid p)
        sock <- connect_ (ip uServer) (port uServer)
        sendAll sock $ loginData p (C.pack $ defaultsid p)
        msg <- recv sock 256
        sendAll sock $ enterW (C.pack $ uid p) (C.pack $ chNumber p)
        msg <- recv sock 80
        threadDelay 480000
        msg2 <- recv sock 2048
        C.putStrLn $ C.append (C.pack $ acc p) 
                   $ C.append ", coin: " 
                   $ C.append (C.pack $ show $ coinInfo msg)
                   $ C.append ", flower: " (C.pack $ show $ flowerInfo msg2)
        close sock

---------------------------------------------------------
reward :: IO ()
reward = do
    pls <- buffPls
    forM_ pls $ \p -> forkIO $ do
        conn <- joinWorld p
        forM_ (map (C.pack . show) [51..65]) $ \r -> do
            sendAll conn (cwarReward r)