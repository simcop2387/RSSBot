#!/usr/bin/perl

use strict;
use warnings;

use lib './lib';

use RSSBot;
use POE;

RSSBot->spawn("var/rssbot.sqlite");

POE::Kernel->run();
