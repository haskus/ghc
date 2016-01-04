module Rules.Dependencies (buildPackageDependencies) where

import Base
import Expression
import GHC
import Oracles
import Rules.Actions
import Rules.Generate
import Rules.IntegerGmp
import Rules.Resources
import Settings
import Development.Shake.Util (parseMakefile)

buildPackageDependencies :: Resources -> PartialTarget -> Rules ()
buildPackageDependencies _ target @ (PartialTarget stage pkg) =
    let path      = targetPath stage pkg
        buildPath = path -/- "build"
        dropBuild = (pkgPath pkg ++) . drop (length buildPath)
        hDepFile  = buildPath -/- ".hs-dependencies"
    in do
        [ buildPath ++ "//*.c.deps", buildPath ++ "//*.cmm.deps" ] |%> \out -> do
            -- integerGmp (cbits/wrappers.c) depends on the integerGmp library,
            -- which provides gmp.h
            when (pkg == integerGmp) $ need [integerGmpLibraryH]
            let srcFile = dropBuild . dropExtension $ out
            orderOnly $ generatedDependencies stage pkg
            need [srcFile]
            build $ fullTarget target (GccM stage) [srcFile] [out]

        hDepFile %> \out -> do
            srcs <- interpretPartial target getPackageSources
            orderOnly $ generatedDependencies stage pkg
            need srcs
            if srcs == []
            then writeFileChanged out ""
            else build $ fullTarget target (GhcM stage) srcs [out]
            removeFileIfExists $ out <.> "bak"

        (buildPath -/- ".dependencies") %> \out -> do
            cSrcs <- pkgDataList $ CSrcs path
            let cDepFiles = [ buildPath -/- src <.> "deps" | src <- cSrcs ]
            need $ hDepFile : cDepFiles -- need all for more parallelism
            cDeps <- fmap concat $ mapM readFile' cDepFiles
            hDeps <- readFile' hDepFile
            let result = unlines
                       . map (\(src, deps) -> unwords $ src : deps)
                       . map (bimap unifyPath (map unifyPath))
                       . map (bimap head concat . unzip)
                       . groupBy ((==) `on` fst)
                       . sortBy (compare `on` fst)
                       . parseMakefile $ cDeps ++ hDeps
            writeFileChanged out result
