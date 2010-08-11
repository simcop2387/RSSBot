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
	print Dumper($bots);
	
	for my $bid (keys %$bots)
	{
		my $sthc = $self->{dbh}->prepare("SELECT channel FROM botchannels WHERE bid = ?");
		$sthc->execute($bid);
		while(my ($channel) = $sthc->fetchrow())	
		{
			push @{$bots->{$bid}{channels}}, $channel;
		}
	}
	
	print Dumper($bots);
	return $bots;
}

sub checkfeeds
{
}

1;