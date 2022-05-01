
-- taken from RosettaCode
-- http://rosettacode.org/wiki/Hostname#Haskell

module GetHostname where
 
import Foreign.Marshal.Array ( allocaArray0 )
import Foreign.C.Types ( CInt(..), CSize(..) )
import Foreign.C.String ( CString, peekCString )
import Foreign.C.Error ( throwErrnoIfMinus1_ )
 
getHostname :: IO String
getHostname = do
  let size = 256
  allocaArray0 size $ \ cstr -> do
    throwErrnoIfMinus1_ "getHostname" $ c_gethostname cstr (fromIntegral size)
    peekCString cstr

foreign import ccall "gethostname"
  c_gethostname :: CString -> CSize -> IO CInt

