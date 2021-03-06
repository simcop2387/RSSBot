package RSSBot::DB;

use strict;
use warnings;

use DBI;
use XML::Feed;
use URI;
use Data::Dumper;

sub new
{
	my $self = bless {}, shift;
	
	$self->{file} = shift;
	$self->{dbh} = DBI->connect("dbi:SQLite:dbname=".$self->{file},"","");
	$self->checkschema();

    #i'm having to coerce rid comparisions to be strings... i dunno why, but it fixes the bugs and prevents sql injections

	$self->{sth}{getbots}         = $self->{dbh}->prepare("SELECT * FROM bots;");
	$self->{sth}{getbotbybid}     = $self->{dbh}->prepare("SELECT * FROM bots WHERE bid||'' = ?||'';");
	$self->{sth}{getchannels}     = $self->{dbh}->prepare("SELECT channel FROM botchannels WHERE bid = ?");
	$self->{sth}{getfeeds}        = $self->{dbh}->prepare("SELECT * FROM rssfeeds;");
	$self->{sth}{getbidbyrid}     = $self->{dbh}->prepare("SELECT bid FROM rssbots WHERE rid||'' = ? || ''");
    $self->{sth}{getridbybid}     = $self->{dbh}->prepare("SELECT rid FROM rssbots WHERE bid||'' = ? || ''");
    $self->{sth}{getfeedsbybid}   = $self->{dbh}->prepare("SELECT rssfeeds.rid, rssfeeds.feedurl FROM rssbots, rssfeeds WHERE rssfeeds.rid||'' = rssbots.rid||'' AND rssbots.bid||''=?||''");
    	
	$self->{sth}{addbot}          = $self->{dbh}->prepare("INSERT INTO bots (nick, server, ircname, port) VALUES (?, ?, ?, ?)");
    $self->{sth}{addfeed}         = $self->{dbh}->prepare("INSERT INTO rssfeeds (feedurl) VALUES (?)");
    $self->{sth}{addentry}        = $self->{dbh}->prepare("INSERT INTO rssentry (rid, entryid) VALUES (?, ?)");
    $self->{sth}{addfeedtobot}    = $self->{dbh}->prepare("INSERT INTO rssbots (rid, bid) VALUES (?, ?)");
    $self->{sth}{addchanneltobot} = $self->{dbh}->prepare("INSERT INTO botchannels (channel, bid) VALUES (?, ?)");
    
    $self->{sth}{removefeed}      = $self->{dbh}->prepare("DELETE FROM rssfeeds WHERE rid||'' = ?; DELETE FROM rssbots WHERE rid||'' = ?; DELETE FROM rssentry    WHERE rid||'' = ?");
    $self->{sth}{removebot}       = $self->{dbh}->prepare("DELETE FROM bots     WHERE bid||'' = ?; DELETE FROM rssbots WHERE bid||'' = ?; DELETE FROM botchannels WHERE bid||'' = ?");
	$self->{sth}{removechanfrombot}=$self->{dbh}->prepare("DELETE FROM botchannels WHERE bid||'' = ?||'' AND channel = ?");
	$self->{sth}{removefeedfrombot}=$self->{dbh}->prepare("DELETE FROM rssbots     WHERE bid||'' = ?||'' AND rid||'' = ?||''");

    $self->{sth}{checkentry}      = $self->{dbh}->prepare("SELECT 1 FROM rssentry WHERE rid||'' = ?||'' AND entryid = ? LIMIT 1");
	
	return $self;
}

sub checkschema
{
	my $self = shift;
	return 1;
}

sub getbots
{
	my $self = shift;
	my $bots;
	my $sthb = $self->{sth}{getbots};
	$sthb->execute();
	
	while(my $row = $sthb->fetchrow_hashref())
	{
		$bots->{$row->{bid}} = $row;
	}
	
	for my $bid (keys %$bots)
	{
		my $sthc = $self->{sth}{getchannels};
		$sthc->execute($bid);
		while(my ($channel) = $sthc->fetchrow())	
		{
			push @{$bots->{$bid}{channels}}, $channel;
		}
	}
	
	return $bots;
}

sub checkuser
{
	my $self = shift;
	my $who  = shift;
	
	return 1; #always admin for now, will make real system later
}

sub getbotbybid
{
	my $self = shift;
	my $bid = shift;
	my $sthb = $self->{sth}{getbotbybid};
	$sthb->execute($bid);
	
	my $bot = $sthb->fetchrow_hashref();
	
    my $sthc = $self->{sth}{getchannels};
    $sthc->execute($bid);
    while(my ($channel) = $sthc->fetchrow())	
	{
	    push @{$bot->{channels}}, $channel;
    }
    
	return $bot;
}

sub getfeeds
{
	my $self = shift;
	
	my $sth = $self->{sth}{getfeeds};
	$sth->execute();
	
	my @feeds;
	
	while(my $row = $sth->fetchrow_hashref())
	{
		push @feeds, $row;
	}
	
	return @feeds;
}

