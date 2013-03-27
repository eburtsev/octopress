---
layout: post
title: "Merging unrelated repositories in mercurial"
date: 2013-03-27 21:46
comments: true
categories: [hg, mercurial]
---
Some time ago I had some projects which I wanted to combine in one big project and keep history for all of them. This can be done following to [this article](http://mercurial.selenic.com/wiki/MergingUnrelatedRepositories). But if I'll use this solution in result I'll have more than one tails (how it illustrated in picture below).
```
   @
   |
   o-----------o
   |           |
   .           .
   .           .
   |           |
   o           o
  tail        tail
   #1          #2
```

But I wanted to make repository structure as on picture below:
```
   @
   |
   o-----------o
   |           |
   . default   .
   .           . Feature
   |           | branch
   o           o
   |           |
   o-----------o
   |
   o
```

After some hours with console magic I found solution, and I want to share it.

<!--more-->

I decided to modify history to avoid possible merge conflicts. I moved all files in each project to appropriate subfolder (named as project). To do this we needs to export patch and modify it to change pathes.
``` bash
PROJECT=project1

cd ${PROJECT}
hg export -r0:tip -o ${PROJECT}.patch

# Modify patch (Move all files to subdirectory)

sed -i.bak -e "s/\(diff -r [0-9a-f]* -r [0-9a-f]*\) \(.*\)/\1 ${PROJECT}\/\2/g" ${PROJECT}.patch
sed -i.bak -e "s/--- a/\0\/${PROJECT}/g" ${PROJECT}.patch
sed -i.bak -e "s/+++ b/\0\/${PROJECT}/g" ${PROJECT}.patch
```

For each of projects we need to make some steps (enough to change ```PROJECT``` variable)

If you want move projects to named branches instead of multiply default branches you needs prepare following commands which adds branch name information to patch:
``` bash
BRANCH=${PROJECT} branch
sed -i.bak -e "s/# Date \(.*\)/# Date \1\n# Branch $BRANCH/g" ${PROJECT}.patch
```

Now we have patches made from all projects we can combine them. First initialize aggregate repository and import oldest project of all.
``` bash
hg init combined
hg import ../project1/project1.patch
```

For other project we need do following steps:  

1. Update aggregate project to revision which will be parent for appropriate project
2. Import patch (don't forget ```--import-branch``` key if you using named branches)
3. Merge branches
4. Repeat it for other patches

This approach illustrated below. If you not using named branches you can use these simple steps:
``` bash
hg up <parent-revision>
hg import ../project1/project1.patch --import-branch
hg merge
```

If you using named branches your way will more complicated:
``` bash
hg up <parent-revision>
hg import ../project1/project1.patch --import-branch
hg up <latest-patch-revision> # update to latest revision of imported project
hg commit --close-branch
hg up default
hg merge <latest-patch-revision>
hg commit -m "Merge"
```

I've created script which can help to automate first part of this article:
``` bash modify-patch.sh http://burtsev.net/downloads/merging-unrelated-repositories-in-mercurial/modify-patch.sh Download
#!/bin/bash

PROJECT=$1

pushd ${PROJECT}

hg export -r0:tip -o ${PROJECT}.patch

# Modify patch (Move all files to subdirectory)

sed -i.bak -e "s/\(diff -r [0-9a-f]* -r [0-9a-f]*\) \(.*\)/\1 ${PROJECT}\/\2/g" ${PROJECT}.patch
sed -i.bak -e "s/--- a/\0\/${PROJECT}/g" ${PROJECT}.patch
sed -i.bak -e "s/+++ b/\0\/${PROJECT}/g" ${PROJECT}.patch

popd

```

I'll glad if this article will useful for someone. Comments are welcome.

