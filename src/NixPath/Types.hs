module NixPath.Types where

import Data.List (sort)
import Network.Types hiding (HEAD)

data NixPath = RootPath NixPathTarget
             | PrefixPath String NixPathTarget
             deriving (Show)

data NixPathTarget = BasicPath String
                   | GitPath URI GitRev
                   | FetchedGitPath FilePath URI GitRev
                   | PathRef FilePath

data GitRev = GitCommit String | HEAD | GitRef String String

data CacheDirs = CacheDirs { cdGit :: FilePath
                           , cdWts :: FilePath
                           , cdLinks :: FilePath
                           , cdTmp :: FilePath
                           }

instance Show NixPathTarget where
  show (BasicPath p) = concat ["\"", p, "\""]
  show (GitPath uri rev) = concat ["\"", uriToString uri, " ", show rev, "\""]
  show (FetchedGitPath _ uri rev) = show (GitPath uri rev)
  show (PathRef p) = concat ["<", p, ">"]

instance Show GitRev where
  show (GitCommit sha) = sha
  show HEAD = "HEAD"
  show (GitRef key val) = key ++ "/" ++ val

nixPathsToNixExpr :: [NixPath] -> String
nixPathsToNixExpr paths = unlines $ "{" : (sort showedPaths) ++ ["}"]
  where showedPaths = [ showPath k p | PrefixPath k p <- paths ]
        showPath k p = concat ["  \"", k, "\" = ", show p, ";"]

uriToString :: URI -> String
uriToString uri
  | uriScheme uri == "file" = uriPath uri
  | otherwise = concat
    [ uriScheme uri
    , "://"
    , maybe "" mkAuth (uriAuthority uri)
    , uriPath uri
    , maybeString ('?':) (uriQuery uri)
    , maybeString ('#':) (uriFragment uri)
    ]
  where maybeString _ "" = ""
        maybeString f s = f s
        mkAuth auth = concat
          [ maybeString (++"@") (uriUserInfo auth)
          , uriRegName auth
          , maybeString (':':) (uriPort auth)
          ]
