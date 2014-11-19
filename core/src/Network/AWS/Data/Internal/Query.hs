{-# LANGUAGE DefaultSignatures   #-}
{-# LANGUAGE DeriveDataTypeable  #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE TypeFamilies        #-}
{-# LANGUAGE TypeOperators       #-}

-- Module      : Network.AWS.Data.Internal.Query
-- Copyright   : (c) 2013-2014 Brendan Hay <brendan.g.hay@gmail.com>
-- License     : This Source Code Form is subject to the terms of
--               the Mozilla Public License, v. 2.0.
--               A copy of the MPL can be found in the LICENSE file or
--               you can obtain it at http://mozilla.org/MPL/2.0/.
-- Maintainer  : Brendan Hay <brendan.g.hay@gmail.com>
-- Stability   : experimental
-- Portability : non-portable (GHC extensions)

module Network.AWS.Data.Internal.Query
    ( ToQuery (..)
    , renderQuery

    , Query
    , keysOf
    , valuesOf

    , pair
    , (=?)
    ) where

import           Control.Applicative
import           Control.Lens                         hiding (to, from)
import           Data.ByteString                      (ByteString)
import qualified Data.ByteString.Char8                as BS
import           Data.Data
import           Data.Data.Lens
import           Data.List                            (sort)
import           Data.Monoid
import           Data.String
import           Data.Text                            (Text)
import qualified Data.Text.Encoding                   as Text
import           Network.AWS.Data.Internal.ByteString
import           Network.AWS.Data.Internal.Text
import           Numeric.Natural

data Query
    = List  [Query]
    | Pair  ByteString Query
    | Value (Maybe ByteString)
      deriving (Eq, Show, Data, Typeable)

makePrisms ''Query

instance Monoid Query where
    mempty = List []

    mappend a b = case (a, b) of
        (List l, List r) -> List (l ++ r)
        (List l, r)      -> List (r : l)
        (l,      List r) -> List (l : r)
        (l,      r)      -> List [l, r]

instance Plated Query where
    plate = uniplate

instance ToByteString Query where
    toBS = renderQuery

instance ToText Query where
    toText = Text.decodeUtf8 . renderQuery

instance IsString Query where
    fromString = toQuery . BS.pack

keysOf :: Traversal' Query ByteString
keysOf = deep (_Pair . _1)

valuesOf :: Traversal' Query (Maybe ByteString)
valuesOf = deep _Value

pair :: ToQuery a => ByteString -> a -> Query -> Query
pair k v = mappend (Pair k (toQuery v))

(=?) :: ToQuery a => ByteString -> a -> Query
(=?) k v = Pair k (toQuery v)

renderQuery :: Query -> ByteString
renderQuery = intercalate . sort . enc Nothing
  where
    enc k (List xs)   = concatMap (enc k) xs
    enc k (Pair k' x)
        | Just n <- k = enc (Just $ n <> "." <> k') x
        | otherwise   = enc (Just k') x
    enc k (Value (Just v))
        | Just n <- k = [n <> vsep <> v]
        | otherwise   = [v]
    enc k _
        | Just n <- k = [n]
        | otherwise   = []

    intercalate []     = mempty
    intercalate [x]    = x
    intercalate (x:xs) = x <> ksep <> intercalate xs

    ksep = "&"
    vsep = "="

class ToQuery a where
    toQuery :: a -> Query

instance ToQuery Query where
    toQuery = id

instance (ToByteString k, ToQuery v) => ToQuery (k, v) where
    toQuery (k, v) = Pair (toBS k) (toQuery v)

instance (ToByteString k, ToByteString v) => ToQuery (k, Maybe v) where
    toQuery (k, v) = Pair (toBS k) . Value $ toBS <$> v

instance ToQuery Char where
    toQuery = toQuery . BS.singleton

instance ToQuery ByteString where
    toQuery "" = Value Nothing
    toQuery bs = Value (Just bs)

instance ToQuery Text    where toQuery = toQuery . toBS
instance ToQuery Int     where toQuery = toQuery . toBS
instance ToQuery Integer where toQuery = toQuery . toBS
instance ToQuery Double  where toQuery = toQuery . toBS
instance ToQuery Natural where toQuery = toQuery . toBS

instance ToQuery a => ToQuery [a] where
    toQuery = List . zipWith (\n v -> Pair (toBS n) (toQuery v)) idx
      where
        idx = [1..] :: [Integer]

instance ToQuery a => ToQuery (Maybe a) where
    toQuery (Just x) = toQuery x
    toQuery Nothing  = mempty

instance ToQuery Bool where
    toQuery True  = toQuery ("true"  :: ByteString)
    toQuery False = toQuery ("false" :: ByteString)
