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
         RSSBot => [ qw(_start irc_001) ],
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

 sub _start {
     my $heap = $_[HEAP];

     # retrieve our component's object from the heap where we stashed it
     
     my $bots = $heap->{bots};

     #cycle through them all and hope for the best
	 for my $bot (keys %$bots)
	 {
       $bots->{$bot}{irc}->yield( register => 'all' );
       $bots->{$bot}{irc}->yield( connect => { } );
	 }
	 
     return;
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
