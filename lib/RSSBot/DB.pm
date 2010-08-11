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
	my $sthb = $self->{dbh}->prepare("SELECT * FROM bots;");
	$sthb->execute();
	
	while(my $row = $sthb->fetchrow_hashref())
	{
		$bots->{$row->{bid}} = $row;
	}
	
	for my $bid (keys %$bots)
	{
		my $sthc = $self->{dbh}->prepare("SELECT channel FROM botchannels WHERE bid = ?");
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
	
	my $sth = $self->{dbh}->prepare("SELECT * FROM rssfeeds;");
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
}

1;