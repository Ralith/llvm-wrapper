module LLVM.Wrapper.Core
    ( module LLVM.FFI.Core
    -- ** Modules
    , Module
    , moduleCreateWithName
    , withModule

    -- * Types
    , Type

    -- ** Function types
    , functionType

    -- ** Struct types
    , structType
    , structCreateNamed
    , structCreateNamedInContext
    , structSetBody

    -- ** Misc
    , getTypeByName

    -- * Values
    , Value
    , getValueName
    , setValueName
    , getLinkage
    , setLinkage
    
    -- ** Scalar constants
    , constInt
    , constString

    -- ** Globals
    , addGlobal
    , getNamedGlobal
    , buildGlobalString
    , buildGlobalStringPtr

    -- ** Functions
    , addFunction
    , getNamedFunction
    , getParams
    , isTailCall
    , setTailCall
    , getFunctionCallConv
    , setFunctionCallConv
    , getInstructionCallConv
    , setInstructionCallConv

    -- * Basic blocks
    , BasicBlock
    , appendBasicBlock

    -- * Instruction building
    , Builder
    , withBuilder

    -- ** Arithmetic
    , buildAdd
    , buildSub
    , buildMul
    , buildFAdd
    , buildFMul
    , buildFPCast
    , buildFSub
    , buildUDiv
    , buildSDiv
    , buildExactSDiv
    , buildFDiv
    , buildURem
    , buildSRem
    , buildFRem
    , buildShl
    , buildLShr
    , buildAShr
    , buildAnd
    , buildOr
    , buildXor
    , buildNeg
    , buildFNeg
    , buildNot
    , buildNSWMul
    , buildNSWNeg
    , buildNSWSub
    , buildNUWAdd
    , buildNUWMul
    , buildNUWNeg
    , buildNUWSub

    -- ** Memory
    , buildLoad
    , buildStructGEP
    , buildInBoundsGEP
    -- ** Casts
    , buildTrunc
    , buildZExt
    , buildSExt
    , buildFPToUI
    , buildFPToSI
    , buildUIToFP
    , buildSIToFP
    , buildFPTrunc
    , buildFPExt
    , buildPtrToInt
    , buildIntToPtr
    , buildBitCast
    , buildPointerCast
    , buildTruncOrBitCast
    , buildZExtOrBitCast
    , buildSExtOrBitCast

    -- ** Misc
    , buildPhi
    , addIncoming
    , buildCall
    ) where

import Foreign.C.String
import Foreign.C.Types
import Foreign.Marshal.Array
import Foreign.Marshal.Utils
import Foreign.ForeignPtr.Safe
import System.IO.Unsafe (unsafePerformIO)
import Control.Exception
import Control.Monad

import LLVM.FFI.Core
    ( disposeModule
    , dumpModule

    , TypeKind(..)
    , getTypeKind

    , int1Type
    , int8Type
    , int16Type
    , int32Type
    , int64Type
    , integerType
    , getIntTypeWidth

    , floatType
    , doubleType
    , x86FP80Type
    , fp128Type
    , ppcFP128Type

    , arrayType
    , pointerType
    , vectorType
    , voidType
      
    , typeOf
    , dumpValue
    , constNull
    , constPointerNull
    , getUndef
    , constReal

    , Linkage(..)

    , IntPredicate(..)
    , FPPredicate(..)

    , sizeOf
    , constNeg
    , constNot
    , constAdd
    , constSub
    , constMul
    , constExactSDiv
    , constFAdd
    , constFMul
    , constFNeg
    , constFPCast
    , constFSub
    , constUDiv
    , constSDiv
    , constFDiv
    , constURem
    , constSRem
    , constFRem
    , constAnd
    , constOr
    , constXor
    , constICmp
    , constFCmp
    , constShl
    , constLShr
    , constAShr
    , constGEP
    , constTrunc
    , constSExt
    , constZExt
    , constFPTrunc
    , constFPExt
    , constUIToFP
    , constSIToFP
    , constFPToUI
    , constFPToSI
    , constPtrToInt
    , constIntToPtr
    , constBitCast
    , constSelect
    , constExtractElement
    , constInsertElement
    , constShuffleVector
    , constNSWMul
    , constNSWNeg
    , constNSWSub
    , constNUWAdd
    , constNUWMul
    , constNUWNeg
    , constNUWSub

    , getEntryBasicBlock
    , getNextBasicBlock
    , getPreviousBasicBlock
    , getInstructionParent

    , setInstrParamAlignment
    , setParamAlignment

    , createBuilder
    , disposeBuilder
    , positionAtEnd
    , getInsertBlock
    , positionBuilder

    , CallingConvention(..)

    , buildRetVoid
    , buildRet
    , buildBr
    , buildIndirectBr
    , buildCondBr
    , buildSwitch
    , addCase

    , buildStore
    )
import qualified LLVM.FFI.Core as FFI

type Type       = FFI.TypeRef
type Module     = FFI.ModuleRef
type Value      = FFI.ValueRef
type Builder    = FFI.BuilderRef
type BasicBlock = FFI.BasicBlockRef
type Context    = FFI.ContextRef

