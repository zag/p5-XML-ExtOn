package XML::Filter::SAX2toPSAX;
use strict;
use warnings;

use XML::SAX::Base;
use XML::PSAX;
use Carp;
use Data::Dumper;
use XML::NamespaceSupport;
use XML::PSAX::Base;
use base 'XML::PSAX::Base';
use vars qw( $AUTOLOAD);

sub start_element {
    my $self = shift;
    my $data = shift;
    $self->{__xmlns}->push_context;
    my $elem = $self->make_element( $data->{LocalName} );
    $elem->attrs_from_sax2( $data->{Attributes} );
    $elem->set_prefix( $data->{Prefix} || '' );
    $elem->set_ns_uri( $data->{NamespaceURI} );
    return $self->SUPER::start_element($elem);
}

sub AUTOLOAD {
    my $self = shift;
    my $data = shift;
    my $call = $AUTOLOAD;
    $call =~ s/^.*:://;
    return if $call eq 'DESTROY';
    #    warn Dumper($data);
    $call = "SUPER::$call";
    return $self->$call($data);
}
1;
