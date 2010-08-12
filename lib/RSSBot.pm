package RSSBot;

use warnings;
use strict;

use Data::Dumper;
use POE qw(Component::IRC);
use RSSBot::DB;

=head1 NAME

RSSBot - The great new RSSBot!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use RSSBot;

    my $foo = RSSBot->spawn("database.db");
    ...

=head1 SUBROUTINES/METHODS

=head2 spawn

=cut

sub spawn {
	my $class = shift;
	my $database = shift; #filename for the database

	my $dbo = RSSBot::DB->new($database);
		
	my $bots = $dbo->getbots();
	
	for my $bot (keys %$bots)
	{
		$bots->{$bot}{irc} =  POE::Component::IRC->spawn( 
			nick => $bots->{$bot}{nick},
			ircname => $bots->{$bot}{ircname},
			alias => "irc_".$bot,
			server => $bots->{$bot}{server},
    	) or die "Oh noooo! $!"; 
	}
	
	 POE::Session->create(
     package_states => [
         RSSBot => [ qw(_start irc_001 checkfeeds irc_msg) ],
     ],
     heap => { bots => $bots, dbo => $dbo },
 );
	
}

=head2 irc_001

=cut

sub irc_001 
{
	my $sender = $_[SENDER];
	my $heap = $_[HEAP];
	my $kernel = $_[KERNEL];

     # Since this is an irc_* event, we can get the component's object by
     # accessing the heap of the sender. Then we register and connect to the
     # specified server.
     my $irc = $sender->get_heap();
     my $bid = $irc->{alias};
     $bid =~ s/irc_//; #remove first part of alias to get the number
     my $bot = $heap->{bots}{$bid};
     my $channels = $bot->{channels};

     print "Connected to ", $irc->server_name(), "\n";

     # we join our channels
     $irc->yield( join => $_ ) for @$channels;
     return;
}

=head2 _start

=cut

sub _splitandsend
{
	my $irc = shift;
	my $who = shift;
	my $string = shift;
	my @lines = split/\n/, $string;
	
	$irc->yield(privmsg=>$who=>$_) for @lines;
}

sub irc_msg
{
     my $heap = $_[HEAP];
     my $kernel = $_[KERNEL];
     my $sender = $_[SENDER];
     my $irc = $sender->get_heap();
     my ($who, $what) = @_[ARG0, ARG2];
     my ($nick) = ($who =~ m/^(.*)!/g);
     
     my $isadmin = $heap->{dbo}->checkuser($who);

    if ($what =~ /help/)
    {
    	if ($isadmin)
    	{
    	_splitandsend($irc, $nick => << 'EOL' );
Welcome to RSSBot!
You're currently recognized as an administrator

Commands
    listbots # list the bots on the system
    listfeeds # list the feeds we check
    explainbot BID # shows you everything about the bot, see listbots for the id
	addfeed URL  # add a feed to the system
	addbot nick server # add bot to the system (requires restart to start bot)
	addfeedtobot RID BID # adds a feed to a bot for announcing, RID is feed id, BID is bot id, see list{feeds,bots}
	addchantobot BID channel # adds a channel to a bot, see listbots for BID
	removefeed RID # remove a feed from the system, see listfeeds
	removebot BID # remove a bot from the system, see listbots
	removefeedfrombot RID BID # removes a feed from a bot for announcing, see list{feeds,bots}
	removechanfrombot BID channel # removes a channel from a bot, see listbots
	help # this you ninny
	source # http://github.com/simcop2387/RSSBot
EOL
    	}
    	else
    	{
    	_splitandsend($irc, $nick => << 'EOL' );
Welcome to RSSBot!
You're currently recognized as a regular user

Commands
	help # this you ninny
	source # http://github.com/simcop2387/RSSBot		    	
EOL
    	}
    }
	elsif ($what =~ /source/)   
	{
		$irc->yield(privmsg => $nick, "http://github.com/simcop2387/RSSBot");
	}
	elsif ($isadmin)
	{
		if ($what =~ /listbots/)
		{
			my @bots = $heap->{dbo}->getbots();
			my $output = "BID | Nickname | Server | [Channels]\n----------------------------------------\n";
			
			for my $bot (@bots)
			{
				my @channels = $heap->{dbo}->getchannels($bot->{bid});
				$output.=$bot->{bid}.".   ".$bot->{nick}."    ".$bot->{server}."    [".()."]\n"
			}
			
		}
		elsif ($what =~ /listfeeds/)
		{
		}
		elsif ($what =~ /explainbot\s+(.*)\s+/)
		{
		}
		elsif ($what =~ /addfeed\s+(.*)\s+/)
		{
			$heap->{dbo}->addfeed($1, $2);
		}
		elsif ($what =~ /addbot\s+(.*?)\s+(.*?)\s+/)
		{
			$heap->{dbo}->addbot($1, $2);
		}
		elsif ($what =~ /addfeedtobot\s+(.*?)\s+(.*?)\s+/)
		{
			$heap->{dbo}->addfeedtobot($1, $2);
		}
		elsif ($what =~ /addchantobot\s+(.*?)\s+(.*?)\s+/)
		{
			$heap->{dbo}->addchantobot($1, $2);
		}
		elsif ($what =~ /removefeed\s+(.*?)\s+/)
		{
			$heap->{dbo}->removefeed($1);
		}
		elsif ($what =~ /removebot\s+(.*?)\s+/)
		{
			$heap->{dbo}->removebot($1);
		}
		elsif ($what =~ /removefeedfrombot\s+(.*?)\s+(.*?)\s+/)
		{
			$heap->{dbo}->removefeedfrombot($1, $2);
		}
		elsif ($what =~ /removechanfrombot\s+(.*?)\s+(.*?)\s+/)
		{
			$heap->{dbo}->removechanfrombot($1, $2);
		}
	}
}

 sub _start {
     my $heap = $_[HEAP];
     my $kernel = $_[KERNEL];

     # retrieve our component's object from the heap where we stashed it
     
     my $bots = $heap->{bots};

     #cycle through them all and hope for the best
	 for my $bot (keys %$bots)
	 {
       $bots->{$bot}{irc}->yield( register => 'all' );
       $bots->{$bot}{irc}->yield( connect => { } );
	 }
	 
	 $kernel->delay("checkfeeds"=>60);
	 
     return;
 }

sub checkfeeds
{
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	my @toannounce = $heap->{dbo}->checkfeeds();
	
	for my $feed (@toannounce)
	{
		my $bid = $feed->{bid};
		my $channels = $heap->{bots}{$bid}{channels};
		
		for my $channel (@$channels)
		{
			$heap->{bots}{$bid}{irc}->yield(privmsg => $channel => "New Article: ".$feed->{entry}->title()." @ ".$feed->{entry}->link().(defined($feed->{entry}->author())?" by ".$feed->{entry}->author():""));
		}
	}
	
	$kernel->delay(checkfeeds=>1800);
}

=head1 AUTHOR

"Ryan Voots", C<< <"simcop2387 at simcop2387.info"> >>

=head1 BUGS

Please report any bugs or feature requests to C<simcop2387 at simcop2387.info>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RSSBot


You can also look for information at:

L<irc://irc.freenode.net/#buubot>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 "Ryan Voots".

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of RSSBot
