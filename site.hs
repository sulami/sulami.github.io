--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid          (mappend)
import           Hakyll
import           Text.Pandoc
import           Text.Pandoc.SideNote (usingSideNotes)


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "raw/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "tufte/et-book/*/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "tufte/tufte.css" $ do
        route   idRoute
        compile compressCssCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "pages/*" $ do
        route   $ setExtension "html"
        compile $ pandocCompilerWithTransform defaultHakyllReaderOptions defaultHakyllWriterOptions usingSideNotes
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompilerWithTransform defaultHakyllReaderOptions defaultHakyllWriterOptions usingSideNotes
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- take 5 <$> (recentFirst =<< loadAll "posts/*")
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler

    create ["atom.xml"] $ do
        route idRoute
        compile $ do
            posts <- take 10 <$> (recentFirst =<< loadAll "posts/*")
            let feedCtx = postCtx `mappend` constField "description" "Description"

            renderAtom atomFeedConfiguration feedCtx posts


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

atomFeedConfiguration :: FeedConfiguration
atomFeedConfiguration = FeedConfiguration
  { feedTitle = "sulami's blog"
  , feedDescription = "a blog"
  , feedAuthorName = "Robin Schroer"
  , feedAuthorEmail = "sulami@peerwire.org"
  , feedRoot = "https://sulami.github.io"
  }
