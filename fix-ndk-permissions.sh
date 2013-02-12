find . -type f -not -perm -o=r -print0 | xargs -0 chmod o+r
find . -type d -not -perm -o=r,o=x -print0 | xargs -0 chmod o+rx
find . -type f \( -perm -u=x -and  -not -perm -o=x \) -print0 | xargs -0 chmod o+x
