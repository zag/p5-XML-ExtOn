package XML::ExtOn::IncXML;
use base 'XML::ExtOn';
use strict;
use warnings;

sub on_start_element {
    my ( $self, $elem ) = @_;
    unless ( $self->{__NOT_SKIPED}++ ) {
        $elem->delete_element;
    }
    $elem;
}
1
