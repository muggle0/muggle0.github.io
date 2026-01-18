git add source/.
git add images/.
git commit -m 'message'
git push
hexo clean
hexo g
cp -r  ./images/ public/images
hexo deploy