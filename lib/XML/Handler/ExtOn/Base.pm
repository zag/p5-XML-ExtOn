package XML::PSAX::Base;
use strict;
use warnings;

use XML::SAX::Base;
use XML::PSAX::Element;
use Carp;
use Data::Dumper;
use base 'XML::SAX::Base';
use vars qw( $AUTOLOAD);

sub start_document {
    my ($self, $document) = @_;
    $self->{__xmlns} = XML::NamespaceSupport->new({ xmlns => 1 });
    $self->SUPER::start_document($document);
}


sub start_prefix_mapping {
    my $self = shift;
    my ($map) = @_;
    $self->{__xmlns}->declare_prefix($map->{Prefix}, $map->{NamespaceURI});
    return $self->SUPER::start_prefix_mapping(@_);
    
}
sub make_element {
    my $self = shift;
    my $name = shift;
    my $element = new XML::PSAX::Element::
      name  => $name,
      xmlns => $self->{__xmlns};
    return $element;
}

sub AUTOLOAD {
    my $self = shift;
    my $data = shift;
    my $call = $AUTOLOAD;
    $call =~ s/^.*:://;
    return if $call eq 'DESTROY';
    warn Dumper($data);
    $call = "SUPER::$call";
    return $self->$call($data)
}
1;
