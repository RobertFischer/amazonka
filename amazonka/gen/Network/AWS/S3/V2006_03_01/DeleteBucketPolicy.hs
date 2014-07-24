{-# LANGUAGE DeriveGeneric               #-}
{-# LANGUAGE FlexibleInstances           #-}
{-# LANGUAGE OverloadedStrings           #-}
{-# LANGUAGE RecordWildCards             #-}
{-# LANGUAGE TypeFamilies                #-}

{-# OPTIONS_GHC -fno-warn-unused-imports #-}

-- Module      : Network.AWS.S3.V2006_03_01.DeleteBucketPolicy
-- Copyright   : (c) 2013-2014 Brendan Hay <brendan.g.hay@gmail.com>
-- License     : This Source Code Form is subject to the terms of
--               the Mozilla Public License, v. 2.0.
--               A copy of the MPL can be found in the LICENSE file or
--               you can obtain it at http://mozilla.org/MPL/2.0/.
-- Maintainer  : Brendan Hay <brendan.g.hay@gmail.com>
-- Stability   : experimental
-- Portability : non-portable (GHC extensions)

-- | Deletes the policy from the bucket.
module Network.AWS.S3.V2006_03_01.DeleteBucketPolicy where

import           Control.Applicative
import           Data.ByteString      (ByteString)
import           Data.Default
import           Data.HashMap.Strict  (HashMap)
import           Data.Maybe
import           Data.Monoid
import           Data.Text            (Text)
import qualified Data.Text            as Text
import           GHC.Generics
import           Network.AWS.Data
import           Network.AWS.Response
import           Network.AWS.Types    hiding (Error)
import           Network.AWS.Request.RestS3
import           Network.AWS.S3.V2006_03_01.Types
import           Network.HTTP.Client  (RequestBody, Response)
import           Prelude              hiding (head)

-- | Default DeleteBucketPolicy request.
deleteBucketPolicy :: BucketName -- ^ '_dbprBucket'
                   -> DeleteBucketPolicy
deleteBucketPolicy p1 = DeleteBucketPolicy
    { _dbprBucket = p1
    }

data DeleteBucketPolicy = DeleteBucketPolicy
    { _dbprBucket :: BucketName
    } deriving (Generic)

instance ToPath DeleteBucketPolicy where
    toPath DeleteBucketPolicy{..} = mconcat
        [ "/"
        , toBS _dbprBucket
        ]

instance ToQuery DeleteBucketPolicy

instance ToHeaders DeleteBucketPolicy

instance ToBody DeleteBucketPolicy

instance AWSRequest DeleteBucketPolicy where
    type Sv DeleteBucketPolicy = S3
    type Rs DeleteBucketPolicy = DeleteBucketPolicyResponse

    request = delete

    response _ _ = return (Right DeleteBucketPolicyResponse)

data DeleteBucketPolicyResponse = DeleteBucketPolicyResponse
    deriving (Eq, Show, Generic)
