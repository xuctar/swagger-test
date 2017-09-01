module Test.Swagger.Request (doHttpRequest) where

import           Control.Arrow
import qualified Data.ByteString.Lazy as LBS
import           Data.CaseInsensitive
import           Data.Maybe
import           Data.Monoid
import qualified Data.Text            as T
import           Data.Text.Encoding
import           Network.HTTP.Client
import           Network.HTTP.Types
import Network.HTTP.Client.TLS
import           Test.Swagger.Types   hiding (requestBody, requestHeaders,
                                       responseBody, responseHeaders,
                                       responseStatus)

doHttpRequest :: HttpRequest -> IO HttpResponse
doHttpRequest req = do manager <- getGlobalManager
                       res <- httpLbs (transformReq req) manager
                       pure $ transformRes res

transformReq :: HttpRequest -> Request
transformReq (HttpRequest h m p query headers body) =
    (parseRequest_ url) { method=m, requestHeaders=headers', requestBody=RequestBodyLBS body' }
  where
    url = host' <> T.unpack (p <> decodeUtf8 (renderQuery True $ queryTextToQuery query))
    host' = fromMaybe "http://localhost" h
    headers' = (mk . encodeUtf8 . original *** encodeUtf8) <$> headers
    body' = fromMaybe mempty body

transformRes :: Response LBS.ByteString -> HttpResponse
transformRes r = HttpResponse (responseVersion r)
                              (responseStatus r)
                              headers'
                              (Just $ responseBody r)
 where
    headers' = (mk . decodeUtf8 . original *** decodeUtf8) <$> responseHeaders r