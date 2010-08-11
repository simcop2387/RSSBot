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
	
	for my $feed (@feeds)
	{
	}
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

sub joinentries
{
}

1;