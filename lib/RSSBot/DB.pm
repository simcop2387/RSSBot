package RSSBot::DB;

use DBI;
use XML::Feed;
use Data::Dumper;

sub new
{
	my $self = bless {}, shift;
	
	$self->{file} = shift;
	$self->{dbh} = DBI->connect("dbi:SQLite:dbname=".$self->{file},"","");
	$self->checkschema();

	$self->{sth}{checkentry} = $self->{dbh}->prepare("SELECT 1 FROM rssentry WHERE rid = ? AND entryid = ? LIMIT 1");
	$self->{sth}{addentry}   = $self->{dbh}->prepare("INSERT INTO rssentry (rid, entryid) VALUES (?, ?)");
	$self->{sth}{getbots}    = $self->{dbh}->prepare("SELECT * FROM bots;");
	$self->{sth}{getchannels}= $self->{dbh}->prepare("SELECT channel FROM botchannels WHERE bid = ?");
	$self->{sth}{getfeeds}   = $self->{dbh}->prepare("SELECT * FROM rssfeeds;");
	$self->{sth}{getbidbyrid}= $self->{dbh}->prepare("SELECT bid FROM rssbots WHERE rid = ?");
	
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

sub checkfeeds
{
	my $self = shift;
	my @feeds = $self->getfeeds();
	my @valid;
	
	for my $feed (@feeds)
	{
		my $parsed = XML::Feed->parse($feed->{feedurl});
		my @entries = $parsed->entries();
		
		for my $entry (@entries)
		{
			if (!$self->checkentry($feed->{rid}, $entry->id()))
			{
				$self->addentry($feed->{rid}, $entry->id());
				push @valid, {feed => $feed, entry => $entry};	
			}
		}
	}
	
	my @joined = $self->joinentries(@valid);
	
	print Dumper(\@joined);
}

sub checkentry
{
	my $self = shift;
	my $rid = shift;
	my $entryid = shift;
	
	my $sth = $self->{sth}{checkentry};
	
	$sth->execute($rid, $entryid);
	return $sth->rows();
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
		$self->{sth}{getbidbyrid}->execute($entry->{rid});
		
		while(my ($bid) = $self->fetchrow())
		{
			push @joined, {%$entry, bid => $bid};
		}	
	}
	
	return @joined;
}

1;