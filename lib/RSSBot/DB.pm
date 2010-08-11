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
}

sub checkschema
{
	#not sure safe way to do this yet
	return 1;
	#$dbh->do("")
}

sub getbots
{
}

sub checkfeeds
{
}

1;