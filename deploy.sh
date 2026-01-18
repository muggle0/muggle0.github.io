git add source/.
git commit -m 'message'
git push
hexo clean
hexo g
cp -r  source/_posts/images/ public/images
hexo deploy