set -x

export hg=/usr/local/bin/hg

cd /data/synto

hg st|/bin/grep -v .swp |/bin/grep ^?
if [ $? -eq 0 ]; then
    hg add .
    hg commit -m "Auto commit via hostmgr & push" -u "oklrelease"
fi

hg st |/bin/grep -v .swp |/bin/grep ^M
if [ $? -eq 0 ]; then
    hg commit -m "Changes in data/synto folder auto commit via hostmgr" -u "oklrelease"
fi

hg st |/bin/grep -v .swp |/bin/grep ^R
if [ $? -eq 0 ]; then
    hg commit -m "Changes in data/synto folder auto commit via hostmgr" -u "oklrelease"
fi