sub getfeedsbybid
{
	my $self = shift;
	my $bid = shift;
	
	my $sth = $self->{sth}{getfeedsbybid};
	$sth->execute($bid);
	
	my @feeds;
	
	while(my $row = $sth->fetchrow_hashref())
	{
		push @feeds, $row;
	}
	
	return @feeds;
}

sub addbot
{
	my $self = shift;
	my $bot = shift;
	my $server = shift;
	my $ircname = shift // "RSSBot";
	my $port = shift // 6667;
	my $sth = $self->{sth}{addbot};
	
	$sth->execute($bot, $server, $ircname, $port);
	return $sth->rows();
}

sub addchanneltobot
{
	my $self = shift;
	my $bid = shift;
	my $channel = shift;
	my $sth = $self->{sth}{addchanneltobot};
	
	$sth->execute($bid, $channel);
	return $sth->rows();
}

sub addfeed
{
	my $self = shift;
	my $url = shift;
	my $sth = $self->{sth}{addfeed};
	
	$sth->execute($url);
	return $sth->rows();
}

sub addfeedtobot
{
	my $self = shift;
	my $rid = shift;
	my $bid = shift;
	my $sth = $self->{sth}{addfeedtobot};
	
	$sth->execute($rid,$bid);
	return $sth->rows();
}

sub removebot
{
	my $self = shift;
	my $bid = shift;
	my $sth = $self->{sth}{removebot};
	
	$sth->execute($bid, $bid, $bid);
	return $sth->rows();
}

sub removechannelfrombot
{
	my $self = shift;
	my $channel = shift;
	my $bid = shift;
	my $sth = $self->{sth}{removechanfrombot};
	
	$sth->execute($bid, $channel);
	return $sth->rows();
}

sub removefeed
{
	my $self = shift;
	my $rid = shift;
	my $sth = $self->{sth}{removefeed};
	
	$sth->execute($rid);
	return $sth->rows();
}

sub getchannels
{
	my $self = shift;
	my $bid = shift;
	my $sth = $self->{sth}{getchannels};
	
	$sth->execute($bid);
	my @results;
	push @results, $_ while (($_) = $sth->fetchrow());
	return @results;
}

sub getridbybid
{
	my $self = shift;
	my $bid = shift;
	my $sth = $self->{sth}{getridbybid};
	
	$sth->execute($bid);
	my @results;
	push @results, $_ while (($_) = $sth->fetchrow());
	return @results;
}

sub getbidbyrid
{
	my $self = shift;
	my $rid = shift;
	my $sth = $self->{sth}{getbidbyrid};
	
	$sth->execute($rid);
	my @results;
	push @results, $_ while (($_) = $sth->fetchrow());
	return @results;
}

sub removefeedfrombot
{
	my $self = shift;
	my $rid = shift;
	my $bid = shift;
	my $sth = $self->{sth}{removefeedfrombot};
	
	#swapped in SQL
	$sth->execute($bid,$rid);
	return $sth->rows();
}

sub checkfeeds
{
	my $self = shift;
	my @feeds = $self->getfeeds();
	my @valid;
	
	for my $feed (@feeds)
	{
		eval{
		my $parsed = XML::Feed->parse(URI->new($feed->{feedurl}));
		my @entries = $parsed->entries();
		
		for my $entry (@entries)
		{
			if (!$self->checkentry($feed->{rid}, $entry->id()))
			{
				$self->addentry($feed->{rid}, $entry->id());
				push @valid, {feed => $feed, entry => $entry};	
			}
		}
		}; #silently ignore errors for now
	}
	
	my @joined = $self->joinentries(@valid);
	
    return @joined;
}

sub checkentry
{
	my $self = shift;
	my $rid = shift;
	my $entryid = shift;
	#$self->{sth}{checkentry} = $self->{dbh}->prepare("SELECT 1 FROM rssentry WHERE rid||'' = ?||'' AND entryid = ? LIMIT 1"); 
	my $sth = $self->{sth}{checkentry};
	
	$sth->execute($rid, $entryid);
	return $sth->fetchrow();
}

sub addentry
{
	my $self = shift;
	my $rid = shift;
	my $entryid = shift;
	
	my $sth = $self->{sth}{addentry};
	
	$sth->execute($rid, $entryid);
	return $sth->rows();
}

#this is just like an inner join on a database, except i can't do it there since sqlite doesn't support fetching thigns from rss feeds, lazy developers....
sub joinentries
{
	my $self = shift;
	my @entries = @_;
	
	my @joined;
	
	for my $entry (@entries)
	{
		#ok for some damned reason it doesn't want to work unless i do this... why? i know about the sql injections but.. wtf
		my $sth = $self->{sth}{getbidbyrid};
		$sth->execute($entry->{feed}{rid});
		
		while(my ($bid) = $sth->fetchrow())
		{
			push @joined, {%$entry, bid => $bid};
		}	
	}
	
	return @joined;
}

1;