moduleCreateWithName :: String -> IO Module
moduleCreateWithName name = withCString name FFI.moduleCreateWithName

withModule :: String -> (Module -> IO a) -> IO a
withModule n f = do m <- moduleCreateWithName n
                    finally (f m) (disposeModule m)

getTypeByName :: Module -> String -> IO Type
getTypeByName m name = withCString name $ FFI.getTypeByName m

getValueName :: Value -> IO String
getValueName v = FFI.getValueName v >>= peekCString

setValueName :: Value -> String -> IO ()
setValueName v name = withCString name $ FFI.setValueName v

addGlobal :: Module -> Type -> String -> IO Value
addGlobal m ty name = withCString name $ FFI.addGlobal m ty

getNamedGlobal :: Module -> String -> IO Value
getNamedGlobal m name = withCString name $ FFI.getNamedGlobal m

buildGlobalString :: Builder -> String -> String -> IO Value
buildGlobalString b string name
    = withCString name (\n -> withCString string (\s -> FFI.buildGlobalString b s n))

buildGlobalStringPtr :: Builder -> String -> String -> IO Value
buildGlobalStringPtr b string name
    = withCString name (\n -> withCString string (\s -> FFI.buildGlobalStringPtr b s n))

addFunction :: Module -> String -> Type -> IO Value
addFunction m name ty = withCString name (\n -> FFI.addFunction m n ty)

getNamedFunction :: Module -> String -> IO Value
getNamedFunction m name = withCString name $ FFI.getNamedFunction m

getParams :: Value -> IO [Value]
getParams f
    = do let count = fromIntegral $ FFI.countParams f
         allocaArray count $ \ptr -> do
           FFI.getParams f ptr
           peekArray count ptr

isTailCall :: Value -> IO Bool
isTailCall call = fmap toBool $ FFI.isTailCall call

setTailCall :: Value -> Bool -> IO ()
setTailCall call isTailCall = FFI.setTailCall call $ fromBool isTailCall

getFunctionCallConv :: Value -> IO CallingConvention
getFunctionCallConv f = fmap FFI.toCallingConvention $ FFI.getFunctionCallConv f

setFunctionCallConv :: Value -> CallingConvention -> IO ()
setFunctionCallConv f c = FFI.setFunctionCallConv f $ FFI.fromCallingConvention c

getInstructionCallConv :: Value -> IO CallingConvention
getInstructionCallConv f = fmap FFI.toCallingConvention $ FFI.getInstructionCallConv f

setInstructionCallConv :: Value -> CallingConvention -> IO ()
setInstructionCallConv f c = FFI.setInstructionCallConv f $ FFI.fromCallingConvention c

-- unsafePerformIO just to wrap the non-effecting withArrayLen call
functionType :: Type -> [Type] -> Bool -> Type
functionType returnTy argTys isVarArg
    = unsafePerformIO $ withArrayLen argTys $ \len ptr ->
      return $ FFI.functionType returnTy ptr (fromIntegral len) (fromBool isVarArg)

-- unsafePerformIO just to wrap the non-effecting withArrayLen call
structType :: [Type] -> Bool -> Type
structType types packed = unsafePerformIO $
    withArrayLen types $ \ len ptr ->
        return $ FFI.structType ptr (fromIntegral len) (fromBool packed)

structCreateNamed :: String -> IO Type
structCreateNamed name
    = do ctx <- FFI.getGlobalContext
         structCreateNamedInContext ctx name

structCreateNamedInContext :: Context -> String -> IO Type
structCreateNamedInContext ctx name = withCString name $ FFI.structCreateNamed ctx

structSetBody :: Type -> [Type] -> Bool -> IO ()
structSetBody struct body packed
    = withArrayLen body $ \len ptr ->
      FFI.structSetBody struct ptr (fromIntegral len) $ fromBool packed

appendBasicBlock :: Value -> String -> IO BasicBlock
appendBasicBlock function name = withCString name $ FFI.appendBasicBlock function

getLinkage :: Value -> IO Linkage
getLinkage v = fmap FFI.toLinkage $ FFI.getLinkage v

setLinkage :: Value -> Linkage -> IO ()
setLinkage v l = FFI.setLinkage v (FFI.fromLinkage l)

constInt :: Type -> CULLong -> Bool -> Value
constInt ty val signExtend = FFI.constInt ty val $ fromBool signExtend

-- unsafePerformIO just to wrap the non-effecting withCStringLen call
constString :: String -> Bool -> Value
constString str dontNullTerminate
    = unsafePerformIO $ withCStringLen str $ \(ptr, len) ->
      return $ FFI.constString ptr (fromIntegral len) $ fromBool dontNullTerminate

withBuilder :: (Builder -> IO a) -> IO a
withBuilder f = do p <- createBuilder
                   finally (f p) (disposeBuilder p)

wrapBin :: (Builder -> Value -> Value -> CString -> IO Value) ->
            Builder -> Value -> Value -> String  -> IO Value
