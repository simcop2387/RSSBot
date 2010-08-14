use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'RSSBot',
    AUTHOR              => q{"Ryan Voots" <"simcop2387@simcop2387.info">},
    VERSION_FROM        => 'lib/RSSBot.pm',
    ABSTRACT_FROM       => 'lib/RSSBot.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'artistic')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::Feed' => 0,
        'POE::Component::IRC' => 0,
        'POE::Component::IRC::Plugin::Connector' => 0,
        'POE::Component::IRC::Plugin::NickReclaim' => 0,
        'DBI' => 0,
        'DBD::SQLite' => 0,
        'URI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'RSSBot-*' },
);
