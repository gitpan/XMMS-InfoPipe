package XMMS::InfoPipe;
use strict;
use warnings;

our $VERSION = '0.02';
our $PIPE    = '/tmp/xmms-info';

=head1 NAME

XMMS::InfoPipe -  A small module to gather the information produced by
the infopipe plugin for XMMS

=head1 SYNOPSIS

        use XMMS::InfoPipe;
	
        my $xmms = XMMS::InfoPipe->new();
        
        print "Currently ", $xmms->{info}->{Status}, ": ", $xmms->{info}->{Title};

=head1 DESCRIPTION

This module was written to provide a way to snag the information from the
file produced by the xmms-infopipe plugin for XMMS.  With only a few
convenience methods, all of the information that the plugin provides can
be obtained from the C<$xmms-E<gt>{info}> hashref.

B<Nota Bene:> If the XMMS plugin isn't enabled, then this module will NOT
return results as expected (if it even works).

=head1 METHODS

=head2 new

    my $xmms = XMMS::InfoPipe->new();

Creates a new XMMS::InfoPipe instance.  By default this parses the file
before returning the object.  This will undoubtedly cause some initial
slowdown (the bottleneck of XMMS::InfoPipe is when it must grab information
from the named pipe the XMMS plugin provides), and so you may disable
this first parsing by specifying a false value to ForceParse.  For example:

    my $xmms = XMMS::InfoPipe->new(ForceParse => 0);

will create the object and immediately return it, without first populating
it with the information from XMMS.  This means that before trying to obtain
this information, you should first call C<$xmms-E<gt>update_info>.

=cut


sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {
        error       => '',
        info        => {},
        _force_parse=> $args{ForceParse} || 1
    }, $class;
    
    $self->{info} = $self->_parse if $self->{_force_parse};
    return $self;
}

=head2 is_running

    $xmms->is_running()

Returns 1 if XMMS is running and 0 if not.  This relies on the fact that
the named pipe does not exist if XMMS is not running.  If the infopipe
plugin isn't enabled, this will also return 1.

=cut

sub is_running {
    my $self = shift;
    return $self->{info}->{Status} ne 'Not Running' ? 1 : 0;
}

=head2 is_playing

    $xmms->is_playing()

Returns 1 if XMMS is playing a song and 0 if not.

=cut

sub is_playing {
    my $self = shift;
    return $self->{info}->{Status} eq 'Playing' ? 1 : 0;
}

=head2 is_paused

    $xmms->is_paused()

Returns 1 if XMMS is paused and 0 if not.

=cut

sub is_paused {
    my $self = shift;
    return $self->{info}->{Status} eq 'Paused' ? 1 : 0;
}

=head2 update_info

    $xmms->update_info()
    
Updates C<$xmms-E<gt>{info}> and returns the updated hashref for convenience.

=cut

sub update_info {
    my $self = shift;
    $self->{info} = $self->_parse;
    return $self->{info};
}

=head2 _parse

    $xmms->_parse
    
Internal function that parses data from the info pipe and returns a hashref.
You shouldn't need to use this.

=cut

sub _parse {
    open DATA, $PIPE or return { Status => 'Not Running' };
    my @data = <DATA>;
    close DATA;
    
    my $info = {};
    for (@data) {
        chomp; my ($field, $value) = split /: /, $_, 2;
        $info->{$field} = $value;
    }
    return $info;
}

=head1 VARIABLES

=head2 $XMMS::InfoPipe::PIPE

    $XMMS::InfoPipe::PIPE = '/tmp/other-name';

This variable defaults to C</tmp/xmms-info> which should be a symlink (created
by xmms-infopipe) to the real named pipe (something like C</tmp/xmms-info_user.0>).
If for whatever reason you need to change it (maybe you have a file generated by
something else that follows the same format as xmms-infopipe), just set it before
C<update_info> is called (by default that means before C<new> is called)
for the right file to be used.

=head1 INFORMATION AVAILABLE

As of version 1.3 of the xmms-infopipe plugin, the following information is available:

    XMMS protocol version
    InfoPipe Plugin version
    Status
    Tunes in playlist
    Currently playing
    uSecPosition
    Position
    uSecTime
    Time
    Current bitrate
    Samping Frequency
    Channels
    Title
    File

To get this information, just use the corresponding key name above.

=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.

=head1 AUTHOR

Copyright (C) 2003, Thomas R. Sibley C<trs [at] perlmonk [dot] org>

=cut

1;