wrapBin f b x y name = withCString name $ f b x y

buildAdd       = wrapBin FFI.buildAdd
buildSub       = wrapBin FFI.buildSub
buildMul       = wrapBin FFI.buildMul
buildNSWAdd    = wrapBin FFI.buildNSWAdd
buildNSWSub    = wrapBin FFI.buildNSWSub
buildNSWMul    = wrapBin FFI.buildNSWMul
buildNUWAdd    = wrapBin FFI.buildNUWAdd
buildNUWSub    = wrapBin FFI.buildNUWSub
buildNUWMul    = wrapBin FFI.buildNUWMul
buildUDiv      = wrapBin FFI.buildUDiv
buildSDiv      = wrapBin FFI.buildSDiv
buildExactSDiv = wrapBin FFI.buildExactSDiv
buildURem      = wrapBin FFI.buildURem
buildSRem      = wrapBin FFI.buildSRem
buildFAdd      = wrapBin FFI.buildFAdd
buildFSub      = wrapBin FFI.buildFSub
buildFMul      = wrapBin FFI.buildFMul
buildFDiv      = wrapBin FFI.buildFDiv
buildFRem      = wrapBin FFI.buildFRem
buildShl       = wrapBin FFI.buildShl
buildLShr      = wrapBin FFI.buildLShr
buildAShr      = wrapBin FFI.buildAShr
buildAnd       = wrapBin FFI.buildAnd
buildOr        = wrapBin FFI.buildOr
buildXor       = wrapBin FFI.buildXor

wrapUn :: (Builder -> Value -> CString -> IO Value) ->
           Builder -> Value -> String  -> IO Value
wrapUn f b v name = withCString name $ f b v

buildNeg    = wrapUn FFI.buildNeg
buildFNeg   = wrapUn FFI.buildFNeg
buildNot    = wrapUn FFI.buildNot
buildNSWNeg = wrapUn FFI.buildNSWNeg
buildNUWNeg = wrapUn FFI.buildNUWNeg

buildICmp :: Builder -> IntPredicate -> Value -> Value -> String -> IO Value
buildICmp b p l r n = withCString n $ FFI.buildICmp b (FFI.fromIntPredicate p) l r

buildFCmp :: Builder -> FPPredicate -> Value -> Value -> String -> IO Value
buildFCmp b p l r n = withCString n $ FFI.buildFCmp b (FFI.fromFPPredicate p) l r

buildLoad :: Builder -> Value -> String -> IO Value
buildLoad b ptr name = withCString name $ FFI.buildLoad b ptr

buildStructGEP :: Builder -> Value -> CUInt -> String -> IO Value
buildStructGEP b s idx name = withCString name $ FFI.buildStructGEP b s idx

buildInBoundsGEP :: Builder -> Value -> [Value] -> String -> IO Value
buildInBoundsGEP b ptr indices name
    = withArrayLen indices $ \len indicesPtr ->
      withCString name $ FFI.buildInBoundsGEP b ptr indicesPtr $ fromIntegral len

wrapCast :: (Builder -> Value -> Type -> CString -> IO Value) ->
             Builder -> Value -> Type -> String  -> IO Value
wrapCast f b v t name = withCString name $ f b v t

buildTrunc          = wrapCast FFI.buildTrunc
buildZExt           = wrapCast FFI.buildZExt
buildSExt           = wrapCast FFI.buildSExt
buildFPToUI         = wrapCast FFI.buildFPToUI
buildFPToSI         = wrapCast FFI.buildFPToSI
buildUIToFP         = wrapCast FFI.buildUIToFP
buildSIToFP         = wrapCast FFI.buildSIToFP
buildFPTrunc        = wrapCast FFI.buildFPTrunc
buildFPExt          = wrapCast FFI.buildFPExt
buildPtrToInt       = wrapCast FFI.buildPtrToInt
buildIntToPtr       = wrapCast FFI.buildIntToPtr
buildBitCast        = wrapCast FFI.buildBitCast
buildPointerCast    = wrapCast FFI.buildPointerCast
buildTruncOrBitCast = wrapCast FFI.buildTruncOrBitCast
buildZExtOrBitCast  = wrapCast FFI.buildZExtOrBitCast
buildSExtOrBitCast  = wrapCast FFI.buildSExtOrBitCast
buildFPCast         = wrapCast FFI.buildFPCast

buildPhi :: Builder -> Type -> String -> IO Value
buildPhi b ty name = withCString name $ FFI.buildPhi b ty

addIncoming :: Value -> [(Value, BasicBlock)] -> IO ()
addIncoming phi incoming
    = withArrayLen (map fst incoming) $ \len valPtr ->
      withArray (map snd incoming) $ \blockPtr ->
      FFI.addIncoming phi valPtr blockPtr (fromIntegral len)

buildCall :: Builder -> Value -> [Value] -> String -> IO Value
buildCall b f args name
    = withArrayLen args $ \len ptr ->
      withCString name $ FFI.buildCall b f ptr (fromIntegral len)

