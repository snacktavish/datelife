[![Build Status](https://travis-ci.org/phylotastic/datelife.svg)](https://travis-ci.org/phylotastic/datelife)

This has the core functionality of DateLife, part of Phylotastic (NSF-funded). It is still under rapid development. With this package, you can get ages of clades or even chronograms using information in [OpenTree](http://opentreeoflife.org)'s tree store. Newick strings or phylo objects can also be dated using these trees and the congruifier, part of Geiger ([Eastman et al. 2013](http://onlinelibrary.wiley.com/doi/10.1111/2041-210X.12051/abstract), [Harmon et al. 2008](http://bioinformatics.oxfordjournals.org/content/24/1/129.short)).

---

**Old instructions, to remove soon**

To have new code actually run on the server, you have to copy it to the proper directory and then re-launch Rserve. To do this from the datelife directory with R, it's

cp *.R /var/FastRWeb/web.R/

then kill Rserve or restart the server

then 

/bin/sh /var/FastRWeb/code/start > /Users/bomeara/Dropbox/recentFastRWebStart.Rout

The command above is automatically run by a cron job two minutes after rebooting (delay so that the server has time to get on the network)